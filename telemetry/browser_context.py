import subprocess
import sys


BROWSER_APP_SCRIPTS = {
    "Safari": """
    tell application "Safari"
        if it is running and (count of windows) > 0 then
            return name of current tab of front window
        end if
    end tell
    return ""
    """,
    "Google Chrome": """
    tell application "Google Chrome"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """,
    "Chrome": """
    tell application "Google Chrome"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """,
    "Chromium": """
    tell application "Chromium"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """,
    "Brave Browser": """
    tell application "Brave Browser"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """,
    "Microsoft Edge": """
    tell application "Microsoft Edge"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """,
    "Arc": """
    tell application "Arc"
        if it is running and (count of windows) > 0 then
            return title of active tab of front window
        end if
    end tell
    return ""
    """
}


def is_supported_browser(app_name):
    return app_name in BROWSER_APP_SCRIPTS


def build_empty_context(app_name):
    return {
        "browser": app_name,
        "tab_title": "Unknown",
        "title_source": "browser_active_tab_title",
        "url_collected": False,
        "page_text_collected": False,
        "access_status": "unsupported"
    }


def get_browser_context(app_name):
    context = build_empty_context(app_name)
    script = BROWSER_APP_SCRIPTS.get(app_name)

    if not script:
        return context

    if sys.platform != "darwin":
        context["access_status"] = "unsupported_platform"
        return context

    context["access_status"] = "unavailable"

    if app_name == "Safari":
        context["title_source"] = "safari_current_tab_title"
    else:
        context["title_source"] = "chromium_active_tab_title"

    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=2
        )
    except Exception as error:
        context["error"] = error.__class__.__name__
        return context

    title = result.stdout.strip()

    if result.returncode == 0 and title:
        context["tab_title"] = title
        context["access_status"] = "ok"
    elif result.stderr:
        context["error"] = result.stderr.strip().splitlines()[-1]

    return context


def get_safari_context():
    return get_browser_context("Safari")


def get_safari_tab_title():
    return get_safari_context()["tab_title"]


if __name__ == "__main__":
    print(get_safari_context())
