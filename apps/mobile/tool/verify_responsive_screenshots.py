#!/usr/bin/env python3
"""Fail CI if any required responsive screenshot is missing or corrupt."""

import argparse
from pathlib import Path
import struct
import zlib

VIEWPORTS = ((320, 640), (360, 800), (393, 873), (430, 932))
EXTENDED = ((320, 568), (375, 667), (393, 873), (440, 956),
            (360, 780), (600, 1024))


def verify(path, width, height):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: invalid PNG signature")
    offset, compressed, saw_header, saw_end = 8, bytearray(), False, False
    while offset < len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        expected_crc = struct.unpack_from(">I", data, offset + 8 + length)[0]
        if zlib.crc32(kind + payload) != expected_crc:
            raise ValueError(f"{path}: corrupt {kind!r} chunk")
        if kind == b"IHDR":
            if struct.unpack_from(">II", payload) != (width, height):
                raise ValueError(f"{path}: wrong viewport dimensions")
            saw_header = True
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            saw_end = True
        offset += length + 12
    if not saw_header or not saw_end or not zlib.decompress(compressed):
        raise ValueError(f"{path}: incomplete PNG")
    print(f"Verified {path}: {width}x{height}, {len(data)} bytes")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path,
                        default=Path("test-artifacts/acceptance"))
    parser.add_argument("--premium-flows", action="store_true")
    args = parser.parse_args()
    for width, height in VIEWPORTS:
        verify(args.directory / f"match-screen-{width}x{height}.png", width, height)
    for width, height in EXTENDED:
        verify(args.directory / f"extended-match-screen-{width}x{height}.png",
               width, height)

    if args.premium_flows:
        for name in ("home", "mode-selection", "classic-setup", "quick-setup",
                     "team-up-setup", "ai-setup", "dice-rolling", "pawn-selection",
                     "pawn-moving", "capture", "winning", "rematch"):
            verify(args.directory / f"flow-{name}.png", 393, 873)
        for width, height in (*VIEWPORTS, (320, 568)):
            verify(args.directory / f"team-up-match-{width}x{height}.png", width, height)
        for state in ("transferred", "winning"):
            verify(args.directory / f"team-up-{state}-393x873.png", 393, 873)


if __name__ == "__main__":
    main()
