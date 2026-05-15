import argparse
import os
import shutil
import sys
from datetime import datetime

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from core.paths import data_path
from telemetry.log_store import (
    CURRENT_ACTIVITY_SCHEMA_VERSION,
    append_jsonl,
    load_jsonl,
    normalize_activity_record
)

DEFAULT_LOG_FILE = data_path("activity_log.json")
DEFAULT_BACKUP_FILE = data_path("activity_log_legacy_backup.jsonl")


def split_activity_records(records):
    current_records = []
    legacy_or_invalid_records = []

    for record in records:
        normalized = normalize_activity_record(record)

        if (
            normalized
            and normalized.get("_source_schema_version")
            == CURRENT_ACTIVITY_SCHEMA_VERSION
        ):
            current_records.append(normalized)
        else:
            legacy_or_invalid_records.append(record)

    return current_records, legacy_or_invalid_records


def timestamped_backup_path(path):
    path = str(path)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    return f"{path}.{timestamp}"


def write_jsonl(path, records):
    with open(path, "w") as f:
        pass

    for record in records:
        append_jsonl(path, record)


def clean_log(log_file, backup_file, apply=False):
    records = load_jsonl(log_file)
    current_records, legacy_or_invalid_records = split_activity_records(records)

    print("=== TELEMETRY LOG CLEANUP ===")
    print(f"Input log: {log_file}")
    print(f"Total readable JSON rows: {len(records)}")
    print(f"Preserved schema v2 rows: {len(current_records)}")
    print(f"Legacy/invalid readable rows for backup: {len(legacy_or_invalid_records)}")

    if not apply:
        print("\nDry run only. Re-run with --apply to write changes.")
        return

    if not os.path.exists(log_file):
        print("\nNo log file exists; nothing to clean.")
        return

    backup_target = backup_file

    if os.path.exists(backup_target):
        backup_target = timestamped_backup_path(backup_target)

    shutil.copy2(log_file, backup_target)
    write_jsonl(log_file, current_records)

    print(f"\nBacked up original log to: {backup_target}")
    print(f"Wrote clean schema v2 log to: {log_file}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--log-file",
        default=str(DEFAULT_LOG_FILE),
        help="Path to the JSONL telemetry log to clean."
    )
    parser.add_argument(
        "--backup-file",
        default=str(DEFAULT_BACKUP_FILE),
        help="Backup path for the original mixed-schema log."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually write the cleaned log. Without this, only prints a summary."
    )

    args = parser.parse_args()

    clean_log(
        args.log_file,
        args.backup_file,
        apply=args.apply
    )


if __name__ == "__main__":
    main()
