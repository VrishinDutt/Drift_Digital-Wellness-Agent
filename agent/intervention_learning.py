import os
import sys

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from core.paths import data_path
from telemetry.log_store import load_json, save_json

LEARNING_FILE = data_path("intervention_learning.json")

DEFAULT_DATA = {
    "reflection": 0,
    "grounding": 0,
    "friction": 0,
    "regulation": 0
}

def load_learning():
    data = load_json(LEARNING_FILE, DEFAULT_DATA)

    for intervention_type, score in DEFAULT_DATA.items():
        data.setdefault(intervention_type, score)

    return data

def save_learning(data):
    save_json(LEARNING_FILE, data)

def update_effectiveness(intervention_type, success):

    data = load_learning()

    if intervention_type not in data:
        data[intervention_type] = 0

    if success:
        data[intervention_type] += 1
    else:
        data[intervention_type] -= 1

    save_learning(data)

def print_learning():

    data = load_learning()

    ranked = sorted(
        data.items(),
        key=lambda x: x[1],
        reverse=True
    )

    print("\n=== INTERVENTION EFFECTIVENESS ===\n")

    for intervention, score in ranked:

        print(f"{intervention}: {score}")

if __name__ == "__main__":

    update_effectiveness(
        "grounding",
        True
    )

    print_learning()
