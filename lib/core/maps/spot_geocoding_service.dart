import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai/ai_client.dart';
import '../ai/ai_mode.dart';
import '../ai/search_client.dart';

class SpotGeocodingResult {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? mapUrl;
  final String? websiteUrl;
  final String? mapLabel;
  final String? geocodeSource;

  const SpotGeocodingResult({
    this.latitude,
    this.longitude,
    this.address,
    this.mapUrl,
    this.websiteUrl,
    this.mapLabel,
    this.geocodeSource,
  });
}

class SpotGeocodingService {
  const SpotGeocodingService._();

  /// スポットの地図情報を解決する。
  ///
  /// 解決の優先順位:
  /// 1. 既存の Maps URL から座標をパース（short URL はリダイレクト展開）
  /// 2. Web 検索結果の URL から Maps URL を検出してパース
  /// 3. AI に Maps URL と住所を抽出させ、URL から座標をパース + リダイレクト展開
  /// 4. Nominatim（OpenStreetMap）で店名＋住所を座標に変換
  /// 5. フォールバック: 店名・エリア・住所から Google Maps 検索 URL を構築
  ///    （座標なしでも Maps URL は必ず返す）
  static Future<SpotGeocodingResult> resolve({
    required String name,
    String? area,
    String? address,
    String? mapUrl,
  }) async {
    // 1a. 既存 Maps URL から座標をパース（直接）
    final parsedFromUrl = _parseFromMapUrl(mapUrl);
    if (parsedFromUrl?.latitude != null) {
      return parsedFromUrl!;
    }

    // 1b. 短縮 URL / 座標なし Maps URL → リダイレクト展開して再パース
    if (parsedFromUrl != null) {
      // Maps URL と認識されたがlatがなかった場合
      final expanded = await _expandMapUrl(mapUrl!);
      if (expanded?.latitude != null) return expanded!;
    }

    // Web 検索が使えない場合は Nominatim だけ試してフォールバック
    if (!SearchClient.canUseWebSearch || !AIClient.isConfigured) {
      final nom = await _nominatimGeocode(name: name, area: area, address: address);
      return SpotGeocodingResult(
        latitude: nom?.latitude,
        longitude: nom?.longitude,
        mapUrl: (mapUrl?.trim().isNotEmpty == true)
            ? mapUrl
            : _buildMapsSearchUrl(name, area, address),
        geocodeSource: nom != null ? 'nominatim' : 'constructed',
      );
    }

    // 2. Web 検索で Google Maps URL を探す
    final queryParts = [
      name.trim(),
      if ((area ?? '').trim().isNotEmpty) area!.trim(),
    ];
    final searchQuery = '${queryParts.join(' ')} Google マップ';
    final results = await SearchClient.instance.search(
      searchQuery,
      maxResults: 8,
    );

    // 検索結果の URL を直接スキャン（最も確実な方法）
    for (final result in results) {
      final parsed = _parseFromMapUrl(result.url);
      if (parsed?.latitude != null) {
        return SpotGeocodingResult(
          latitude: parsed!.latitude,
          longitude: parsed.longitude,
          address: address,
          mapUrl: result.url,
          geocodeSource: 'web_search_url',
        );
      }
    }

    // 3. AI に Maps URL と住所を探してもらう
    String? foundAddress = address;
    String? foundMapUrl = mapUrl;
    String? foundWebsiteUrl;
    String? foundMapLabel;

    if (results.isNotEmpty) {
      final searchContext = SearchClient.instance.formatSearchResults(results);
      final response = await AIClient.instance.generateStructured(
        prompt: '''
あなたはスポット情報の整理補助AIです。
以下の検索結果から、対象スポットの **Google Maps URL** と **住所** を抽出してください。
根拠がない値は空欄にしてください。推測で補わないでください。

対象スポット: $name${area != null && area.isNotEmpty ? ' ($area)' : ''}
${address != null && address.isNotEmpty ? '住所ヒント: $address' : ''}

検索結果:
$searchContext

注意:
- map_url は maps.google.com、google.com/maps、maps.app.goo.gl、goo.gl/maps などのみ
- 検索結果の URL 列も確認すること
- 住所は日本語の完全な住所で
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'map_url': {
              'type': 'string',
              'description':
                  'Google Maps URL (maps.google.com / google.com/maps)',
            },
            'address': {'type': 'string'},
            'website_url': {'type': 'string'},
            'map_label': {'type': 'string'},
          },
        },
        mode: AIMode.standard,
      );

      foundMapUrl = _toStringOrNull(response['map_url']) ?? foundMapUrl;
      foundAddress = _toStringOrNull(response['address']) ?? foundAddress;
      foundWebsiteUrl = _toStringOrNull(response['website_url']);
      foundMapLabel = _toStringOrNull(response['map_label']);

      // AI が見つけた Maps URL から座標をパース（直接 or リダイレクト展開）
      if (foundMapUrl != null) {
        final parsedFromAiUrl = _parseFromMapUrl(foundMapUrl);
        final coords = parsedFromAiUrl?.latitude != null
            ? parsedFromAiUrl
            : await _expandMapUrl(foundMapUrl);
        if (coords?.latitude != null) {
          return SpotGeocodingResult(
            latitude: coords!.latitude,
            longitude: coords.longitude,
            address: foundAddress,
            mapUrl: foundMapUrl,
            websiteUrl: foundWebsiteUrl,
            mapLabel: foundMapLabel,
            geocodeSource: 'web_search',
          );
        }
      }
    }

    // 4. Nominatim で座標を取得（住所 or 店名＋エリアで検索）
    final nom = await _nominatimGeocode(
      name: name,
      area: area,
      address: foundAddress,
    );
    final finalMapUrl =
        (foundMapUrl?.isNotEmpty == true)
            ? foundMapUrl!
            : _buildMapsSearchUrl(name, area, foundAddress);

    if (nom != null) {
      return SpotGeocodingResult(
        latitude: nom.latitude,
        longitude: nom.longitude,
        address: foundAddress,
        mapUrl: finalMapUrl,
        websiteUrl: foundWebsiteUrl,
        mapLabel: foundMapLabel,
        geocodeSource: 'nominatim',
      );
    }

    // 5. 座標なしでも Maps URL は必ず返す
    return SpotGeocodingResult(
      address: foundAddress,
      mapUrl: finalMapUrl,
      websiteUrl: foundWebsiteUrl,
      mapLabel: foundMapLabel,
      geocodeSource: (foundMapUrl?.isNotEmpty == true) ? 'web_search_url' : 'constructed',
    );
  }

  /// Google Maps 短縮 URL をリダイレクト展開して座標をパースする。
  ///
  /// `maps.app.goo.gl/xxx` や `goo.gl/maps/xxx` のような短縮 URL は
  /// リダイレクト先の完全 URL に `@lat,lng` が含まれる。
  /// 最大 5 回リダイレクトを辿り、座標が見つかった時点で返す。
  static Future<SpotGeocodingResult?> _expandMapUrl(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      String current = url;
      for (int i = 0; i < 5; i++) {
        final uri = Uri.tryParse(current);
        if (uri == null) break;
        final req = await client.getUrl(uri);
        req.followRedirects = false;
        req.headers.set(HttpHeaders.userAgentHeader, 'NoesisApp/1.0');
        final res = await req.close();
        await res.drain<void>(); // ボディ不要

        if (res.statusCode >= 300 && res.statusCode < 400) {
          final location = res.headers.value(HttpHeaders.locationHeader);
          if (location == null) break;
          current = location.startsWith('http')
              ? location
              : uri.resolve(location).toString();
          final parsed = _parseFromMapUrl(current);
          if (parsed?.latitude != null) {
            client.close();
            return parsed;
          }
        } else {
          break;
        }
      }
      client.close();
    } catch (_) {
      // タイムアウト・ネットワークエラーは無視
    }
    return null;
  }

  /// Nominatim（OpenStreetMap）で店名＋住所から座標を取得する。
  /// 失敗した場合は null を返す。
  static Future<SpotGeocodingResult?> _nominatimGeocode({
    required String name,
    String? area,
    String? address,
  }) async {
    // クエリを組み立て: 住所があれば住所優先、なければ店名＋エリア
    final queries = <String>[];
    if ((address ?? '').isNotEmpty) {
      // 住所＋店名で精度を上げる
      queries.add('$name $address');
      queries.add(address!);
    }
    queries.add([name, if ((area ?? '').isNotEmpty) area!].join(' '));

    for (final query in queries) {
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': query,
          'format': 'json',
          'limit': '1',
          'accept-language': 'ja',
          'countrycodes': 'jp',
        });
        final response = await http
            .get(uri, headers: {'User-Agent': 'NoesisApp/1.0'})
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) continue;

        final List<dynamic> json = _parseJsonArray(response.body);
        if (json.isEmpty) continue;

        final item = json.first as Map<String, dynamic>;
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return SpotGeocodingResult(latitude: lat, longitude: lon);
        }
      } catch (_) {
        // タイムアウト・パースエラーは無視して次のクエリへ
      }
    }
    return null;
  }

  static List<dynamic> _parseJsonArray(String body) {
    try {
      final trimmed = body.trim();
      if (!trimmed.startsWith('[')) return [];
      return jsonDecode(trimmed) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// 名前・エリア・住所から Google Maps 検索 URL を構築する
  static String _buildMapsSearchUrl(
    String name,
    String? area,
    String? address,
  ) {
    final queryParts = [
      name,
      if ((area ?? '').isNotEmpty) area!,
      if ((address ?? '').isNotEmpty) address!,
    ];
    final query = Uri.encodeComponent(queryParts.join(' '));
    return 'https://www.google.com/maps/search/$query';
  }

  /// Google Maps URL から座標をパースする
  static SpotGeocodingResult? _parseFromMapUrl(String? mapUrl) {
    final raw = mapUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    // @lat,lng 形式（例: /maps/place/.../@35.6762,139.6503,17z）
    final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(raw);
    if (atMatch != null) {
      return SpotGeocodingResult(
        latitude: double.tryParse(atMatch.group(1)!),
        longitude: double.tryParse(atMatch.group(2)!),
        mapUrl: raw,
        geocodeSource: 'google_maps_url',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    // クエリパラメータ (q= / query= / ll=)
    for (final key in ['q', 'query', 'll']) {
      final value = uri.queryParameters[key];
      if (value == null) continue;
      final coords = value.split(',');
      if (coords.length >= 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null) {
          return SpotGeocodingResult(
            latitude: lat,
            longitude: lng,
            mapUrl: raw,
            geocodeSource: 'google_maps_url',
          );
        }
      }
    }

    // Google Maps URL だが座標なし（URL 自体は保持）
    final isMapsUrl = raw.contains('maps.google.com') ||
        raw.contains('google.com/maps') ||
        raw.contains('goo.gl/maps') ||
        raw.contains('maps.app.goo.gl');
    if (isMapsUrl) {
      return SpotGeocodingResult(mapUrl: raw, geocodeSource: 'google_maps_url');
    }

    return null;
  }

  static String? _toStringOrNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
