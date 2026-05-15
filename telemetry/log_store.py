import json
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


def append_jsonl(path, record):
    path = resolve_path(path)
    ensure_parent_dir(path)

    with open(path, "a") as f:
        f.write(json.dumps(record) + "\n")


def load_jsonl(path, limit=None):
    path = resolve_path(path)

    if not path.exists():
        return []

    records = []

    with open(path, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                continue

    if limit is not None:
        return records[-limit:]

    return records


def build_privacy_metadata():
    return {
        "mode": "non_invasive_context_only",
        "url_collected": False,
        "page_text_collected": False,
        "keystrokes_collected": False,
        "screenshots_collected": False,
        "clipboard_collected": False
    }


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
        normalized.setdefault("privacy", build_privacy_metadata())
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
        "privacy": record.get("privacy", build_privacy_metadata()),
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
    records = [
        normalize_activity_record(record)
        for record in load_jsonl(path)
    ]
    records = [
        record
        for record in records
        if record is not None
    ]

    current_records = [
        record
        for record in records
        if record.get("_source_schema_version") == CURRENT_ACTIVITY_SCHEMA_VERSION
    ]

    if prefer_current_schema and current_records:
        records = current_records
    elif not include_legacy_fallback:
        records = current_records

    if limit is not None:
        return records[-limit:]

    return records


def load_json(path, default):
    path = resolve_path(path)

    if not path.exists():
        return deepcopy(default)

    try:
        with open(path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return deepcopy(default)


def save_json(path, data):
    path = resolve_path(path)
    ensure_parent_dir(path)

    with open(path, "w") as f:
        json.dump(data, f, indent=4)


def parse_timestamp(value):
    if not value:
        return None

    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None
