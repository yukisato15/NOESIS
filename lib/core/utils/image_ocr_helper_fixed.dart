import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
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

/// 修正版Tesseract OCR ヘルパー
/// tessdataを書き込み可能なディレクトリにコピーしてから使用
class ImageOcrHelper {
  static final ImagePicker _picker = ImagePicker();
  static bool _isInitialized = false;
  static String? _tessdataPath;

  /// tessdataを初期化（書き込み可能なディレクトリにコピー）
  static Future<void> _ensureTessdataInitialized() async {
    if (_isInitialized) return;

    try {
      debugPrint('[OCR] Initializing tessdata...');

      // ドキュメントディレクトリを取得
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String tessdataDir = '${appDocDir.path}/tessdata';

      // tessdataディレクトリを作成
      final Directory tessDir = Directory(tessdataDir);
      if (!await tessDir.exists()) {
        await tessDir.create(recursive: true);
        debugPrint('[OCR] Created tessdata directory: $tessdataDir');
      }

      // 各学習データファイルをコピー
      final trainedDataFiles = ['eng.traineddata', 'jpn.traineddata', 'jpn_vert.traineddata'];

      for (final filename in trainedDataFiles) {
        final File destFile = File('$tessdataDir/$filename');

        // ファイルが存在しない、または古い場合はコピー
        if (!await destFile.exists()) {
          debugPrint('[OCR] Copying $filename from assets...');

          // アセットから読み込み
          final ByteData data = await rootBundle.load('assets/tessdata/$filename');
          final List<int> bytes = data.buffer.asUint8List();

          // ドキュメントディレクトリに書き込み
          await destFile.writeAsBytes(bytes);

          final size = await destFile.length();
          debugPrint('[OCR] Copied $filename (${size} bytes)');
        } else {
          final size = await destFile.length();
          debugPrint('[OCR] $filename already exists (${size} bytes)');
        }
      }

      _tessdataPath = appDocDir.path;
      _isInitialized = true;
      debugPrint('[OCR] tessdata initialized successfully at: $_tessdataPath');
    } catch (e, stackTrace) {
      debugPrint('[OCR] ERROR initializing tessdata: $e');
      debugPrint('[OCR] Stack trace: $stackTrace');
      rethrow;
    }
  }

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

      // tessdataを初期化
      await _ensureTessdataInitialized();

      // ファイルの存在確認
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[OCR] ERROR: File does not exist!');
        return null;
      }
      final fileSize = await file.length();
      debugPrint('[OCR] File size: ${fileSize} bytes');

      // Tesseractの言語コードを決定
      final String tessLang = _getTesseractLanguage(settings);
      debugPrint('[OCR] Tesseract language: $tessLang');
      debugPrint('[OCR] Tessdata path: $_tessdataPath');

      // PSMモードを決定
      final String psmMode = _getPsmMode(settings);
      debugPrint('[OCR] PSM mode: $psmMode');

      // Tesseract OCR実行
      debugPrint('[OCR] Calling FlutterTesseractOcr.extractText...');

      try {
        final text = await FlutterTesseractOcr.extractText(
          imagePath,
          language: tessLang,
          args: {
            'psm': psmMode,
            'oem': '3',
            'tessdata': _tessdataPath, // 書き込み可能なディレクトリを指定
          },
        );

        debugPrint('[OCR] Raw result length: ${text.length}');
        debugPrint('[OCR] Raw result: "$text"');

        final trimmed = text.trim();
        debugPrint('[OCR] Trimmed result length: ${trimmed.length}');
        debugPrint('[OCR] Trimmed result: "$trimmed"');
        debugPrint('[OCR] ========== OCR END ==========');

        return trimmed.isEmpty ? null : trimmed;
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
    if (settings.direction == WritingDirection.vertical) {
      return '5'; // 垂直配置テキスト
    } else {
      return '6'; // 単一テキストブロック
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
