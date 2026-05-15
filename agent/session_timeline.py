import os
import sys
from datetime import datetime

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from core.paths import data_path
from telemetry.log_store import load_json, save_json

TIMELINE_FILE = data_path("session_timeline.json")
MAX_TIMELINE_ENTRIES = 50

def load_timeline():
    return load_json(TIMELINE_FILE, [])

def save_timeline(timeline):
    save_json(TIMELINE_FILE, timeline)

def add_state(state, context, ccs):

    timeline = load_timeline()

    timeline.append({
        "timestamp": datetime.now().isoformat(),
        "state": state,
        "context": context,
        "ccs": ccs
    })

    timeline = timeline[-MAX_TIMELINE_ENTRIES:]

    save_timeline(timeline)

def print_timeline():

    timeline = load_timeline()

    print("\n=== SESSION TIMELINE ===\n")

    for entry in timeline:

        print(
            f"{entry['timestamp']} | "
            f"{entry['state']} | "
            f"{entry['context']} | "
            f"CCS={entry['ccs']}"
        )

if __name__ == "__main__":

    add_state(
        "Passive Drift",
        "Passive Consumption",
        65
    )

    print_timeline()
