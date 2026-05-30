import json
from collections import deque
from copy import deepcopy
from datetime import datetime
from pathlib import Path

CURRENT_ACTIVITY_SCHEMA_VERSION = 2


def resolve_path(path):
    return Path(path)


def ensure_parent_dir(path):
    path = resolve_path(path)
    parent = path.parent

    if parent:
        parent.mkdir(parents=True, exist_ok=True)


def rotate_file(path, max_bytes, backup_count):
    path = resolve_path(path)

    if not max_bytes or max_bytes <= 0 or backup_count <= 0:
        return

    if not path.exists() or path.stat().st_size < max_bytes:
        return

    oldest_backup = path.with_name(f"{path.name}.{backup_count}")

    if oldest_backup.exists():
        oldest_backup.unlink()

    for index in range(backup_count - 1, 0, -1):
        source = path.with_name(f"{path.name}.{index}")
        target = path.with_name(f"{path.name}.{index + 1}")

        if source.exists():
            source.replace(target)

    path.replace(path.with_name(f"{path.name}.1"))


def append_jsonl(path, record, max_bytes=None, backup_count=3):
    path = resolve_path(path)
    ensure_parent_dir(path)
    rotate_file(path, max_bytes, backup_count)

    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")


def iter_jsonl(path):
    path = resolve_path(path)

    if not path.exists():
        return

    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def load_jsonl(path, limit=None):
    records = deque(maxlen=limit) if limit is not None else []

    for record in iter_jsonl(path):
        records.append(record)

    return list(records)


def build_privacy_metadata():
    return {
        "mode": "non_invasive_context_only",
        "url_collected": False,
        "page_text_collected": False,
        "keystrokes_collected": False,
        "screenshots_collected": False,
        "screen_recording_collected": False,
        "clipboard_collected": False,
        "camera_collected": False,
        "microphone_collected": False
    }


def normalize_privacy_metadata(value):
    privacy = build_privacy_metadata()

    if isinstance(value, dict):
        privacy.update(value)

    return privacy


def normalize_activity_record(record):
    if not isinstance(record, dict):
        return None

    timestamp = record.get("timestamp")
    active_app = record.get("active_app")

    if not timestamp or not active_app:
        return None

    source_schema_version = record.get("schema_version", 1)

    if source_schema_version == CURRENT_ACTIVITY_SCHEMA_VERSION:
        normalized = deepcopy(record)
        normalized.setdefault("window_title", "Unknown")
        normalized.setdefault("sample_interval_seconds", 1)
        normalized.setdefault("title_source", "unknown")
        normalized["privacy"] = normalize_privacy_metadata(
            normalized.get("privacy")
        )
        normalized.setdefault("_source_schema_version", CURRENT_ACTIVITY_SCHEMA_VERSION)
        normalized.setdefault("_normalized_from_legacy", False)

        return normalized

    if source_schema_version not in (None, 1):
        return None

    window_title = record.get("window_title") or "Unknown"

    return {
        "schema_version": 1,
        "_source_schema_version": 1,
        "_normalized_from_legacy": True,
        "timestamp": timestamp,
        "sample_interval_seconds": record.get("sample_interval_seconds", 1),
        "active_app": active_app,
        "active_app_bundle_id": record.get("active_app_bundle_id", "Unknown"),
        "process_id": record.get("process_id"),
        "window_title": window_title,
        "title_source": record.get("title_source", "legacy"),
        "active_context": record.get("active_context"),
        "idle_seconds": record.get("idle_seconds"),
        "is_idle": record.get("is_idle", False),
        "browser": record.get("browser"),
        "privacy": normalize_privacy_metadata(record.get("privacy")),
        "collector": record.get("collector", "legacy.telemetry"),
        "app_changed": record.get("app_changed", False),
        "title_changed": record.get("title_changed", False),
        "context_changed": record.get("context_changed", False),
        "seconds_since_last_sample": record.get("seconds_since_last_sample"),
        "seconds_in_current_context": record.get("seconds_in_current_context", 0),
        "context_started_at": record.get("context_started_at", timestamp),
        "deduplicated_samples": record.get("deduplicated_samples", 0)
    }


def load_activity_logs(
    path,
    limit=None,
    prefer_current_schema=True,
    include_legacy_fallback=True
):
    normalized_records = deque(maxlen=limit) if limit is not None else []
    current_records = deque(maxlen=limit) if limit is not None else []

    for raw_record in iter_jsonl(path):
        record = normalize_activity_record(raw_record)

        if record is None:
            continue

        normalized_records.append(record)

        if (
            record.get("_source_schema_version")
            == CURRENT_ACTIVITY_SCHEMA_VERSION
        ):
            current_records.append(record)

    if prefer_current_schema and current_records:
        records = list(current_records)
    elif not include_legacy_fallback:
        records = list(current_records)
    else:
        records = list(normalized_records)

    return records


def load_json(path, default):
    path = resolve_path(path)

    if not path.exists():
        return deepcopy(default)

    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return deepcopy(default)


def save_json(path, data):
    path = resolve_path(path)
    ensure_parent_dir(path)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)


def parse_timestamp(value):
    if not value:
        return None

    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None
