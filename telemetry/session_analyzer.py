import os
import sys
from collections import Counter, defaultdict

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from ml.context_classifier import classify_context
from core.paths import data_path
from telemetry.log_store import load_activity_logs, parse_timestamp

LOG_FILE = data_path("activity_log.json")
MAX_SAMPLE_GAP_SECONDS = 120
DEFAULT_SAMPLE_INTERVAL_SECONDS = 1


def load_logs():
    return load_activity_logs(LOG_FILE)


def get_context(log):
    return log.get(
        "active_context",
        classify_context(
            log.get("active_app", "Unknown"),
            log.get("window_title", "Unknown")
        )
    )


def infer_duration_seconds(log, next_log):
    fallback = log.get(
        "sample_interval_seconds",
        DEFAULT_SAMPLE_INTERVAL_SECONDS
    )

    current_timestamp = parse_timestamp(
        log.get("timestamp")
    )
    next_timestamp = parse_timestamp(
        next_log.get("timestamp")
    ) if next_log else None

    if not current_timestamp or not next_timestamp:
        return fallback

    delta = (next_timestamp - current_timestamp).total_seconds()

    if delta <= 0 or delta > MAX_SAMPLE_GAP_SECONDS:
        return fallback

    return delta


def iter_logs_with_duration(logs):
    for index, log in enumerate(logs):
        next_log = logs[index + 1] if index + 1 < len(logs) else None

        yield log, infer_duration_seconds(log, next_log)


def analyze_sessions(logs):
    app_seconds = defaultdict(float)
    context_seconds = defaultdict(float)

    for log, duration in iter_logs_with_duration(logs):
        app = log.get("active_app", "Unknown")
        context = get_context(log)

        app_seconds[app] += duration
        context_seconds[context] += duration

    print("\n=== APP USAGE SUMMARY ===\n")

    for app, seconds in sorted(
        app_seconds.items(),
        key=lambda item: item[1],
        reverse=True
    ):
        print(f"{app}: {seconds / 60:.2f} mins")

    print("\n=== CONTEXT SUMMARY ===\n")

    for context, seconds in sorted(
        context_seconds.items(),
        key=lambda item: item[1],
        reverse=True
    ):
        print(f"{context}: {seconds / 60:.2f} mins")


def analyze_switching(logs):
    app_switches = 0
    title_switches = 0
    context_switches = 0

    previous_app = None
    previous_title = None
    previous_context = None

    for log in logs:
        current_app = log.get("active_app", "Unknown")
        current_title = log.get("window_title", "Unknown")
        current_context = get_context(log)

        if previous_app and current_app != previous_app:
            app_switches += 1

        if previous_title and current_title != previous_title:
            title_switches += 1

        if previous_context and current_context != previous_context:
            context_switches += 1

        previous_app = current_app
        previous_title = current_title
        previous_context = current_context

    print("\n=== SWITCHING ANALYSIS ===\n")
    print(f"Total app switches: {app_switches}")
    print(f"Total title switches: {title_switches}")
    print(f"Total context switches: {context_switches}")


def analyze_data_points(logs):
    schema_counter = Counter(
        log.get("schema_version", 1)
        for log in logs
    )
    field_counter = Counter()
    privacy_counter = Counter()
    title_source_counter = Counter()

    for log in logs:
        field_counter.update(log.keys())
        title_source_counter[log.get("title_source", "legacy")] += 1

        privacy = log.get("privacy", {})

        for key in [
            "url_collected",
            "page_text_collected",
            "keystrokes_collected",
            "screenshots_collected",
            "screen_recording_collected",
            "clipboard_collected",
            "camera_collected",
            "microphone_collected"
        ]:
            privacy_counter[f"{key}={privacy.get(key, False)}"] += 1

    print("\n=== DATA POINT COVERAGE ===\n")
    print(f"Total samples: {len(logs)}")
    print(f"Schema versions: {dict(schema_counter)}")

    print("\nCollected fields:")

    for field, count in sorted(field_counter.items()):
        print(f"- {field}: {count}")

    print("\nTitle sources:")

    for source, count in title_source_counter.most_common():
        print(f"- {source}: {count}")

    print("\nPrivacy flags:")

    for flag, count in sorted(privacy_counter.items()):
        print(f"- {flag}: {count}")


if __name__ == "__main__":
    logs = load_logs()

    analyze_sessions(logs)
    analyze_switching(logs)
    analyze_data_points(logs)
