#!/usr/bin/env python3
"""One fail-closed command for the V6 baseline and V7 Godot development tree."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def run(command, marker=None):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=120)
    print(result.stdout, end="", flush=True)
    if result.returncode or re.search(r"SCRIPT ERROR|Parse Error|SHADER ERROR|Failed loading resource|^ERROR:", result.stdout, re.M):
        raise SystemExit(f"CHECK_FAILED: {command}")
    if marker and marker not in result.stdout:
        raise SystemExit(f"CHECK_FAILED: missing success marker {marker}")


def main():
    run(["godot", "--version"], "4.6.3.stable")
    run([sys.executable, "tests/source_audit.py"], "SOURCE_AUDIT_OK")
    run([sys.executable, "tests/environment_layers_audit.py"], "ENVIRONMENT_LAYER_AUDIT_OK")
    for test, marker in [
        ("ambient_browser_smoke.mjs", "AMBIENT_BROWSER_SOURCE_OK"),
        ("environment_v5_smoke.mjs", "ENVIRONMENT_V5_BROWSER_OK"),
        ("environment_v6_smoke.mjs", "ENVIRONMENT_V6_BROWSER_OK"),
    ]:
        run(["node", f"tests/{test}"], marker)
    run(["bash", "-n", "tools/export_25d_web.sh"])
    run(["godot", "--headless", "--path", ".", "--editor", "--import", "--quit"])
    for test, marker in [
        ("first_home_25d_smoke.gd", "FIRST_HOME_25D_OK"),
        ("ambient_godot_smoke.gd", "AMBIENT_GODOT_OK"),
        ("environment_v5_smoke.gd", "ENVIRONMENT_V5_GODOT_OK"),
        ("environment_v6_smoke.gd", "ENVIRONMENT_V6_GODOT_OK"),
        ("resident_v7_smoke.gd", "RESIDENT_V7_GODOT_OK"),
    ]:
        run(["godot", "--headless", "--path", ".", "--script", f"res://tests/{test}"], marker)
    print("RUNTIME_V7_ALL_CHECKS_PASSED")


if __name__ == "__main__":
    main()
