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
DURATION_SECONDS = 1.6
FREQUENCY_HZ = 220.0
MAX_AMPLITUDE = 0.16


def breathing_envelope(position: float) -> float:
    """Soft in/out pulse between 0 and 1."""
    return math.sin(math.pi * position) ** 2


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

