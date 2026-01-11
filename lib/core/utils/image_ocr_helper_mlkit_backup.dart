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

class ImageOcrHelper {
  static final ImagePicker _picker = ImagePicker();

  /// 画像を選択（カメラまたはギャラリー）
  static Future<XFile?> pickImage({
    required BuildContext context,
    ImageSource? source,
  }) async {
    try {
      // sourceが指定されていない場合はダイアログで選択
      ImageSource? selectedSource = source;
      if (selectedSource == null) {
        selectedSource = await _showImageSourceDialog(context);
        if (selectedSource == null) return null;
      }

      final XFile? image = await _picker.pickImage(
        source: selectedSource,
        imageQuality: 85,
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
      final basePaths = <String>{imagePath};
      final upscaled = await _upscaleImage(imagePath, 2.0);
      if (upscaled != null) {
        basePaths.add(upscaled);
      }
      final enhanced = await _enhanceImage(imagePath);
      if (enhanced != null) {
        basePaths.add(enhanced);
      }

      final candidatePaths = <String>{...basePaths};
      if (settings.direction == WritingDirection.vertical) {
        for (final path in basePaths) {
          candidatePaths.add(await _rotateImage(path, pi / 2));
          candidatePaths.add(await _rotateImage(path, -pi / 2));
        }
      }

      final scriptCandidates = settings.language == OcrLanguage.japanese
          ? [
              TextRecognitionScript.japanese,
              TextRecognitionScript.latin,
            ]
          : [
              TextRecognitionScript.latin,
              TextRecognitionScript.japanese,
            ];

      String? bestJapaneseText;
      int bestJapaneseScore = 0;
      String? bestLatinText;
      int bestLatinScore = 0;

      for (final path in candidatePaths) {
        for (final script in scriptCandidates) {
          final inputImage = InputImage.fromFilePath(path);
          final recognizer = TextRecognizer(script: script);
          final RecognizedText recognizedText =
              await recognizer.processImage(inputImage);
          await recognizer.close();

          final text = recognizedText.text.trim();
          if (text.isEmpty) {
            continue;
          }
          final compact = text.replaceAll(RegExp(r'\s+'), '');
          final total = compact.length;
          if (total == 0) {
            continue;
          }
          final jpCount = _countJapaneseChars(compact);
          if (jpCount > 0) {
            final score = jpCount * 3 + total;
            if (score > bestJapaneseScore) {
              bestJapaneseScore = score;
              bestJapaneseText = text;
            }
          } else {
            if (total > bestLatinScore) {
              bestLatinScore = total;
              bestLatinText = text;
            }
          }
        }
      }

      if (settings.language == OcrLanguage.japanese) {
        if (bestJapaneseText != null) {
          return bestJapaneseText;
        }
        if (bestLatinText != null && bestLatinScore >= 3) {
          return bestLatinText;
        }
        return null;
      }

      if (bestLatinText != null) {
        return bestLatinText;
      }
      return bestJapaneseText;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
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

  /// リソースを解放
  static void dispose() {
  }

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

  static Future<String> _rotateImage(String imagePath, double radians) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    if (radians > 0) {
      canvas.translate(height, 0);
    } else {
      canvas.translate(0, width);
    }
    canvas.rotate(radians);
    canvas.drawImage(image, const ui.Offset(0, 0), ui.Paint());

    final picture = recorder.endRecording();
    final rotatedImage =
        await picture.toImage(height.toInt(), width.toInt());
    final byteData =
        await rotatedImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) {
      return imagePath;
    }

    final tempDir = await Directory.systemTemp.createTemp('ocr_rotate_');
    final rotatedPath =
        '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(rotatedPath).writeAsBytes(pngBytes);
    return rotatedPath;
  }

  static int _countJapaneseChars(String text) {
    return RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').allMatches(text).length;
  }

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
      final outData =
          await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = outData?.buffer.asUint8List();
      if (pngBytes == null) {
        return null;
      }

      final tempDir = await Directory.systemTemp.createTemp('ocr_up_');
      final outPath =
          '${tempDir.path}/up_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);
      return outPath;
    } catch (e) {
      debugPrint('Error upscaling image: $e');
      return null;
    }
  }

  static Future<String?> _enhanceImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return null;
      }
      final data = byteData.buffer.asUint8List();
      for (var i = 0; i < data.length; i += 4) {
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];
        var lum = (0.2126 * r + 0.7152 * g + 0.0722 * b).round();
        lum = ((lum - 128) * 1.35 + 128).round().clamp(0, 255);
        data[i] = lum;
        data[i + 1] = lum;
        data[i + 2] = lum;
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        data,
        image.width,
        image.height,
        ui.PixelFormat.rgba8888,
        (result) => completer.complete(result),
      );
      final processed = await completer.future;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(2.0, 2.0);
      canvas.drawImage(processed, const ui.Offset(0, 0), ui.Paint());
      final picture = recorder.endRecording();
      final outImage =
          await picture.toImage(image.width * 2, image.height * 2);
      final outData =
          await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = outData?.buffer.asUint8List();
      if (pngBytes == null) {
        return null;
      }
      final tempDir = await Directory.systemTemp.createTemp('ocr_pre_');
      final outPath =
          '${tempDir.path}/pre_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes);
      return outPath;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      return null;
    }
  }
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
