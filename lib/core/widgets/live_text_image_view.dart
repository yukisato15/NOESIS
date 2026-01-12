import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOSのLive Text機能に対応した画像ビューウィジェット
/// iOS 16以降で画像からテキストを選択・コピーできます
class LiveTextImageView extends StatelessWidget {
  final String imagePath;
  final double? height;

  const LiveTextImageView({
    super.key,
    required this.imagePath,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // iOSの場合のみプラットフォームビューを使用
    if (Platform.isIOS) {
      const String viewType = 'live_text_image_view';
      final Map<String, dynamic> creationParams = {
        'imagePath': imagePath,
      };

      return SizedBox(
        height: height ?? 400,
        child: UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      );
    }

    // Android等の場合は通常のImageウィジェットを使用
    return SizedBox(
      height: height ?? 400,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
