#!/usr/bin/env python3
"""Export the actual authored V3 480x300 pixel surfaces to ordinary PNG files.

No Pillow, Godot or network dependency; standard-library only.
Reads the exact palette-indexed RLE constants the in-game Godot decoder uses.
These are *not* enlarged concept art renders or converted SVG screenshots.
"""
from __future__ import annotations
import argparse
import base64
import json
import re
import struct
import zlib
from pathlib import Path

HOME = Path(__file__).resolve().parents[1]
W, H = 480, 300
N = W * H
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

def _chunk(tag: bytes, data: bytes) -> bytes:
    payload = tag + data
    return struct.pack(">I", len(data)) + payload + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF)

def decode_authoring_script(path: Path):
    source = path.read_text(encoding="utf-8")
    colors = re.search(r"^const PALETTE := (\[[^\n]*\])$", source, re.M)
    packed = re.search(r'^const PIXELS := "([A-Za-z0-9+/=]+)"$', source, re.M)
    if not colors or not packed:
        raise ValueError(f"missing V3 indexed art constants: {path}")
    palette = json.loads(colors.group(1))
    if not 1 <= len(palette) <= 256 or any(not re.fullmatch(r"#[0-9a-fA-F]{6}", c) for c in palette):
        raise ValueError("unexpected color palette")
    binary = base64.b64decode(packed.group(1), validate=True)
    if len(binary) % 2 or len(binary) > N * 2:
        raise ValueError("invalid RLE bytes")
    out = bytearray()
    for run, index in zip(binary[0::2], binary[1::2]):
        if run == 0 or index >= len(palette):
            raise ValueError("invalid pixel run or palette index")
        out.extend(bytes([index]) * run)
        if len(out) > N:
            raise ValueError("run exceeds the fixed lot canvas")
    if len(out) != N:
        raise ValueError(f"incorrect fixed lot size: {len(out)} != {N}")
    return palette, bytes(out)

def _colors(palette, dusk):
    result = bytearray()
    for c in palette:
        r,g,b = bytes.fromhex(c[1:])
        if dusk:
            # Match GDScript's restrained dusk palette conversion.
            r = max(0, min(255, round((r / 255 * .76 + .09) * 255)))
            g = max(0, min(255, round((g / 255 * .69 + .055) * 255)))
            b = max(0, min(255, round((b / 255 * .76 + .12) * 255)))
        result.extend((r,g,b))
    return bytes(result)

def png_bytes(colors, indices):
    raw = b"".join(b"\x00" + indices[y*W:(y+1)*W] for y in range(H))
    header = struct.pack(">IIBBBBB", W, H, 8, 3, 0, 0, 0)
    return b"".join((
        PNG_SIGNATURE,
        _chunk(b"IHDR", header),
        _chunk(b"PLTE", colors),
        _chunk(b"IDAT", zlib.compress(raw, 9)),
        _chunk(b"IEND", b""),
    ))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate data only; write no PNGs")
    parser.add_argument("--output-dir", type=Path, default=HOME / "art" / "generated-v3")
    args = parser.parse_args()
    for name in ("exterior", "interior"):
        palette, indexed = decode_authoring_script(HOME / "scripts" / f"pixel_{name}_v3.gd")
        # Important: no map expansion in either export; same 480x300 pixels.
        for phase in ("day", "dusk"):
            data = png_bytes(_colors(palette, phase == "dusk"), indexed)
            if data[:8] != PNG_SIGNATURE:
                raise ValueError("invalid PNG signature")
            if not args.check:
                args.output_dir.mkdir(parents=True, exist_ok=True)
                dest = args.output_dir / f"first_home_{name}_{phase}.png"
                dest.write_bytes(data)
                print(f"[PNG] {dest} ({W}x{H}, {len(data)} bytes)")
    print("PIXEL_V3_SOURCE_OK: two authored scenes, fixed compact extent, no new lot")

if __name__ == "__main__":
    main()
