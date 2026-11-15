#!/usr/bin/env python3
"""Reconstitute the original 2.5D Godot ZIP from GitHub-hosted ASCII parts.

This package exists because the upload connector restricts large binary requests.
The final archive is byte-identical to the 2026-11-15 delivered ZIP.
No external downloads, credentials or network fetches are involved.
"""
from __future__ import annotations

import base64
import hashlib
import io
import re
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PARTS = HERE / "parts"
DEST = HERE / "fantasia_first_home_25d_interactive.zip"
EXPECTED_COUNT = 22
EXPECTED_BYTES = 3992641
EXPECTED_SHA256 = "821538f39beab8d541eea2f8d22abfe4a5a46682ed0b98775fb980e82950d5b0"

def main() -> None:
    parts = sorted(PARTS.glob("part-*.b64"))
    names = [f"part-{i:03}.b64" for i in range(EXPECTED_COUNT)]
    if [p.name for p in parts] != names:
        raise SystemExit(f"Missing/extra parts: expected {EXPECTED_COUNT}, got {len(parts)}")
    encoded = "".join(p.read_text(encoding="ascii").strip() for p in parts)
    if not re.fullmatch(r"[A-Za-z0-9+/]*={0,2}", encoded):
        raise SystemExit("Refusing malformed base64 data")
    data = base64.b64decode(encoded, validate=True)
    digest = hashlib.sha256(data).hexdigest()
    if len(data) != EXPECTED_BYTES or digest != EXPECTED_SHA256:
        raise SystemExit(f"Integrity failure: bytes={len(data)}, sha256={digest}")
    with zipfile.ZipFile(io.BytesIO(data), "r") as zf:
        if zf.testzip() is not None or len(zf.namelist()) != 19:
            raise SystemExit("Invalid ZIP entries or CRC")
        required = {
            "fantasia_first_home_25d/art/home_25d_exterior.png",
            "fantasia_first_home_25d/art/home_25d_interior.png",
            "fantasia_first_home_25d/project.godot",
            "fantasia_first_home_25d/DEEPSEEK_25D_HANDOFF.md",
        }
        if not required.issubset(set(zf.namelist())):
            raise SystemExit("Required Godot/image/handoff file missing")
    DEST.write_bytes(data)
    print(f"ZIP_READY: {DEST} bytes={len(data)} sha256={digest}")

if __name__ == "__main__":
    main()
