# NOESIS

辞書と読書メモを共通DBで扱うローカルMVPです。FastAPI + SQLite + FTS5で最小の縦切り構成にしています。

## ディレクトリ構成

- app/main.py: FastAPI エントリーポイント
- app/db.py: DB接続とスキーマ初期化
- app/repository.py: CRUD・検索
- app/services/mock_ai.py: 生成モック
- app/templates/: 画面
- app/static/style.css: スタイル
- data/knowledge.db: SQLite DB（初回起動で作成）
- tests/test_db.py: 最小テスト

## Entryの役割（思想）

- 辞書Entry: 単語や言い回しの「定義・用例・関連語」を安定した知識として保管する器。
- 読書メモEntry: 書籍や章などの出典に紐づく要約・気づき・引用をまとめる器。

## 辞書AIの生成範囲

辞書EntryはAIが初期生成し、人が編集して確定します。生成項目は以下です。

- genre
- tags
- definition
- example
- synonyms
- antonyms
- related
- reference_urls

タグは検索横断のための多様なラベルとして分散させ、同義語は synonyms に寄せます。

## ジャンルとタグ（辞書Entryのみ）

- ジャンル: 俯瞰用の分類。少数に絞り、辞書全体の見取り図を作る。
- タグ: 横断検索のための多対多ラベル。辞書Entryに複数付与して検索性を高める。

## 読書メモのBook構造

読書メモは `book` に紐づきます。同一タイトルは同じ book に集約し、UIでは「本 → メモ一覧」の導線で確認します。

## セットアップ

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## OpenAI APIキー設定（辞書AI用）

```bash
export OPENAI_API_KEY="your-api-key"
export OPENAI_MODEL="gpt-4o-mini"
```

`OPENAI_MODEL` は省略可能です。Responses API + JSON Schema を使って出力を強制しています。

## 実AIの確認方法（開発用）

- 実AIが使われた場合: サーバーログに `[AI_USED] model=...` が出ます。
- フォールバック時: サーバーログに `[AI_FALLBACK] reason=...` が出ます。
  - `api_key_missing` / `responses_api_unavailable` / `schema_validation_failed` / `api_exception:...` を区別します。

## 起動

```bash
uvicorn app.main:app --reload
```

ブラウザで `http://127.0.0.1:8000` にアクセス。

## DB作成

起動時に自動で `data/knowledge.db` を作成します。削除して再起動すると再作成されます。

## テスト

```bash
python -m pytest
```

## 使い方メモ

- 辞書入力: 単語を入力 → モック生成 → 編集 → 保存
- 読書メモ: 本タイトル/章/メモ本文 → モック要約 → 編集 → 保存
- 出典/引用は1行1件で `|` 区切り
  - 出典: `url | title | note`
  - 引用: `quote_text | page_or_loc | note`

## 思索アーカイブ / 日常メモアーカイブ

- 思索アーカイブ: `http://127.0.0.1:8000/think`
  - 概念辞書一覧・作成、概念メモ一覧・作成にアクセスします。
  - 概念メモから要約・抽出を実行し、概念辞書へ昇格できます。
- 日常メモアーカイブ: `http://127.0.0.1:8000/daily`
  - 短文メモを日付順に保存します。

## 辞書タイプの分離

- 既存辞書入力（default）
- IT用語辞書入力: 設定やコード片も入力可能
- 英語辞書入力: ニュアンス・使用シーンを重視
既存の辞書は default として扱います。

## 読書メモ → 辞書エントリ昇格

読書メモ詳細画面から「辞書エントリとして昇格」を押すと、本文をAIに渡して辞書ドラフトを作成します。

## reviewテーブルの役割（将来）

学習・復習のスケジューリング用に、各Entryの次回レビュー日時や間隔を保持します。今回は実装せず、UIやAPIを追加する際に参照します。

## 拡張方針（次の一手）

- 生成APIの差し替え: `app/services/mock_ai.py` を実装に置換
- エントリー詳細の編集/削除
- Tag/Source/Quoteの専用UI
- レビュー間隔の自動計算と復習画面
