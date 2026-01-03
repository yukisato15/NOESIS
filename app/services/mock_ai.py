import inspect
import json
import logging
import os
from dataclasses import dataclass
from typing import Any

import httpx
import openai
from openai import OpenAI

logger = logging.getLogger(__name__)
KANA_ALLOWED = set("ー・゛゜")


@dataclass
class DictionaryDraft:
    genre_candidates: list[str]
    tag_candidates: list[str]
    concepts: str
    definition: str
    example: str
    synonyms: str
    antonyms: str
    related: str
    reference_urls: str


@dataclass
class ReadingDraft:
    summary: str


@dataclass
class EnglishLexiconDraft:
    headword: str
    pronunciation: str
    definition_ja: str
    etymology_background: str
    synonyms: list
    antonyms: list
    examples: list
    phrases: list
    usage_note: str
    free_memo: str


def generate_dictionary(term: str, dictionary_type: str = "default", context: str = "") -> DictionaryDraft:
    # Use real AI if the API key is available; otherwise fall back safely.
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return fallback_dictionary(term, "api_key_missing")

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        # Older SDKs don't expose Responses API; avoid crashing and fall back safely.
        return fallback_dictionary(term, "responses_api_unavailable")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    schema = {
        "type": "object",
        "properties": {
            "genre": {"type": "string"},
            "tags": {"type": "array", "items": {"type": "string"}, "minItems": 5, "maxItems": 10},
            "definition": {"type": "string"},
            "example": {"type": "string"},
            "concepts": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": 3},
            "synonyms": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": 5},
            "antonyms": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": 5},
            "related": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": 5},
            "reference_urls": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": 3},
        },
        "required": [
            "genre",
            "tags",
            "definition",
            "example",
            "concepts",
            "synonyms",
            "antonyms",
            "related",
            "reference_urls",
        ],
        "additionalProperties": False,
    }
    response_format = {
        "type": "json_schema",
        "name": "dictionary_entry",
        "schema": schema,
        "strict": True,
    }
    text_config = {"format": response_format}
    system_prompt = build_system_prompt(dictionary_type)
    user_prompt = build_user_prompt(term, context, dictionary_type)
    try:
        if supports_text_format(client):
            response = client.responses.create(
                model=model,
                input=[
                    {"role": "system", "content": system_prompt},
                    {
                        "role": "user",
                        "content": user_prompt,
                    },
                ],
                temperature=0.3,
                text=text_config,
            )
            data = getattr(response, "output_parsed", None)
            if data is None:
                # Newer SDKs may store parsed data inside the output list.
                try:
                    data = response.output[0].content[0].parsed
                except (AttributeError, IndexError, TypeError):
                    data = None
            if data is None:
                data = parse_json_text(getattr(response, "output_text", None))
            ai_path = "sdk"
        else:
            response_json = responses_via_http(
                api_key=api_key,
                model=model,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                text_config=text_config,
            )
            data = extract_parsed_from_response(response_json)
            ai_path = "http"
        if not validate_schema(data, schema):
            logger.warning("[AI_SCHEMA_FAIL] parsed=%r", data)
            return fallback_dictionary(term, "schema_validation_failed")
        logger.info("[AI_USED] model=%s path=%s", model, ai_path)
        return DictionaryDraft(
            genre_candidates=[data["genre"]],
            tag_candidates=data["tags"],
            concepts=join_items(data["concepts"]),
            definition=data["definition"],
            example=data["example"],
            synonyms=join_items(data["synonyms"]),
            antonyms=join_items(data["antonyms"]),
            related=join_items(data["related"]),
            reference_urls=join_lines(data["reference_urls"]),
        )
    except Exception as exc:
        return fallback_dictionary(term, f"api_exception:{exc}")


def generate_english_entry(term: str, context: str = "") -> EnglishLexiconDraft:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=api_key_missing")
        raise RuntimeError("api_key_missing")

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=responses_api_unavailable")
        raise RuntimeError("responses_api_unavailable")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    schema = {
        "type": "object",
        "properties": {
            "headword": {"type": "string"},
            "pronunciation": {"type": "string"},
            "meaning_ja": {"type": "string"},
            "etymology_background": {"type": "string"},
            "synonyms": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "term_en": {"type": "string"},
                        "term_ja": {"type": "string"},
                        "note": {"type": "string"},
                    },
                    "required": ["term_en", "term_ja", "note"],
                    "additionalProperties": False,
                },
                "minItems": 1,
                "maxItems": 6,
            },
            "antonyms": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "term_en": {"type": "string"},
                        "term_ja": {"type": "string"},
                        "note": {"type": "string"},
                    },
                    "required": ["term_en", "term_ja", "note"],
                    "additionalProperties": False,
                },
                "minItems": 1,
                "maxItems": 6,
            },
            "examples": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "sentence_en": {"type": "string"},
                        "sentence_ja": {"type": "string"},
                    },
                    "required": ["sentence_en", "sentence_ja"],
                    "additionalProperties": False,
                },
                "minItems": 1,
                "maxItems": 5,
            },
            "phrases": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "phrase_en": {"type": "string"},
                        "phrase_ja": {"type": "string"},
                        "note": {"type": "string"},
                    },
                    "required": ["phrase_en", "phrase_ja", "note"],
                    "additionalProperties": False,
                },
                "minItems": 1,
                "maxItems": 5,
            },
            "usage_note": {"type": "string"},
            "free_memo": {"type": "string"},
        },
        "required": [
            "headword",
            "pronunciation",
            "meaning_ja",
            "etymology_background",
            "synonyms",
            "antonyms",
            "examples",
            "phrases",
            "usage_note",
            "free_memo",
        ],
        "additionalProperties": False,
    }
    response_format = {
        "type": "json_schema",
        "name": "english_lexicon",
        "schema": schema,
        "strict": True,
    }
    text_config = {"format": response_format}
    system_prompt = (
        "You are a lexical knowledge base assistant for English entries. "
        "Output must be pure JSON only. "
        "No code blocks, no markdown, no extra text, no comments, no explanations. "
        "The first character must be '{' and the last character must be '}'. "
        "Output must contain only the keys: headword, pronunciation, meaning_ja, etymology_background, "
        "synonyms, antonyms, examples, phrases, usage_note, free_memo. "
        "Do not output any additional keys. "
        "Use a normal dictionary tone (no chatty or teaching tone). "
        "meaning_ja must be a natural Japanese description without over-assertion. "
        "Pronunciation must be written as phonetic symbols (IPA) but do not use the letters 'IPA' in the output. "
        "synonyms/antonyms must be arrays with at least 1 item. "
        "examples must be 1-5 items. "
        "phrases must be 1-5 items. "
        "All note fields must be strings (empty string allowed). "
        "Etymology_background must include: origin, why the current meaning emerged, and a point people often misread. "
        "Usage_note must be a short dictionary-style note on usage and contrasts without teaching tone. "
        "free_memo must be an empty string. "
        "Do not use generic template sentences such as 'refers to a concept' or 'commonly used in context'. "
        "Do not use quizzes or teaching tone."
    )
    user_prompt = build_user_prompt(term, context, "english")
    try:
        if supports_text_format(client):
            response = client.responses.create(
                model=model,
                input=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3,
                text=text_config,
            )
            data = getattr(response, "output_parsed", None)
            if data is None:
                try:
                    data = response.output[0].content[0].parsed
                except (AttributeError, IndexError, TypeError):
                    data = None
            if data is None:
                data = parse_json_text(getattr(response, "output_text", None))
        else:
            response_json = responses_via_http(
                api_key=api_key,
                model=model,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                text_config=text_config,
            )
            data = extract_parsed_from_response(response_json)
        ok, errors = validate_english_schema(data)
        if not ok:
            logger.warning("[AI_SCHEMA_FAIL] parsed=%r", data)
            logger.warning("[AI_SCHEMA_FAIL] errors=%s", "; ".join(errors))
            logger.warning("[AI_FALLBACK] reason=schema_validation_failed")
            raise RuntimeError("schema_validation_failed")
        logger.info("[AI_USED] model=%s path=english", model)
        return EnglishLexiconDraft(
            headword=data["headword"],
            pronunciation=data["pronunciation"],
            definition_ja=data["meaning_ja"],
            etymology_background=data["etymology_background"],
            synonyms=data["synonyms"],
            antonyms=data["antonyms"],
            examples=data["examples"],
            phrases=data["phrases"],
            usage_note=data["usage_note"],
            free_memo=data["free_memo"],
        )
    except Exception as exc:
        logger.exception("[AI_FALLBACK] reason=api_exception")
        raise


def generate_reading(headword: str, dictionary_type: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=reading_api_key_missing")
        return headword

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=reading_responses_api_unavailable")
        return headword

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    schema = {
        "type": "object",
        "properties": {"reading": {"type": "string"}},
        "required": ["reading"],
        "additionalProperties": False,
    }
    response_format = {
        "type": "json_schema",
        "name": "reading_only",
        "schema": schema,
        "strict": True,
    }
    text_config = {"format": response_format}
    system_prompt = (
        "Output must be pure JSON only. "
        "No code blocks, no markdown, no extra text, no comments, no explanations. "
        "The first character must be '{' and the last character must be '}'. "
        "Output must contain only the key: reading. "
        "The reading must be in Katakana or Hiragana only. "
        "Do not use IPA, romaji, or alphabet letters. "
        "If dictionary_type is 'it', use common Japanese reading; abbreviations should be spelled out in kana. "
        "If dictionary_type is 'english', use the common Japanese reading in katakana. "
        "If dictionary_type is 'default', use katakana as a rule. "
        "Do not add any explanation."
    )
    user_prompt = f"headword: {headword}\ndictionary_type: {dictionary_type}"
    try:
        if supports_text_format(client):
            response = client.responses.create(
                model=model,
                input=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.1,
                text=text_config,
            )
            data = getattr(response, "output_parsed", None)
            if data is None:
                try:
                    data = response.output[0].content[0].parsed
                except (AttributeError, IndexError, TypeError):
                    data = None
            if data is None:
                data = parse_json_text(getattr(response, "output_text", None))
        else:
            response_json = responses_via_http(
                api_key=api_key,
                model=model,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                text_config=text_config,
            )
            data = extract_parsed_from_response(response_json)
        reading = data.get("reading") if isinstance(data, dict) else ""
        if not isinstance(reading, str) or not reading.strip() or not is_kana_text(reading):
            logger.warning("[AI_FALLBACK] reason=reading_invalid")
            return headword
        logger.info("[AI_USED] model=%s path=reading", model)
        return reading.strip()
    except Exception:
        logger.exception("[AI_FALLBACK] reason=reading_api_exception")
        return headword


def generate_chat_response(term: str, dictionary_type: str, question: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=chat_api_key_missing")
        return ""

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=chat_responses_api_unavailable")
        return ""

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    system_prompt = (
        "You are a concise knowledge assistant for a personal lexical knowledge base. "
        "Answer in Japanese, dictionary-style, not chatty, not teaching. "
        "Focus on clarifying context, background, and structure. "
        "Do not add quizzes or evaluations."
    )
    user_prompt = f"headword: {term}\ndictionary_type: {dictionary_type}\nquestion: {question}"
    try:
        response = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.3,
        )
        text = getattr(response, "output_text", "")
        if not isinstance(text, str) or not text.strip():
            logger.warning("[AI_FALLBACK] reason=chat_empty_response")
            return ""
        logger.info("[AI_USED] model=%s path=chat", model)
        return text.strip()
    except Exception:
        logger.exception("[AI_FALLBACK] reason=chat_api_exception")
        return ""


def summarize_chat_log(chat_log: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=summary_api_key_missing")
        return ""

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=summary_responses_api_unavailable")
        return ""

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    system_prompt = (
        "Summarize the chat log in Japanese. "
        "Return 3-6 short bullet points. "
        "No teaching tone."
    )
    user_prompt = f"chat_log:\n{chat_log}"
    try:
        response = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.2,
        )
        text = getattr(response, "output_text", "")
        if not isinstance(text, str) or not text.strip():
            logger.warning("[AI_FALLBACK] reason=summary_empty_response")
            return ""
        logger.info("[AI_USED] model=%s path=summary", model)
        return text.strip()
    except Exception:
        logger.exception("[AI_FALLBACK] reason=summary_api_exception")
        return ""


def generate_concept_chat_response(title: str, content: str, question: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=concept_chat_api_key_missing")
        return ""

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=concept_chat_responses_api_unavailable")
        return ""

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    system_prompt = (
        "You are a philosophical dialogue assistant for a personal thinking archive. "
        "Respond in Japanese, dictionary-like, reflective, and non-teaching. "
        "Do not conclude too quickly; ask clarifying points when appropriate. "
        "Avoid evaluative or corrective tone."
    )
    user_prompt = f"title: {title}\ncontent: {content}\nquestion: {question}"
    try:
        response = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.4,
        )
        text = getattr(response, "output_text", "")
        if not isinstance(text, str) or not text.strip():
            logger.warning("[AI_FALLBACK] reason=concept_chat_empty_response")
            return ""
        logger.info("[AI_USED] model=%s path=concept_chat", model)
        return text.strip()
    except Exception:
        logger.exception("[AI_FALLBACK] reason=concept_chat_api_exception")
        return ""


def summarize_concept_memo(title: str, content: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=concept_summary_api_key_missing")
        return ""

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=concept_summary_responses_api_unavailable")
        return ""

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    system_prompt = (
        "Summarize the memo in Japanese with 3-6 short bullet points. "
        "Keep a neutral, reflective tone. "
        "Do not teach or evaluate."
    )
    user_prompt = f"title: {title}\ncontent:\n{content}"
    try:
        response = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.2,
        )
        text = getattr(response, "output_text", "")
        if not isinstance(text, str) or not text.strip():
            logger.warning("[AI_FALLBACK] reason=concept_summary_empty_response")
            return ""
        logger.info("[AI_USED] model=%s path=concept_summary", model)
        return text.strip()
    except Exception:
        logger.exception("[AI_FALLBACK] reason=concept_summary_api_exception")
        return ""


def extract_concepts_from_memo(title: str, content: str) -> list:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.warning("[AI_FALLBACK] reason=concept_extract_api_key_missing")
        return []

    client = OpenAI(api_key=api_key)
    if not hasattr(client, "responses"):
        logger.warning("[AI_FALLBACK] reason=concept_extract_responses_api_unavailable")
        return []

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    system_prompt = (
        "Return only JSON. No code blocks, no extra text. "
        "Output schema: {\"concepts\": [{\"title\": \"...\", \"note\": \"...\"}]}. "
        "Titles should be concise concept labels. "
        "Notes should explain why the concept matters in this memo. "
        "Keep 3-6 concepts at most."
    )
    user_prompt = f"title: {title}\ncontent:\n{content}"
    try:
        response = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.3,
        )
        text = getattr(response, "output_text", "")
        data = parse_json_text(text)
        concepts = data.get("concepts") if isinstance(data, dict) else None
        if not isinstance(concepts, list):
            logger.warning("[AI_FALLBACK] reason=concept_extract_invalid_json")
            return []
        cleaned = []
        for item in concepts:
            if not isinstance(item, dict):
                continue
            title_value = str(item.get("title", "")).strip()
            note_value = str(item.get("note", "")).strip()
            if not title_value:
                continue
            cleaned.append({"title": title_value, "note": note_value})
        if not cleaned:
            logger.warning("[AI_FALLBACK] reason=concept_extract_empty")
            return []
        logger.info("[AI_USED] model=%s path=concept_extract", model)
        return cleaned
    except Exception:
        logger.exception("[AI_FALLBACK] reason=concept_extract_api_exception")
        return []


def validate_schema(data: Any, schema: dict) -> bool:
    if not isinstance(data, dict):
        return False
    for key in schema["required"]:
        if key not in data:
            return False
    if not isinstance(data.get("genre"), str):
        return False
    if not isinstance(data.get("tags"), list) or not all(isinstance(t, str) for t in data["tags"]):
        return False
    if not isinstance(data.get("definition"), str):
        return False
    if not isinstance(data.get("example"), str):
        return False
    if not is_non_empty_list(data.get("concepts")):
        return False
    if not is_non_empty_list(data.get("synonyms")):
        return False
    if not is_non_empty_list(data.get("antonyms")):
        return False
    if not is_non_empty_list(data.get("related")):
        return False
    if not is_non_empty_list(data.get("reference_urls")):
        return False
    if not (5 <= len(data["tags"]) <= 10):
        return False
    if not (1 <= len(data["concepts"]) <= 3):
        return False
    if not is_unique_list(data["tags"]):
        return False
    if not is_unique_list(data["concepts"]):
        return False
    if not is_unique_list(data["synonyms"]):
        return False
    if not is_unique_list(data["antonyms"]):
        return False
    if not is_unique_list(data["related"]):
        return False
    if not is_unique_list(data["reference_urls"]):
        return False
    if len(data["synonyms"]) > 5 or len(data["antonyms"]) > 5 or len(data["related"]) > 5:
        return False
    if len(data["reference_urls"]) > 3:
        return False
    return True


def validate_english_schema(data: Any) -> tuple[bool, list[str]]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return False, ["data is not an object"]

    required = [
        "headword",
        "pronunciation",
        "meaning_ja",
        "etymology_background",
        "synonyms",
        "antonyms",
        "examples",
        "phrases",
        "usage_note",
        "free_memo",
    ]
    for key in required:
        if key not in data:
            errors.append(f"missing:{key}")

    for key in ("synonyms", "antonyms", "examples", "phrases"):
        if not isinstance(data.get(key), list):
            errors.append(f"{key}:not_array")
        elif len(data.get(key, [])) < 1:
            errors.append(f"{key}:empty_list")

    list_ranges = {
        "synonyms": (1, 6),
        "antonyms": (1, 6),
        "examples": (1, 5),
        "phrases": (1, 5),
    }
    for key, (min_len, max_len) in list_ranges.items():
        if isinstance(data.get(key), list):
            length = len(data.get(key, []))
            if length < min_len or length > max_len:
                errors.append(f"{key}:length_out_of_range")

    for key in ("headword", "pronunciation", "meaning_ja", "etymology_background", "usage_note"):
        if not isinstance(data.get(key), str) or not data.get(key).strip():
            errors.append(f"{key}:empty")

    if not isinstance(data.get("free_memo"), str):
        errors.append("free_memo:not_string")
    elif data.get("free_memo") != "":
        errors.append("free_memo:not_empty")

    for key in ("synonyms", "antonyms"):
        for idx, item in enumerate(data.get(key, [])):
            if not isinstance(item, dict):
                errors.append(f"{key}[{idx}]:not_object")
                continue
            if not item.get("term_en"):
                errors.append(f"{key}[{idx}].term_en:empty")
            if not item.get("term_ja"):
                errors.append(f"{key}[{idx}].term_ja:empty")
            if "note" not in item:
                errors.append(f"{key}[{idx}].note:missing")
            elif not isinstance(item.get("note"), str):
                errors.append(f"{key}[{idx}].note:not_string")

    for key in ("examples",):
        for idx, item in enumerate(data.get(key, [])):
            if not isinstance(item, dict):
                errors.append(f"{key}[{idx}]:not_object")
                continue
            if not item.get("sentence_en"):
                errors.append(f"{key}[{idx}].sentence_en:empty")
            if not item.get("sentence_ja"):
                errors.append(f"{key}[{idx}].sentence_ja:empty")

    for key in ("phrases",):
        for idx, item in enumerate(data.get(key, [])):
            if not isinstance(item, dict):
                errors.append(f"{key}[{idx}]:not_object")
                continue
            if not item.get("phrase_en"):
                errors.append(f"{key}[{idx}].phrase_en:empty")
            if not item.get("phrase_ja"):
                errors.append(f"{key}[{idx}].phrase_ja:empty")
            if "note" not in item:
                errors.append(f"{key}[{idx}].note:missing")
            elif not isinstance(item.get("note"), str):
                errors.append(f"{key}[{idx}].note:not_string")

    return len(errors) == 0, errors


def fallback_dictionary(term: str, reason: str) -> DictionaryDraft:
    # Fallback keeps the UI editable and the app running.
    logger.warning("[AI_FALLBACK] reason=%s", reason)
    return DictionaryDraft(
        genre_candidates=["未分類"],
        tag_candidates=["タグ未設定"],
        concepts="",
        definition=f"{term}の定義（フォールバック）",
        example="例文を編集してください。",
        synonyms="",
        antonyms="",
        related="",
        reference_urls="",
    )


def empty_english_draft(term: str) -> EnglishLexiconDraft:
    return EnglishLexiconDraft(
        headword=term,
        pronunciation="",
        definition_ja="",
        etymology_background="",
        synonyms=[],
        antonyms=[],
        examples=[],
        phrases=[],
        usage_note="",
        free_memo="",
    )


def supports_text_format(client: OpenAI) -> bool:
    try:
        signature = inspect.signature(client.responses.create)
    except (TypeError, ValueError):
        return False
    return "text" in signature.parameters


def responses_via_http(
    api_key: str,
    model: str,
    system_prompt: str,
    user_prompt: str,
    text_config: dict,
) -> dict:
    payload = {
        "model": model,
        "input": [
            {
                "role": "system",
                "content": [{"type": "input_text", "text": system_prompt}],
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": user_prompt,
                    }
                ],
            },
        ],
        "temperature": 0.3,
        "text": text_config,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    with httpx.Client(timeout=30.0) as client:
        response = client.post("https://api.openai.com/v1/responses", json=payload, headers=headers)
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError:
            # Log the response body for debugging while keeping fallback behavior.
            logger.warning("dictionary AI HTTP error: %s", response.text)
            raise
        return response.json()


def extract_parsed_from_response(response_json: dict) -> Any:
    if isinstance(response_json, dict) and isinstance(response_json.get("output_parsed"), dict):
        return response_json["output_parsed"]
    output_text = response_json.get("output_text") if isinstance(response_json, dict) else None
    parsed = parse_json_text(output_text)
    if parsed is not None:
        return parsed
    output = response_json.get("output") if isinstance(response_json, dict) else None
    if not isinstance(output, list):
        return None
    for item in output:
        content = item.get("content") if isinstance(item, dict) else None
        if not isinstance(content, list):
            continue
        for part in content:
            if not isinstance(part, dict):
                continue
            if "parsed" in part:
                return part["parsed"]
            if "json" in part:
                return part["json"]
    return None


def build_system_prompt(dictionary_type: str) -> str:
    base = (
        "You are a dictionary assistant. "
        "Output must be pure JSON only. "
        "No code blocks, no markdown, no extra text, no comments, no explanations. "
        "The first character must be '{' and the last character must be '}'. "
        "Output must contain only the keys: genre, tags, definition, example, concepts, synonyms, antonyms, related, reference_urls. "
        "Do not output any additional keys. "
        "Use Japanese. "
        "Definition must be 100-200 Japanese characters. "
        "Example must be 1-2 sentences. "
        "Concepts must be 1-3 items, unique, non-empty strings. "
        "Concepts must be structural ideas that can explain other terms. "
        "If uncertain, use tags instead of concepts. "
        "Tags must be 5-10 items, unique, non-empty strings, and not too similar in meaning. "
        "Do not put near-duplicate tags; move close terms into synonyms or related. "
        "Synonyms, antonyms, related must be 1-5 items, unique, non-empty strings. "
        "Reference_urls must be 1-3 items, official or primary sources preferred. "
        "Genre must be a non-empty string. "
        "Genre is a high-level category like 'programming/backend'. "
        "Tags are cross-search keywords. "
        "For software/technical terms, prefer professional terminology. "
        "Tags should be semantically distinct and at different abstraction levels."
    )
    if dictionary_type == "it":
        return (
            base
            + " This is an IT glossary entry. "
            "If input looks like code/config/syntax, explain meaning and usage context. "
            "If input is a term, include typical usage context and related technologies."
        )
    if dictionary_type == "english":
        return (
            base
            + " This is an English dictionary entry. "
            "Definition must include nuance and typical usage scene in Japanese. "
            "Example should include an English sentence and its Japanese translation. "
            "For the definition field, output a full lexical entry in the following order and labels: "
            "1. 見出し語 (headword), "
            "2. 発音 (ipa, katakana, tts_text, audio_url), "
            "3. 品詞 (part_of_speech), "
            "4. 可算性 (countability), "
            "5. 使用レジスター (register), "
            "6. 定義（英語） (definition_en), "
            "7. 定義（日本語） (definition_ja), "
            "8. 語源 (etymology), "
            "9. 概念メモ（語源的背景） (concept_memo), "
            "10. 類義語 (synonyms), "
            "11. 対立概念 (antonyms), "
            "12. 関連語 (related_terms). "
            "Do not add extra keys outside the JSON schema."
        )
    return base


def build_user_prompt(term: str, context: str, dictionary_type: str) -> str:
    lines = [
        f"term: {term}",
        "definition_length: 100-200 Japanese characters",
    ]
    if context:
        lines.append(f"context: {context}")
    if dictionary_type:
        lines.append(f"dictionary_type: {dictionary_type}")
    return "\n".join(lines)


def parse_json_text(text: Any) -> Any:
    if not isinstance(text, str) or not text.strip():
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        extracted = extract_first_json(text)
        if extracted:
            try:
                return json.loads(extracted)
            except json.JSONDecodeError:
                logger.warning("[AI_SCHEMA_FAIL] raw=%r", text)
                return None
        logger.warning("[AI_SCHEMA_FAIL] raw=%r", text)
        return None


def is_non_empty_list(value: Any) -> bool:
    return isinstance(value, list) and value and all(isinstance(item, str) and item.strip() for item in value)


def is_unique_list(items: Any) -> bool:
    if not isinstance(items, list):
        return False
    normalized = [item.strip() for item in items if isinstance(item, str)]
    return len(normalized) == len(set(normalized))


def join_items(items: Any) -> str:
    if not isinstance(items, list):
        return ""
    return ", ".join(item.strip() for item in items if isinstance(item, str) and item.strip())


def join_lines(items: Any) -> str:
    if not isinstance(items, list):
        return ""
    return "\n".join(item.strip() for item in items if isinstance(item, str) and item.strip())


def extract_first_json(text: str) -> str | None:
    depth = 0
    start = None
    for idx, ch in enumerate(text):
        if ch == "{":
            if start is None:
                start = idx
            depth += 1
        elif ch == "}":
            if start is not None:
                depth -= 1
                if depth == 0:
                    return text[start : idx + 1]
    return None


def is_kana_text(text: str) -> bool:
    if not isinstance(text, str):
        return False
    for ch in text:
        if ch in KANA_ALLOWED:
            continue
        code = ord(ch)
        if 0x3040 <= code <= 0x309F:
            continue
        if 0x30A0 <= code <= 0x30FF:
            continue
        return False
    return bool(text.strip())


def generate_reading_summary(title: str, chapter: str, memo: str) -> ReadingDraft:
    summary = f"{title} {chapter} の要約（モック）"
    if memo:
        summary = f"{summary}：{memo[:40]}..."
    return ReadingDraft(summary=summary)
