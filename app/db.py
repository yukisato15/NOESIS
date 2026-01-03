import os
import sqlite3
from pathlib import Path
from typing import Iterable, Optional

DB_PATH = Path(os.getenv("KNOWLEDGE_DB_PATH", "data/knowledge.db"))


def get_connection() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS book (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL UNIQUE,
            author TEXT,
            isbn TEXT,
            overview TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS entry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            -- Dictionary: stable definition-centric knowledge.
            -- Reading note: source-tied insights and quotes.
            type TEXT NOT NULL CHECK (type IN ('dictionary', 'reading_note')),
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            genre TEXT,
            book_id INTEGER,
            domain TEXT NOT NULL DEFAULT 'general',
            field TEXT NOT NULL DEFAULT 'unspecified',
            concept TEXT,
            reading TEXT NOT NULL DEFAULT '',
            language TEXT NOT NULL DEFAULT 'ja',
            reading_source TEXT NOT NULL DEFAULT 'manual',
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            -- NOTE: book_id FK is not enforced for existing DBs without migration.
        );

        CREATE TABLE IF NOT EXISTS english_lexicon (
            entry_id INTEGER PRIMARY KEY,
            headword TEXT NOT NULL,
            language TEXT NOT NULL,
            ipa TEXT NOT NULL,
            reading_kana TEXT NOT NULL DEFAULT '',
            pronunciation_note TEXT NOT NULL,
            part_of_speech TEXT NOT NULL,
            countability TEXT NOT NULL,
            definition_en TEXT NOT NULL,
            definition_ja TEXT NOT NULL,
            synonyms_json TEXT NOT NULL,
            antonyms_json TEXT NOT NULL,
            related_terms_json TEXT NOT NULL,
            examples_json TEXT NOT NULL,
            phrases_json TEXT NOT NULL,
            register TEXT NOT NULL,
            etymology TEXT NOT NULL,
            usage_note TEXT NOT NULL,
            concept_memo TEXT NOT NULL DEFAULT '',
            audio_tts_text TEXT NOT NULL DEFAULT '',
            audio_url TEXT NOT NULL DEFAULT '',
            audio_note TEXT NOT NULL DEFAULT '',
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS entry_tag (
            entry_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (entry_id, tag_id),
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS source (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT,
            title TEXT,
            note TEXT
        );

        CREATE TABLE IF NOT EXISTS entry_source (
            entry_id INTEGER NOT NULL,
            source_id INTEGER NOT NULL,
            PRIMARY KEY (entry_id, source_id),
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE,
            FOREIGN KEY (source_id) REFERENCES source(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS quote (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            quote_text TEXT NOT NULL,
            page_or_loc TEXT,
            note TEXT,
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS review (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            next_review_at TEXT,
            interval_days INTEGER,
            ease REAL,
            last_result TEXT,
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS entry_appendix (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            type TEXT NOT NULL CHECK (type IN ('log', 'extract', 'summary')),
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (entry_id) REFERENCES entry(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS reading_impression (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL UNIQUE,
            summary TEXT NOT NULL,
            started_at TEXT,
            finished_at TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS reading_memo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS reading_reflection (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS book_appendix (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            type TEXT NOT NULL CHECK (type IN ('log', 'extract', 'summary')),
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS concept_dictionary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS concept_memo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            summary TEXT NOT NULL DEFAULT '',
            extracted_json TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS daily_memo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_type TEXT NOT NULL,
            source_id INTEGER NOT NULL,
            target_type TEXT NOT NULL,
            target_id INTEGER NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS ai_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_type TEXT NOT NULL,
            subject_id INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE VIRTUAL TABLE IF NOT EXISTS entry_fts USING fts5(
            title, body, content='entry', content_rowid='id'
        );

        CREATE VIRTUAL TABLE IF NOT EXISTS quote_fts USING fts5(
            quote_text, content='quote', content_rowid='id'
        );

        CREATE TRIGGER IF NOT EXISTS entry_ai AFTER INSERT ON entry BEGIN
            INSERT INTO entry_fts(rowid, title, body)
            VALUES (new.id, new.title, new.body);
        END;

        CREATE TRIGGER IF NOT EXISTS entry_au AFTER UPDATE ON entry BEGIN
            INSERT INTO entry_fts(entry_fts, rowid, title, body)
            VALUES('delete', old.id, old.title, old.body);
            INSERT INTO entry_fts(rowid, title, body)
            VALUES (new.id, new.title, new.body);
        END;

        CREATE TRIGGER IF NOT EXISTS entry_ad AFTER DELETE ON entry BEGIN
            INSERT INTO entry_fts(entry_fts, rowid, title, body)
            VALUES('delete', old.id, old.title, old.body);
        END;

        CREATE TRIGGER IF NOT EXISTS quote_ai AFTER INSERT ON quote BEGIN
            INSERT INTO quote_fts(rowid, quote_text)
            VALUES (new.id, new.quote_text);
        END;

        CREATE TRIGGER IF NOT EXISTS quote_au AFTER UPDATE ON quote BEGIN
            INSERT INTO quote_fts(quote_fts, rowid, quote_text)
            VALUES('delete', old.id, old.quote_text);
            INSERT INTO quote_fts(rowid, quote_text)
            VALUES (new.id, new.quote_text);
        END;

        CREATE TRIGGER IF NOT EXISTS quote_ad AFTER DELETE ON quote BEGIN
            INSERT INTO quote_fts(quote_fts, rowid, quote_text)
            VALUES('delete', old.id, old.quote_text);
        END;
        """
    )
    # Keep schema migrations minimal and safe for existing DBs.
    ensure_column(conn, "entry", "genre", "TEXT")
    ensure_column(conn, "entry", "book_id", "INTEGER")
    ensure_column(conn, "entry", "domain", "TEXT NOT NULL DEFAULT 'general'")
    ensure_column(conn, "entry", "field", "TEXT NOT NULL DEFAULT 'unspecified'")
    ensure_column(conn, "entry", "concept", "TEXT")
    ensure_column(conn, "entry", "reading", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "entry", "language", "TEXT NOT NULL DEFAULT 'ja'")
    ensure_column(conn, "entry", "reading_source", "TEXT NOT NULL DEFAULT 'manual'")
    ensure_column(conn, "english_lexicon", "reading_kana", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "english_lexicon", "concept_memo", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "english_lexicon", "audio_tts_text", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "english_lexicon", "audio_url", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "english_lexicon", "audio_note", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "book", "overview", "TEXT NOT NULL DEFAULT ''")
    ensure_column(conn, "book", "created_at", "TEXT")
    ensure_column(conn, "book", "updated_at", "TEXT")
    conn.execute(
        """
        UPDATE book
        SET created_at = COALESCE(created_at, datetime('now')),
            updated_at = COALESCE(updated_at, datetime('now'))
        """
    )
    conn.commit()


def ensure_column(conn: sqlite3.Connection, table: str, column: str, column_type: str) -> None:
    cursor = conn.execute(f"PRAGMA table_info({table})")
    existing = {row[1] for row in cursor.fetchall()}
    if column not in existing:
        # Avoid brittle migrations; add only missing columns.
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {column_type}")


def fetchall_dict(cursor: sqlite3.Cursor) -> Iterable[dict]:
    return [dict(row) for row in cursor.fetchall()]


def fetchone_dict(cursor: sqlite3.Cursor) -> Optional[dict]:
    row = cursor.fetchone()
    return dict(row) if row else None
