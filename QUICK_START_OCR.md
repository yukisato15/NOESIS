# OCR改善 クイックスタートガイド

## 🚀 5分で始める OCR改善

### オプション1: ML Kit改善版（推奨・最速）

#### メリット
✅ セットアップ不要
✅ すぐに使える
✅ 現状より精度向上

#### デメリット
🟡 横書き日本語は中程度の精度

#### 手順

```bash
cd /Users/yukisato/アプリ作成/noesis_flutter

# 現在のファイルをバックアップ
cp lib/core/utils/image_ocr_helper.dart lib/core/utils/image_ocr_helper_backup.dart

# 改善版で上書き
cp lib/core/utils/image_ocr_helper_improved.dart lib/core/utils/image_ocr_helper.dart

# クラス名を変更（ImageOcrHelperImproved -> ImageOcrHelper）
sed -i '' 's/ImageOcrHelperImproved/ImageOcrHelper/g' lib/core/utils/image_ocr_helper.dart

# アプリを実行
flutter run
```

**完了！** これだけでOCR精度が向上します。

---

### オプション2: Tesseract OCR（高精度）

#### メリット
✅ 横書き日本語も高精度
✅ 縦書きも完璧対応
✅ オフライン動作

#### デメリット
🟡 初回セットアップ15分
🟡 アプリサイズ+30MB

#### 手順

##### 1. パッケージ追加（1分）

`pubspec.yaml` を開いて `dependencies:` に追加:

```yaml
dependencies:
  flutter_tesseract_ocr: ^0.4.24
```

```bash
flutter pub get
```

##### 2. 学習データをダウンロード（5分）

```bash
# ディレクトリ作成
mkdir -p assets/tessdata
cd assets/tessdata

# 日本語横書き（約15MB）
curl -L -O https://github.com/tesseract-ocr/tessdata/raw/main/jpn.traineddata

# 日本語縦書き（約15MB）
curl -L -O https://github.com/tesseract-ocr/tessdata/raw/main/jpn_vert.traineddata

# 英語（約4MB）
curl -L -O https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata

cd ../..
```

##### 3. assetsを登録（1分）

`pubspec.yaml` の `flutter:` セクションに追加:

```yaml
flutter:
  assets:
    - assets/tessdata/
```

##### 4. コードを置き換え（3分）

```bash
# 現在のファイルをバックアップ
cp lib/core/utils/image_ocr_helper.dart lib/core/utils/image_ocr_helper_mlkit.dart

# Tesseract版で上書き
cp lib/core/utils/image_ocr_helper_tesseract.dart lib/core/utils/image_ocr_helper.dart

# クラス名を変更（ImageOcrHelperTesseract -> ImageOcrHelper）
sed -i '' 's/ImageOcrHelperTesseract/ImageOcrHelper/g' lib/core/utils/image_ocr_helper.dart
```

##### 5. テスト

```bash
flutter clean
flutter pub get
flutter run
```

**完了！** 高精度なOCRが使えるようになりました。

---

## 🧪 テスト方法

### テストケース1: 横書き日本語

以下のテキストを印刷またはスクリーンショットで撮影:

```
ボリシェヴィズムは社会主義の一派である。
```

**期待結果**:
- ML Kit現状版: ❌ "A" など誤認識
- ML Kit改善版: 🟡 部分的に認識
- Tesseract版: ✅ ほぼ完璧に認識

### テストケース2: 縦書き日本語

```
吾
輩
は
猫
で
あ
る
```

**期待結果**:
- ML Kit現状版: ❌ ほぼ認識できず
- ML Kit改善版: ✅ 認識可能
- Tesseract版: ✅ 高精度で認識

### テストケース3: 英語

```
The quick brown fox jumps over the lazy dog.
```

**期待結果**:
- 全バージョン: ✅ 高精度で認識

---

## 📊 どれを選ぶべき？

### あなたの状況に合わせて選択:

| 状況 | 推奨 | 理由 |
|------|------|------|
| **今すぐ改善したい** | ML Kit改善版 | セットアップ不要 |
| **横書き日本語が重要** | Tesseract | ML Kitの限界を超える |
| **縦書きがメイン** | ML Kit改善版 | 十分な精度 |
| **英語のみ** | ML Kit改善版 | 十分な精度 |
| **最高精度が必要** | Tesseract | 実用レベル |
| **アプリサイズを小さく** | ML Kit改善版 | 追加容量なし |

---

## 🔧 既存コードへの影響

### ✅ 変更不要

どちらのオプションを選んでも、既存のコードは**そのまま動作**します:

```dart
// このコードは変更なしで動作
final result = await ImageOcrHelper.pickCropAndRecognize(
  context: context,
);

if (result != null && result.hasText) {
  print('認識結果: ${result.recognizedText}');
}
```

### 🎯 主な改善ポイント

両バージョン共通の改善:

1. **適切なスクリプト選択**
   - 横書き日本語: `latin` スクリプト優先
   - 縦書き日本語: `japanese` スクリプト優先

2. **画像前処理の最適化**
   - Otsu二値化（適応的閾値）
   - グレースケール化
   - 適切な拡大処理

3. **スコアリング改善**
   - 日本語文字を高く評価
   - 最良の結果を自動選択

4. **デバッグ出力**
   - 各候補のスコアを出力
   - 最終選択理由を表示

---

## 🐛 よくある問題

### Q: どちらを試すべき？

**A**: まず **ML Kit改善版** を試してください。

1. セットアップ不要で即座に改善
2. 実際の文書でテスト
3. 精度が不十分ならTesseractへ移行

### Q: 両方同時に使える？

**A**: はい、可能です。

```dart
// ML Kit版
import 'package:noesis_flutter/core/utils/image_ocr_helper_improved.dart';
final mlkitResult = await ImageOcrHelperImproved.recognizeText(...);

// Tesseract版
import 'package:noesis_flutter/core/utils/image_ocr_helper_tesseract.dart';
final tessResult = await ImageOcrHelperTesseract.recognizeText(...);

// 両方の結果を比較して最良を選択
```

### Q: 処理時間はどれくらい？

**A**:
- ML Kit改善版: 2-5秒
- Tesseract版: 3-7秒
- ML Kit現状版: 5-10秒（候補が多いため）

---

## 📈 成功の確認方法

改善が成功したか確認する方法:

### 1. デバッグログを確認

```bash
flutter run
```

OCR実行時に以下のようなログが表示されます:

```
OCR Result: original + latin -> 23 chars, score: 215
OCR Result: preprocessed + japanese -> 25 chars, score: 248
Best Result: preprocessed + japanese -> "ボリシェヴィズムは社会主義の一派である。" (score: 248)
```

### 2. 実際の文書でテスト

- 自分の本やノートをOCR
- 認識結果を確認
- 以前と比較

### 3. スコアを比較

- 高スコアの結果が選ばれているか確認
- 日本語文字が正しくカウントされているか確認

---

## 🎉 次のステップ

OCRが改善されたら:

1. **実際の使用ケースでテスト**
   - 読書メモの作成
   - 辞書エントリの作成
   - 日常メモの入力

2. **フィードバック収集**
   - どの文書タイプで精度が高いか
   - どの文書タイプで改善が必要か

3. **さらなる改善検討**
   - 前処理パラメータの調整
   - Cloud Vision APIの検討
   - カスタム学習データの作成

---

## 📞 サポート

問題が発生した場合:

1. **ログを確認**
   ```bash
   flutter run --verbose
   ```

2. **クリーンビルド**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **詳細ガイドを参照**
   - [OCR_SETUP_GUIDE.md](./OCR_SETUP_GUIDE.md)

---

## ✅ チェックリスト

### ML Kit改善版

- [ ] `image_ocr_helper_improved.dart` を `image_ocr_helper.dart` に置き換え
- [ ] クラス名を `ImageOcrHelper` に変更
- [ ] アプリをビルド・実行
- [ ] テスト画像でOCR実行
- [ ] 結果を確認

### Tesseract版

- [ ] `pubspec.yaml` にパッケージ追加
- [ ] `flutter pub get` 実行
- [ ] `assets/tessdata/` に学習データ配置
- [ ] `pubspec.yaml` に assets 登録
- [ ] `image_ocr_helper_tesseract.dart` を `image_ocr_helper.dart` に置き換え
- [ ] クラス名を `ImageOcrHelper` に変更
- [ ] `flutter clean` 実行
- [ ] アプリをビルド・実行
- [ ] テスト画像でOCR実行
- [ ] 結果を確認

---

## 🎯 まとめ

| 項目 | ML Kit改善版 | Tesseract |
|------|-------------|-----------|
| セットアップ時間 | 1分 | 15分 |
| 横書き日本語精度 | 🟡 中 | ✅ 高 |
| 縦書き日本語精度 | ✅ 高 | ✅ 高 |
| アプリサイズ増加 | なし | +30MB |
| 推奨ケース | クイック改善 | 本格運用 |

**まずはML Kit改善版を試して、必要に応じてTesseractへ移行しましょう！**
