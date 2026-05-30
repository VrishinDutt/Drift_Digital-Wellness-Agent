import argparse
import platform
import time
from datetime import datetime

from core.paths import data_path
from ml.context_classifier import classify_context
from telemetry.log_store import append_jsonl, parse_timestamp
from telemetry.diagnostics import install_crash_handlers, log_exception

LOG_FILE = data_path("activity_log.json")
DEFAULT_SAMPLE_INTERVAL_SECONDS = 1
DEFAULT_DEDUP_WINDOW_SECONDS = 30
ACTIVITY_LOG_MAX_BYTES = 5 * 1024 * 1024
ACTIVITY_LOG_BACKUP_COUNT = 3
MAX_TEXT_LENGTH = 240
MAX_DEDUPLICATED_SAMPLES = 1_000_000
IDLE_THRESHOLD_SECONDS = 60
PRIVACY_MODE = "non_invasive_context_only"

APP_NAME_ALIASES = {
    "Code": "VSCode",
    "Code.exe": "VSCode",
    "Google Chrome": "Chrome",
    "WindowsTerminal.exe": "Terminal",
    "cmd.exe": "Terminal",
    "powershell.exe": "Terminal",
    "pwsh.exe": "Terminal",
    "python.exe": "python",
    "pythonw.exe": "python",
    "chrome.exe": "Chrome",
    "msedge.exe": "Microsoft Edge",
    "brave.exe": "Brave Browser",
}


def normalize_text(value, fallback="Unknown", max_length=MAX_TEXT_LENGTH):
    if value is None:
        return fallback

    normalized = str(value).strip()

    if not normalized:
        return fallback

    if max_length and len(normalized) > max_length:
        return normalized[:max_length].rstrip()

    return normalized


def normalize_app_name(app_name):
    app_name = normalize_text(app_name)

    return APP_NAME_ALIASES.get(app_name, app_name)


def build_privacy_metadata():
    return {
        "mode": PRIVACY_MODE,
        "url_collected": False,
        "page_text_collected": False,
        "keystrokes_collected": False,
        "screenshots_collected": False,
        "screen_recording_collected": False,
        "clipboard_collected": False,
        "camera_collected": False,
        "microphone_collected": False
    }


def build_collector_error_snapshot():
    return {
        "active_app": "Unknown",
        "active_app_bundle_id": "Unknown",
        "process_id": None,
        "window_title": "Unknown",
        "title_source": "collector_error",
        "browser": None,
        "permission_status": "collector_error"
    }


def build_transition(current, previous):
    timestamp = parse_timestamp(current["timestamp"])
    previous_timestamp = (
        parse_timestamp(previous.get("timestamp"))
        if previous
        else None
    )

    seconds_since_last_sample = None

    if timestamp and previous_timestamp:
        seconds_since_last_sample = round(
            (timestamp - previous_timestamp).total_seconds(),
            2
        )

    if not previous:
        current_context_started_at = current["timestamp"]
    else:
        same_context = (
            previous.get("active_app") == current["active_app"]
            and previous.get("window_title") == current["window_title"]
        )

        current_context_started_at = (
            previous.get("context_started_at")
            if same_context
            else current["timestamp"]
        )

    context_started_at = parse_timestamp(current_context_started_at)
    seconds_in_current_context = 0

    if timestamp and context_started_at:
        seconds_in_current_context = round(
            (timestamp - context_started_at).total_seconds(),
            2
        )

    return {
        "app_changed": bool(
            previous
            and previous.get("active_app") != current["active_app"]
        ),
        "title_changed": bool(
            previous
            and previous.get("window_title") != current["window_title"]
        ),
        "context_changed": bool(
            previous
            and previous.get("active_context") != current["active_context"]
        ),
        "seconds_since_last_sample": seconds_since_last_sample,
        "seconds_in_current_context": seconds_in_current_context,
        "context_started_at": current_context_started_at
    }


def build_activity(
    snapshot,
    idle_seconds,
    previous=None,
    sample_interval_seconds=DEFAULT_SAMPLE_INTERVAL_SECONDS,
    collector="telemetry.activity_tracker"
):
    active_app = normalize_app_name(
        snapshot.get("active_app", "Unknown")
    )
    window_title = normalize_text(
        snapshot.get("window_title", "Unknown")
    )
    active_context = classify_context(active_app, window_title)

    activity = {
        "schema_version": 2,
        "timestamp": datetime.now().isoformat(),
        "sample_interval_seconds": sample_interval_seconds,
        "active_app": active_app,
        "active_app_bundle_id": snapshot.get(
            "active_app_bundle_id",
            "Unknown"
        ),
        "process_id": snapshot.get("process_id"),
        "window_title": window_title,
        "title_source": snapshot.get("title_source", "unavailable"),
        "active_context": active_context,
        "idle_seconds": idle_seconds,
        "is_idle": (
            idle_seconds is not None
            and idle_seconds >= IDLE_THRESHOLD_SECONDS
        ),
        "browser": snapshot.get("browser"),
        "privacy": build_privacy_metadata(),
        "collector": collector,
        "platform": platform.system() or "Unknown",
        "telemetry_adapter": collector,
        "permission_status": snapshot.get("permission_status", "ok")
    }

    activity.update(
        build_transition(activity, previous)
    )

    return activity


def should_emit_activity(
    activity,
    previous_emitted,
    dedup_window_seconds
):
    if previous_emitted is None:
        return True

    changed = (
        activity["active_app"] != previous_emitted.get("active_app")
        or activity["window_title"] != previous_emitted.get("window_title")
        or activity["active_context"] != previous_emitted.get("active_context")
        or activity["is_idle"] != previous_emitted.get("is_idle")
    )

    if changed:
        return True

    if dedup_window_seconds <= 0:
        return True

    timestamp = parse_timestamp(activity["timestamp"])
    previous_timestamp = parse_timestamp(
        previous_emitted.get("timestamp")
    )

    if not timestamp or not previous_timestamp:
        return True

    return (
        timestamp - previous_timestamp
    ).total_seconds() >= dedup_window_seconds


def log_activity(
    capture_activity,
    sample_interval_seconds=DEFAULT_SAMPLE_INTERVAL_SECONDS,
    dedup_window_seconds=DEFAULT_DEDUP_WINDOW_SECONDS,
    quiet=False
):
    install_crash_handlers()

    if not quiet:
        print("Tracking active applications...\n")

    previous_sample = None
    previous_emitted = None
    deduplicated_samples = 0

    while True:
        try:
            activity = capture_activity(
                previous=previous_sample,
                sample_interval_seconds=sample_interval_seconds
            )
        except KeyboardInterrupt:
            raise
        except Exception as exc:
            log_exception(
                "telemetry_capture_failed",
                exc,
                logger_name="telemetry"
            )
            activity = build_activity(
                build_collector_error_snapshot(),
                None,
                previous=previous_sample,
                sample_interval_seconds=sample_interval_seconds,
                collector=f"{capture_activity.__module__}.error"
            )

        should_emit = should_emit_activity(
            activity,
            previous_emitted,
            dedup_window_seconds
        )

        if should_emit:
            activity["deduplicated_samples"] = deduplicated_samples
            append_jsonl(
                LOG_FILE,
                activity,
                max_bytes=ACTIVITY_LOG_MAX_BYTES,
                backup_count=ACTIVITY_LOG_BACKUP_COUNT
            )

            if not quiet:
                print(activity)

            previous_emitted = activity
            deduplicated_samples = 0
        else:
            deduplicated_samples = min(
                deduplicated_samples + 1,
                MAX_DEDUPLICATED_SAMPLES
            )

        previous_sample = activity

        time.sleep(sample_interval_seconds)


def run_cli(capture_activity, log_activity_func):
    install_crash_handlers()

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--once",
        action="store_true",
        help="Capture one sample and print it without writing to the log."
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=DEFAULT_SAMPLE_INTERVAL_SECONDS,
        help="Seconds between samples."
    )
    parser.add_argument(
        "--dedup-window",
        type=float,
        default=DEFAULT_DEDUP_WINDOW_SECONDS,
        help="Maximum seconds between heartbeat logs for unchanged context."
    )
    parser.add_argument(
        "--no-dedup",
        action="store_true",
        help="Write every sample."
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Do not print each emitted telemetry row."
    )

    args = parser.parse_args()
    sample_interval = max(args.interval, 0.2)

    if args.once:
        try:
            activity = capture_activity(
                sample_interval_seconds=sample_interval
            )
        except Exception as exc:
            log_exception(
                "telemetry_once_capture_failed",
                exc,
                logger_name="telemetry"
            )
            activity = build_activity(
                build_collector_error_snapshot(),
                None,
                sample_interval_seconds=sample_interval,
                collector=f"{capture_activity.__module__}.error"
            )

        print(
            activity
        )
        return

    dedup_window = 0 if args.no_dedup else max(args.dedup_window, 0)

    log_activity_func(
        sample_interval_seconds=sample_interval,
        dedup_window_seconds=dedup_window,
        quiet=args.quiet
    )
