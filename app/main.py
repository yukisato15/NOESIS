import json
import logging

from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .db import get_connection, init_db
from .repository import (
    add_quotes,
    add_entry_appendix,
    add_book_appendix,
    add_ai_session,
    add_link,
    add_sources,
    add_tags,
    create_entry,
    create_concept_dictionary,
    create_concept_memo,
    create_daily_memo,
    create_english_lexicon,
    create_reading_memo,
    create_reading_reflection,
    delete_entry,
    get_book,
    get_concept_dictionary,
    get_concept_memo,
    get_entry,
    get_entry_quotes,
    list_entry_appendix,
    list_book_appendix,
    list_ai_sessions,
    list_concept_dictionary,
    list_concept_memo,
    list_daily_memo,
    list_links_by_source,
    list_links_by_target,
    get_entry_sources,
    get_entry_tags,
    get_tags_for_entries,
    list_tags,
    get_books_with_counts,
    get_or_create_book,
    get_reading_notes_by_book,
    get_reading_reflections_by_book,
    list_dictionary_entries,
    update_book_overview,
    get_english_lexicon,
    replace_quotes,
    replace_sources,
    replace_tags,
    search_entries,
    update_concept_memo,
    update_entry,
)
from .services.mock_ai import (
    DictionaryDraft,
    EnglishLexiconDraft,
    ReadingDraft,
    empty_english_draft,
    extract_concepts_from_memo,
    generate_chat_response,
    generate_concept_chat_response,
    generate_dictionary,
    generate_english_entry,
    generate_reading,
    generate_reading_summary,
    summarize_concept_memo,
    summarize_chat_log,
    validate_english_schema,
)
from .utils import gojuon_row, normalize_reading

app = FastAPI()
app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")
logger = logging.getLogger(__name__)


@app.on_event("startup")
def startup() -> None:
    conn = get_connection()
    init_db(conn)
    conn.close()


def parse_tags(tag_text: str) -> list:
    if not tag_text:
        return []
    return [t.strip() for t in tag_text.split(",") if t.strip()]


def parse_sources(source_text: str) -> list:
    sources = []
    if not source_text:
        return sources
    for line in source_text.splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        sources.append(
            {
                "url": parts[0] if len(parts) > 0 else "",
                "title": parts[1] if len(parts) > 1 else "",
                "note": parts[2] if len(parts) > 2 else "",
            }
        )
    return sources


def parse_quotes(quote_text: str) -> list:
    quotes = []
    if not quote_text:
        return quotes
    for line in quote_text.splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        quotes.append(
            {
                "quote_text": parts[0] if len(parts) > 0 else "",
                "page_or_loc": parts[1] if len(parts) > 1 else "",
                "note": parts[2] if len(parts) > 2 else "",
            }
        )
    return quotes


def parse_term_pairs(text: str) -> list:
    items = []
    if not text:
        return items
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        items.append(
            {
                "term_en": parts[0] if len(parts) > 0 else "",
                "term_ja": parts[1] if len(parts) > 1 else "",
                "note": parts[2] if len(parts) > 2 else "",
            }
        )
    return items


def parse_examples(text: str) -> list:
    items = []
    if not text:
        return items
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        items.append(
            {
                "sentence_en": parts[0] if len(parts) > 0 else "",
                "sentence_ja": parts[1] if len(parts) > 1 else "",
            }
        )
    return items


def parse_phrases(text: str) -> list:
    items = []
    if not text:
        return items
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        items.append(
            {
                "phrase_en": parts[0] if len(parts) > 0 else "",
                "phrase_ja": parts[1] if len(parts) > 1 else "",
                "note": parts[2] if len(parts) > 2 else "",
            }
        )
    return items


def build_dictionary_body(definition: str, example: str, synonyms: str, antonyms: str, related: str, urls: str) -> str:
    sections = [
        f"## 定義\n{definition}",
        f"## 例文\n{example}",
        f"## 類義語\n{synonyms}",
        f"## 対立概念\n{antonyms}",
        f"## 関連語\n{related}",
        f"## 参考URL\n{urls}",
    ]
    return "\n\n".join(sections)


def build_reading_body(summary: str, memo: str) -> str:
    sections = [f"## 要約\n{summary}", f"## メモ本文\n{memo}"]
    return "\n\n".join(sections)


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/search", response_class=HTMLResponse)
def search(request: Request, q: str = "", entry_type: str = "", tag: str = ""):
    date_from = request.query_params.get("date_from", "")
    date_to = request.query_params.get("date_to", "")
    conn = get_connection()
    entries = search_entries(
        conn,
        q,
        entry_type or None,
        tag or None,
        date_from or None,
        date_to or None,
    )
    tag_map = get_tags_for_entries(conn, [e["id"] for e in entries])
    tags = list_tags(conn)
    conn.close()
    return templates.TemplateResponse(
        "search.html",
        {
            "request": request,
            "entries": entries,
            "query": q,
            "entry_type": entry_type,
            "tag": tag,
            "tag_map": tag_map,
            "tags": tags,
            "date_from": date_from,
            "date_to": date_to,
        },
    )


def dictionary_ui_context(dictionary_type: str) -> dict:
    label_map = {
        "default": "辞書入力",
        "it": "IT用語辞書入力",
        "english": "英語辞書入力",
    }
    description_map = {
        "default": "単語や言い回しの核になる意味だけを先に保存します。後から追記できます。",
        "it": "単語だけでなく、設定やコード片も入力できます。文脈や構造もAIが補足します。",
        "english": "単語・熟語・言い回しを入力します。ニュアンスや使用シーンもAIが補足します。",
    }
    placeholder_map = {
        "default": "例: パース",
        "it": "例: uvicorn / 設定やコード片も可",
        "english": "例: get by / out of the blue",
    }
    return {
        "dictionary_type": dictionary_type,
        "dictionary_label": label_map.get(dictionary_type, label_map["default"]),
        "dictionary_description": description_map.get(dictionary_type, description_map["default"]),
        "dictionary_placeholder": placeholder_map.get(dictionary_type, placeholder_map["default"]),
    }


def dictionary_meta_from_type(dictionary_type: str) -> dict:
    domain_map = {
        "default": "general",
        "it": "technology",
        "english": "english",
    }
    language_map = {
        "default": "ja",
        "it": "ja",
        "english": "en",
    }
    return {
        "domain": domain_map.get(dictionary_type, "general"),
        "field": "unspecified",
        "language": language_map.get(dictionary_type, "ja"),
    }


def dictionary_type_from_entry(entry: dict) -> str:
    if entry.get("language") == "en":
        return "english"
    if entry.get("domain") == "technology":
        return "it"
    return "default"


def dictionary_fields(domain: str) -> list:
    fields = {
        "general": [
            "思考・認知",
            "哲学・思想",
            "社会・政治",
            "経済・資本",
            "歴史・時間",
            "感情・心理",
            "言語・記号",
            "倫理・価値",
            "文化・表象",
        ],
        "english": [
            "日常語彙",
            "抽象語",
            "感情表現",
            "ビジネス英語",
            "IT英語",
            "熟語・イディオム",
            "文法・構文",
        ],
        "technology": [
            "プログラミング基礎",
            "言語仕様",
            "データ構造",
            "アルゴリズム",
            "Webフロントエンド",
            "Webバックエンド",
            "インフラ・クラウド",
            "OS・低レイヤ",
            "ネットワーク",
            "セキュリティ",
            "開発プロセス",
            "設計思想・アーキテクチャ",
            "AI・機械学習",
            "数学・論理",
        ],
    }
    return fields.get(domain, fields["general"])


@app.get("/dictionary", response_class=HTMLResponse)
def dictionary_list(
    request: Request,
    domain: str = "general",
    field: str = "",
    row: str = "",
):
    conn = get_connection()
    entries = list_dictionary_entries(conn, domain, field or None)
    conn.close()
    filtered = []
    for entry in entries:
        reading = entry.get("reading") or ""
        row_key = gojuon_row(reading)
        if row and row_key != row:
            continue
        entry["reading_sort"] = normalize_reading(reading)
        filtered.append(entry)
    filtered.sort(key=lambda item: item.get("reading_sort", ""))
    return templates.TemplateResponse(
        "dictionary_list.html",
        {
            "request": request,
            "entries": filtered,
            "domain": domain,
            "field": field,
            "row": row,
            "fields": dictionary_fields(domain),
            "rows": ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "ん"],
            "domain_labels": {"general": "一般知", "english": "英語", "technology": "IT・技術"},
        },
    )


@app.get("/dictionary/new", response_class=HTMLResponse)
def dictionary_new(request: Request):
    # Dictionary entry: store stable definition-oriented knowledge.
    context = dictionary_ui_context("default")
    return templates.TemplateResponse("dictionary_new.html", {"request": request, **context})


@app.get("/dictionary/it/new", response_class=HTMLResponse)
def dictionary_it_new(request: Request):
    context = dictionary_ui_context("it")
    return templates.TemplateResponse("dictionary_new.html", {"request": request, **context})


@app.get("/dictionary/english/new", response_class=HTMLResponse)
def dictionary_english_new(request: Request):
    context = dictionary_ui_context("english")
    return templates.TemplateResponse("dictionary_new.html", {"request": request, **context})


@app.post("/dictionary/preview", response_class=HTMLResponse)
def dictionary_preview(
    request: Request,
    term: str = Form(...),
    dictionary_type: str = Form("default"),
):
    context = dictionary_ui_context(dictionary_type)
    if dictionary_type == "english":
        error_message = ""
        ai_generated = "1"
        try:
            draft = generate_english_entry(term)
        except Exception:
            draft = empty_english_draft(term)
            error_message = "AI生成に失敗しました（詳細はサーバログ参照）。"
            ai_generated = "0"
        return templates.TemplateResponse(
            "english_preview.html",
            {
                "request": request,
                "term": term,
                "draft": draft,
                "dictionary_type": dictionary_type,
                "synonyms_text": format_term_pairs(draft.synonyms),
                "antonyms_text": format_term_pairs(draft.antonyms),
                "examples_text": format_examples(draft.examples),
                "phrases_text": format_phrases(draft.phrases),
                "ai_generated": ai_generated,
                "error_message": error_message,
                "chat_log": "",
                "chat_answer": "",
                **context,
            },
        )
    draft = generate_dictionary(term, dictionary_type=dictionary_type)
    return templates.TemplateResponse(
        "dictionary_preview.html",
        {
            "request": request,
            "term": term,
            "draft": draft,
            "dictionary_type": dictionary_type,
            "genre": draft.genre_candidates[0] if draft.genre_candidates else "",
            "tags": ", ".join(draft.tag_candidates),
            "chat_log": "",
            "chat_answer": "",
            **context,
        },
    )


@app.post("/dictionary/chat", response_class=HTMLResponse)
async def dictionary_chat(request: Request):
    form = await request.form()
    dictionary_type = form.get("dictionary_type", "default")
    term = form.get("term", "")
    question = form.get("chat_question", "")
    chat_log = form.get("chat_log", "")

    answer = generate_chat_response(term, dictionary_type, question) if question else ""
    if answer:
        entry = f"Q: {question}\nA: {answer}"
        chat_log = f"{chat_log}\n\n{entry}".strip() if chat_log else entry

    context = dictionary_ui_context(dictionary_type)
    if dictionary_type == "english":
        draft = EnglishLexiconDraft(
            headword=form.get("headword", ""),
            pronunciation=form.get("pronunciation", ""),
            definition_ja=form.get("meaning_ja", ""),
            etymology_background=form.get("etymology_background", ""),
            synonyms=parse_term_pairs(form.get("synonyms_items", "")),
            antonyms=parse_term_pairs(form.get("antonyms_items", "")),
            examples=parse_examples(form.get("examples_items", "")),
            phrases=parse_phrases(form.get("phrases_items", "")),
            usage_note=form.get("usage_note", ""),
            free_memo=form.get("free_memo", ""),
        )
        return templates.TemplateResponse(
            "english_preview.html",
            {
                "request": request,
                "term": term,
                "draft": draft,
                "dictionary_type": dictionary_type,
                "synonyms_text": format_term_pairs(draft.synonyms),
                "antonyms_text": format_term_pairs(draft.antonyms),
                "examples_text": format_examples(draft.examples),
                "phrases_text": format_phrases(draft.phrases),
                "ai_generated": "1",
                "error_message": "",
                "chat_log": chat_log,
                "chat_answer": answer,
                **context,
            },
        )

    draft = DictionaryDraft(
        genre_candidates=[form.get("genre", "")],
        tag_candidates=[t.strip() for t in form.get("tags", "").split(",") if t.strip()],
        concepts=form.get("concepts", ""),
        definition=form.get("definition", ""),
        example=form.get("example", ""),
        synonyms=form.get("synonyms", ""),
        antonyms=form.get("antonyms", ""),
        related=form.get("related", ""),
        reference_urls=form.get("reference_urls", ""),
    )
    return templates.TemplateResponse(
        "dictionary_preview.html",
        {
            "request": request,
            "term": term,
            "draft": draft,
            "dictionary_type": dictionary_type,
            "genre": form.get("genre", ""),
            "tags": form.get("tags", ""),
            "chat_log": chat_log,
            "chat_answer": answer,
            **context,
        },
    )


@app.post("/dictionary/save")
def dictionary_save(
    request: Request,
    term: str = Form(...),
    dictionary_type: str = Form("default"),
    genre: str = Form(""),
    concepts: str = Form(""),
    definition: str = Form(""),
    example: str = Form(""),
    synonyms: str = Form(""),
    antonyms: str = Form(""),
    related: str = Form(""),
    reference_urls: str = Form(""),
    tags: str = Form(""),
    sources: str = Form(""),
    headword: str = Form(""),
    ipa: str = Form(""),
    pronunciation: str = Form(""),
    meaning_ja: str = Form(""),
    synonyms_items: str = Form(""),
    antonyms_items: str = Form(""),
    etymology_background: str = Form(""),
    examples_items: str = Form(""),
    phrases_items: str = Form(""),
    usage_note: str = Form(""),
    free_memo: str = Form(""),
    chat_log: str = Form(""),
    chat_extract: str = Form(""),
    chat_save_mode: str = Form("none"),
    ai_generated: str = Form("0"),
):
    conn = get_connection()
    meta = dictionary_meta_from_type(dictionary_type)
    if dictionary_type == "english":
        title_value = headword or term
        body = meaning_ja or title_value
        reading_value = generate_reading(title_value, dictionary_type)
        payload = {
            "headword": headword,
            "pronunciation": pronunciation,
            "meaning_ja": meaning_ja,
            "etymology_background": etymology_background,
            "synonyms": parse_term_pairs(synonyms_items),
            "antonyms": parse_term_pairs(antonyms_items),
            "examples": parse_examples(examples_items),
            "phrases": parse_phrases(phrases_items),
            "usage_note": usage_note,
            "free_memo": free_memo,
        }
        ok, errors = validate_english_schema(payload)
        if ai_generated != "1" or not ok:
            if errors:
                logger.warning("[AI_SCHEMA_FAIL] errors=%s", "; ".join(errors))
            conn.close()
            draft = empty_english_draft(term)
            draft.headword = headword
            draft.pronunciation = pronunciation
            draft.definition_ja = meaning_ja
            draft.etymology_background = etymology_background
            draft.synonyms = payload["synonyms"]
            draft.antonyms = payload["antonyms"]
            draft.examples = payload["examples"]
            draft.phrases = payload["phrases"]
            draft.usage_note = usage_note
            draft.free_memo = free_memo
            context = dictionary_ui_context("english")
            return templates.TemplateResponse(
                "english_preview.html",
                {
                    "request": request,
                    "term": term,
                    "draft": draft,
                    "dictionary_type": "english",
                    "synonyms_text": format_term_pairs(draft.synonyms),
                    "antonyms_text": format_term_pairs(draft.antonyms),
                    "examples_text": format_examples(draft.examples),
                    "phrases_text": format_phrases(draft.phrases),
                    "ai_generated": "0",
                    "error_message": "AI生成に失敗しました（詳細はサーバログ参照）。",
                    "chat_log": chat_log,
                    "chat_answer": "",
                    **context,
                },
                status_code=400,
            )
        entry_id = create_entry(
            conn,
            "dictionary",
            title_value,
            body,
            domain=meta["domain"],
            field=meta["field"],
            concept=None,
            reading=reading_value,
            language=meta["language"],
            reading_source="ai" if reading_value != title_value else "manual",
        )
        create_english_lexicon(
            conn,
            entry_id,
            {
                "headword": headword,
                "language": "en",
                "ipa": pronunciation,
                "reading_kana": "",
                "part_of_speech": "",
                "countability": "",
                "definition_en": "",
                "definition_ja": meaning_ja,
                "synonyms": payload["synonyms"],
                "antonyms": payload["antonyms"],
                "related_terms": [],
                "examples": payload["examples"],
                "phrases": payload["phrases"],
                "register": "",
                "etymology": etymology_background,
                "concept_memo": "",
                "usage_note": usage_note,
                "pronunciation_note": "",
                "audio_tts_text": "",
                "audio_url": "",
                "audio_note": free_memo,
            },
        )
        if chat_save_mode == "log" and chat_log:
            add_entry_appendix(conn, entry_id, "log", chat_log)
        elif chat_save_mode == "extract" and chat_extract:
            add_entry_appendix(conn, entry_id, "extract", chat_extract)
        elif chat_save_mode == "summary" and chat_log:
            summary = summarize_chat_log(chat_log)
            if summary:
                add_entry_appendix(conn, entry_id, "summary", summary)
    else:
        body = build_dictionary_body(definition, example, synonyms, antonyms, related, reference_urls)
        reading_value = generate_reading(term, dictionary_type)
        entry_id = create_entry(
            conn,
            "dictionary",
            term,
            body,
            genre=genre or None,
            domain=meta["domain"],
            field=meta["field"],
            concept=concepts.strip() or None,
            reading=reading_value,
            language=meta["language"],
            reading_source="ai" if reading_value != term else "manual",
        )
        add_tags(conn, entry_id, parse_tags(tags))
        add_sources(conn, entry_id, parse_sources(sources))
        if chat_save_mode == "log" and chat_log:
            add_entry_appendix(conn, entry_id, "log", chat_log)
        elif chat_save_mode == "extract" and chat_extract:
            add_entry_appendix(conn, entry_id, "extract", chat_extract)
        elif chat_save_mode == "summary" and chat_log:
            summary = summarize_chat_log(chat_log)
            if summary:
                add_entry_appendix(conn, entry_id, "summary", summary)
    conn.close()
    return RedirectResponse(url=f"/entry/{entry_id}", status_code=303)


@app.get("/reading-notes/new", response_class=HTMLResponse)
def reading_new(request: Request):
    return RedirectResponse(url="/reading-archive/new", status_code=303)


@app.post("/reading-notes/preview", response_class=HTMLResponse)
def reading_preview(
    request: Request,
    book_title: str = Form(...),
    author: str = Form(""),
    isbn: str = Form(""),
    chapter: str = Form(""),
    memo: str = Form(""),
):
    return RedirectResponse(url="/reading-archive/new", status_code=303)


@app.post("/reading-notes/save")
def reading_save(
    book_title: str = Form(...),
    author: str = Form(""),
    isbn: str = Form(""),
    chapter: str = Form(""),
    summary: str = Form(""),
    memo: str = Form(""),
    tags: str = Form(""),
    sources: str = Form(""),
    quotes: str = Form(""),
    chat_log: str = Form(""),
    chat_extract: str = Form(""),
    chat_save_mode: str = Form("none"),
):
    return RedirectResponse(url="/reading-archive/new", status_code=303)


@app.get("/entry/{entry_id}", response_class=HTMLResponse)
def entry_view(request: Request, entry_id: int):
    conn = get_connection()
    entry = get_entry(conn, entry_id)
    tags = get_entry_tags(conn, entry_id)
    sources = get_entry_sources(conn, entry_id)
    quotes = get_entry_quotes(conn, entry_id)
    appendix = list_entry_appendix(conn, entry_id)
    english_lexicon = get_english_lexicon(conn, entry_id) if entry and entry.get("language") == "en" else None
    book = get_book(conn, entry["book_id"]) if entry and entry.get("book_id") else None
    conn.close()
    if not entry:
        return templates.TemplateResponse(
            "entry_view.html",
            {
                "request": request,
                "entry": None,
                "tags": [],
                "sources": [],
                "quotes": [],
                "book": None,
                "english_lexicon": None,
                "appendix": [],
                "chat_log": "",
                "chat_answer": "",
            },
            status_code=404,
        )
    return templates.TemplateResponse(
        "entry_view.html",
        {
            "request": request,
            "entry": entry,
            "tags": tags,
            "sources": sources,
            "quotes": quotes,
            "book": book,
            "english_lexicon": english_lexicon,
            "appendix": appendix,
            "chat_log": "",
            "chat_answer": "",
        },
    )


@app.post("/entry/{entry_id}/chat", response_class=HTMLResponse)
async def entry_chat(request: Request, entry_id: int):
    form = await request.form()
    question = form.get("chat_question", "")
    chat_log = form.get("chat_log", "")

    conn = get_connection()
    entry = get_entry(conn, entry_id)
    tags = get_entry_tags(conn, entry_id)
    sources = get_entry_sources(conn, entry_id)
    quotes = get_entry_quotes(conn, entry_id)
    appendix = list_entry_appendix(conn, entry_id)
    english_lexicon = get_english_lexicon(conn, entry_id) if entry and entry.get("language") == "en" else None
    book = get_book(conn, entry["book_id"]) if entry and entry.get("book_id") else None
    conn.close()
    if not entry:
        return RedirectResponse(url="/", status_code=303)

    dictionary_type = dictionary_type_from_entry(entry)
    answer = generate_chat_response(entry["title"], dictionary_type, question) if question else ""
    if answer:
        entry_text = f"Q: {question}\nA: {answer}"
        chat_log = f"{chat_log}\n\n{entry_text}".strip() if chat_log else entry_text

    return templates.TemplateResponse(
        "entry_view.html",
        {
            "request": request,
            "entry": entry,
            "tags": tags,
            "sources": sources,
            "quotes": quotes,
            "book": book,
            "english_lexicon": english_lexicon,
            "appendix": appendix,
            "chat_log": chat_log,
            "chat_answer": answer,
        },
    )


@app.post("/entry/{entry_id}/chat/save")
async def entry_chat_save(request: Request, entry_id: int):
    form = await request.form()
    save_mode = form.get("chat_save_mode", "none")
    chat_log = form.get("chat_log", "")
    chat_extract = form.get("chat_extract", "")

    conn = get_connection()
    entry = get_entry(conn, entry_id)
    if not entry:
        conn.close()
        return RedirectResponse(url="/", status_code=303)

    if save_mode == "log" and chat_log:
        add_entry_appendix(conn, entry_id, "log", chat_log)
    elif save_mode == "extract" and chat_extract:
        add_entry_appendix(conn, entry_id, "extract", chat_extract)
    elif save_mode == "summary" and chat_log:
        summary = summarize_chat_log(chat_log)
        if summary:
            add_entry_appendix(conn, entry_id, "summary", summary)

    conn.close()
    return RedirectResponse(url=f"/entry/{entry_id}", status_code=303)


@app.get("/reading-notes/{entry_id}/promote", response_class=HTMLResponse)
def reading_note_promote(request: Request, entry_id: int):
    conn = get_connection()
    entry = get_entry(conn, entry_id)
    conn.close()
    if not entry or entry["type"] != "reading_note":
        return RedirectResponse(url="/", status_code=303)
    draft = generate_dictionary(entry["title"], dictionary_type="default", context=entry["body"])
    context = dictionary_ui_context("default")
    return templates.TemplateResponse(
        "dictionary_preview.html",
        {
            "request": request,
            "term": entry["title"],
            "draft": draft,
            "dictionary_type": "default",
            "genre": draft.genre_candidates[0] if draft.genre_candidates else "",
            "tags": ", ".join(draft.tag_candidates),
            **context,
        },
    )


def format_sources_for_edit(sources: list) -> str:
    # Use a simple loop to avoid brittle f-string escaping issues.
    lines = []
    for source in sources:
        line = f"{source.get('url', '')} | {source.get('title', '')} | {source.get('note', '')}"
        lines.append(line)
    return "\n".join(lines)


def format_quotes_for_edit(quotes: list) -> str:
    # Use a simple loop to avoid brittle f-string escaping issues.
    lines = []
    for quote in quotes:
        line = f"{quote.get('quote_text', '')} | {quote.get('page_or_loc', '')} | {quote.get('note', '')}"
        lines.append(line)
    return "\n".join(lines)


def format_term_pairs(items: list) -> str:
    lines = []
    for item in items or []:
        line = f"{item.get('term_en', '')} | {item.get('term_ja', '')}"
        if item.get("note"):
            line = f"{line} | {item.get('note')}"
        lines.append(line)
    return "\n".join(lines)


def format_examples(items: list) -> str:
    lines = []
    for item in items or []:
        line = f"{item.get('sentence_en', '')} | {item.get('sentence_ja', '')}"
        lines.append(line)
    return "\n".join(lines)


def format_phrases(items: list) -> str:
    lines = []
    for item in items or []:
        line = f"{item.get('phrase_en', '')} | {item.get('phrase_ja', '')}"
        if item.get("note"):
            line = f"{line} | {item.get('note')}"
        lines.append(line)
    return "\n".join(lines)


@app.get("/entry/{entry_id}/edit", response_class=HTMLResponse)
def entry_edit(request: Request, entry_id: int):
    conn = get_connection()
    entry = get_entry(conn, entry_id)
    tags = get_entry_tags(conn, entry_id)
    sources = get_entry_sources(conn, entry_id)
    quotes = get_entry_quotes(conn, entry_id)
    conn.close()
    if not entry:
        return templates.TemplateResponse(
            "entry_edit.html",
            {
                "request": request,
                "entry": None,
                "tags_text": "",
                "sources_text": "",
                "quotes_text": "",
            },
            status_code=404,
        )
    return templates.TemplateResponse(
        "entry_edit.html",
        {
            "request": request,
            "entry": entry,
            "tags_text": ", ".join(tags),
            "sources_text": format_sources_for_edit(sources),
            "quotes_text": format_quotes_for_edit(quotes),
        },
    )


@app.post("/entry/{entry_id}/edit")
def entry_update(
    entry_id: int,
    title: str = Form(...),
    body: str = Form(...),
    genre: str = Form(""),
    tags: str = Form(""),
    sources: str = Form(""),
    quotes: str = Form(""),
):
    conn = get_connection()
    entry = get_entry(conn, entry_id)
    if not entry:
        conn.close()
        return RedirectResponse(url="/", status_code=303)
    genre_value = genre.strip() if entry["type"] == "dictionary" else None
    update_entry(conn, entry_id, title, body, genre=genre_value or None)
    replace_tags(conn, entry_id, parse_tags(tags))
    replace_sources(conn, entry_id, parse_sources(sources))
    replace_quotes(conn, entry_id, parse_quotes(quotes))
    conn.close()
    return RedirectResponse(url=f"/entry/{entry_id}", status_code=303)


@app.post("/entry/{entry_id}/delete")
def entry_delete(entry_id: int):
    conn = get_connection()
    delete_entry(conn, entry_id)
    conn.close()
    return RedirectResponse(url="/", status_code=303)


@app.get("/reading-notes/books", response_class=HTMLResponse)
def reading_books(request: Request):
    return RedirectResponse(url="/reading-archive", status_code=303)


@app.post("/reading-notes/chat", response_class=HTMLResponse)
async def reading_notes_chat(request: Request):
    form = await request.form()
    question = form.get("chat_question", "")
    chat_log = form.get("chat_log", "")
    book_title = form.get("book_title", "")
    author = form.get("author", "")
    isbn = form.get("isbn", "")
    chapter = form.get("chapter", "")
    memo = form.get("memo", "")
    summary = form.get("summary", "")

    answer = generate_chat_response(book_title, "default", question) if question else ""
    if answer:
        entry_text = f"Q: {question}\nA: {answer}"
        chat_log = f"{chat_log}\n\n{entry_text}".strip() if chat_log else entry_text

    draft = ReadingDraft(summary=summary or generate_reading_summary(book_title, chapter, memo).summary)
    return templates.TemplateResponse(
        "reading_preview.html",
        {
            "request": request,
            "book_title": book_title,
            "author": author,
            "isbn": isbn,
            "chapter": chapter,
            "memo": memo,
            "draft": draft,
            "chat_log": chat_log,
            "chat_answer": answer,
        },
    )


@app.get("/language-archive", response_class=HTMLResponse)
def language_archive_hub(request: Request):
    return templates.TemplateResponse("language_archive_hub.html", {"request": request})


@app.get("/reading-archive", response_class=HTMLResponse)
def reading_archive_hub(request: Request):
    conn = get_connection()
    books = get_books_with_counts(conn)
    conn.close()
    return templates.TemplateResponse(
        "reading_archive_hub.html",
        {"request": request, "books": books},
    )


@app.get("/reading-archive/new", response_class=HTMLResponse)
def reading_archive_new(request: Request):
    return templates.TemplateResponse("reading_archive_new.html", {"request": request})


@app.post("/reading-archive/save")
def reading_archive_save(
    book_title: str = Form(...),
    author: str = Form(...),
    isbn: str = Form(""),
    overview: str = Form(""),
):
    conn = get_connection()
    book_id = get_or_create_book(conn, book_title, author, isbn)
    if overview:
        update_book_overview(conn, book_id, overview)
    conn.close()
    return RedirectResponse(url=f"/reading-archive/{book_id}", status_code=303)


@app.get("/reading-archive/{book_id}", response_class=HTMLResponse)
def reading_archive_detail(request: Request, book_id: int):
    conn = get_connection()
    book = get_book(conn, book_id)
    memos = get_reading_notes_by_book(conn, book_id)
    reflections = get_reading_reflections_by_book(conn, book_id)
    appendix = list_book_appendix(conn, book_id)
    conn.close()
    return templates.TemplateResponse(
        "reading_archive_detail.html",
        {
            "request": request,
            "book": book,
            "memos": memos,
            "reflections": reflections,
            "appendix": appendix,
            "chat_log": "",
            "chat_answer": "",
        },
    )


@app.post("/reading-archive/{book_id}/memo")
def reading_archive_add_memo(request: Request, book_id: int, content: str = Form(...)):
    conn = get_connection()
    create_reading_memo(conn, book_id, content)
    conn.close()
    return RedirectResponse(url=f"/reading-archive/{book_id}", status_code=303)


@app.post("/reading-archive/{book_id}/reflection")
def reading_archive_add_reflection(request: Request, book_id: int, content: str = Form(...)):
    conn = get_connection()
    create_reading_reflection(conn, book_id, content)
    conn.close()
    return RedirectResponse(url=f"/reading-archive/{book_id}", status_code=303)


@app.post("/reading-archive/{book_id}/chat", response_class=HTMLResponse)
async def reading_archive_chat(request: Request, book_id: int):
    form = await request.form()
    question = form.get("chat_question", "")
    chat_log = form.get("chat_log", "")
    conn = get_connection()
    book = get_book(conn, book_id)
    memos = get_reading_notes_by_book(conn, book_id)
    reflections = get_reading_reflections_by_book(conn, book_id)
    appendix = list_book_appendix(conn, book_id)
    conn.close()
    answer = generate_chat_response(book.get("title", ""), "default", question) if question else ""
    if answer:
        entry_text = f"Q: {question}\nA: {answer}"
        chat_log = f"{chat_log}\n\n{entry_text}".strip() if chat_log else entry_text
    return templates.TemplateResponse(
        "reading_archive_detail.html",
        {
            "request": request,
            "book": book,
            "memos": memos,
            "reflections": reflections,
            "appendix": appendix,
            "chat_log": chat_log,
            "chat_answer": answer,
        },
    )


@app.post("/reading-archive/{book_id}/chat/save")
def reading_archive_chat_save(
    request: Request,
    book_id: int,
    chat_log: str = Form(""),
    chat_extract: str = Form(""),
    chat_save_mode: str = Form("none"),
):
    conn = get_connection()
    if chat_save_mode == "log" and chat_log:
        add_book_appendix(conn, book_id, "log", chat_log)
    elif chat_save_mode == "extract" and chat_extract:
        add_book_appendix(conn, book_id, "extract", chat_extract)
    elif chat_save_mode == "summary" and chat_log:
        summary = summarize_chat_log(chat_log)
        if summary:
            add_book_appendix(conn, book_id, "summary", summary)
    conn.close()
    return RedirectResponse(url=f"/reading-archive/{book_id}", status_code=303)


@app.get("/reading-notes/books/{book_id}", response_class=HTMLResponse)
def reading_book_notes(request: Request, book_id: int):
    return RedirectResponse(url=f"/reading-archive/{book_id}", status_code=303)


@app.get("/think", response_class=HTMLResponse)
def think_hub(request: Request):
    return templates.TemplateResponse("think_hub.html", {"request": request})


@app.get("/concepts", response_class=HTMLResponse)
def concept_dictionary_list(request: Request):
    conn = get_connection()
    concepts = list_concept_dictionary(conn)
    conn.close()
    return templates.TemplateResponse(
        "concept_dictionary_list.html",
        {"request": request, "concepts": concepts},
    )


@app.get("/concepts/new", response_class=HTMLResponse)
def concept_dictionary_new(request: Request):
    return templates.TemplateResponse("concept_dictionary_new.html", {"request": request})


@app.get("/concepts/ai/new", response_class=HTMLResponse)
def concept_dictionary_ai_new(request: Request):
    return templates.TemplateResponse(
        "concept_dictionary_ai_new.html",
        {"request": request, "chat_answer": ""},
    )


@app.post("/concepts/ai/chat", response_class=HTMLResponse)
def concept_dictionary_ai_chat(
    request: Request,
    question: str = Form(""),
):
    answer = generate_chat_response("concept_dictionary", "default", question) if question else ""
    return templates.TemplateResponse(
        "concept_dictionary_ai_new.html",
        {"request": request, "chat_answer": answer},
    )


@app.post("/concepts/ai/preview", response_class=HTMLResponse)
def concept_dictionary_ai_preview(
    request: Request,
    term: str = Form(...),
):
    draft = generate_dictionary(term, dictionary_type="default")
    return templates.TemplateResponse(
        "concept_dictionary_preview.html",
        {
            "request": request,
            "term": term,
            "draft": draft,
        },
    )


@app.post("/concepts/ai/save")
def concept_dictionary_ai_save(
    term: str = Form(...),
    definition: str = Form(""),
    example: str = Form(""),
    synonyms: str = Form(""),
    antonyms: str = Form(""),
    related: str = Form(""),
    reference_urls: str = Form(""),
):
    body = build_dictionary_body(definition, example, synonyms, antonyms, related, reference_urls)
    conn = get_connection()
    concept_id = create_concept_dictionary(conn, term.strip(), body)
    conn.close()
    return RedirectResponse(url=f"/concepts/{concept_id}", status_code=303)


@app.post("/concepts/save")
def concept_dictionary_save(
    title: str = Form(""),
    body: str = Form(""),
):
    if not title.strip() or not body.strip():
        return RedirectResponse(url="/concepts/new", status_code=303)
    conn = get_connection()
    concept_id = create_concept_dictionary(conn, title.strip(), body.strip())
    conn.close()
    return RedirectResponse(url=f"/concepts/{concept_id}", status_code=303)


@app.get("/concepts/{concept_id}", response_class=HTMLResponse)
def concept_dictionary_detail(request: Request, concept_id: int):
    conn = get_connection()
    concept = get_concept_dictionary(conn, concept_id)
    links = list_links_by_target(conn, "concept_dictionary", concept_id)
    memos = []
    for link in links:
        memo = get_concept_memo(conn, link["source_id"])
        if memo:
            memos.append(memo)
    conn.close()
    return templates.TemplateResponse(
        "concept_dictionary_detail.html",
        {"request": request, "concept": concept, "memos": memos},
    )


@app.get("/concept-memos", response_class=HTMLResponse)
def concept_memo_list(request: Request):
    conn = get_connection()
    memos = list_concept_memo(conn)
    conn.close()
    return templates.TemplateResponse(
        "concept_memo_list.html",
        {"request": request, "memos": memos},
    )


@app.get("/concept-memos/new", response_class=HTMLResponse)
def concept_memo_new(request: Request):
    return templates.TemplateResponse("concept_memo_new.html", {"request": request})


@app.post("/concept-memos/save")
def concept_memo_save(
    title: str = Form(""),
    content: str = Form(""),
):
    if not title.strip() or not content.strip():
        return RedirectResponse(url="/concept-memos/new", status_code=303)
    conn = get_connection()
    memo_id = create_concept_memo(conn, title.strip(), content.strip())
    conn.close()
    return RedirectResponse(url=f"/concept-memos/{memo_id}", status_code=303)


def _parse_extracted_json(raw: str) -> list:
    if not raw:
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


@app.get("/concept-memos/{memo_id}", response_class=HTMLResponse)
def concept_memo_detail(request: Request, memo_id: int):
    conn = get_connection()
    memo = get_concept_memo(conn, memo_id)
    if not memo:
        conn.close()
        return RedirectResponse(url="/concept-memos", status_code=303)
    links = list_links_by_source(conn, "concept_memo", memo_id)
    linked_concepts = []
    for link in links:
        concept = get_concept_dictionary(conn, link["target_id"])
        if concept:
            linked_concepts.append(concept)
    sessions = list_ai_sessions(conn, "concept_memo", memo_id)
    conn.close()
    extracted = _parse_extracted_json(memo["extracted_json"])
    return templates.TemplateResponse(
        "concept_memo_detail.html",
        {
            "request": request,
            "memo": memo,
            "summary": memo.get("summary", "") if memo else "",
            "extracted": extracted,
            "linked_concepts": linked_concepts,
            "sessions": sessions,
            "chat_log": "",
            "chat_answer": "",
        },
    )


@app.post("/concept-memos/{memo_id}/summarize")
def concept_memo_summarize(request: Request, memo_id: int):
    conn = get_connection()
    memo = get_concept_memo(conn, memo_id)
    if not memo:
        conn.close()
        return RedirectResponse(url="/concept-memos", status_code=303)
    summary = summarize_concept_memo(memo["title"], memo["content"])
    if summary:
        update_concept_memo(conn, memo_id, summary=summary)
    conn.close()
    return RedirectResponse(url=f"/concept-memos/{memo_id}", status_code=303)


@app.post("/concept-memos/{memo_id}/extract")
def concept_memo_extract(request: Request, memo_id: int):
    conn = get_connection()
    memo = get_concept_memo(conn, memo_id)
    if not memo:
        conn.close()
        return RedirectResponse(url="/concept-memos", status_code=303)
    extracted = extract_concepts_from_memo(memo["title"], memo["content"])
    if extracted:
        update_concept_memo(conn, memo_id, extracted=extracted)
    conn.close()
    return RedirectResponse(url=f"/concept-memos/{memo_id}", status_code=303)


@app.post("/concept-memos/{memo_id}/promote")
def concept_memo_promote(
    memo_id: int,
    concept_title: str = Form(""),
    concept_note: str = Form(""),
):
    conn = get_connection()
    memo = get_concept_memo(conn, memo_id)
    if not memo or not concept_title.strip():
        conn.close()
        return RedirectResponse(url=f"/concept-memos/{memo_id}", status_code=303)
    summary = memo.get("summary", "").strip()
    base_body = summary if summary else memo.get("content", "")
    body = base_body
    if concept_note.strip():
        body = f"{concept_note.strip()}\n\n---\n{base_body}"
    concept_id = create_concept_dictionary(conn, concept_title.strip(), body.strip())
    add_link(conn, "concept_memo", memo_id, "concept_dictionary", concept_id)
    conn.close()
    return RedirectResponse(url=f"/concepts/{concept_id}", status_code=303)


@app.post("/concept-memos/{memo_id}/chat", response_class=HTMLResponse)
async def concept_memo_chat(request: Request, memo_id: int):
    form = await request.form()
    question = form.get("chat_question", "")
    chat_log = form.get("chat_log", "")

    conn = get_connection()
    memo = get_concept_memo(conn, memo_id)
    links = list_links_by_source(conn, "concept_memo", memo_id)
    linked_concepts = []
    for link in links:
        concept = get_concept_dictionary(conn, link["target_id"])
        if concept:
            linked_concepts.append(concept)
    sessions = list_ai_sessions(conn, "concept_memo", memo_id)
    conn.close()
    if not memo:
        return RedirectResponse(url="/concept-memos", status_code=303)

    answer = generate_concept_chat_response(memo["title"], memo["content"], question) if question else ""
    if answer:
        entry_text = f"Q: {question}\nA: {answer}"
        chat_log = f"{chat_log}\n\n{entry_text}".strip() if chat_log else entry_text

    extracted = _parse_extracted_json(memo["extracted_json"])
    return templates.TemplateResponse(
        "concept_memo_detail.html",
        {
            "request": request,
            "memo": memo,
            "summary": memo.get("summary", ""),
            "extracted": extracted,
            "linked_concepts": linked_concepts,
            "sessions": sessions,
            "chat_log": chat_log,
            "chat_answer": answer,
        },
    )


@app.post("/concept-memos/{memo_id}/chat/save")
async def concept_memo_chat_save(request: Request, memo_id: int):
    form = await request.form()
    chat_log = form.get("chat_log", "")
    if chat_log:
        conn = get_connection()
        add_ai_session(conn, "concept_memo", memo_id, "log", chat_log)
        conn.close()
    return RedirectResponse(url=f"/concept-memos/{memo_id}", status_code=303)


@app.get("/daily", response_class=HTMLResponse)
def daily_hub(request: Request):
    conn = get_connection()
    memos = list_daily_memo(conn)
    conn.close()
    return templates.TemplateResponse(
        "daily_hub.html",
        {"request": request, "memos": memos, "chat_answer": ""},
    )


@app.post("/daily/chat", response_class=HTMLResponse)
def daily_chat(request: Request, question: str = Form("")):
    conn = get_connection()
    memos = list_daily_memo(conn)
    conn.close()
    answer = generate_chat_response("daily_memo", "default", question) if question else ""
    return templates.TemplateResponse(
        "daily_hub.html",
        {"request": request, "memos": memos, "chat_answer": answer},
    )


@app.post("/daily/save")
def daily_save(content: str = Form("")):
    if not content.strip():
        return RedirectResponse(url="/daily", status_code=303)
    conn = get_connection()
    create_daily_memo(conn, content.strip())
    conn.close()
    return RedirectResponse(url="/daily", status_code=303)
