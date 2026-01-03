import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(ROOT))

from app.db import get_connection
from app.repository import get_entry, update_entry
from app.services.mock_ai import generate_reading, is_kana_text


def load_manual_readings(path: Path) -> dict[int, str]:
    readings: dict[int, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 2:
            continue
        try:
            entry_id = int(parts[0])
        except ValueError:
            continue
        reading = parts[1]
        if reading:
            readings[entry_id] = reading
    return readings


def main() -> int:
    parser = argparse.ArgumentParser(description="Backfill reading for dictionary entries.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing readings.")
    parser.add_argument("--domain", choices=["general", "english", "technology"], help="Filter by domain.")
    parser.add_argument("--language", choices=["ja", "en", "mixed"], help="Filter by language.")
    parser.add_argument("--only-failed", action="store_true", help="Retry only failed entries.")
    parser.add_argument(
        "--manual-file",
        type=Path,
        help="Apply manual readings from TSV: entry_id | reading",
    )
    parser.add_argument(
        "--failures-file",
        type=Path,
        default=ROOT / "data/reading_failures.json",
        help="Path to write failed entry ids.",
    )
    args = parser.parse_args()

    conn = get_connection()
    if args.manual_file:
        manual = load_manual_readings(args.manual_file)
        for entry_id, reading in manual.items():
            entry = get_entry(conn, entry_id)
            if not entry or entry.get("type") != "dictionary":
                continue
            update_entry(
                conn,
                entry_id,
                entry["title"],
                entry["body"],
                reading=reading,
                reading_source="manual",
            )
        conn.close()
        print(f"updated: {len(manual)}")
        return 0

    base_query = "SELECT id, title, type, language, reading, domain FROM entry WHERE type = 'dictionary'"
    params: list = []
    if args.domain:
        base_query += " AND domain = ?"
        params.append(args.domain)
    if args.language:
        base_query += " AND language = ?"
        params.append(args.language)
    rows = conn.execute(base_query, params).fetchall()

    failed_ids: set[int] = set()
    if args.only_failed and args.failures_file.exists():
        try:
            failed_ids = set(json.loads(args.failures_file.read_text(encoding="utf-8")))
        except json.JSONDecodeError:
            failed_ids = set()
    updated = 0
    failed = []
    for row in rows:
        entry_id = int(row["id"])
        title = row["title"]
        reading = row["reading"] or ""
        entry = get_entry(conn, entry_id)
        if args.only_failed and entry_id not in failed_ids:
            continue
        dictionary_type = "english" if entry.get("language") == "en" else "default"
        if entry.get("domain") == "technology":
            dictionary_type = "it"

        if not args.force and reading and is_kana_text(reading):
            continue
        new_reading = generate_reading(title, dictionary_type)
        if not is_kana_text(new_reading):
            failed.append(
                {
                    "id": entry_id,
                    "title": title,
                    "domain": entry.get("domain"),
                    "language": entry.get("language"),
                }
            )
            continue
        update_entry(
            conn,
            entry_id,
            title,
            entry["body"],
            reading=new_reading,
            reading_source="ai",
        )
        updated += 1

    conn.close()
    if failed:
        args.failures_file.write_text(
            json.dumps([item["id"] for item in failed], ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        tsv_path = args.failures_file.with_suffix(".tsv")
        lines = ["id|title|domain|language|reading"]
        lines.extend(
            f"{item['id']}|{item['title']}|{item['domain']}|{item['language']}|"
            for item in failed
        )
        tsv_path.write_text("\n".join(lines), encoding="utf-8")
        print(f"failed: {len(failed)} -> {args.failures_file}")
        print(f"manual template: {tsv_path}")
    print(f"updated: {updated}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
