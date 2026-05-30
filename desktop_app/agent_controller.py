from __future__ import annotations

import contextlib
import copy
import io
from datetime import datetime

from telemetry.diagnostics import log_exception

MISSING_PYSIDE6_MESSAGE = (
    "PySide6 is not installed. Run: python -m pip install -r requirements.txt"
)

try:
    from PySide6.QtCore import (  # type: ignore
        QObject,
        QRunnable,
        QThreadPool,
        QTimer,
        Signal,
        Slot,
    )

    PYSIDE6_AVAILABLE = True
except ImportError:
    QObject = object
    QRunnable = object
    QThreadPool = None
    QTimer = None
    Signal = None
    Slot = lambda *args, **kwargs: (lambda func: func)
    PYSIDE6_AVAILABLE = False


DEMO_SCENARIOS = [
    {
        "status": "demo",
        "context": "Deep Work",
        "ccs": 15,
        "reasoning": {
            "state": "Focused",
            "summary": "Sustained attention with low drift pressure.",
        },
        "intervention": {
            "type": "none",
            "message": "No intervention needed. Keep the current rhythm.",
        },
        "latest_active_app": "Xcode",
        "latest_active_context": "Deep Work",
    },
    {
        "status": "demo",
        "context": "Development Loop",
        "ccs": 30,
        "reasoning": {
            "state": "Assisted Deep Work",
            "summary": "Coding and AI assistance are moving in one loop.",
        },
        "intervention": {
            "type": "none",
            "message": "Assisted development loop looks intentional.",
        },
        "latest_active_app": "Codex",
        "latest_active_context": "Development Loop",
    },
    {
        "status": "demo",
        "context": "General Browsing",
        "ccs": 45,
        "reasoning": {
            "state": "Passive Drift",
            "summary": "Attention is wandering but still easy to redirect.",
        },
        "intervention": {
            "type": "reflection",
            "message": "Take one quiet moment to choose what deserves the next tab.",
        },
        "latest_active_app": "Safari",
        "latest_active_context": "General Browsing",
    },
    {
        "status": "demo",
        "context": "Passive Consumption",
        "ccs": 75,
        "reasoning": {
            "state": "Compulsive Drift",
            "summary": "High-stimulation context with repeated passive momentum.",
        },
        "intervention": {
            "type": "pause",
            "message": "A small pause may help you decide whether this still fits.",
        },
        "latest_active_app": "YouTube",
        "latest_active_context": "Passive Consumption",
    },
    {
        "status": "demo",
        "context": "Unknown Context",
        "ccs": 90,
        "reasoning": {
            "state": "Overloaded",
            "summary": "The context is unclear and the drift score is elevated.",
        },
        "intervention": {
            "type": "grounding",
            "message": "Try a slow breath and let the next action be simple.",
        },
        "latest_active_app": "Unknown",
        "latest_active_context": "Unknown Context",
    },
]


def build_demo_timeline(snapshot, limit=4):
    now = datetime.now().isoformat(timespec="seconds")
    return [
        {
            "timestamp": now,
            "state": snapshot["reasoning"]["state"],
            "context": snapshot["context"],
            "ccs": snapshot["ccs"],
        }
    ][-limit:]


def complete_snapshot(base_snapshot, *, telemetry_running=False):
    snapshot = copy.deepcopy(base_snapshot)
    now = datetime.now().isoformat(timespec="seconds")
    snapshot.setdefault("spotify_context", None)
    snapshot.setdefault("timeline_preview", build_demo_timeline(snapshot))
    snapshot.setdefault("ui_interventions_enabled", False)
    snapshot.setdefault("privacy_mode", "local-only")
    snapshot.setdefault("snapshot_timestamp", now)
    snapshot.setdefault("latest_telemetry_timestamp", now)
    snapshot.setdefault("latest_telemetry_age_seconds", 0)
    snapshot.setdefault("telemetry_freshness", "demo")
    snapshot.setdefault("telemetry_platform", "Demo")
    snapshot.setdefault("telemetry_adapter", "telemetry.demo")
    snapshot.setdefault("telemetry_permission_status", "demo")
    snapshot.setdefault("latest_active_app", "Demo")
    snapshot.setdefault("latest_window_title", "Demo Mode")
    snapshot.setdefault("latest_active_context", snapshot.get("context"))
    snapshot.setdefault("rows_used_for_analysis", 0)
    snapshot["telemetry_running"] = bool(telemetry_running)
    return snapshot


class DemoSnapshotProvider:
    def __init__(self):
        self._index = 0

    def reset(self):
        self._index = 0

    def next_snapshot(self):
        scenario = DEMO_SCENARIOS[self._index % len(DEMO_SCENARIOS)]
        self._index += 1
        return complete_snapshot(scenario, telemetry_running=False)


class AnalysisInFlightGuard:
    def __init__(self):
        self.analysis_in_flight = False

    def try_acquire(self):
        if self.analysis_in_flight:
            return False

        self.analysis_in_flight = True
        return True

    def release(self):
        self.analysis_in_flight = False


if PYSIDE6_AVAILABLE:

    class WorkerSignals(QObject):
        snapshot_ready = Signal(dict)
        timeline_ready = Signal(list)
        error_raised = Signal(str)
        finished = Signal()


    class AnalysisWorker(QRunnable):
        def __init__(self, mode, demo_provider):
            super().__init__()
            self.mode = mode
            self.demo_provider = demo_provider
            self.signals = WorkerSignals()

        @Slot()
        def run(self):
            try:
                if self.mode == "demo":
                    snapshot = self.demo_provider.next_snapshot()
                else:
                    from agent.main_agent import run_agent
                    from agent import runtime

                    if not runtime.tracker_is_running():
                        runtime.start_tracker(interval=1, quiet=True)

                    with contextlib.redirect_stdout(io.StringIO()):
                        snapshot = run_agent(
                            show_ui=False,
                            verbose=False,
                            update_learning=False,
                        )

                    snapshot["telemetry_running"] = (
                        runtime.tracker_is_running()
                    )

                timeline = snapshot.get("timeline_preview", [])
                self.signals.snapshot_ready.emit(snapshot)
                self.signals.timeline_ready.emit(timeline)
            except Exception as exc:
                log_exception(
                    "desktop_analysis_worker_failed",
                    exc,
                    logger_name="desktop"
                )
                self.signals.error_raised.emit(str(exc))
            finally:
                self.signals.finished.emit()


    class AgentController(QObject):
        snapshot_ready = Signal(dict)
        timeline_ready = Signal(list)
        status_changed = Signal(dict)
        error_raised = Signal(str)

        def __init__(self, parent=None, analysis_interval_ms=5000):
            super().__init__(parent)
            self.thread_pool = QThreadPool.globalInstance()
            self.timer = QTimer(self)
            self.timer.setInterval(analysis_interval_ms)
            self.timer.timeout.connect(self.request_analysis)
            self.guard = AnalysisInFlightGuard()
            self.demo_provider = DemoSnapshotProvider()
            self.mode = "stopped"
            self.telemetry_running = False
            self.spotify_available = False
            self.ui_interventions_enabled = False

        def start_live(self):
            from agent import runtime

            if self.mode == "demo":
                self.timer.stop()

            self.mode = "live"
            self.ui_interventions_enabled = False

            try:
                runtime.start_tracker(interval=1, quiet=True)
                self.telemetry_running = runtime.tracker_is_running()
            except Exception as exc:
                log_exception(
                    "desktop_tracker_start_failed",
                    exc,
                    logger_name="desktop"
                )
                self.telemetry_running = False
                self.error_raised.emit(str(exc))

            self.timer.start()
            self._emit_status()
            self.request_analysis()

        def start_demo(self):
            self._stop_tracker()
            self.demo_provider.reset()
            self.mode = "demo"
            self.telemetry_running = False
            self.spotify_available = False
            self.ui_interventions_enabled = False
            self.timer.start()
            self._emit_status()
            self.request_analysis()

        def cycle_demo_once(self):
            if self.mode != "demo":
                self.start_demo()
                return

            self.request_analysis()

        def stop(self):
            self.timer.stop()
            self.mode = "stopped"
            self._stop_tracker()
            self.telemetry_running = False
            self.spotify_available = False
            self._emit_status()

        def request_analysis(self):
            if self.mode == "stopped":
                return False

            if not self.guard.try_acquire():
                return False

            worker = AnalysisWorker(self.mode, self.demo_provider)
            worker.signals.snapshot_ready.connect(self._handle_snapshot)
            worker.signals.timeline_ready.connect(self._handle_timeline)
            worker.signals.error_raised.connect(self.error_raised.emit)
            worker.signals.finished.connect(self.guard.release)
            self.thread_pool.start(worker)
            return True

        def _handle_snapshot(self, snapshot):
            if self.mode == "stopped":
                return

            self.spotify_available = bool(snapshot.get("spotify_context"))

            if self.mode == "demo":
                self.telemetry_running = False
            else:
                self.telemetry_running = bool(
                    snapshot.get("telemetry_running")
                )

            snapshot.setdefault(
                "ui_interventions_enabled",
                self.ui_interventions_enabled,
            )
            snapshot.setdefault("privacy_mode", "local-only")
            snapshot["telemetry_running"] = self.telemetry_running

            self.snapshot_ready.emit(snapshot)
            self._emit_status()

        def _handle_timeline(self, timeline):
            if self.mode == "stopped":
                return

            self.timeline_ready.emit(timeline)

        def _stop_tracker(self):
            try:
                from agent import runtime

                runtime.stop_tracker()
            except Exception as exc:
                log_exception(
                    "desktop_tracker_stop_failed",
                    exc,
                    logger_name="desktop"
                )
                self.error_raised.emit(str(exc))

        def _emit_status(self):
            self.status_changed.emit(
                {
                    "mode": self.mode,
                    "telemetry": (
                        "running" if self.telemetry_running else "stopped"
                    ),
                    "telemetry_running": self.telemetry_running,
                    "spotify": (
                        "available"
                        if self.spotify_available
                        else "unavailable"
                    ),
                    "spotify_available": self.spotify_available,
                    "ui_interventions": (
                        "enabled"
                        if self.ui_interventions_enabled
                        else "disabled"
                    ),
                    "ui_interventions_enabled": (
                        self.ui_interventions_enabled
                    ),
                    "privacy_mode": "local-only",
                }
            )

else:

    class AgentController:
        def __init__(self, *args, **kwargs):
            raise RuntimeError(MISSING_PYSIDE6_MESSAGE)
