import sys


def load_platform_tracker():
    try:
        if sys.platform == "darwin":
            from telemetry import macos_tracker

            return macos_tracker

        if sys.platform.startswith("win"):
            from telemetry import windows_tracker

            return windows_tracker
    except ImportError as error:
        print(
            "Platform telemetry dependencies are unavailable; "
            f"using fallback tracker. ({error.__class__.__name__}: {error})",
            file=sys.stderr
        )

    from telemetry import fallback_tracker

    return fallback_tracker


def capture_activity(*args, **kwargs):
    return load_platform_tracker().capture_activity(*args, **kwargs)


def log_activity(*args, **kwargs):
    return load_platform_tracker().log_activity(*args, **kwargs)


def get_active_window(*args, **kwargs):
    return load_platform_tracker().get_active_window(*args, **kwargs)


def main():
    load_platform_tracker().main()


if __name__ == "__main__":
    main()
