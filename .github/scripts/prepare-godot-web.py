#!/usr/bin/env python3
"""CI-only setup for the existing 001 project; downloads no Windows templates."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import runpy
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
# Hashes of the exact members obtained from the official 4.6.3 template archive.
# Ranged extraction verifies these member hashes instead of fetching the 1.26 GB
# archive and its whole-file checksum. zipfile also checks each member's CRC.
WEB_SHA256 = {
    "web_nothreads_debug.zip": "4a8a8ef7519637f7898fad25f09d3e466965e99c04e441682e1bc2d97a548922",
    "web_nothreads_release.zip": "1446f79dc12f60ce5d244c39fb6628ec298337ca5c4f91a16491feea72aa1bc9",
}


def verify(data: bytes, algorithm: str, expected: str, name: str) -> None:
    actual = hashlib.new(algorithm, data).hexdigest()
    if actual != expected:
        raise RuntimeError(f"Checksum mismatch for {name}: {actual}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    project = args.project.resolve()
    if not (project / "project.godot").is_file():
        parser.error("--project must point to the independent 001 project directory.")
    tools_dir = project / ".build-tools"
    engine_dir = tools_dir / "godot"
    engine_dir.mkdir(parents=True, exist_ok=True)
    engine_archive = tools_dir / (ENGINE_NAME + ".zip")
    with urllib.request.urlopen(f"{RELEASE}/{ENGINE_NAME}.zip", timeout=120) as response:
        engine_data = response.read()
    verify(engine_data, "sha512", ENGINE_SHA512, engine_archive.name)
    engine_archive.write_bytes(engine_data)
    with zipfile.ZipFile(engine_archive) as archive:
        executable = engine_dir / ENGINE_NAME
        executable.write_bytes(archive.read(ENGINE_NAME))
        executable.chmod(0o755)
    print(f"Official {ENGINE_NAME}: SHA-512 verified")

    # Reuse the project's existing standard-library HTTPS Range ZIP reader.
    module = runpy.run_path(str(project / "tools" / "fetch_export_templates.py"))
    template_url = f"{RELEASE}/Godot_v{VERSION}-stable_export_templates.tpz"
    template_dir = tools_dir / "templates"
    template_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(module["RemoteZip"](template_url)) as archive:
        for filename, expected in WEB_SHA256.items():
            data = archive.read("templates/" + filename)
            verify(data, "sha256", expected, filename)
            (template_dir / filename).write_bytes(data)
            print(f"Official {filename}: SHA-256 and ZIP CRC verified")
    print(f"Godot and the two Web templates are ready in {tools_dir}")


if __name__ == "__main__":
    main()

