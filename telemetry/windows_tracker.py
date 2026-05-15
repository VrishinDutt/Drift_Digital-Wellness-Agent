import psutil
import win32api
import win32gui
import win32process

from telemetry.tracker_common import (
    build_activity,
    log_activity as run_log_loop,
    normalize_app_name,
    normalize_text,
    run_cli
)

DEFAULT_SAMPLE_INTERVAL_SECONDS = 1
DEFAULT_DEDUP_WINDOW_SECONDS = 30

WINDOWS_BROWSER_APPS = {
    "Chrome",
    "Microsoft Edge",
    "Brave Browser",
    "Firefox"
}


def get_idle_seconds():
    try:
        last_input_tick = win32api.GetLastInputInfo()
        current_tick = win32api.GetTickCount()
        return round((current_tick - last_input_tick) / 1000, 2)
    except Exception:
        return None


def get_process_name(pid):
    if not pid:
        return "Unknown"

    try:
        process = psutil.Process(pid)
        return process.name() or "Unknown"
    except (psutil.Error, OSError):
        return "Unknown"


def build_browser_context(app_name, title):
    if app_name not in WINDOWS_BROWSER_APPS:
        return None

    return {
        "browser": app_name,
        "tab_title": title,
        "title_source": "win32_foreground_window_title",
        "url_collected": False,
        "page_text_collected": False,
        "access_status": "window_title_only"
    }


def get_active_window_snapshot():
    hwnd = win32gui.GetForegroundWindow()

    if not hwnd:
        return {
            "active_app": "Unknown",
            "active_app_bundle_id": "Unknown",
            "process_id": None,
            "window_title": "Unknown",
            "title_source": "win32_foreground_window_unavailable",
            "browser": None,
            "permission_status": "unavailable_foreground_window"
        }

    title = normalize_text(
        win32gui.GetWindowText(hwnd)
    )
    _, pid = win32process.GetWindowThreadProcessId(hwnd)
    process_name = get_process_name(pid)
    app_name = normalize_app_name(process_name)

    return {
        "active_app": app_name,
        "active_app_bundle_id": process_name,
        "process_id": pid,
        "window_title": title,
        "title_source": "win32_foreground_window_title",
        "browser": build_browser_context(app_name, title),
        "permission_status": "ok"
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
        collector="telemetry.windows_tracker"
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
