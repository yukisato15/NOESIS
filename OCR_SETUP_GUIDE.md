# OCR セットアップガイド

NOESISアプリのOCR機能改善版のセットアップと使い方を説明します。

## 📋 目次

1. [ML Kit改善版の使い方](#ml-kit改善版)
2. [Tesseract OCRの導入手順](#tesseract-ocrの導入)
3. [パフォーマンス比較](#パフォーマンス比較)
4. [トラブルシューティング](#トラブルシューティング)

---

## 🔧 ML Kit改善版

### 使い方

既存の `image_ocr_helper.dart` を `image_ocr_helper_improved.dart` に置き換えるだけです。

#### 1. ファイルを置き換え

```bash
# 現在のファイルをバックアップ
mv lib/core/utils/image_ocr_helper.dart lib/core/utils/image_ocr_helper_backup.dart

# 改善版をリネーム
mv lib/core/utils/image_ocr_helper_improved.dart lib/core/utils/image_ocr_helper.dart
```

#### 2. インポートを更新

既存コードで `ImageOcrHelper` を使用している箇所はそのまま動作します。

```dart
// 変更なし - そのまま使えます
import 'package:noesis_flutter/core/utils/image_ocr_helper.dart';

final result = await ImageOcrHelper.pickCropAndRecognize(context: context);
```

### 改善内容

✅ **横書き日本語の認識精度向上**
- ML Kitの `latin` スクリプトを優先使用
- 日本語文字を含む結果を優先選択

✅ **画像前処理の最適化**
- Otsu二値化（適応的閾値）
- グレースケール化
- 3倍拡大（小さい文字対応）

✅ **処理速度の向上**
- 候補画像を3枚に削減（原画像、前処理版、拡大版）
- 不要な回転処理を削除

✅ **スコアリング改善**
- 日本語文字を10点、その他を1点で評価
- 最も高スコアの結果を自動選択

### 制限事項

⚠️ **ML Kitの本質的な制限により、以下は改善が難しい**:
- 横書き日本語の認識精度は中程度
- 縦書き日本語は比較的良好
- フォントや画質に依存

---

## 🚀 Tesseract OCRの導入

**推奨**: より高精度な日本語OCRが必要な場合、Tesseractへの移行を強く推奨します。

### メリット

✅ **横書き・縦書き日本語に完全対応**
✅ **ML Kitより高精度**（特に横書き日本語）
✅ **オフライン動作**
✅ **無料・オープンソース**
✅ **100以上の言語に対応**

### デメリット

❌ **初回セットアップが必要** (学習データのダウンロード)
❌ **アプリサイズが増加** (学習データ: 約15MB/言語)
❌ **処理速度はML Kitより若干遅い**

---

### セットアップ手順

#### ステップ1: パッケージを追加

`pubspec.yaml` に以下を追加:

```yaml
dependencies:
  flutter_tesseract_ocr: ^0.4.24
```

```bash
flutter pub get
```

#### ステップ2: 学習データをダウンロード

以下のファイルをダウンロードして `assets/tessdata/` に配置します。

```bash
# assetsディレクトリを作成
mkdir -p assets/tessdata
cd assets/tessdata

# 日本語横書き用（約15MB）
curl -O https://github.com/tesseract-ocr/tessdata/raw/main/jpn.traineddata

# 日本語縦書き用（約15MB）
curl -O https://github.com/tesseract-ocr/tessdata/raw/main/jpn_vert.traineddata

# 英語用（約4MB）
curl -O https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata
```

#### ステップ3: assetsを登録

`pubspec.yaml` に以下を追加:

```yaml
flutter:
  assets:
    - assets/tessdata/
```

#### ステップ4: コードを更新

既存の `ImageOcrHelper` を `ImageOcrHelperTesseract` に置き換えます。

```dart
// Before
import 'package:noesis_flutter/core/utils/image_ocr_helper.dart';

final result = await ImageOcrHelper.pickCropAndRecognize(context: context);

// After
import 'package:noesis_flutter/core/utils/image_ocr_helper_tesseract.dart';

final result = await ImageOcrHelperTesseract.pickCropAndRecognize(context: context);
```

または、ファイル名を置き換えて既存コードをそのまま使用:

```bash
# ML Kit版をバックアップ
mv lib/core/utils/image_ocr_helper.dart lib/core/utils/image_ocr_helper_mlkit.dart

# Tesseract版をリネーム
mv lib/core/utils/image_ocr_helper_tesseract.dart lib/core/utils/image_ocr_helper.dart

# ImageOcrHelperTesseract -> ImageOcrHelper にクラス名を変更
```

#### ステップ5: テスト

```bash
flutter run
```

アプリでOCR機能を試してみてください。

---

## 📊 パフォーマンス比較

| 項目 | ML Kit (現状) | ML Kit (改善版) | Tesseract |
|------|---------------|-----------------|-----------|
| **横書き日本語** | ❌ 低精度 | 🟡 中程度 | ✅ 高精度 |
| **縦書き日本語** | 🟡 中程度 | ✅ 高精度 | ✅ 高精度 |
| **英語横書き** | ✅ 高精度 | ✅ 高精度 | ✅ 高精度 |
| **処理速度** | 🟡 遅い (18回実行) | ✅ 速い (6回実行) | 🟡 中程度 |
| **オフライン動作** | ✅ 可能 | ✅ 可能 | ✅ 可能 |
| **セットアップ** | ✅ 不要 | ✅ 不要 | 🟡 学習データDL必要 |
| **アプリサイズ増加** | なし | なし | 約30MB (日英) |

---

## 💡 推奨使用パターン

### パターン1: まずML Kit改善版を試す

```
1. image_ocr_helper_improved.dart を使用
2. 実際の文書でテスト
3. 精度が不十分ならパターン2へ
```

**適用ケース**:
- 英語メインで日本語が少ない場合
- アプリサイズを小さく保ちたい場合
- セットアップの手間を避けたい場合

### パターン2: Tesseractに移行

```
1. 学習データをダウンロード
2. image_ocr_helper_tesseract.dart を使用
3. 精度向上を確認
```

**適用ケース**:
- 日本語横書きの認識が重要な場合
- 高い認識精度が必要な場合
- アプリサイズ増加が許容できる場合

### パターン3: ハイブリッド戦略（上級者向け）

ユーザーに選択させる:

```dart
enum OcrEngine {
  mlKit,
  tesseract,
}

class OcrOptions {
  final OcrLanguage language;
  final WritingDirection direction;
  final OcrEngine engine; // 追加

  const OcrOptions({
    required this.language,
    required this.direction,
    this.engine = OcrEngine.tesseract, // デフォルトはTesseract
  });
}
```

---

## 🐛 トラブルシューティング

### ML Kit改善版の問題

#### Q1. 「ボリシェヴィズム」が「A」になる問題は解決する?

**A**: ML Kit改善版では**部分的に改善**しますが、完全には解決しません。

- 改善版では日本語文字を含む結果を優先選択
- 二値化により文字が明瞭化
- しかしML Kitの `latin` スクリプトは日本語に最適化されていないため限界あり

**解決策**: Tesseract OCRへの移行を推奨

#### Q2. 処理が遅い

**A**: 改善版では候補画像を削減し、処理を高速化しています。

- 現状: 最大18回のOCR実行
- 改善版: 最大6回のOCR実行（3画像 × 2スクリプト）

#### Q3. 縦書きが認識できない

**A**: 改善版では縦書き用に `TextRecognitionScript.japanese` を優先使用します。

```dart
OcrOptions(
  language: OcrLanguage.japanese,
  direction: WritingDirection.vertical, // 縦書きを指定
)
```

---

### Tesseract版の問題

#### Q1. 「Error: Unable to load asset」

**A**: 学習データが正しく配置されていません。

```bash
# ファイルの存在確認
ls -la assets/tessdata/

# 以下のファイルがあることを確認:
# jpn.traineddata
# jpn_vert.traineddata
# eng.traineddata
```

`pubspec.yaml` の確認:

```yaml
flutter:
  assets:
    - assets/tessdata/  # スラッシュを忘れずに
```

#### Q2. 「Language not found」エラー

**A**: 学習データのファイル名が間違っています。

- ❌ `japanese.traineddata`
- ✅ `jpn.traineddata`

- ❌ `japanese_vert.traineddata`
- ✅ `jpn_vert.traineddata`

#### Q3. ビルドエラー

**A**: Flutterのクリーンビルドを試してください。

```bash
flutter clean
flutter pub get
flutter build ios  # or flutter build apk
```

#### Q4. iOS実機で動作しない

**A**: Xcodeのプロジェクト設定を確認してください。

1. Xcode で `ios/Runner.xcworkspace` を開く
2. Runner > Build Phases > Copy Bundle Resources
3. `tessdata` フォルダが含まれていることを確認

---

## 📈 次のステップ

### より高度な改善（オプション）

#### 1. 複数エンジンの並列実行

ML KitとTesseractを両方実行し、最良の結果を選択:

```dart
final mlkitResult = await ImageOcrHelper.recognizeText(imagePath: path);
final tesseractResult = await ImageOcrHelperTesseract.recognizeText(imagePath: path);

// スコアリングして最良を選択
final best = _selectBestResult([mlkitResult, tesseractResult]);
```

#### 2. Cloud Vision APIの検討

オンライン環境で最高精度が必要な場合:

- Google Cloud Vision API
- 月1000リクエストまで無料
- 横書き・縦書き日本語に完全対応
- 認識精度は最高レベル

```yaml
dependencies:
  google_ml_vision: ^0.0.8
```

#### 3. 前処理のさらなる最適化

- アンシャープマスク（シャープ化）
- ガンマ補正
- ノイズ除去
- 適応的二値化（ローカル閾値）

---

## 📝 まとめ

### 短期対策（今すぐ実施可能）

✅ **ML Kit改善版を使用**
- `image_ocr_helper_improved.dart` に置き換え
- セットアップ不要
- 即座に精度向上

### 中期対策（推奨）

✅ **Tesseract OCRに移行**
- 学習データをダウンロード（15分程度）
- `image_ocr_helper_tesseract.dart` を使用
- 横書き日本語の精度が大幅向上

### 長期対策（必要に応じて）

✅ **Cloud Vision API検討**
- オンライン環境限定
- 最高精度が必要な場合
- コスト管理が必要

---

## 🔗 参考リンク

- [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
- [flutter_tesseract_ocr](https://pub.dev/packages/flutter_tesseract_ocr)
- [Tesseract学習データ](https://github.com/tesseract-ocr/tessdata)
- [Cloud Vision API](https://cloud.google.com/vision/docs/ocr)

---

## ❓ 質問・サポート

このガイドで解決しない問題があれば、以下の情報を添えて報告してください:

1. 使用しているOCRエンジン（ML Kit / Tesseract）
2. エラーメッセージ（あれば）
3. 認識対象の画像サンプル
4. 期待する結果と実際の結果
5. Flutter・Dartのバージョン

```bash
flutter --version
```
