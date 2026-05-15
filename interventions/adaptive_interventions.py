import random

INTERVENTIONS = {

    "Passive Drift": [
        {
            "type": "reflection",
            "message": "Still intentional?"
        },
        {
            "type": "reflection",
            "message": "Pause briefly before continuing."
        }
    ],

    "Compulsive Drift": [
        {
            "type": "grounding",
            "message": "Take one conscious breath."
        },
        {
            "type": "friction",
            "message": "Slow down before reopening."
        }
    ],

    "Overloaded": [
        {
            "type": "regulation",
            "message": "Your interaction pattern suggests fatigue."
        },
        {
            "type": "grounding",
            "message": "Take a short reset before continuing."
        }
    ],

    "Recurring Drift": [
        {
            "type": "reflection",
            "message": "A familiar drift pattern is showing up. Still the right direction?"
        },
        {
            "type": "friction",
            "message": "Take a moment to choose the next action deliberately."
        }
    ]
}

def choose_intervention(
    state,
    context,
    previous_states
):

    if state == "Focused":

        return {
            "type": "none",
            "message": "No intervention needed."
        }

    options = INTERVENTIONS.get(state)

    if not options:

        return {
            "type": "none",
            "message": "No intervention."
        }

    return random.choice(options)

if __name__ == "__main__":

    result = choose_intervention(
        "Compulsive Drift",
        "Passive Consumption",
        []
    )

    print(result)
