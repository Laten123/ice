#!/usr/bin/env python3
"""Build reproducible 001 Windows and single-thread Web exports with Godot 4.6.3."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run_checked(command, env):
    completed = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, encoding="utf-8", errors="replace", env=env)
    print(completed.stdout, end="")
    if completed.returncode or "SCRIPT ERROR:" in completed.stdout or "\nERROR:" in completed.stdout:
        raise RuntimeError(f"Godot build failed (exit {completed.returncode}).")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN") or shutil.which("godot")
                        or shutil.which("godot4"))
    parser.add_argument("--target", choices=("all", "web", "windows"), default="all")
    args = parser.parse_args()
    if not args.godot:
        parser.error("Install Godot 4.6.3 or set GODOT_BIN to the executable path.")
    # Managed Linux workspaces can have a read-only home. Isolate Godot's
    # editor state instead of requiring writes outside this build invocation.
    runtime_state = tempfile.TemporaryDirectory(prefix="fantasy-village-001-build-")
    env = os.environ.copy()
    if os.name != "nt":
        for category in ("CONFIG", "DATA", "CACHE"):
            location = Path(runtime_state.name) / category.lower()
            location.mkdir()
            env[f"XDG_{category}_HOME"] = str(location)
    version = subprocess.check_output([args.godot, "--version"], text=True, env=env).strip()
    if not version.startswith("4.6.3.stable."):
        parser.error(f"Godot 4.6.3 stable is required, found {version}.")
    templates = ROOT / ".build-tools" / "templates"
    required = []
    if args.target in ("all", "web"):
        required.extend(("web_nothreads_debug.zip", "web_nothreads_release.zip"))
    if args.target in ("all", "windows"):
        required.extend(("windows_debug_x86_64.exe", "windows_release_x86_64.exe"))
    for filename in required:
        if not (templates / filename).is_file():
            parser.error("Export templates are missing. Run python tools/fetch_export_templates.py first.")
    run_checked([args.godot, "--headless", "--path", str(ROOT), "--editor", "--import"], env)
    if args.target in ("all", "web"):
        output = ROOT / "builds" / "web" / "index.html"
        output.parent.mkdir(parents=True, exist_ok=True)
        run_checked([args.godot, "--headless", "--path", str(ROOT), "--export-release", "Web", str(output)], env)
        # Godot emits its default logo PNG even when project splash is disabled.
        # Remove the hidden element and unused image from this placeholder build.
        html = output.read_text(encoding="utf-8")
        splash = re.search(r'<img\b[^>]*\bid="status-splash"[^>]*>', html)
        if splash and "show-image--false" in splash.group():
            output.write_text(html[:splash.start()] + html[splash.end():], encoding="utf-8")
            output.with_suffix(".png").unlink(missing_ok=True)
            output.with_suffix(".png.import").unlink(missing_ok=True)
    if args.target in ("all", "windows"):
        output = ROOT / "builds" / "windows" / "FantasyVillage.exe"
        output.parent.mkdir(parents=True, exist_ok=True)
        run_checked([args.godot, "--headless", "--path", str(ROOT), "--export-release", "Windows Desktop", str(output)], env)
    print(f"Build completed with {version}. Outputs: {ROOT / 'builds'}")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
