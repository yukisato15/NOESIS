import sqlite3

from app.db import init_db
from app.repository import create_entry, delete_entry, search_entries, update_entry


def test_init_and_search():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    init_db(conn)

    entry_id = create_entry(conn, "dictionary", "test term", "some body")
    conn.execute(
        "INSERT INTO quote (entry_id, quote_text) VALUES (?, ?)",
        (entry_id, "quote for search"),
    )
    conn.commit()

    results = search_entries(conn, "test", None, None, None, None)
    assert results
    assert results[0]["title"] == "test term"

    quote_results = search_entries(conn, "quote", None, None, None, None)
    assert quote_results
    assert quote_results[0]["id"] == entry_id

    update_entry(conn, entry_id, "updated", "updated body")
    updated_results = search_entries(conn, "updated", None, None, None, None)
    assert updated_results

    delete_entry(conn, entry_id)
    deleted_results = search_entries(conn, "updated", None, None, None, None)
    assert not deleted_results
