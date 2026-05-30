import argparse
import os
import subprocess
import sys
import time

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from agent.main_agent import run_agent
from telemetry.diagnostics import get_logger, install_crash_handlers

TRACKER_PROCESS = None


def build_tracker_popen_kwargs(quiet):
    kwargs = {
        "cwd": PROJECT_ROOT,
        "stdin": subprocess.DEVNULL,
    }

    if quiet:
        kwargs["stdout"] = subprocess.DEVNULL
        kwargs["stderr"] = subprocess.DEVNULL

    if sys.platform.startswith("win") and quiet:
        creationflags = 0

        if hasattr(subprocess, "CREATE_NO_WINDOW"):
            creationflags |= subprocess.CREATE_NO_WINDOW

        if hasattr(subprocess, "CREATE_NEW_PROCESS_GROUP"):
            creationflags |= subprocess.CREATE_NEW_PROCESS_GROUP

        if creationflags:
            kwargs["creationflags"] = creationflags

    return kwargs


def start_tracker(interval=1, quiet=True):
    global TRACKER_PROCESS

    if tracker_is_running():
        return TRACKER_PROCESS

    command = [
        sys.executable,
        "-m",
        "telemetry.activity_tracker",
        "--interval",
        str(interval)
    ]

    if quiet:
        command.append("--quiet")

    get_logger("runtime").info("starting_telemetry_tracker")
    TRACKER_PROCESS = subprocess.Popen(
        command,
        **build_tracker_popen_kwargs(quiet)
    )

    return TRACKER_PROCESS


def tracker_is_running():
    return (
        TRACKER_PROCESS is not None
        and TRACKER_PROCESS.poll() is None
    )


def tracker_exit_code():
    if TRACKER_PROCESS is None:
        return None

    return TRACKER_PROCESS.poll()


def ensure_tracker(interval=1, auto_restart=True):
    if tracker_is_running():
        return

    exit_code = tracker_exit_code()

    if exit_code is not None:
        get_logger("runtime").warning(
            "telemetry_tracker_exited code=%s",
            exit_code
        )
        print(
            "\nTelemetry tracker exited "
            f"with code {exit_code}."
        )

    if auto_restart:
        print("Restarting telemetry tracker...\n")
        start_tracker(interval=interval)


def stop_tracker():
    global TRACKER_PROCESS

    if not TRACKER_PROCESS:
        return

    if TRACKER_PROCESS.poll() is None:
        get_logger("runtime").info("stopping_telemetry_tracker")
        TRACKER_PROCESS.terminate()

        try:
            TRACKER_PROCESS.wait(timeout=5)
        except subprocess.TimeoutExpired:
            TRACKER_PROCESS.kill()
            TRACKER_PROCESS.wait(timeout=5)

    TRACKER_PROCESS = None


def runtime_loop(
    analysis_interval=20,
    tracker_interval=1,
    auto_restart=True,
    start_telemetry=True,
    show_ui=True,
    max_cycles=None
):
    print("\n=== DIGITAL WELLNESS AGENT RUNTIME ===\n")

    if start_telemetry:
        start_tracker(interval=tracker_interval)

    cycles = 0

    try:
        while True:
            if start_telemetry:
                ensure_tracker(
                    interval=tracker_interval,
                    auto_restart=auto_restart
                )

            time.sleep(analysis_interval)

            print("\n=== ANALYZING BEHAVIOR ===\n")
            run_agent(show_ui=show_ui)

            cycles += 1

            if max_cycles is not None and cycles >= max_cycles:
                break

    except KeyboardInterrupt:
        print("\nStopping runtime...\n")

    finally:
        stop_tracker()


def main():
    install_crash_handlers()

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--analysis-interval",
        type=float,
        default=20,
        help="Seconds between behavioral analyses."
    )
    parser.add_argument(
        "--tracker-interval",
        type=float,
        default=1,
        help="Seconds between telemetry samples."
    )
    parser.add_argument(
        "--no-restart",
        action="store_true",
        help="Do not restart the telemetry tracker if it exits."
    )
    parser.add_argument(
        "--no-tracker",
        action="store_true",
        help="Run analyses without launching telemetry."
    )
    parser.add_argument(
        "--no-ui",
        action="store_true",
        help="Suppress intervention overlays."
    )
    parser.add_argument(
        "--cycles",
        type=int,
        default=None,
        help="Run a finite number of analysis cycles."
    )

    args = parser.parse_args()

    runtime_loop(
        analysis_interval=args.analysis_interval,
        tracker_interval=args.tracker_interval,
        auto_restart=not args.no_restart,
        start_telemetry=not args.no_tracker,
        show_ui=not args.no_ui,
        max_cycles=args.cycles
    )


if __name__ == "__main__":
    main()
