#!/usr/bin/env bash
# Run in the Godot 4.6.3 cloud environment from the repository root.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT" ]]; then
  echo "ERROR: Godot binary not found. Set GODOT_BIN to the Godot 4.6.3 executable." >&2
  exit 2
fi

echo "[smoke] Godot version:"
"$GODOT" --version
echo "[smoke] Resource import and script parse:"
"$GODOT" --headless --path . --editor --import --quit 2>&1 | tee /tmp/fantasia-import.log
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:.*[Ss]cript' /tmp/fantasia-import.log; then
  echo "ERROR: Godot import found script errors" >&2
  exit 1
fi

echo "[smoke] Scene and terrain checks:"
"$GODOT" --headless --path . --script res://tests/smoke.gd
echo "[smoke] Passed"
