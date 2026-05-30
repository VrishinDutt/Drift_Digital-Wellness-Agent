try:
    import psutil
except ImportError:
    psutil = None

try:
    import win32api
    import win32gui
    import win32process
except ImportError:
    win32api = None
    win32gui = None
    win32process = None

from telemetry.tracker_common import (
    build_activity,
    log_activity as run_log_loop,
    normalize_app_name,
    normalize_text,
    run_cli
)

DEFAULT_SAMPLE_INTERVAL_SECONDS = 1
DEFAULT_DEDUP_WINDOW_SECONDS = 30
WINDOWS_TICK_WRAP_MS = 2 ** 32

WINDOWS_BROWSER_APPS = {
    "Chrome",
    "Microsoft Edge",
    "Brave Browser",
    "Firefox"
}


def missing_dependencies():
    missing = []

    if psutil is None:
        missing.append("psutil")

    if win32api is None or win32gui is None or win32process is None:
        missing.append("pywin32")

    return missing


def windows_dependencies_available():
    return not missing_dependencies()


def unavailable_snapshot(title_source, permission_status):
    return {
        "active_app": "Unknown",
        "active_app_bundle_id": "Unknown",
        "process_id": None,
        "window_title": "Unknown",
        "title_source": title_source,
        "browser": None,
        "permission_status": permission_status
    }


def get_idle_seconds():
    if win32api is None:
        return None

    try:
        last_input_tick = win32api.GetLastInputInfo()
        current_tick = win32api.GetTickCount()

        elapsed_ms = current_tick - last_input_tick

        if elapsed_ms < 0:
            elapsed_ms += WINDOWS_TICK_WRAP_MS

        return round(elapsed_ms / 1000, 2)
    except Exception:
        return None


def get_process_name(pid):
    if not pid or psutil is None:
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


def get_foreground_window_handle():
    try:
        return win32gui.GetForegroundWindow()
    except Exception:
        return None


def get_window_title(hwnd):
    try:
        return normalize_text(
            win32gui.GetWindowText(hwnd)
        ), "win32_foreground_window_title", "ok"
    except Exception:
        return (
            "Unknown",
            "win32_foreground_window_title_unavailable",
            "limited_window_title"
        )


def get_window_process_id(hwnd):
    try:
        _, pid = win32process.GetWindowThreadProcessId(hwnd)
        return pid
    except Exception:
        return None


def get_active_window_snapshot():
    if not windows_dependencies_available():
        return unavailable_snapshot(
            "windows_dependency_unavailable",
            "missing_windows_dependency"
        )

    hwnd = get_foreground_window_handle()

    if not hwnd:
        return unavailable_snapshot(
            "win32_foreground_window_unavailable",
            "unavailable_foreground_window"
        )

    title, title_source, title_status = get_window_title(hwnd)
    pid = get_window_process_id(hwnd)
    process_name = get_process_name(pid)
    app_name = normalize_app_name(process_name)
    permission_status = title_status

    if process_name == "Unknown":
        permission_status = (
            "limited_process_metadata"
            if title_status == "ok"
            else title_status
        )

    return {
        "active_app": app_name,
        "active_app_bundle_id": process_name,
        "process_id": pid,
        "window_title": title,
        "title_source": title_source,
        "browser": build_browser_context(app_name, title),
        "permission_status": permission_status
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
