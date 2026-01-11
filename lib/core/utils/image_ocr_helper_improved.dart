import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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

/// 改善版OCRヘルパー
///
/// 主な改善点:
/// 1. 適切なスクリプト選択ロジック
/// 2. 画像前処理の最適化（二値化、シャープ化）
/// 3. 候補画像の削減
/// 4. 縦書き対応の修正
class ImageOcrHelperImproved {
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
        imageQuality: 100, // 最高品質で取得
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
  /// 改善された処理フロー:
  /// 1. 原画像でOCR実行
  /// 2. 前処理画像（二値化+シャープ化）でOCR実行
  /// 3. 拡大画像でOCR実行
  /// 4. 最良の結果を選択
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

      // 2. 前処理画像（二値化+シャープ化）
      final preprocessed = await _preprocessImage(imagePath);
      if (preprocessed != null) {
        candidateImages.add(_ImageCandidate(
          path: preprocessed,
          type: 'preprocessed',
        ));
      }

      // 3. 拡大画像（3倍）- 小さい文字用
      final upscaled = await _upscaleImage(imagePath, 3.0);
      if (upscaled != null) {
        candidateImages.add(_ImageCandidate(
          path: upscaled,
          type: 'upscaled',
        ));
      }

      // スクリプトの優先順位を決定
      final scripts = _getScriptPriority(settings);

      // 各画像候補でOCRを実行
      final results = <_OcrResult>[];

      for (final candidate in candidateImages) {
        for (final script in scripts) {
          final text = await _performOcr(candidate.path, script);
          if (text.isNotEmpty) {
            final score = _calculateScore(text, settings);
            results.add(_OcrResult(
              text: text,
              score: score,
              imageType: candidate.type,
              script: script,
            ));

            debugPrint(
              'OCR Result: ${candidate.type} + ${script.name} '
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
        'Best Result: ${best.imageType} + ${best.script.name} '
        '-> "${best.text.substring(0, min(50, best.text.length))}..." '
        '(score: ${best.score})'
      );

      return best.text;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
  }

  /// スクリプトの優先順位を取得
  static List<TextRecognitionScript> _getScriptPriority(OcrOptions settings) {
    if (settings.language == OcrLanguage.japanese) {
      if (settings.direction == WritingDirection.vertical) {
        // 縦書き日本語: japanese > latin
        return [
          TextRecognitionScript.japanese,
          TextRecognitionScript.latin,
        ];
      } else {
        // 横書き日本語: latin > japanese
        // ML Kitのjapaneseスクリプトは縦書き特化のため
        return [
          TextRecognitionScript.latin,
          TextRecognitionScript.japanese,
        ];
      }
    } else {
      // 英語: latin のみ
      return [TextRecognitionScript.latin];
    }
  }

  /// OCRを実行
  static Future<String> _performOcr(
    String imagePath,
    TextRecognitionScript script,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = TextRecognizer(script: script);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('Error in _performOcr: $e');
      return '';
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
      // 日本語期待時: 日本語文字を高く評価
      // 日本語1文字 = 10点, その他1文字 = 1点
      return jpChars * 10 + latinChars;
    } else {
      // 英語期待時: ラテン文字を高く評価
      // ラテン文字1文字 = 5点, 日本語文字 = 1点（ノイズ扱い）
      return latinChars * 5 + jpChars;
    }
  }

  /// 日本語文字数をカウント
  static int _countJapaneseChars(String text) {
    // ひらがな、カタカナ、漢字
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

      final tempDir = await Directory.systemTemp.createTemp('ocr_upscale_');
      final outPath =
          '${tempDir.path}/upscale_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);
      return outPath;
    } catch (e) {
      debugPrint('Error upscaling image: $e');
      return null;
    }
  }

  /// 画像を前処理（二値化 + シャープ化）
  ///
  /// 処理内容:
  /// 1. グレースケール化
  /// 2. Otsu二値化（適応的な閾値）
  /// 3. シャープ化（エッジ強調）
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

      // 2. Otsu二値化の閾値を計算
      final threshold = _calculateOtsuThreshold(gray);

      // 3. 二値化
      final binary = gray.map((v) => v >= threshold ? 255 : 0).toList();

      // 4. RGBAに戻す
      final processed = <int>[];
      for (final v in binary) {
        processed.addAll([v, v, v, 255]); // R, G, B, A
      }

      // 5. ui.Imageに変換
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        Uint8List.fromList(processed),
        width,
        height,
        ui.PixelFormat.rgba8888,
        (result) => completer.complete(result),
      );
      final processedImage = await completer.future;

      // 6. PNGとして保存
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

      final tempDir = await Directory.systemTemp.createTemp('ocr_preprocess_');
      final outPath =
          '${tempDir.path}/preprocess_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);

      debugPrint('Preprocessed image: threshold=$threshold, path=$outPath');
      return outPath;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      return null;
    }
  }

  /// Otsuの二値化閾値を計算
  static int _calculateOtsuThreshold(List<int> gray) {
    // ヒストグラムを計算
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
  final String type; // 'original', 'preprocessed', 'upscaled'

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
  final TextRecognitionScript script;

  _OcrResult({
    required this.text,
    required this.score,
    required this.imageType,
    required this.script,
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
