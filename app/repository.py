import json
from typing import Iterable, Optional

from .db import fetchall_dict, fetchone_dict


def create_entry(
    conn,
    entry_type: str,
    title: str,
    body: str,
    genre: Optional[str] = None,
    book_id: Optional[int] = None,
    domain: str = "general",
    field: str = "unspecified",
    concept: Optional[str] = None,
    reading: Optional[str] = None,
    language: str = "ja",
    reading_source: str = "manual",
) -> int:
    cursor = conn.execute(
        """
        INSERT INTO entry (
            type,
            title,
            body,
            genre,
            book_id,
            domain,
            field,
            concept,
            reading,
            language,
            reading_source,
            created_at,
            updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        """,
        (
            entry_type,
            title,
            body,
            genre,
            book_id,
            domain,
            field,
            concept,
            reading or title,
            language,
            reading_source,
        ),
    )
    conn.commit()
    return int(cursor.lastrowid)


def update_entry(
    conn,
    entry_id: int,
    title: str,
    body: str,
    genre: Optional[str] = None,
    book_id: Optional[int] = None,
    domain: Optional[str] = None,
    field: Optional[str] = None,
    concept: Optional[str] = None,
    reading: Optional[str] = None,
    language: Optional[str] = None,
    reading_source: Optional[str] = None,
) -> None:
    fields = ["title = ?", "body = ?", "updated_at = datetime('now')"]
    params = [title, body]
    if genre is not None:
        fields.append("genre = ?")
        params.append(genre)
    if book_id is not None:
        fields.append("book_id = ?")
        params.append(book_id)
    if domain is not None:
        fields.append("domain = ?")
        params.append(domain)
    if field is not None:
        fields.append("field = ?")
        params.append(field)
    if concept is not None:
        fields.append("concept = ?")
        params.append(concept)
    if reading is not None:
        fields.append("reading = ?")
        params.append(reading)
    if language is not None:
        fields.append("language = ?")
        params.append(language)
    if reading_source is not None:
        fields.append("reading_source = ?")
        params.append(reading_source)
    params.append(entry_id)
    # Build SQL dynamically to avoid clobbering unset optional fields.
    conn.execute(
        f"""
        UPDATE entry
        SET {", ".join(fields)}
        WHERE id = ?
        """,
        params,
    )
    conn.commit()


def delete_entry(conn, entry_id: int) -> None:
    conn.execute("DELETE FROM entry WHERE id = ?", (entry_id,))
    conn.commit()


def add_tags(conn, entry_id: int, tags: Iterable[str]) -> None:
    for tag in tags:
        if not tag:
            continue
        cursor = conn.execute("SELECT id FROM tag WHERE name = ?", (tag,))
        row = cursor.fetchone()
        if row:
            tag_id = row[0]
        else:
            tag_cursor = conn.execute("INSERT INTO tag (name) VALUES (?)", (tag,))
            tag_id = tag_cursor.lastrowid
        conn.execute(
            "INSERT OR IGNORE INTO entry_tag (entry_id, tag_id) VALUES (?, ?)",
            (entry_id, tag_id),
        )
    conn.commit()


def replace_tags(conn, entry_id: int, tags: Iterable[str]) -> None:
    conn.execute("DELETE FROM entry_tag WHERE entry_id = ?", (entry_id,))
    conn.commit()
    add_tags(conn, entry_id, tags)


def add_sources(conn, entry_id: int, sources: Iterable[dict]) -> None:
    for source in sources:
        if not any(source.values()):
            continue
        cursor = conn.execute(
            "INSERT INTO source (url, title, note) VALUES (?, ?, ?)",
            (source.get("url"), source.get("title"), source.get("note")),
        )
        source_id = cursor.lastrowid
        conn.execute(
            "INSERT INTO entry_source (entry_id, source_id) VALUES (?, ?)",
            (entry_id, source_id),
        )
    conn.commit()


def replace_sources(conn, entry_id: int, sources: Iterable[dict]) -> None:
    cursor = conn.execute("SELECT source_id FROM entry_source WHERE entry_id = ?", (entry_id,))
    source_ids = [row[0] for row in cursor.fetchall()]
    conn.execute("DELETE FROM entry_source WHERE entry_id = ?", (entry_id,))
    if source_ids:
        placeholders = ",".join(["?"] * len(source_ids))
        conn.execute(f"DELETE FROM source WHERE id IN ({placeholders})", source_ids)
    conn.commit()
    add_sources(conn, entry_id, sources)


def add_quotes(conn, entry_id: int, quotes: Iterable[dict]) -> None:
    for quote in quotes:
        if not quote.get("quote_text"):
            continue
        conn.execute(
            """
            INSERT INTO quote (entry_id, quote_text, page_or_loc, note)
            VALUES (?, ?, ?, ?)
            """,
            (entry_id, quote.get("quote_text"), quote.get("page_or_loc"), quote.get("note")),
        )
    conn.commit()


def replace_quotes(conn, entry_id: int, quotes: Iterable[dict]) -> None:
    conn.execute("DELETE FROM quote WHERE entry_id = ?", (entry_id,))
    conn.commit()
    add_quotes(conn, entry_id, quotes)


def get_entry(conn, entry_id: int) -> Optional[dict]:
    cursor = conn.execute("SELECT * FROM entry WHERE id = ?", (entry_id,))
    return fetchone_dict(cursor)


def get_entry_tags(conn, entry_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT t.name
        FROM tag t
        JOIN entry_tag et ON et.tag_id = t.id
        WHERE et.entry_id = ?
        ORDER BY t.name
        """,
        (entry_id,),
    )
    return [row[0] for row in cursor.fetchall()]


def get_entry_sources(conn, entry_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT s.*
        FROM source s
        JOIN entry_source es ON es.source_id = s.id
        WHERE es.entry_id = ?
        ORDER BY s.id
        """,
        (entry_id,),
    )
    return fetchall_dict(cursor)


def get_entry_quotes(conn, entry_id: int) -> list:
    cursor = conn.execute(
        "SELECT * FROM quote WHERE entry_id = ? ORDER BY id",
        (entry_id,),
    )
    return fetchall_dict(cursor)


def list_tags(conn) -> list:
    cursor = conn.execute("SELECT name FROM tag ORDER BY name")
    return [row[0] for row in cursor.fetchall()]


def add_entry_appendix(conn, entry_id: int, appendix_type: str, content: str) -> None:
    if not content:
        return
    conn.execute(
        """
        INSERT INTO entry_appendix (entry_id, type, content)
        VALUES (?, ?, ?)
        """,
        (entry_id, appendix_type, content),
    )
    conn.commit()


def list_entry_appendix(conn, entry_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT * FROM entry_appendix
        WHERE entry_id = ?
        ORDER BY created_at DESC, id DESC
        """,
        (entry_id,),
    )
    return fetchall_dict(cursor)


def add_book_appendix(conn, book_id: int, appendix_type: str, content: str) -> None:
    if not content:
        return
    conn.execute(
        """
        INSERT INTO book_appendix (book_id, type, content)
        VALUES (?, ?, ?)
        """,
        (book_id, appendix_type, content),
    )
    conn.commit()


def list_book_appendix(conn, book_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT * FROM book_appendix
        WHERE book_id = ?
        ORDER BY created_at DESC, id DESC
        """,
        (book_id,),
    )
    return fetchall_dict(cursor)


def list_reading_reflections(conn) -> list:
    cursor = conn.execute(
        """
        SELECT r.*, b.title, b.author, b.isbn
        FROM reading_reflection r
        JOIN book b ON b.id = r.book_id
        ORDER BY r.created_at DESC
        """
    )
    return fetchall_dict(cursor)


def get_reading_reflection(conn, reflection_id: int) -> Optional[dict]:
    cursor = conn.execute(
        """
        SELECT r.*, b.title, b.author, b.isbn
        FROM reading_reflection r
        JOIN book b ON b.id = r.book_id
        WHERE r.id = ?
        """,
        (reflection_id,),
    )
    return fetchone_dict(cursor)


def update_book_overview(conn, book_id: int, overview: str) -> int:
    cursor = conn.execute(
        """
        UPDATE book
        SET overview = ?,
            updated_at = datetime('now')
        WHERE id = ?
        """,
        (overview, book_id),
    )
    conn.commit()
    return int(book_id if cursor.rowcount else 0)


def get_book(conn, book_id: int) -> Optional[dict]:
    cursor = conn.execute("SELECT * FROM book WHERE id = ?", (book_id,))
    return fetchone_dict(cursor)


def get_or_create_book(conn, title: str, author: str, isbn: str) -> int:
    cursor = conn.execute("SELECT * FROM book WHERE title = ?", (title,))
    row = cursor.fetchone()
    if row:
        book_id = row["id"]
        updates = {}
        if author and not row["author"]:
            updates["author"] = author
        if isbn and not row["isbn"]:
            updates["isbn"] = isbn
        if updates:
            conn.execute(
                """
                UPDATE book
                SET author = COALESCE(?, author),
                    isbn = COALESCE(?, isbn),
                    updated_at = datetime('now')
                WHERE id = ?
                """,
                (updates.get("author"), updates.get("isbn"), book_id),
            )
            conn.commit()
        return int(book_id)
    cursor = conn.execute(
        "INSERT INTO book (title, author, isbn) VALUES (?, ?, ?)",
        (title, author, isbn),
    )
    conn.commit()
    return int(cursor.lastrowid)


def get_books_with_counts(conn) -> list:
    cursor = conn.execute(
        """
        SELECT b.id,
               b.title,
               b.author,
               b.isbn,
               b.overview,
               (SELECT COUNT(*) FROM reading_memo m WHERE m.book_id = b.id) AS memo_count,
               (SELECT COUNT(*) FROM reading_reflection r WHERE r.book_id = b.id) AS reflection_count,
               MAX(
                   COALESCE(
                       (SELECT MAX(m.created_at) FROM reading_memo m WHERE m.book_id = b.id),
                       (SELECT MAX(r.created_at) FROM reading_reflection r WHERE r.book_id = b.id),
                       b.updated_at
                   )
               ) AS last_updated
        FROM book b
        GROUP BY b.id
        ORDER BY last_updated DESC, b.title
        """
    )
    return fetchall_dict(cursor)


def get_reading_notes_by_book(conn, book_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM reading_memo
        WHERE book_id = ?
        ORDER BY created_at DESC
        """,
        (book_id,),
    )
    return fetchall_dict(cursor)


def get_reading_reflections_by_book(conn, book_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM reading_reflection
        WHERE book_id = ?
        ORDER BY created_at DESC
        """,
        (book_id,),
    )
    return fetchall_dict(cursor)


def create_reading_memo(conn, book_id: int, content: str) -> int:
    cursor = conn.execute(
        """
        INSERT INTO reading_memo (book_id, content)
        VALUES (?, ?)
        """,
        (book_id, content),
    )
    conn.commit()
    return int(cursor.lastrowid)


def create_reading_reflection(conn, book_id: int, content: str) -> int:
    cursor = conn.execute(
        """
        INSERT INTO reading_reflection (book_id, content)
        VALUES (?, ?)
        """,
        (book_id, content),
    )
    conn.commit()
    return int(cursor.lastrowid)


def create_english_lexicon(conn, entry_id: int, data: dict) -> None:
    conn.execute(
        """
        INSERT INTO english_lexicon (
            entry_id,
            headword,
            language,
            ipa,
            reading_kana,
            pronunciation_note,
            part_of_speech,
            countability,
            definition_en,
            definition_ja,
            synonyms_json,
            antonyms_json,
            related_terms_json,
            examples_json,
            phrases_json,
            register,
            etymology,
            usage_note,
            concept_memo,
            audio_tts_text,
            audio_url,
            audio_note
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            entry_id,
            data.get("headword", ""),
            data.get("language", "en"),
            data.get("ipa", ""),
            data.get("reading_kana", ""),
            data.get("pronunciation_note", ""),
            data.get("part_of_speech", ""),
            data.get("countability", ""),
            data.get("definition_en", ""),
            data.get("definition_ja", ""),
            json.dumps(data.get("synonyms", []), ensure_ascii=False),
            json.dumps(data.get("antonyms", []), ensure_ascii=False),
            json.dumps(data.get("related_terms", []), ensure_ascii=False),
            json.dumps(data.get("examples", []), ensure_ascii=False),
            json.dumps(data.get("phrases", []), ensure_ascii=False),
            data.get("register", ""),
            data.get("etymology", ""),
            data.get("usage_note", ""),
            data.get("concept_memo", ""),
            data.get("audio_tts_text", ""),
            data.get("audio_url", ""),
            data.get("audio_note", ""),
        ),
    )
    conn.commit()


def get_english_lexicon(conn, entry_id: int) -> Optional[dict]:
    cursor = conn.execute("SELECT * FROM english_lexicon WHERE entry_id = ?", (entry_id,))
    row = fetchone_dict(cursor)
    if not row:
        return None
    for key in ("synonyms_json", "antonyms_json", "related_terms_json", "examples_json", "phrases_json"):
        try:
            row[key] = json.loads(row.get(key) or "[]")
        except json.JSONDecodeError:
            row[key] = []
    return row


def list_dictionary_entries(conn, domain: str, field: Optional[str]) -> list:
    params = [domain]
    field_clause = ""
    if field:
        field_clause = "AND field = ?"
        params.append(field)
    cursor = conn.execute(
        f"""
        SELECT id, title, reading, field
        FROM entry
        WHERE type = 'dictionary'
          AND domain = ?
          {field_clause}
          AND reading != ''
        """,
        params,
    )
    return fetchall_dict(cursor)


def search_entries(
    conn,
    query: str,
    entry_type: Optional[str],
    tag: Optional[str],
    date_from: Optional[str],
    date_to: Optional[str],
) -> list:
    params = []
    conditions = []

    if query:
        conditions.append(
            """
            e.id IN (
                SELECT rowid FROM entry_fts WHERE entry_fts MATCH ?
            )
            OR e.id IN (
                SELECT q.entry_id
                FROM quote q
                JOIN quote_fts ON quote_fts.rowid = q.id
                WHERE quote_fts MATCH ?
            )
            """
        )
        params.extend([query, query])

    if entry_type:
        conditions.append("e.type = ?")
        params.append(entry_type)

    if tag:
        conditions.append(
            """
            e.id IN (
                SELECT et.entry_id
                FROM entry_tag et
                JOIN tag t ON t.id = et.tag_id
                WHERE t.name = ?
            )
            """
        )
        params.append(tag)

    if date_from:
        conditions.append("date(e.created_at) >= date(?)")
        params.append(date_from)
    if date_to:
        conditions.append("date(e.created_at) <= date(?)")
        params.append(date_to)

    where_clause = ""
    if conditions:
        where_clause = "WHERE " + " AND ".join(f"({c})" for c in conditions)

    cursor = conn.execute(
        f"""
        SELECT e.*
        FROM entry e
        {where_clause}
        ORDER BY e.updated_at DESC
        LIMIT 50
        """,
        params,
    )
    return fetchall_dict(cursor)


def get_tags_for_entries(conn, entry_ids: Iterable[int]) -> dict:
    entry_ids = list(entry_ids)
    if not entry_ids:
        return {}
    placeholders = ",".join(["?"] * len(entry_ids))
    cursor = conn.execute(
        f"""
        SELECT et.entry_id, t.name
        FROM entry_tag et
        JOIN tag t ON t.id = et.tag_id
        WHERE et.entry_id IN ({placeholders})
        ORDER BY t.name
        """,
        entry_ids,
    )
    tag_map: dict[int, list] = {}
    for row in cursor.fetchall():
        tag_map.setdefault(row[0], []).append(row[1])
    return tag_map


def create_concept_dictionary(conn, title: str, body: str) -> int:
    cursor = conn.execute(
        """
        INSERT INTO concept_dictionary (title, body, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
        """,
        (title, body),
    )
    conn.commit()
    return int(cursor.lastrowid)


def list_concept_dictionary(conn) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM concept_dictionary
        ORDER BY updated_at DESC
        """
    )
    return fetchall_dict(cursor)


def get_concept_dictionary(conn, concept_id: int) -> Optional[dict]:
    cursor = conn.execute("SELECT * FROM concept_dictionary WHERE id = ?", (concept_id,))
    return fetchone_dict(cursor)


def update_concept_dictionary(conn, concept_id: int, title: str, body: str) -> None:
    conn.execute(
        """
        UPDATE concept_dictionary
        SET title = ?, body = ?, updated_at = datetime('now')
        WHERE id = ?
        """,
        (title, body, concept_id),
    )
    conn.commit()


def create_concept_memo(conn, title: str, content: str) -> int:
    cursor = conn.execute(
        """
        INSERT INTO concept_memo (title, content, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
        """,
        (title, content),
    )
    conn.commit()
    return int(cursor.lastrowid)


def list_concept_memo(conn) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM concept_memo
        ORDER BY updated_at DESC
        """
    )
    return fetchall_dict(cursor)


def get_concept_memo(conn, memo_id: int) -> Optional[dict]:
    cursor = conn.execute("SELECT * FROM concept_memo WHERE id = ?", (memo_id,))
    return fetchone_dict(cursor)


def update_concept_memo(
    conn,
    memo_id: int,
    title: Optional[str] = None,
    content: Optional[str] = None,
    summary: Optional[str] = None,
    extracted: Optional[list] = None,
) -> None:
    fields = ["updated_at = datetime('now')"]
    params: list = []
    if title is not None:
        fields.append("title = ?")
        params.append(title)
    if content is not None:
        fields.append("content = ?")
        params.append(content)
    if summary is not None:
        fields.append("summary = ?")
        params.append(summary)
    if extracted is not None:
        fields.append("extracted_json = ?")
        params.append(json.dumps(extracted, ensure_ascii=False))
    params.append(memo_id)
    conn.execute(
        f"""
        UPDATE concept_memo
        SET {", ".join(fields)}
        WHERE id = ?
        """,
        params,
    )
    conn.commit()


def create_daily_memo(conn, content: str) -> int:
    cursor = conn.execute(
        """
        INSERT INTO daily_memo (content, created_at)
        VALUES (?, datetime('now'))
        """,
        (content,),
    )
    conn.commit()
    return int(cursor.lastrowid)


def list_daily_memo(conn) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM daily_memo
        ORDER BY created_at DESC
        """
    )
    return fetchall_dict(cursor)


def add_link(conn, source_type: str, source_id: int, target_type: str, target_id: int) -> None:
    conn.execute(
        """
        INSERT INTO links (source_type, source_id, target_type, target_id, created_at)
        VALUES (?, ?, ?, ?, datetime('now'))
        """,
        (source_type, source_id, target_type, target_id),
    )
    conn.commit()


def list_links_by_source(conn, source_type: str, source_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM links
        WHERE source_type = ? AND source_id = ?
        ORDER BY id DESC
        """,
        (source_type, source_id),
    )
    return fetchall_dict(cursor)


def list_links_by_target(conn, target_type: str, target_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM links
        WHERE target_type = ? AND target_id = ?
        ORDER BY id DESC
        """,
        (target_type, target_id),
    )
    return fetchall_dict(cursor)


def add_ai_session(conn, subject_type: str, subject_id: int, role: str, content: str) -> None:
    conn.execute(
        """
        INSERT INTO ai_sessions (subject_type, subject_id, role, content, created_at)
        VALUES (?, ?, ?, ?, datetime('now'))
        """,
        (subject_type, subject_id, role, content),
    )
    conn.commit()


def list_ai_sessions(conn, subject_type: str, subject_id: int) -> list:
    cursor = conn.execute(
        """
        SELECT *
        FROM ai_sessions
        WHERE subject_type = ? AND subject_id = ?
        ORDER BY id ASC
        """,
        (subject_type, subject_id),
    )
    return fetchall_dict(cursor)
