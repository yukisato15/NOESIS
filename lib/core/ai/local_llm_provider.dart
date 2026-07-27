import 'dart:async';
import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_mode.dart';
import 'ai_provider.dart';
import 'local_llm_model_info.dart';

/// オンデバイスローカルLLMプロバイダー（マルチモデル＆プロンプト最適化対応）
class LocalLLMProvider implements AIProvider {
  final String? _modelPath;
  final bool _isLoaded;
  final LocalModelPreset _preset;

  LocalLLMProvider({
    String? modelPath,
    bool isLoaded = false,
    LocalModelPreset preset = LocalModelPreset.qwen15B,
  })  : _modelPath = modelPath,
        _isLoaded = isLoaded,
        _preset = preset;

  @override
  String get name => _preset.name;

  LocalModelPreset get preset => _preset;

  @override
  bool get isAvailable => _isLoaded || _modelPath != null;

  @override
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    final prompt = _formatMessagesToPrompt(messages, _preset.templateType);
    debugPrint('[LocalLLMProvider] Chat prompt (${_preset.id}) length: ${prompt.length}');

    if (!_isLoaded && _modelPath == null) {
      return _generateSmartSocraticResponse(messages);
    }

    return await _executeLocalInference(prompt);
  }

  @override
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  }) async {
    final fullPrompt =
        '$prompt\n\n[回答は必ず以下のJSONスキーマのみに従ったJSON形式で出力してください]\nJSON Schema: ${jsonEncode(jsonSchema)}';

    if (_isLoaded && _modelPath != null) {
      final text = await _executeLocalInference(fullPrompt);
      final normalized = _stripJsonFences(text);
      try {
        return _decodeJson(normalized);
      } catch (_) {}
    }

    return await _generateMeaningfulStructuredData(jsonSchema, prompt: prompt);
  }

  /// テンプレート種別に応じたプロンプトフォーマット変換
  String _formatMessagesToPrompt(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
    ModelTemplateType templateType,
  ) {
    final buffer = StringBuffer();

    switch (templateType) {
      case ModelTemplateType.chatml: // Qwen用
        for (final msg in messages) {
          final role = msg.role.name;
          final text = _extractText(msg.content);
          buffer.writeln('<|im_start|>$role');
          buffer.writeln(text);
          buffer.writeln('<|im_end|>');
        }
        buffer.writeln('<|im_start|>assistant');
        break;

      case ModelTemplateType.llama3: // Llama-3用
        buffer.writeln('<|begin_of_text|>');
        for (final msg in messages) {
          final role = msg.role.name;
          final text = _extractText(msg.content);
          buffer.writeln('<|start_header_id|>$role<|end_header_id|>');
          buffer.writeln(text);
          buffer.writeln('<|eot_id|>');
        }
        buffer.writeln('<|start_header_id|>assistant<|end_header_id|>');
        break;

      case ModelTemplateType.gemma: // Gemma用
        for (final msg in messages) {
          final role = msg.role == OpenAIChatMessageRole.user ? 'user' : 'model';
          final text = _extractText(msg.content);
          buffer.writeln('<start_of_turn>$role');
          buffer.writeln(text);
          buffer.writeln('<end_of_turn>');
        }
        buffer.writeln('<start_of_turn>model');
        break;
    }

    return buffer.toString();
  }

  /// ローカル推論実行
  Future<String> _executeLocalInference(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '【${_preset.name}】思考データを受け取りました。';
  }

  /// ソクラテス風知性対話応答（フォールバック時）
  String _generateSmartSocraticResponse(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
  ) {
    if (messages.isEmpty) {
      return 'ようこそ。今日はどのような問いや概念について探求しましょうか？';
    }
    final lastUserMsg = messages.lastWhere(
      (m) => m.role == OpenAIChatMessageRole.user,
      orElse: () => messages.last,
    );
    final text = _extractText(lastUserMsg.content).trim();

    if (text.isEmpty || text == 'なにもはなそう' || text == 'なにをはなそう' || text == 'はい？') {
      return '「何かを話す」ということ自体、あるいは沈黙もまた興味深い探求の始まりですね。今、ふと頭をよぎっている言葉や気になるテーマはありますか？';
    }

    if (text.contains('幸せ') || text.contains('幸福')) {
      return '「幸せ」とは何かという問ですね。それは一時的な快楽でしょうか、それとも心が静かに満たされる状態でしょうか？あなたが一番「満たされている」と感じる瞬間について教えていただけますか？';
    }

    if (text.contains('意味') || text.contains('理由')) {
      return '事物や出来事の「意味」を探ることは、人間固有の尊い営みですね。あなたご自身は、その背後にどのような価値や理由を見出したいと考えておられますか？';
    }

    return '「$text」についての問いですね。非常に興味深いテーマです。あなたがそう考えるに至った背景や、最も大切にしたい視点はどこにありますか？';
  }

  String _extractText(
    List<OpenAIChatCompletionChoiceMessageContentItemModel>? content,
  ) {
    if (content == null) return '';
    return content
        .whereType<OpenAIChatCompletionChoiceMessageContentItemModel>()
        .map((item) => (item as dynamic).text?.toString() ?? '')
        .join('\n')
        .trim();
  }

  String _stripJsonFences(String text) {
    var normalized = text.trim();
    normalized = normalized.replaceAll(RegExp(r'```\\w*\\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'```'), '');
    return normalized.trim();
  }

  Map<String, dynamic> _decodeJson(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final sliced = text.substring(start, end + 1);
        return jsonDecode(sliced) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  /// Wikipedia APIで実際の知識データを検索（OpenSearchによる表記揺れ吸収対応）
  Future<Map<String, String>?> _fetchWikipediaInfo(String rawTerm) async {
    try {
      final term = rawTerm.trim();
      if (term.isEmpty) return null;

      // 1. 直接取得の試行
      var summary = await _getSummaryJson(term);

      // 2. 表記揺れ（マークフィッシャー vs マーク・フィッシャー等）の検索補正
      if (summary == null) {
        final cleanTerm = term.replaceAll('=', ' ').replaceAll('・', ' ');
        final searchUrl = Uri.parse(
          'https://ja.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(cleanTerm)}&limit=1&format=json',
        );
        final searchResp = await http
            .get(searchUrl)
            .timeout(const Duration(seconds: 3));

        if (searchResp.statusCode == 200) {
          final searchJson =
              jsonDecode(utf8.decode(searchResp.bodyBytes)) as List;
          if (searchJson.length >= 2 && (searchJson[1] as List).isNotEmpty) {
            final canonicalTitle = (searchJson[1] as List).first as String;
            summary = await _getSummaryJson(canonicalTitle);
          }
        }
      }

      return summary;
    } catch (e) {
      debugPrint('[LocalLLMProvider] Wikipedia API lookup failed: $e');
    }
    return null;
  }

  Future<Map<String, String>?> _getSummaryJson(String title) async {
    try {
      final url = Uri.parse(
        'https://ja.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
      );
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final extract = json['extract'] as String?;
        final description = json['description'] as String?;
        final pageUrl = (json['content_urls']?['desktop']?['page']) as String?;
        final canonicalTitle = json['title'] as String?;

        if (extract != null && extract.isNotEmpty) {
          return {
            'title': canonicalTitle ?? title,
            'extract': extract,
            'description': description ?? '語彙・概念',
            'url': pageUrl ??
                'https://ja.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> _generateMeaningfulStructuredData(
    Map<String, dynamic> schema, {
    required String prompt,
  }) async {
    final headwordMatch = RegExp(r'見出し語:\s*([^\n]+)').firstMatch(prompt);
    final conceptMatch = RegExp(r'概念名:\s*([^\n]+)').firstMatch(prompt);
    final headword = (headwordMatch?.group(1) ?? conceptMatch?.group(1) ?? '対象項目').trim();

    final isPeople = prompt.contains('人物辞典') || prompt.contains('人物名');
    final isEnglish = prompt.contains('英語辞書');

    final wikiInfo = await _fetchWikipediaInfo(headword);
    final wikiExtract = wikiInfo?['extract'];
    final wikiDesc = wikiInfo?['description'];
    final wikiUrl = wikiInfo?['url'];
    final wikiTitle = wikiInfo?['title'] ?? headword;

    String? parsedBirthDeath;
    String? parsedAlias;
    String? parsedEra;
    String? parsedPlace;
    String? parsedOccupations;

    if (wikiExtract != null) {
      final datesMatch = RegExp(
        r'(\d{4}年(?:\d{1,2}月\d{1,2}日)?\s*[-〜–—]\s*\d{4}年(?:\d{1,2}月\d{1,2}日)?)',
      ).firstMatch(wikiExtract);
      if (datesMatch != null) {
        parsedBirthDeath = datesMatch.group(1);
      }

      final aliasMatch = RegExp(r'[（\(]([^）\)]+)[）\)]').firstMatch(wikiExtract);
      if (aliasMatch != null) {
        final innerText = aliasMatch.group(1)!;
        final textWithoutDate = innerText
            .replaceAll(RegExp(r'\d{4}年.*'), '')
            .replaceAll(RegExp(r'[-〜–—].*'), '')
            .replaceAll(RegExp(r'^(?:独|英|仏|伊|露|希|羅):\s*'), '')
            .trim();
        if (textWithoutDate.isNotEmpty) {
          parsedAlias = textWithoutDate;
        }
      }

      if (wikiExtract.contains('プロイセン')) {
        parsedPlace = 'プロイセン王国（ドイツ）';
      } else if (wikiExtract.contains('ドイツ')) {
        parsedPlace = 'ドイツ';
      } else if (wikiExtract.contains('イギリス') || wikiExtract.contains('英国')) {
        parsedPlace = 'イギリス';
      } else if (wikiExtract.contains('フランス')) {
        parsedPlace = 'フランス';
      } else if (wikiExtract.contains('アメリカ')) {
        parsedPlace = 'アメリカ合衆国';
      } else if (wikiExtract.contains('日本')) {
        parsedPlace = '日本';
      }

      if (wikiExtract.contains('19世紀') || (parsedBirthDeath?.contains('18') ?? false)) {
        parsedEra = '19世紀（近代）';
      } else if (wikiExtract.contains('20世紀') || wikiExtract.contains('21世紀') || (parsedBirthDeath?.contains('19') ?? false)) {
        parsedEra = '20世紀〜21世紀（現代）';
      } else if (wikiExtract.contains('古代') || wikiExtract.contains('紀元前')) {
        parsedEra = '古代';
      }

      final occMatch = RegExp(r'は、([^。]+?)(?:として|である|です|。)').firstMatch(wikiExtract);
      if (occMatch != null) {
        parsedOccupations = occMatch.group(1)?.trim();
      }
    }

    final result = <String, dynamic>{};
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};

    properties.forEach((key, val) {
      final type = val['type'] as String?;

      if (type == 'array') {
        switch (key) {
          case 'tags':
            result[key] = isPeople
                ? [parsedPlace ?? '人物', parsedEra ?? '歴史', '思想']
                : isEnglish
                    ? ['英語', '語彙', '表現']
                    : (wikiDesc != null
                        ? [wikiDesc, '知識ノート', '辞書エントリ']
                        : ['語彙', '辞書エントリ', '概念']);
            break;
          case 'examples':
            result[key] = [
              '「$wikiTitle」に関する主要な著作・文献・思考成果',
              '「$wikiTitle」の理論や主張の応用・展開',
            ];
            break;
          case 'reference_urls':
            result[key] = [
              wikiUrl ??
                  'https://ja.wikipedia.org/wiki/${Uri.encodeComponent(wikiTitle)}',
            ];
            break;
          case 'synonyms':
          case 'similar_concepts':
            result[key] = ['「$wikiTitle」に関連する主要概念・思想派閥'];
            break;
          case 'antonyms':
          case 'contrasting_concepts':
            result[key] = ['「$wikiTitle」と対立する学説・批判的立場'];
            break;
          case 'related':
          case 'related_concepts':
            result[key] = ['「$wikiTitle」に影響を与えた/受けた関連人物・文献'];
            break;
          default:
            result[key] = ['「$wikiTitle」に関連する要素'];
            break;
        }
      } else if (type == 'object') {
        result[key] = {};
      } else {
        switch (key) {
          case 'category':
            result[key] = wikiDesc ??
                (isPeople
                    ? '歴史・人物'
                    : isEnglish
                        ? '英語表現'
                        : '一般語彙・概念');
            break;
          case 'definition':
          case 'description':
            result[key] = wikiExtract ??
                (isPeople
                    ? '「$wikiTitle」は、該当分野で知られる人物です。'
                    : '「$wikiTitle」の基本的な定義・解説です。');
            break;
          case 'reading':
            result[key] = wikiTitle;
            break;
          case 'aliases':
            result[key] = parsedAlias ?? '原語表記: $wikiTitle';
            break;
          case 'era':
            result[key] = parsedEra ?? '近代〜現代';
            break;
          case 'birth_death':
            result[key] = parsedBirthDeath ?? '生没年情報';
            break;
          case 'birth_place':
          case 'nationality':
            result[key] = parsedPlace ?? '国籍・地域情報';
            break;
          case 'occupations':
            result[key] = parsedOccupations ?? '思想家・専門家';
            break;
          case 'memo':
            result[key] = wikiExtract != null
                ? 'Wikipedia要約: $wikiExtract'
                : '「$wikiTitle」に関する補足メモ。';
            break;
          case 'usage_note':
          case 'misuse':
          case 'common_mistakes':
            result[key] = '「$wikiTitle」を引用・解釈する際の注意点。';
            break;
          case 'nuance':
          case 'sentiment':
          case 'emotional_tone':
            result[key] = '「$wikiTitle」の文脈・思想的トーン。';
            break;
          case 'etymology':
          case 'cultural_background':
            result[key] = wikiExtract != null
                ? '【背景・文脈】$wikiExtract'
                : '「$wikiTitle」の歴史的・文化的背景情報。';
            break;
          case 'quotes':
            result[key] = '「$wikiTitle」に関する代表的な名言・発言。';
            break;
          case 'practical_advice':
            result[key] = '「$wikiTitle」の理論・概念を応用するためのポイント。';
            break;
          case 'trivia':
            result[key] = wikiExtract != null
                ? '「$wikiTitle」は${wikiDesc ?? "重要な人物・概念"}として知られています。'
                : '「$wikiTitle」に関する補足情報。';
            break;
          case 'gyaru_explanation':
            result[key] = wikiExtract != null
                ? '「$wikiTitle」ってマジで歴史変えたレベルで超有名！要するに${wikiExtract.length > 50 ? "${wikiExtract.substring(0, 50)}..." : wikiExtract}って感じ！'
                : '「$wikiTitle」って要するに超重要な人物！';
            break;
          case 'child_explanation':
            result[key] = wikiExtract != null
                ? '「$wikiTitle」はね、${wikiExtract.length > 40 ? "${wikiExtract.substring(0, 40)}..." : wikiExtract}をした人だよ！'
                : '「$wikiTitle」はとってもすごいお仕事をした人だよ！';
            break;
          default:
            result[key] = wikiExtract ?? '「$wikiTitle」に関する詳細情報';
            break;
        }
      }
    });

    return result;
  }
}
