from AppKit import NSWorkspace
from Quartz import (
    CGEventSourceSecondsSinceLastEventType,
    CGWindowListCopyWindowInfo,
    kCGAnyInputEventType,
    kCGEventSourceStateCombinedSessionState,
    kCGWindowListOptionOnScreenOnly,
    kCGNullWindowID
)

from telemetry.browser_context import (
    get_browser_context,
    is_supported_browser
)
from telemetry.tracker_common import (
    build_activity,
    log_activity as run_log_loop,
    normalize_app_name,
    normalize_text,
    run_cli
)

DEFAULT_SAMPLE_INTERVAL_SECONDS = 1
DEFAULT_DEDUP_WINDOW_SECONDS = 30
MIN_WINDOW_WIDTH = 120
MIN_WINDOW_HEIGHT = 80

IGNORED_WINDOW_OWNERS = {
    "Dock",
    "Window Server",
    "SystemUIServer",
    "Control Center",
    "Notification Center"
}


def get_idle_seconds():
    try:
        return round(
            CGEventSourceSecondsSinceLastEventType(
                kCGEventSourceStateCombinedSessionState,
                kCGAnyInputEventType
            ),
            2
        )
    except Exception:
        return None


def get_bundle_id_for_pid(pid):
    if pid is None:
        return "Unknown"

    workspace = NSWorkspace.sharedWorkspace()

    for app in workspace.runningApplications():
        if app.processIdentifier() == pid:
            return app.bundleIdentifier() or "Unknown"

    return "Unknown"


def get_frontmost_app_fallback():
    workspace = NSWorkspace.sharedWorkspace()
    active_app = workspace.frontmostApplication()

    if not active_app:
        return {
            "active_app": "Unknown",
            "active_app_bundle_id": "Unknown",
            "process_id": None,
            "window_title": "Unknown",
            "title_source": "frontmost_app_fallback",
            "browser": None,
            "permission_status": "unavailable_frontmost_app"
        }

    return {
        "active_app": normalize_app_name(
            active_app.localizedName()
        ),
        "active_app_bundle_id": active_app.bundleIdentifier() or "Unknown",
        "process_id": active_app.processIdentifier(),
        "window_title": "Unknown",
        "title_source": "frontmost_app_fallback",
        "browser": None,
        "permission_status": "limited_window_metadata"
    }


def is_candidate_window(window):
    owner = normalize_text(
        window.get("kCGWindowOwnerName", ""),
        fallback=""
    )

    if not owner or owner in IGNORED_WINDOW_OWNERS:
        return False

    if window.get("kCGWindowLayer", 0) != 0:
        return False

    if window.get("kCGWindowAlpha", 1) <= 0:
        return False

    if not window.get("kCGWindowIsOnscreen", True):
        return False

    bounds = window.get("kCGWindowBounds", {})
    width = bounds.get("Width", 0)
    height = bounds.get("Height", 0)

    return (
        width >= MIN_WINDOW_WIDTH
        and height >= MIN_WINDOW_HEIGHT
    )


def get_visible_windows():
    windows = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly,
        kCGNullWindowID
    ) or []

    return [
        window
        for window in windows
        if is_candidate_window(window)
    ]


def select_top_window():
    windows = get_visible_windows()

    if windows:
        return windows[0]

    return None


def get_quartz_window_snapshot():
    window = select_top_window()

    if not window:
        return get_frontmost_app_fallback()

    owner = normalize_app_name(
        window.get("kCGWindowOwnerName", "Unknown")
    )
    title = normalize_text(
        window.get("kCGWindowName", "")
    )
    pid = window.get("kCGWindowOwnerPID")

    return {
        "active_app": owner,
        "active_app_bundle_id": get_bundle_id_for_pid(pid),
        "process_id": pid,
        "window_title": title,
        "title_source": "quartz_front_window_title",
        "browser": None,
        "permission_status": "ok"
    }


def get_active_window_snapshot():
    snapshot = {
        "window_title": "Unknown",
        "title_source": "unavailable",
        "browser": None,
        **get_quartz_window_snapshot()
    }

    app_name = snapshot["active_app"]

    if is_supported_browser(app_name):
        browser_context = get_browser_context(app_name)
        snapshot["browser"] = browser_context

        if browser_context["tab_title"] != "Unknown":
            snapshot["window_title"] = browser_context["tab_title"]
            snapshot["title_source"] = browser_context["title_source"]
        elif browser_context.get("access_status") not in (None, "ok"):
            snapshot["permission_status"] = "limited_browser_metadata"

    return snapshot


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
        collector="telemetry.macos_tracker"
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
