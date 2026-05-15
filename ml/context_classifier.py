BROWSER_APPS = {
    "Safari",
    "Chrome",
    "Google Chrome",
    "Chromium",
    "Brave Browser",
    "Microsoft Edge",
    "Arc"
}

DEVELOPMENT_APPS = {
    "VSCode",
    "Visual Studio Code",
    "Code",
    "PyCharm",
    "Cursor",
    "Xcode",
    "Terminal",
    "iTerm2",
    "python",
    "Python",
    "Python Launcher",
    "GitHub",
    "GitHub Desktop",
    "StackOverflow",
    "StackExchange",
    "Stack Exchange"
}

AI_ASSISTANCE_APPS = {
    "ChatGPT",
    "Claude",
    "Perplexity",
    "Codex"
}

PASSIVE_APPS = {
    "Instagram",
    "TikTok",
    "Reddit",
    "X",
    "Twitter",
    "YouTube",
    "Netflix"
}

WRITING_APPS = {
    "Notes",
    "TextEdit",
    "Pages",
    "Microsoft Word",
    "Google Docs"
}

PASSIVE_KEYWORDS = [
    "youtube",
    "shorts",
    "instagram",
    "reels",
    "tiktok",
    "twitter",
    "x.com",
    "reddit",
    "netflix",
    "prime video",
    "hulu"
]

FOCUSED_WORK_KEYWORDS = [
    "pull request",
    "docs",
    "documentation",
    "developer",
    "api reference",
    "leetcode",
    "notion",
    "research",
    "arxiv",
    "google docs",
    "colab"
]

DEVELOPMENT_KEYWORDS = [
    "github",
    "pull request",
    "stackoverflow",
    "stack overflow",
    "stackexchange",
    "stack exchange",
    "python",
    "traceback",
    "importerror",
    "terminal",
    "xcode",
    "vscode",
    "visual studio code",
    "compiler",
    "debugger"
]

AI_ASSISTANCE_KEYWORDS = [
    "chatgpt",
    "codex",
    "claude",
    "perplexity"
]


def contains_any(value, keywords):
    return any(
        keyword in value
        for keyword in keywords
    )


def classify_browser_context(title):
    if contains_any(title, PASSIVE_KEYWORDS):
        return "Passive Consumption"

    if contains_any(title, AI_ASSISTANCE_KEYWORDS):
        return "Assisted Deep Work"

    if contains_any(title, DEVELOPMENT_KEYWORDS):
        return "Development Loop"

    if contains_any(title, FOCUSED_WORK_KEYWORDS):
        return "Focused Work"

    return "General Browsing"


def classify_context(app_name, window_title):
    app_name = app_name or "Unknown"
    window_title = window_title or "Unknown"

    title = window_title.lower()

    if app_name in PASSIVE_APPS:
        return "Passive Consumption"

    if app_name in BROWSER_APPS:
        return classify_browser_context(title)

    if app_name in DEVELOPMENT_APPS:
        return "Development Loop"

    if app_name in AI_ASSISTANCE_APPS:
        return "Assisted Deep Work"

    if app_name in WRITING_APPS:
        return "Writing"

    if app_name == "Spotify":
        return "Background Regulation"

    return "Unknown Context"


if __name__ == "__main__":
    tests = [
        ("Safari", "YouTube"),
        ("Safari", "LeetCode Problem"),
        ("Chrome", "Stack Overflow - Python ImportError"),
        ("Codex", ""),
        ("Terminal", "zsh"),
        ("Spotify", "Music")
    ]

    for app, title in tests:
        context = classify_context(app, title)

        print(f"{app} | {title}")
        print(f"-> {context}\n")
