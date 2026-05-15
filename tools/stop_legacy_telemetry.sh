#!/bin/sh
set -eu

echo "Stopping legacy telemetry processes if present..."

pkill -f "telemetry[.]activity_tracker" || true
pkill -f "telemetry/activity_tracker[.]py" || true

echo "Done. Restart with: ./venv/bin/python -m agent.runtime"
