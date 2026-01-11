import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

enum OcrLanguage {
  japanese,
  english,
}

enum WritingDirection {
  horizontal,
  vertical,
}

class OcrOptions {
  final OcrLanguage language;
  final WritingDirection direction;

  const OcrOptions({
    required this.language,
    required this.direction,
  });
}

/// Tesseract OCR ヘルパー
///
/// 必須セットアップ:
/// 1. pubspec.yaml に追加:
///    dependencies:
///      flutter_tesseract_ocr: ^0.4.24
///
/// 2. 学習データをダウンロード:
///    - 日本語縦書き: https://github.com/tesseract-ocr/tessdata/raw/main/jpn_vert.traineddata
///    - 日本語横書き: https://github.com/tesseract-ocr/tessdata/raw/main/jpn.traineddata
///    - 英語: https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata
///
/// 3. assets/ フォルダに配置:
///    assets/
///      tessdata/
///        jpn.traineddata
///        jpn_vert.traineddata
///        eng.traineddata
///
/// 4. pubspec.yaml に追加:
///    flutter:
///      assets:
///        - assets/tessdata/
class ImageOcrHelper {
  static final ImagePicker _picker = ImagePicker();

  /// 画像を選択（カメラまたはギャラリー）
  static Future<XFile?> pickImage({
    required BuildContext context,
    ImageSource? source,
  }) async {
    try {
      ImageSource? selectedSource = source;
      if (selectedSource == null) {
        selectedSource = await _showImageSourceDialog(context);
        if (selectedSource == null) return null;
      }

      final XFile? image = await _picker.pickImage(
        source: selectedSource,
        imageQuality: 100,
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// 画像ソース選択ダイアログ
  static Future<ImageSource?> _showImageSourceDialog(
      BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('画像を選択'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 16),
                  Text('カメラで撮影'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 16),
                  Text('ギャラリーから選択'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 画像をトリミング
  static Future<CroppedFile?> cropImage({
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '画像をトリミング',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: '画像をトリミング',
          ),
        ],
      );

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  /// 画像からテキストを認識（OCR）
  ///
  /// Tesseractの利点:
  /// - 横書き・縦書き日本語に対応
  /// - ML Kitより高精度
  /// - オフライン動作
  /// - 無料
  static Future<String?> recognizeText({
    required String imagePath,
    OcrOptions? options,
  }) async {
    try {
      final settings = options ??
          const OcrOptions(
            language: OcrLanguage.japanese,
            direction: WritingDirection.horizontal,
          );

      // 処理する画像の候補を準備
      final candidateImages = <_ImageCandidate>[];

      // 1. 原画像
      candidateImages.add(_ImageCandidate(
        path: imagePath,
        type: 'original',
      ));

      // 2. 前処理画像（二値化）
      final preprocessed = await _preprocessImage(imagePath);
      if (preprocessed != null) {
        candidateImages.add(_ImageCandidate(
          path: preprocessed,
          type: 'preprocessed',
        ));
      }

      // 3. 拡大画像（2倍）
      final upscaled = await _upscaleImage(imagePath, 2.0);
      if (upscaled != null) {
        candidateImages.add(_ImageCandidate(
          path: upscaled,
          type: 'upscaled',
        ));
      }

      // Tesseractの言語コードを決定
      final tessLanguages = _getTesseractLanguages(settings);

      // 各画像候補でOCRを実行
      final results = <_OcrResult>[];

      for (final candidate in candidateImages) {
        for (final tessLang in tessLanguages) {
          final text = await _performTesseractOcr(
            candidate.path,
            tessLang,
            settings,
          );
          if (text.isNotEmpty) {
            final score = _calculateScore(text, settings);
            results.add(_OcrResult(
              text: text,
              score: score,
              imageType: candidate.type,
              language: tessLang,
            ));

            debugPrint(
              'Tesseract OCR: ${candidate.type} + $tessLang '
              '-> ${text.length} chars, score: $score'
            );
          }
        }
      }

      // スコアが最も高い結果を選択
      if (results.isEmpty) {
        return null;
      }

      results.sort((a, b) => b.score.compareTo(a.score));
      final best = results.first;

      debugPrint(
        'Best Result: ${best.imageType} + ${best.language} '
        '-> "${best.text.substring(0, best.text.length > 50 ? 50 : best.text.length)}..." '
        '(score: ${best.score})'
      );

      return best.text;
    } catch (e) {
      debugPrint('Error recognizing text with Tesseract: $e');
      return null;
    }
  }

  /// Tesseractの言語コードを取得
  static List<String> _getTesseractLanguages(OcrOptions settings) {
    if (settings.language == OcrLanguage.japanese) {
      if (settings.direction == WritingDirection.vertical) {
        // 縦書き日本語: jpn_vert > jpn+eng
        return ['jpn_vert', 'jpn+eng'];
      } else {
        // 横書き日本語: jpn+eng > jpn
        return ['jpn+eng', 'jpn'];
      }
    } else {
      // 英語
      return ['eng'];
    }
  }

  /// Tesseract OCRを実行
  static Future<String> _performTesseractOcr(
    String imagePath,
    String language,
    OcrOptions settings,
  ) async {
    try {
      // Tesseractのパラメータ設定
      final args = <String, dynamic>{
        'psm': _getPsmMode(settings), // Page Segmentation Mode
        'oem': '3', // OCR Engine Mode (LSTM)
      };

      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: language,
        args: args,
      );

      return text.trim();
    } catch (e) {
      debugPrint('Error in _performTesseractOcr: $e');
      return '';
    }
  }

  /// Page Segmentation Mode を取得
  ///
  /// PSM モード:
  /// 3 = 完全自動ページセグメンテーション（デフォルト）
  /// 4 = 単一列の可変サイズテキスト
  /// 5 = 垂直に配置された単一の均一テキストブロック
  /// 6 = 単一の均一テキストブロック
  /// 7 = 単一のテキスト行として扱う
  /// 11 = 疎なテキスト（順序なし）
  /// 12 = 疎なテキスト（OCR順序検出付き）
  static String _getPsmMode(OcrOptions settings) {
    if (settings.direction == WritingDirection.vertical) {
      return '5'; // 垂直配置テキスト
    } else {
      return '6'; // 単一テキストブロック（トリミング済み想定）
    }
  }

  /// テキストのスコアを計算
  static int _calculateScore(String text, OcrOptions settings) {
    if (text.isEmpty) return 0;

    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final totalChars = compact.length;
    if (totalChars == 0) return 0;

    final jpChars = _countJapaneseChars(compact);
    final latinChars = totalChars - jpChars;

    if (settings.language == OcrLanguage.japanese) {
      // 日本語期待時
      return jpChars * 10 + latinChars;
    } else {
      // 英語期待時
      return latinChars * 5 + jpChars;
    }
  }

  /// 日本語文字数をカウント
  static int _countJapaneseChars(String text) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]')
        .allMatches(text)
        .length;
  }

  /// 画像選択 → トリミング → OCR の一連のフロー
  static Future<OCRResult?> pickCropAndRecognize({
    required BuildContext context,
    ImageSource? source,
    bool cropEnabled = true,
  }) async {
    // 1. 画像を選択
    final XFile? pickedImage = await pickImage(
      context: context,
      source: source,
    );

    if (pickedImage == null) return null;

    String imagePath = pickedImage.path;

    // 2. トリミング（オプション）
    if (cropEnabled) {
      final CroppedFile? croppedImage = await cropImage(
        imagePath: imagePath,
        context: context,
      );

      if (croppedImage == null) return null;
      imagePath = croppedImage.path;
    }

    final options = await _showOcrOptionsDialog(context);
    if (options == null) {
      return null;
    }

    // 3. OCR実行
    final String? recognizedText = await recognizeText(
      imagePath: imagePath,
      options: options,
    );

    return OCRResult(
      imagePath: imagePath,
      recognizedText: recognizedText ?? '',
    );
  }

  /// OCR設定ダイアログ
  static Future<OcrOptions?> _showOcrOptionsDialog(
    BuildContext context,
  ) async {
    OcrLanguage language = OcrLanguage.japanese;
    WritingDirection direction = WritingDirection.horizontal;

    return showDialog<OcrOptions>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('OCR設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<OcrLanguage>(
                    value: language,
                    decoration: const InputDecoration(labelText: '言語'),
                    items: const [
                      DropdownMenuItem(
                        value: OcrLanguage.japanese,
                        child: Text('日本語'),
                      ),
                      DropdownMenuItem(
                        value: OcrLanguage.english,
                        child: Text('英語'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        language = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WritingDirection>(
                    value: direction,
                    decoration: const InputDecoration(labelText: '書字方向'),
                    items: const [
                      DropdownMenuItem(
                        value: WritingDirection.horizontal,
                        child: Text('横書き'),
                      ),
                      DropdownMenuItem(
                        value: WritingDirection.vertical,
                        child: Text('縦書き'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        direction = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    OcrOptions(language: language, direction: direction),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 画像を拡大
  static Future<String?> _upscaleImage(
    String imagePath,
    double scale,
  ) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(scale, scale);
      canvas.drawImage(image, const ui.Offset(0, 0), ui.Paint());

      final picture = recorder.endRecording();
      final outImage = await picture.toImage(
        (image.width * scale).round(),
        (image.height * scale).round(),
      );
      final outData = await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = outData?.buffer.asUint8List();
      if (pngBytes == null) {
        return null;
      }

      final tempDir = await Directory.systemTemp.createTemp('tess_upscale_');
      final outPath =
          '${tempDir.path}/upscale_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);
      return outPath;
    } catch (e) {
      debugPrint('Error upscaling image: $e');
      return null;
    }
  }

  /// 画像を前処理（二値化）
  static Future<String?> _preprocessImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return null;
      }

      final data = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // 1. グレースケール化
      final gray = <int>[];
      for (var i = 0; i < data.length; i += 4) {
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];
        final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
        gray.add(lum);
      }

      // 2. Otsu二値化
      final threshold = _calculateOtsuThreshold(gray);
      final binary = gray.map((v) => v >= threshold ? 255 : 0).toList();

      // 3. RGBAに戻す
      final processed = <int>[];
      for (final v in binary) {
        processed.addAll([v, v, v, 255]);
      }

      // 4. ui.Imageに変換
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        Uint8List.fromList(processed),
        width,
        height,
        ui.PixelFormat.rgba8888,
        (result) => completer.complete(result),
      );
      final processedImage = await completer.future;

      // 5. PNGとして保存
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(processedImage, const ui.Offset(0, 0), ui.Paint());
      final picture = recorder.endRecording();
      final outImage = await picture.toImage(width, height);
      final outData = await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = outData?.buffer.asUint8List();
      if (pngBytes == null) {
        return null;
      }

      final tempDir = await Directory.systemTemp.createTemp('tess_prep_');
      final outPath =
          '${tempDir.path}/prep_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);

      debugPrint('Preprocessed: threshold=$threshold');
      return outPath;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      return null;
    }
  }

  /// Otsuの二値化閾値を計算
  static int _calculateOtsuThreshold(List<int> gray) {
    final histogram = List.filled(256, 0);
    for (final v in gray) {
      histogram[v]++;
    }

    final total = gray.length;

    double sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;

    double varMax = 0;
    int threshold = 0;

    for (var t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final varBetween = wB * wF * (mB - mF) * (mB - mF);

      if (varBetween > varMax) {
        varMax = varBetween;
        threshold = t;
      }
    }

    return threshold;
  }
}

/// 画像候補
class _ImageCandidate {
  final String path;
  final String type;

  _ImageCandidate({
    required this.path,
    required this.type,
  });
}

/// OCR結果
class _OcrResult {
  final String text;
  final int score;
  final String imageType;
  final String language;

  _OcrResult({
    required this.text,
    required this.score,
    required this.imageType,
    required this.language,
  });
}

/// OCR結果を格納するクラス
class OCRResult {
  final String imagePath;
  final String recognizedText;

  OCRResult({
    required this.imagePath,
    required this.recognizedText,
  });

  bool get hasText => recognizedText.isNotEmpty;

  File get imageFile => File(imagePath);
}
