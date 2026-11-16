#!/usr/bin/env python3
"""CI-only setup for the independent 002 project: engine binary only.

The Web export templates are intentionally not downloaded here. The 002 test
suite runs headless and loads the bundled placeholder font at runtime, so the
editor import cache and Web templates are not required.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import urllib.request
import zipfile

VERSION = "4.6.3"
RELEASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
ENGINE_NAME = f"Godot_v{VERSION}-stable_linux.x86_64"
# From the official 4.6.3-stable/SHA512-SUMS.txt release manifest.
ENGINE_SHA512 = (
    "a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7"
    "d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c"
)


def verify(data: bytes, expected: str, name: str) -> None:
    actual = hashlib.sha512(data).hexdigest()
    if actual != expected:
        raise RuntimeError(f"Checksum mismatch for {name}: {actual}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    project = args.project.resolve()
    if not (project / "project.godot").is_file():
        parser.error("--project must point to the independent 002 project directory.")
    tools_dir = project / ".build-tools"
    engine_dir = tools_dir / "godot"
    engine_dir.mkdir(parents=True, exist_ok=True)
    engine_archive = tools_dir / (ENGINE_NAME + ".zip")
    with urllib.request.urlopen(f"{RELEASE}/{ENGINE_NAME}.zip", timeout=120) as response:
        engine_data = response.read()
    verify(engine_data, ENGINE_SHA512, engine_archive.name)
    engine_archive.write_bytes(engine_data)
    with zipfile.ZipFile(engine_archive) as archive:
        executable = engine_dir / ENGINE_NAME
        executable.write_bytes(archive.read(ENGINE_NAME))
        executable.chmod(0o755)
    print(f"Official {ENGINE_NAME}: SHA-512 verified")


if __name__ == "__main__":
    main()
