#!/usr/bin/env python3
"""Generate tiny local WAV placeholders for Drift Native.

This script uses only the Python standard library. It does not download audio,
call cloud APIs, use Apple Music content, copy Endel assets, or inspect any
private system data.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 8_000
DURATION_SECONDS = 4.0
FREQUENCY_HZ = 330.0
MAX_AMPLITUDE = 0.32


def breathing_envelope(position: float) -> float:
    """Soft pulsing fade between 0 and 1."""
    fade = math.sin(math.pi * position) ** 0.5
    pulse = 0.55 + 0.45 * (math.sin(2 * math.pi * 0.5 * DURATION_SECONDS * position) ** 2)
    return fade * pulse


def generate_breathing_cue(output_path: Path) -> None:
    frame_count = int(SAMPLE_RATE * DURATION_SECONDS)

    with wave.open(str(output_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)

        for frame_index in range(frame_count):
            position = frame_index / max(frame_count - 1, 1)
            envelope = breathing_envelope(position)
            sample = math.sin(2 * math.pi * FREQUENCY_HZ * frame_index / SAMPLE_RATE)
            value = int(sample * envelope * MAX_AMPLITUDE * 32767)
            wav_file.writeframesraw(struct.pack("<h", value))


def main() -> None:
    output_path = Path(__file__).with_name("breathing_cue.wav")
    generate_breathing_cue(output_path)
    print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
