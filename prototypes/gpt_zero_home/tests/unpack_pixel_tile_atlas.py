#!/usr/bin/env python3
"""Decode the original 16px terrain PNG stored as a text-safe base64 asset.

Using this helper on an isolated project produces an actual Godot-importable
64x48 PNG, with 12 tiles of 16x16. It does not touch any server or API.
"""
import base64
import hashlib
import struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/tiles/first_home_terrain_16.png.base64"
TARGET = ROOT / "art/tiles/first_home_terrain_16.png"
EXPECTED = "8ab88a551d4e5fd12960de7f184db57153bbe432432b659201c5672c1a1406fd"
data = base64.b64decode(SOURCE.read_text("ascii").strip(), validate=True)
assert data.startswith(b"\x89PNG\r\n\x1a\n"), "not a PNG"
assert struct.unpack(">II", data[16:24]) == (64, 48), "not the expected tile atlas"
assert hashlib.sha256(data).hexdigest() == EXPECTED, "atlas bytes changed unexpectedly"
if __name__ == "__main__":
    # Explicit operation in the isolated directory; never replace an edited atlas.
    if TARGET.exists():
        assert TARGET.read_bytes() == data, "existing tile art differs: keep and review"
    else:
        TARGET.write_bytes(data)
    print("PIXEL_ATLAS_OK:", TARGET)
else:
    print("PIXEL_ATLAS_SOURCE_OK: 12 original 16x16 pixel tiles; SHA256 verified")
