from telemetry.tracker_common import (
    build_activity,
    log_activity as run_log_loop,
    run_cli
)

DEFAULT_SAMPLE_INTERVAL_SECONDS = 1
DEFAULT_DEDUP_WINDOW_SECONDS = 30


def get_idle_seconds():
    return None


def get_active_window_snapshot():
    return {
        "active_app": "Unknown",
        "active_app_bundle_id": "Unknown",
        "process_id": None,
        "window_title": "Unknown",
        "title_source": "platform_fallback",
        "browser": None,
        "permission_status": "unsupported_platform"
    }


def get_active_window():
    snapshot = get_active_window_snapshot()

    return snapshot["active_app"], snapshot["window_title"]


def capture_activity(
    previous=None,
    sample_interval_seconds=DEFAULT_SAMPLE_INTERVAL_SECONDS
):
    return build_activity(
        get_active_window_snapshot(),
        get_idle_seconds(),
        previous=previous,
        sample_interval_seconds=sample_interval_seconds,
        collector="telemetry.fallback_tracker"
    )


def log_activity(
    sample_interval_seconds=DEFAULT_SAMPLE_INTERVAL_SECONDS,
    dedup_window_seconds=DEFAULT_DEDUP_WINDOW_SECONDS,
    quiet=False
):
    run_log_loop(
        capture_activity,
        sample_interval_seconds=sample_interval_seconds,
        dedup_window_seconds=dedup_window_seconds,
        quiet=quiet
    )


def main():
    run_cli(capture_activity, log_activity)


if __name__ == "__main__":
    main()
