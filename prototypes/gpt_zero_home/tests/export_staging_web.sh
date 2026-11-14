#!/usr/bin/env bash
# Build an entirely separate Godot Web staging export for the public observer.
# Run from ANY directory. Requires installed Godot 4.6.3 Web export templates.
# Never modifies main/rebuild/production; all changes are in fresh /tmp.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT" ]]; then
  echo "[FAIL] Godot editor not found; set GODOT_BIN to Godot 4.6.3." >&2
  exit 2
fi

ROOT="$(mktemp -d /tmp/fantasia-staging-web.XXXXXXXX)"
PROJECT="$ROOT/project"
OUTPUT="$ROOT/web"
mkdir -p "$PROJECT" "$OUTPUT"
cp -a "$SOURCE_PROJECT/." "$PROJECT/"

python3 - "$PROJECT/project.godot" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
raw = p.read_text(encoding="utf-8")
old = 'run/main_scene="res://scenes/public_viewer.tscn"'
new = 'run/main_scene="res://scenes/public_viewer_staging.tscn"'
if raw.count(old) != 1:
    raise SystemExit("[FAIL] unexpected main scene setting; not modifying project")
p.write_text(raw.replace(old, new), encoding="utf-8")
PY

# This preset is intentionally generated in /tmp only.
# No secrets, service URLs, tokens or production settings.
cat > "$PROJECT/export_presets.cfg" <<'EOF'
[preset.0]
name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""
script_export_mode=2

[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
EOF

echo "[INFO] Godot version: $("$GODOT" --version)"
echo "[INFO] All work stays in: $ROOT"
echo "[1/3] Import isolated staging project"
"$GODOT" --headless --path "$PROJECT" --editor --import --quit
echo "[2/3] Export single-threaded Godot Web"
if ! "$GODOT" --headless --path "$PROJECT" --export-release Web "$OUTPUT/index.html"; then
  echo "[FAIL] Web export failed. Install matching Godot 4.6.3 Web export templates, then rerun." >&2
  echo "[INFO] Production files were not changed; temp copy: $ROOT" >&2
  exit 1
fi
echo "[3/3] Inspect flat export package"
for ext in html js wasm pck; do
  if ! find "$OUTPUT" -maxdepth 1 -type f -name "*.$ext" -size +0c -print -quit | grep -q .; then
    echo "[FAIL] Missing Web export .$ext asset" >&2
    exit 1
  fi
done
if [[ ! -s "$OUTPUT/index.html" ]]; then
  echo "[FAIL] index.html missing" >&2
  exit 1
fi
echo "[PASS] Single-threaded Web staging export is ready"
echo "[WEB_DIR] $OUTPUT"
echo "[PREVIEW] python3 tests/preview_public_server.py --test-resident-id path-test --web-dir '$OUTPUT'"
echo "[INFO] Use Quick Tunnel to 127.0.0.1:8211 ONLY, never 8200"
