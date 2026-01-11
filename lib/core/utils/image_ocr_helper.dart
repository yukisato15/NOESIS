import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

      debugPrint('[OCR] Image picked: ${image?.path}');
      return image;
    } catch (e) {
      debugPrint('[OCR] Error picking image: $e');
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

  /// 画像を前処理（OCR精度向上のため）
  static Future<String> _preprocessImage(String imagePath) async {
    try {
      debugPrint('[OCR] Preprocessing image...');

      // 画像を読み込み
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('[OCR] Failed to decode image');
        return imagePath;
      }

      // グレースケール化
      image = img.grayscale(image);

      // コントラスト強調（1.5倍）
      image = img.adjustColor(image, contrast: 1.5);

      // シャープネス適用
      image = img.adjustColor(image, saturation: 0);

      // Otsu二値化（Tesseractに最適）
      // しきい値を自動計算
      final histogram = List<int>.filled(256, 0);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = pixel.r.toInt();
          histogram[gray]++;
        }
      }

      int total = image.width * image.height;
      double sum = 0;
      for (int i = 0; i < 256; i++) {
        sum += i * histogram[i];
      }

      double sumB = 0;
      int wB = 0;
      int wF = 0;
      double maxVariance = 0;
      int threshold = 0;

      for (int i = 0; i < 256; i++) {
        wB += histogram[i];
        if (wB == 0) continue;

        wF = total - wB;
        if (wF == 0) break;

        sumB += i * histogram[i];
        double mB = sumB / wB;
        double mF = (sum - sumB) / wF;
        double variance = wB * wF * (mB - mF) * (mB - mF);

        if (variance > maxVariance) {
          maxVariance = variance;
          threshold = i;
        }
      }

      debugPrint('[OCR] Otsu threshold: $threshold');

      // 二値化適用
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = pixel.r.toInt();
          final newValue = gray > threshold ? 255 : 0;
          image.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
        }
      }

      // 一時ファイルとして保存
      final tempDir = await getTemporaryDirectory();
      final processedPath = '${tempDir.path}/ocr_processed_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(processedPath).writeAsBytes(img.encodePng(image));

      debugPrint('[OCR] Preprocessed image saved: $processedPath');
      return processedPath;
    } catch (e) {
      debugPrint('[OCR] Error in preprocessing: $e');
      return imagePath; // 前処理失敗時は元の画像を使用
    }
  }

  /// 画像をトリミング
  static Future<CroppedFile?> cropImage({
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      debugPrint('[OCR] Starting crop for: $imagePath');
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

      debugPrint('[OCR] Cropped file: ${croppedFile?.path}');
      return croppedFile;
    } catch (e) {
      debugPrint('[OCR] Error cropping image: $e');
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

      debugPrint('[OCR] ========== OCR START ==========');
      debugPrint('[OCR] Image path: $imagePath');
      debugPrint('[OCR] Language: ${settings.language}');
      debugPrint('[OCR] Direction: ${settings.direction}');

      // ファイルの存在確認
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[OCR] ERROR: File does not exist!');
        return null;
      }
      final fileSize = await file.length();
      debugPrint('[OCR] File size: ${fileSize} bytes');

      // 画像前処理を実行
      final processedPath = await _preprocessImage(imagePath);
      debugPrint('[OCR] Using processed image: $processedPath');

      // Tesseractの言語コードを決定
      final String tessLang = _getTesseractLanguage(settings);
      debugPrint('[OCR] Tesseract language: $tessLang');

      // PSMモードを決定
      final String psmMode = _getPsmMode(settings);
      debugPrint('[OCR] PSM mode: $psmMode');

      // Tesseract OCR実行
      debugPrint('[OCR] Calling FlutterTesseractOcr.extractText...');

      try {
        final text = await FlutterTesseractOcr.extractText(
          processedPath, // 前処理済み画像を使用
          language: tessLang,
          args: {
            'psm': psmMode,
            'oem': '3',
          },
        );

        // 一時ファイルをクリーンアップ
        if (processedPath != imagePath) {
          try {
            await File(processedPath).delete();
            debugPrint('[OCR] Cleaned up temporary file');
          } catch (e) {
            debugPrint('[OCR] Failed to delete temp file: $e');
          }
        }

        debugPrint('[OCR] Raw result length: ${text.length}');
        debugPrint('[OCR] Raw result: "$text"');

        // 後処理: 日本語の場合は不要な空白を削除
        String processed = text.trim();
        if (settings.language == OcrLanguage.japanese) {
          // 日本語文字間の不要な空白を削除
          processed = processed.replaceAll(RegExp(r'(?<=[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF])\s+(?=[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF])'), '');
        }

        debugPrint('[OCR] Processed result length: ${processed.length}');
        debugPrint('[OCR] Processed result: "$processed"');
        debugPrint('[OCR] ========== OCR END ==========');

        return processed.isEmpty ? null : processed;
      } catch (e, stackTrace) {
        debugPrint('[OCR] ERROR in FlutterTesseractOcr.extractText: $e');
        debugPrint('[OCR] Stack trace: $stackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[OCR] ERROR in recognizeText: $e');
      debugPrint('[OCR] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Tesseractの言語コードを取得
  static String _getTesseractLanguage(OcrOptions settings) {
    if (settings.language == OcrLanguage.japanese) {
      if (settings.direction == WritingDirection.vertical) {
        return 'jpn_vert';
      } else {
        return 'jpn';
      }
    } else {
      return 'eng';
    }
  }

  /// Page Segmentation Mode を取得
  static String _getPsmMode(OcrOptions settings) {
    // PSM 3: 自動ページ分割（デフォルト）
    // PSM 4: 単一列の可変サイズテキスト
    // PSM 6: 単一テキストブロック
    // PSM 11: 疎なテキスト（写真など）
    if (settings.direction == WritingDirection.vertical) {
      return '4'; // 単一列（縦書き向け）
    } else {
      return '3'; // 自動ページ分割
    }
  }

  /// 画像選択 → トリミング → OCR の一連のフロー
  static Future<OCRResult?> pickCropAndRecognize({
    required BuildContext context,
    ImageSource? source,
    bool cropEnabled = true,
  }) async {
    debugPrint('[OCR] ========== FULL OCR FLOW START ==========');

    // 1. 画像を選択
    final XFile? pickedImage = await pickImage(
      context: context,
      source: source,
    );

    if (pickedImage == null) {
      debugPrint('[OCR] No image picked');
      return null;
    }

    String imagePath = pickedImage.path;

    // 2. トリミング（オプション）
    if (cropEnabled) {
      final CroppedFile? croppedImage = await cropImage(
        imagePath: imagePath,
        context: context,
      );

      if (croppedImage == null) {
        debugPrint('[OCR] Crop cancelled');
        return null;
      }
      imagePath = croppedImage.path;
    }

    final options = await _showOcrOptionsDialog(context);
    if (options == null) {
      debugPrint('[OCR] OCR options cancelled');
      return null;
    }

    // 3. OCR実行
    final String? recognizedText = await recognizeText(
      imagePath: imagePath,
      options: options,
    );

    debugPrint('[OCR] Final result: ${recognizedText ?? "(empty)"}');
    debugPrint('[OCR] ========== FULL OCR FLOW END ==========');

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
