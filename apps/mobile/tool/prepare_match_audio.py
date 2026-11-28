#!/usr/bin/env python3
"""Reproduce local cue aliases and original short synthesized celebration chimes."""
import io
import math
from pathlib import Path
import shutil
import struct
import wave


def chime(notes, duration):
    rate = 16000
    samples = []
    for n in range(int(rate * duration)):
        t = n / rate
        segment = min(len(notes) - 1, int(t / duration * len(notes)))
        phase = (t * len(notes) / duration) % 1
        envelope = math.sin(math.pi * phase) ** 2
        samples.append(int(6500 * envelope * math.sin(2 * math.pi * notes[segment] * t)))
    stream = io.BytesIO()
    with wave.open(stream, 'wb') as out:
        out.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
    return stream.getvalue()


def main():
    root = Path(__file__).resolve().parents[1] / 'assets/audio'
    for target, source in {'dice_roll': 'rattle', 'pawn_hop': 'hop0', 'capture': 'impact'}.items():
        shutil.copyfile(root / (source + '.wav'), root / (target + '.wav'))
    (root / 'safe_star.wav').write_bytes(chime([659.25, 987.77], .18))
    (root / 'victory.wav').write_bytes(chime([523.25, 659.25, 783.99, 1046.5], .6))


if __name__ == '__main__':
    main()
