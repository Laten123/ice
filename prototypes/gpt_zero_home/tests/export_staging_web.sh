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
# Decode the original 16x16 tile atlas in the TEMP copy only. The public
# viewer uses the pixel raster pass; the atlas is reusable for later TileMap.
python3 "$PROJECT/tests/unpack_pixel_tile_atlas.py"

# Include an OFL-licensed, unmodified Simplified Chinese font in the
# TEMPORARY export only. Do not put font binaries or secrets in the repo.
# To avoid downloading when offline, set FANTASIA_CJK_FONT_LOCAL to the official
# .ttf file and FANTASIA_CJK_LICENSE_LOCAL to its original OFL.txt.
FONT_DIR="$PROJECT/art/fonts"
mkdir -p "$FONT_DIR"
FONT_FILE="$FONT_DIR/NotoSansSC-VF.ttf"
LICENSE_FILE="$FONT_DIR/OFL.txt"
if [[ "${FANTASIA_SKIP_CJK:-0}" != "1" ]]; then
  if [[ -n "${FANTASIA_CJK_FONT_LOCAL:-}" ]]; then
    : "${FANTASIA_CJK_LICENSE_LOCAL:?Specify the matching OFL license with FANTASIA_CJK_LICENSE_LOCAL}"
    cp -- "$FANTASIA_CJK_FONT_LOCAL" "$FONT_FILE"
    cp -- "$FANTASIA_CJK_LICENSE_LOCAL" "$LICENSE_FILE"
  else
    if ! command -v curl >/dev/null; then
      echo "[FAIL] curl is required to download the official OFL CJK font; alternatively provide FANTASIA_CJK_FONT_LOCAL." >&2
      exit 2
    fi
    echo "[FONT] Downloading official Noto Sans SC and OFL license into /tmp staging copy only"
    curl -fLSs --retry 2 --connect-timeout 10 --max-time 150 \
      'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf' -o "$FONT_FILE"
    curl -fLSs --retry 2 --connect-timeout 10 --max-time 30 \
      'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/OFL.txt' -o "$LICENSE_FILE"
  fi
  python3 - "$FONT_FILE" "$LICENSE_FILE" <<'PYFONT'
from pathlib import Path
import sys
font = Path(sys.argv[1])
license_file = Path(sys.argv[2])
if not font.is_file() or not 1_000_000 <= font.stat().st_size <= 40_000_000:
    raise SystemExit("[FAIL] Noto Sans SC source font missing or implausible size")
if font.open("rb").read(4) not in (b"\x00\x01\x00\x00", b"OTTO", b"true"):
    raise SystemExit("[FAIL] downloaded font does not look like TTF/OTF")
text = license_file.read_text(encoding="utf-8")
if "SIL OPEN FONT LICENSE" not in text or "Copyright" not in text:
    raise SystemExit("[FAIL] official font license is missing")
print("[FONT] Verified official font and full OFL license")
PYFONT
else
  echo "[FONT] Skipping CJK embed: Chinese may render as tofu boxes"
fi

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
# Distribute the full OFL terms together with the font embedded in index.pck.
if [[ -f "$LICENSE_FILE" ]]; then
  cp -- "$LICENSE_FILE" "$OUTPUT/font-license.txt"
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
