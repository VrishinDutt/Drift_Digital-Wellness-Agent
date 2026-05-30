from __future__ import annotations

import shutil
from datetime import datetime

from PySide6.QtCore import (
    QEasingCurve,
    QPropertyAnimation,
    QRectF,
    QSize,
    Qt,
    QTimer,
)
from PySide6.QtGui import QColor, QFont, QPainter, QPen
from PySide6.QtWidgets import (
    QFrame,
    QGraphicsDropShadowEffect,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QStackedWidget,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from core.paths import data_path
from desktop_app.agent_controller import AgentController
from telemetry.log_store import ensure_parent_dir

PRIVACY_NOTE = (
    "No screenshots, recording, keystrokes, clipboard, camera, mic, "
    "or page text are collected."
)


class StateRingWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._color = QColor("#8d99a6")
        self._ccs = 0
        self._pulse_on = False
        self.setFixedSize(136, 136)
        self.setSizePolicy(
            QSizePolicy.Policy.Fixed,
            QSizePolicy.Policy.Fixed
        )

        self._pulse_timer = QTimer(self)
        self._pulse_timer.setInterval(1200)
        self._pulse_timer.timeout.connect(self._toggle_pulse)
        self._pulse_timer.start()

    def set_state(self, color, ccs):
        self._color = QColor(color)
        self._ccs = int(ccs or 0)
        self.update()

    def _toggle_pulse(self):
        self._pulse_on = not self._pulse_on
        self.update()

    def paintEvent(self, event):
        del event

        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)

        side = min(self.width(), self.height()) - 24
        origin_x = (self.width() - side) / 2
        origin_y = (self.height() - side) / 2
        ring = QRectF(origin_x, origin_y, side, side)
        pulse_padding = 7 if self._pulse_on else 3

        pulse = QColor(self._color)
        pulse.setAlpha(34 if self._pulse_on else 18)
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(pulse)
        painter.drawEllipse(
            ring.adjusted(
                -pulse_padding,
                -pulse_padding,
                pulse_padding,
                pulse_padding,
            )
        )

        glass = QColor(9, 13, 18, 220)
        painter.setBrush(glass)

        ring_color = QColor(self._color)
        ring_color.setAlpha(220)
        painter.setPen(QPen(ring_color, 4))
        painter.drawEllipse(ring)

        inner = ring.adjusted(20, 20, -20, -20)
        inner_color = QColor(self._color)
        inner_color.setAlpha(28)
        painter.setBrush(inner_color)
        painter.setPen(Qt.PenStyle.NoPen)
        painter.drawEllipse(inner)

        score_font = QFont(self.font())
        score_font.setPointSize(23)
        score_font.setBold(True)
        painter.setFont(score_font)
        painter.setPen(ring_color)
        painter.drawText(ring, Qt.AlignmentFlag.AlignCenter, str(self._ccs))

        label_rect = QRectF(
            ring.left(),
            ring.center().y() + 20,
            ring.width(),
            18,
        )
        label_font = QFont(self.font())
        label_font.setPointSize(8)
        label_font.setBold(True)
        painter.setFont(label_font)
        painter.setPen(QColor("#a9b4bc"))
        painter.drawText(label_rect, Qt.AlignmentFlag.AlignCenter, "DRIFT")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.controller = AgentController(self)
        self.current_mode = "compact"
        self.current_status = self._default_status()
        self.current_snapshot = self._neutral_snapshot("Quiet until started.")
        self._size_animation = None

        self.setWindowTitle("Intentional")
        self.setWindowOpacity(0.97)
        self._build_ui()
        self._connect_controller()

        self.freshness_timer = QTimer(self)
        self.freshness_timer.setInterval(1000)
        self.freshness_timer.timeout.connect(
            lambda: self.update_freshness(self.current_snapshot)
        )
        self.freshness_timer.start()

        self.render_snapshot(self.current_snapshot)
        self._handle_status(self.current_status)
        self.set_compact_mode()

    def _build_ui(self):
        self.setStyleSheet(self._stylesheet())

        central = QWidget()
        outer = QVBoxLayout(central)
        outer.setContentsMargins(10, 10, 10, 10)

        self.stack = QStackedWidget()
        self.stack.addWidget(self._build_compact_view())
        self.stack.addWidget(self._build_expanded_view())
        outer.addWidget(self.stack)

        self.setCentralWidget(central)

    def _build_compact_view(self):
        view = QFrame()
        view.setObjectName("glassPanel")
        view.setGraphicsEffect(self._soft_shadow())

        layout = QVBoxLayout(view)
        layout.setContentsMargins(18, 16, 18, 16)
        layout.setSpacing(12)

        header = QHBoxLayout()
        title_block = QVBoxLayout()
        title_block.setSpacing(1)

        app_name = QLabel("Intentional")
        app_name.setObjectName("appName")
        title_block.addWidget(app_name)

        subtitle = QLabel("ambient attention vitals")
        subtitle.setObjectName("hudSubtitle")
        title_block.addWidget(subtitle)

        header.addLayout(title_block)
        header.addStretch()

        self.compact_mode_label = QLabel("idle")
        self.compact_mode_label.setObjectName("modePill")
        self.compact_mode_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.compact_mode_label.setMinimumHeight(26)
        header.addWidget(self.compact_mode_label)
        layout.addLayout(header)

        body = QHBoxLayout()
        body.setSpacing(16)

        self.state_ring = StateRingWidget()
        body.addWidget(
            self.state_ring,
            alignment=Qt.AlignmentFlag.AlignCenter,
        )

        vitals = QVBoxLayout()
        vitals.setSpacing(7)

        self.compact_state_label = QLabel("Neutral")
        self.compact_state_label.setObjectName("stateLabel")
        self.compact_state_label.setWordWrap(True)
        self.compact_state_label.setMinimumHeight(32)
        vitals.addWidget(self.compact_state_label)

        self.compact_context_label = QLabel("Context: Unknown Context")
        self.compact_context_label.setObjectName("compactMetric")
        self.compact_context_label.setWordWrap(True)
        vitals.addWidget(self.compact_context_label)

        self.compact_drift_label = QLabel("Drift: 0")
        self.compact_drift_label.setObjectName("compactMetric")
        vitals.addWidget(self.compact_drift_label)

        self.compact_latest_label = QLabel("Latest: Unknown")
        self.compact_latest_label.setObjectName("compactMetric")
        self.compact_latest_label.setWordWrap(True)
        vitals.addWidget(self.compact_latest_label)

        self.compact_freshness_label = QLabel("Updated: --")
        self.compact_freshness_label.setObjectName("freshnessLabel")
        self.compact_freshness_label.setMinimumHeight(22)
        vitals.addWidget(self.compact_freshness_label)
        vitals.addStretch()

        body.addLayout(vitals, 1)
        layout.addLayout(body)

        self.compact_intervention_label = QLabel("Quiet until started.")
        self.compact_intervention_label.setObjectName("interventionText")
        self.compact_intervention_label.setWordWrap(True)
        layout.addWidget(self.compact_intervention_label)

        controls = QHBoxLayout()
        controls.setSpacing(7)

        self.start_button = self._hud_button("Start")
        self.stop_button = self._hud_button("Stop")
        self.demo_button = self._hud_button("Demo")
        self.expand_button = self._hud_button("Expand")

        controls.addWidget(self.start_button)
        controls.addWidget(self.stop_button)
        controls.addWidget(self.demo_button)
        controls.addStretch()
        controls.addWidget(self.expand_button)
        layout.addLayout(controls)

        return view

    def _build_expanded_view(self):
        view = QFrame()
        view.setObjectName("glassPanel")
        view.setGraphicsEffect(self._soft_shadow())

        layout = QVBoxLayout(view)
        layout.setContentsMargins(22, 20, 22, 20)
        layout.setSpacing(14)

        header = QHBoxLayout()
        title_block = QVBoxLayout()
        title_block.setSpacing(1)

        title = QLabel("Intentional")
        title.setObjectName("appName")
        title_block.addWidget(title)

        subtitle = QLabel("expanded local diagnostics")
        subtitle.setObjectName("hudSubtitle")
        title_block.addWidget(subtitle)

        header.addLayout(title_block)
        header.addStretch()

        self.collapse_button = self._hud_button("Collapse")
        header.addWidget(self.collapse_button)
        layout.addLayout(header)

        scroll_area = QScrollArea()
        scroll_area.setObjectName("expandedScroll")
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QFrame.Shape.NoFrame)

        scroll_content = QWidget()
        content_layout = QVBoxLayout(scroll_content)
        content_layout.setContentsMargins(2, 4, 2, 4)
        content_layout.setSpacing(14)

        vitals_panel = QFrame()
        vitals_panel.setObjectName("innerPanel")
        vitals_grid = QGridLayout(vitals_panel)
        vitals_grid.setContentsMargins(16, 16, 16, 16)
        vitals_grid.setHorizontalSpacing(18)
        vitals_grid.setVerticalSpacing(12)

        self.status_label = self._value_label("Stopped")
        self.context_label = self._value_label("Unknown Context")
        self.ccs_label = self._value_label("0")
        self.reasoning_label = self._value_label("Neutral")
        self.intervention_label = self._value_label("Quiet until started.")
        self.spotify_label = self._value_label("Unavailable")
        self.last_updated_label = self._value_label("--")
        self.updated_ago_label = self._value_label("--")
        self.telemetry_freshness_label = self._value_label("Unknown")
        self.platform_label = self._value_label("Unknown")
        self.adapter_label = self._value_label("Unknown")
        self.permission_status_label = self._value_label("unknown")
        self.latest_telemetry_label = self._value_label("--")
        self.latest_app_label = self._value_label("Unknown")
        self.latest_title_label = self._value_label("Unknown")
        self.latest_context_label = self._value_label("Unknown Context")
        self.tracker_running_label = self._value_label("no")
        self.rows_used_label = self._value_label("0")
        self.ui_status_label = self._value_label("disabled")
        self.privacy_status_label = self._value_label("local-only")

        self._add_row(vitals_grid, 0, "Current status", self.status_label)
        self._add_row(vitals_grid, 1, "Dominant context", self.context_label)
        self._add_row(vitals_grid, 2, "CCS / drift score", self.ccs_label)
        self._add_row(vitals_grid, 3, "Reasoning state", self.reasoning_label)
        self._add_row(vitals_grid, 4, "Intervention", self.intervention_label)
        self._add_row(vitals_grid, 5, "Spotify / audio", self.spotify_label)
        self._add_row(vitals_grid, 6, "Last updated", self.last_updated_label)
        self._add_row(vitals_grid, 7, "Updated ago", self.updated_ago_label)
        self._add_row(vitals_grid, 8, "Telemetry", self.telemetry_freshness_label)
        self._add_row(vitals_grid, 9, "Platform", self.platform_label)
        self._add_row(vitals_grid, 10, "Telemetry adapter", self.adapter_label)
        self._add_row(vitals_grid, 11, "Permission / status", self.permission_status_label)
        self._add_row(vitals_grid, 12, "Latest telemetry", self.latest_telemetry_label)
        self._add_row(vitals_grid, 13, "Latest app", self.latest_app_label)
        self._add_row(vitals_grid, 14, "Latest title", self.latest_title_label)
        self._add_row(vitals_grid, 15, "Latest context", self.latest_context_label)
        self._add_row(vitals_grid, 16, "Tracker running", self.tracker_running_label)
        self._add_row(vitals_grid, 17, "Log rows used", self.rows_used_label)
        self._add_row(vitals_grid, 18, "UI interventions", self.ui_status_label)
        self._add_row(vitals_grid, 19, "Privacy mode", self.privacy_status_label)

        content_layout.addWidget(vitals_panel)

        timeline_label = QLabel("Session timeline")
        timeline_label.setObjectName("sectionLabel")
        content_layout.addWidget(timeline_label)

        self.timeline_preview = QTextEdit()
        self.timeline_preview.setObjectName("timelinePreview")
        self.timeline_preview.setReadOnly(True)
        self.timeline_preview.setMinimumHeight(132)
        self.timeline_preview.setPlainText("No timeline entries yet.")
        content_layout.addWidget(self.timeline_preview)

        controls = QHBoxLayout()
        controls.setSpacing(8)

        self.start_expanded_button = self._hud_button("Start Agent")
        self.stop_expanded_button = self._hud_button("Stop Agent")
        self.demo_expanded_button = self._hud_button("Demo Mode")
        self.refresh_button = self._hud_button("Refresh Now")
        self.reset_button = self._hud_button("Reset Session")

        controls.addWidget(self.start_expanded_button)
        controls.addWidget(self.stop_expanded_button)
        controls.addWidget(self.demo_expanded_button)
        controls.addStretch()
        controls.addWidget(self.refresh_button)
        controls.addWidget(self.reset_button)
        content_layout.addLayout(controls)

        privacy = QLabel(PRIVACY_NOTE)
        privacy.setObjectName("privacyNote")
        privacy.setWordWrap(True)
        privacy.setMinimumHeight(24)
        content_layout.addWidget(privacy)

        scroll_area.setWidget(scroll_content)
        layout.addWidget(scroll_area, 1)

        return view

    def _connect_controller(self):
        for button in (self.start_button, self.start_expanded_button):
            button.clicked.connect(self.controller.start_live)

        for button in (self.stop_button, self.stop_expanded_button):
            button.clicked.connect(self.controller.stop)

        for button in (self.demo_button, self.demo_expanded_button):
            button.clicked.connect(self.controller.cycle_demo_once)

        self.expand_button.clicked.connect(self.set_expanded_mode)
        self.collapse_button.clicked.connect(self.set_compact_mode)
        self.refresh_button.clicked.connect(self.refresh_now)
        self.reset_button.clicked.connect(self.reset_session)

        self.controller.snapshot_ready.connect(self.render_snapshot)
        self.controller.timeline_ready.connect(self.render_timeline)
        self.controller.status_changed.connect(self._handle_status)
        self.controller.error_raised.connect(self._handle_error)

    def set_compact_mode(self):
        self.current_mode = "compact"
        self.stack.setCurrentIndex(0)
        self.setMinimumSize(360, 390)
        self.setMaximumSize(460, 560)
        self._animate_window(QSize(390, 455))

    def set_expanded_mode(self):
        self.current_mode = "expanded"
        self.stack.setCurrentIndex(1)
        self.setMaximumSize(16777215, 16777215)
        self.setMinimumSize(780, 660)
        self._animate_window(QSize(900, 780))

    def render_snapshot(self, snapshot):
        self.current_snapshot = snapshot
        state = self._state_from_snapshot(snapshot)
        context = snapshot.get("context", "Unknown Context")
        ccs = snapshot.get("ccs", 0)
        intervention = self.format_intervention(snapshot)
        spotify = self.format_spotify_context(snapshot)
        latest_app = snapshot.get("latest_active_app", "Unknown")
        latest_title = snapshot.get("latest_window_title", "Unknown")
        latest_context = snapshot.get("latest_active_context", "Unknown Context")
        accent = self.state_to_color(state, context)

        self.compact_state_label.setText(state)
        self.compact_context_label.setText(f"Context: {context}")
        self.compact_drift_label.setText(f"Drift: {ccs}")
        self.compact_latest_label.setText(f"Latest app: {latest_app}")
        self.compact_intervention_label.setText(intervention)

        self.context_label.setText(str(context))
        self.ccs_label.setText(str(ccs))
        self.reasoning_label.setText(self._format_reasoning(snapshot))
        self.intervention_label.setText(intervention)
        self.spotify_label.setText(spotify)
        self.platform_label.setText(
            str(snapshot.get("telemetry_platform", "Unknown"))
        )
        self.adapter_label.setText(
            str(snapshot.get("telemetry_adapter", "Unknown"))
        )
        self.permission_status_label.setText(
            str(snapshot.get("telemetry_permission_status", "unknown"))
        )
        self.latest_app_label.setText(str(latest_app))
        self.latest_title_label.setText(str(latest_title))
        self.latest_context_label.setText(str(latest_context))
        self.latest_telemetry_label.setText(
            snapshot.get("latest_telemetry_timestamp") or "--"
        )
        self.rows_used_label.setText(
            str(snapshot.get("rows_used_for_analysis", 0))
        )
        self.tracker_running_label.setText(
            "yes" if snapshot.get("telemetry_running") else "no"
        )

        self.update_state_indicator(state, ccs, context)
        self._apply_accent(accent)
        self.update_freshness(snapshot)
        self.render_timeline(snapshot.get("timeline_preview", []))

    def update_freshness(self, snapshot):
        snapshot_timestamp = snapshot.get("snapshot_timestamp")
        snapshot_dt = self._parse_time(snapshot_timestamp)
        now = (
            datetime.now(snapshot_dt.tzinfo)
            if snapshot_dt and snapshot_dt.tzinfo
            else datetime.now()
        )

        if snapshot_dt:
            updated_seconds = max(0, int((now - snapshot_dt).total_seconds()))
            last_updated = snapshot_dt.strftime("%H:%M:%S")
            updated_text = self._format_age(updated_seconds)
        else:
            last_updated = "--"
            updated_text = "--"

        latest_dt = self._parse_time(snapshot.get("latest_telemetry_timestamp"))
        freshness = snapshot.get("telemetry_freshness", "unknown")

        if freshness != "demo" and latest_dt:
            latest_now = (
                datetime.now(latest_dt.tzinfo)
                if latest_dt.tzinfo
                else datetime.now()
            )
            latest_age = max(0, int((latest_now - latest_dt).total_seconds()))
            freshness = "live" if latest_age <= 10 else "stale"
        elif freshness != "demo":
            freshness = "unknown"

        freshness_text = self._format_freshness(freshness)
        self.compact_freshness_label.setText(
            f"Updated: {last_updated} | {freshness_text}"
        )
        self.last_updated_label.setText(last_updated)
        self.updated_ago_label.setText(updated_text)
        self.telemetry_freshness_label.setText(freshness_text)
        self._style_freshness_label(freshness)

    def render_timeline(self, entries):
        if not entries:
            self.timeline_preview.setPlainText("No timeline entries yet.")
            return

        lines = []
        for entry in entries[-7:]:
            if isinstance(entry, dict):
                timestamp = entry.get("timestamp", "")
                state = entry.get("state", "Unknown")
                context = entry.get("context", "Unknown Context")
                ccs = entry.get("ccs", "?")
                lines.append(f"{timestamp} | {state} | {context} | CCS={ccs}")
            else:
                lines.append(str(entry))

        self.timeline_preview.setPlainText("\n".join(lines))

    def refresh_now(self):
        requested = self.controller.request_analysis()
        if not requested and self.current_status.get("mode") == "stopped":
            self.compact_intervention_label.setText(
                "Start the agent or enter Demo Mode to refresh live state."
            )

    def reset_session(self):
        self.controller.stop()
        archived = self._archive_and_clear_session_files()
        message = (
            "Session reset. Previous logs were archived."
            if archived
            else "Session reset. Waiting for fresh telemetry."
        )
        self.current_status = self._default_status()
        self._handle_status(self.current_status)
        self.render_snapshot(self._neutral_snapshot(message))

    def state_to_color(self, state, context=None):
        combined = f"{state or ''} {context or ''}".lower()

        if "overloaded" in combined or "overload" in combined:
            return "#ff6b8a"

        if "idle" in combined or "paused" in combined:
            return "#7f97a8"

        if "compulsive" in combined:
            return "#ff9a47"

        if "passive" in combined:
            return "#f2c15b"

        if "assisted" in combined:
            return "#78b7ff"

        if "development" in combined:
            return "#5ea2ff"

        if "focused" in combined or "deep" in combined:
            return "#45d6ff"

        return "#9aa3ac"

    def update_state_indicator(self, state, ccs, context=None):
        color = self.state_to_color(state, context)
        self.state_ring.set_state(color, ccs)

    def format_spotify_context(self, snapshot):
        spotify = snapshot.get("spotify_context")
        if not spotify:
            return "Unavailable"

        track = spotify.get("track")
        artists = spotify.get("artists", [])

        if track and artists:
            return f"{track} by {', '.join(artists)}"

        if track:
            return track

        return "Available"

    def format_intervention(self, snapshot):
        intervention = snapshot.get("intervention", {})
        if isinstance(intervention, dict):
            return intervention.get("message") or "No intervention needed."
        return str(intervention or "No intervention needed.")

    def _handle_status(self, status):
        self.current_status = status
        mode = status.get("mode", "stopped")

        self.compact_mode_label.setText(mode)
        self.status_label.setText(self._format_mode(mode))
        self.ui_status_label.setText(
            status.get("ui_interventions", "disabled")
        )
        self.privacy_status_label.setText(
            status.get("privacy_mode", "local-only")
        )

        tracker_running = status.get("telemetry_running", False)
        self.tracker_running_label.setText("yes" if tracker_running else "no")

        self.start_button.setEnabled(mode != "live")
        self.start_expanded_button.setEnabled(mode != "live")
        self.stop_button.setEnabled(mode != "stopped")
        self.stop_expanded_button.setEnabled(mode != "stopped")

        demo_label = "Next" if mode == "demo" else "Demo"
        expanded_demo_label = "Next Demo State" if mode == "demo" else "Demo Mode"
        self.demo_button.setText(demo_label)
        self.demo_expanded_button.setText(expanded_demo_label)

    def _handle_error(self, message):
        self.compact_mode_label.setText("error")
        self.status_label.setText(f"Error: {message}")
        self.compact_intervention_label.setText(
            "Something paused in the backend. The HUD stayed local."
        )

    def closeEvent(self, event):
        self.controller.stop()
        super().closeEvent(event)

    def _archive_and_clear_session_files(self):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        targets = [
            (
                data_path("activity_log.json"),
                data_path(f"activity_log_reset_backup_{timestamp}.jsonl"),
                "",
            ),
            (
                data_path("session_timeline.json"),
                data_path(f"session_timeline_reset_backup_{timestamp}.json"),
                "[]\n",
            ),
        ]
        archived_any = False

        for source, backup, replacement in targets:
            ensure_parent_dir(source)

            if source.exists() and source.stat().st_size > 0:
                shutil.copy2(source, backup)
                archived_any = True

            with open(source, "w") as f:
                f.write(replacement)

        return archived_any

    def _neutral_snapshot(self, message):
        now = datetime.now().isoformat(timespec="seconds")
        return {
            "status": "idle",
            "context": "Unknown Context",
            "ccs": 0,
            "reasoning": {
                "state": "Neutral",
                "summary": "Waiting for fresh telemetry.",
            },
            "intervention": {
                "type": "none",
                "message": message,
            },
            "spotify_context": None,
            "timeline_preview": [],
            "ui_interventions_enabled": False,
            "privacy_mode": "local-only",
            "snapshot_timestamp": now,
            "latest_telemetry_timestamp": None,
            "latest_telemetry_age_seconds": None,
            "telemetry_freshness": "unknown",
            "telemetry_platform": "Unknown",
            "telemetry_adapter": "Unknown",
            "telemetry_permission_status": "unknown",
            "latest_active_app": "Unknown",
            "latest_window_title": "Unknown",
            "latest_active_context": "Unknown Context",
            "latest_is_idle": False,
            "rows_used_for_analysis": 0,
            "telemetry_running": False,
        }

    def _default_status(self):
        return {
            "mode": "stopped",
            "telemetry": "stopped",
            "telemetry_running": False,
            "spotify": "unavailable",
            "ui_interventions": "disabled",
            "privacy_mode": "local-only",
        }

    def _state_from_snapshot(self, snapshot):
        reasoning = snapshot.get("reasoning", {})
        if isinstance(reasoning, dict):
            return reasoning.get("state") or "Neutral"
        if reasoning:
            return str(reasoning)
        return "Neutral"

    def _format_reasoning(self, snapshot):
        reasoning = snapshot.get("reasoning", {})
        if isinstance(reasoning, dict):
            state = reasoning.get("state", "Neutral")
            summary = reasoning.get("summary") or reasoning.get("reason")
            if summary:
                return f"{state} - {summary}"
            return state
        return str(reasoning or "Neutral")

    def _format_mode(self, mode):
        if mode == "live":
            return "Live agent running"
        if mode == "demo":
            return "Demo mode"
        return "Stopped"

    def _format_age(self, seconds):
        if seconds < 2:
            return "now"
        if seconds < 60:
            return f"{seconds}s ago"
        minutes = seconds // 60
        return f"{minutes}m ago"

    def _format_freshness(self, freshness):
        if freshness == "live":
            return "Telemetry Live"
        if freshness == "stale":
            return "Telemetry Stale"
        if freshness == "demo":
            return "Demo Signal"
        return "Telemetry Unknown"

    def _parse_time(self, value):
        if not value:
            return None

        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return None

    def _style_freshness_label(self, freshness):
        color = {
            "live": "#68d6b3",
            "stale": "#f2c15b",
            "demo": "#78b7ff",
        }.get(freshness, "#9aa3ac")

        style = (
            f"color: {color};"
            "background-color: rgba(255, 255, 255, 18);"
            f"border: 1px solid {color};"
            "border-radius: 10px;"
            "padding: 5px 10px;"
            "min-height: 22px;"
        )
        self.telemetry_freshness_label.setStyleSheet(style)
        self.compact_freshness_label.setStyleSheet(
            f"color: {color}; font-size: 11px; padding: 2px 0px;"
        )

    def _apply_accent(self, color):
        self.compact_state_label.setStyleSheet(
            f"color: {color}; font-size: 24px; font-weight: 700;"
        )
        self.compact_intervention_label.setStyleSheet(
            "color: #edf4f7;"
            "background-color: rgba(255, 255, 255, 20);"
            "border: 1px solid rgba(255, 255, 255, 36);"
            f"border-left: 3px solid {color};"
            "border-radius: 14px;"
            "padding: 10px 12px;"
        )

    def _value_label(self, text):
        label = QLabel(text)
        label.setWordWrap(True)
        label.setObjectName("valueLabel")
        label.setMinimumHeight(26)
        label.setAlignment(
            Qt.AlignmentFlag.AlignLeft
            | Qt.AlignmentFlag.AlignVCenter
        )
        label.setTextInteractionFlags(
            Qt.TextInteractionFlag.TextSelectableByMouse
        )
        return label

    def _add_row(self, grid, row, name, value_widget):
        name_label = QLabel(name)
        name_label.setObjectName("fieldLabel")
        name_label.setMinimumHeight(26)
        name_label.setMinimumWidth(150)
        name_label.setAlignment(
            Qt.AlignmentFlag.AlignLeft
            | Qt.AlignmentFlag.AlignVCenter
        )
        grid.addWidget(name_label, row, 0)
        grid.addWidget(value_widget, row, 1)

    def _hud_button(self, text):
        button = QPushButton(text)
        button.setCursor(Qt.CursorShape.PointingHandCursor)
        button.setMinimumHeight(32)
        return button

    def _animate_window(self, size):
        self._size_animation = QPropertyAnimation(self, b"size", self)
        self._size_animation.setDuration(180)
        self._size_animation.setEasingCurve(QEasingCurve.Type.InOutCubic)
        self._size_animation.setStartValue(self.size())
        self._size_animation.setEndValue(size)
        self._size_animation.start()

    def _soft_shadow(self):
        shadow = QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(28)
        shadow.setOffset(0, 10)
        shadow.setColor(QColor(0, 0, 0, 120))
        return shadow

    def _stylesheet(self):
        return """
            QMainWindow, QWidget {
                background-color: #05070a;
                color: #edf4f7;
                font-family: "SF Pro Display", "SF Pro Text", "Segoe UI", BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
                font-size: 13px;
            }

            QFrame#glassPanel {
                background-color: rgba(18, 22, 28, 232);
                border: 1px solid rgba(255, 255, 255, 42);
                border-radius: 22px;
            }

            QFrame#innerPanel {
                background-color: rgba(255, 255, 255, 18);
                border: 1px solid rgba(255, 255, 255, 34);
                border-radius: 16px;
            }

            QLabel#appName {
                color: #f6fbfd;
                font-size: 22px;
                font-weight: 700;
            }

            QLabel#hudSubtitle {
                color: #8e9aa3;
                font-size: 11px;
                padding-top: 1px;
            }

            QLabel#modePill {
                color: #d8edf5;
                background-color: rgba(255, 255, 255, 18);
                border: 1px solid rgba(255, 255, 255, 32);
                border-radius: 11px;
                padding: 4px 10px;
                font-size: 11px;
            }

            QLabel#stateLabel {
                color: #f2fbff;
                font-size: 24px;
                font-weight: 700;
            }

            QLabel#compactMetric {
                color: #b3bec5;
                font-size: 12px;
                padding: 1px 0px;
            }

            QLabel#freshnessLabel {
                color: #9aa3ac;
                font-size: 11px;
                padding: 2px 0px;
            }

            QLabel#interventionText {
                color: #edf4f7;
                background-color: rgba(255, 255, 255, 20);
                border-radius: 14px;
                padding: 10px 12px;
            }

            QLabel#compactPrivacy, QLabel#privacyNote {
                color: #7e8991;
                font-size: 10px;
                padding-top: 2px;
            }

            QLabel#sectionLabel {
                color: #edf4f7;
                font-weight: 700;
                padding-top: 4px;
            }

            QLabel#fieldLabel {
                color: #8e9aa3;
                font-size: 12px;
                padding: 3px 0px;
            }

            QLabel#valueLabel {
                color: #edf4f7;
                font-size: 13px;
                padding: 3px 0px;
            }

            QPushButton {
                color: #edf4f7;
                background-color: rgba(255, 255, 255, 18);
                border: 1px solid rgba(255, 255, 255, 34);
                border-radius: 11px;
                padding: 6px 12px;
                font-size: 12px;
            }

            QPushButton:hover {
                background-color: rgba(255, 255, 255, 30);
                border-color: rgba(255, 255, 255, 56);
            }

            QPushButton:disabled {
                color: #68737b;
                background-color: rgba(255, 255, 255, 10);
                border-color: rgba(255, 255, 255, 20);
            }

            QTextEdit#timelinePreview {
                color: #c2ccd2;
                background-color: rgba(0, 0, 0, 76);
                border: 1px solid rgba(255, 255, 255, 28);
                border-radius: 14px;
                padding: 10px;
                selection-background-color: rgba(120, 183, 255, 70);
            }

            QScrollArea#expandedScroll {
                background: transparent;
                border: none;
            }
        """
