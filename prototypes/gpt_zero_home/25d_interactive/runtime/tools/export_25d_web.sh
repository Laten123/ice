#!/usr/bin/env bash
# Compile the standalone 2.5D Godot module in /tmp; never deploy or edit original.
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$(cd -- "$HERE/.." && pwd)"
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || true)}"
[[ -n "$GODOT" ]] || { echo '[FAIL] Godot 4.6.3 executable missing' >&2; exit 2; }
[[ "$("$GODOT" --version)" == 4.6.3* ]] || { echo '[FAIL] Expected Godot 4.6.3' >&2; exit 2; }
PROFILE="${FANTASIA_25D_PROFILE:-local}"
case "$PROFILE" in local|public) ;; *) echo '[FAIL] Profile must be local or public' >&2;exit 2;; esac
WORK="$(mktemp -d /tmp/fantasia-25d-${PROFILE}.XXXXXXXX)"
mkdir -p "$WORK/project" "$WORK/web"
cp -a "$SOURCE/." "$WORK/project/"
if [[ "$PROFILE" == public ]]; then
  python3 - "$WORK/project/project.godot" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1]); s=p.read_text()
old='run/main_scene="res://scenes/first_home_25d.tscn"'
new='run/main_scene="res://scenes/first_home_25d_staging.tscn"'
assert s.count(old)==1
p.write_text(s.replace(old,new))
PY
fi
# The original script has a documented optional CJK font; never embed an
# unlicensed font or silently generate Chinese tofu-box exports.
FONT="$WORK/project/art/fonts/NotoSansSC-VF.ttf"
LICENSE="$WORK/project/art/fonts/OFL.txt"
mkdir -p "$(dirname "$FONT")"
if [[ -n "${FANTASIA_CJK_FONT_LOCAL:-}" ]]; then
  : "${FANTASIA_CJK_LICENSE_LOCAL:?Specify matching SIL OFL license file}"
  cp -- "$FANTASIA_CJK_FONT_LOCAL" "$FONT"
  cp -- "$FANTASIA_CJK_LICENSE_LOCAL" "$LICENSE"
else
  command -v curl >/dev/null || { echo '[FAIL] Need curl or FANTASIA_CJK_FONT_LOCAL' >&2; exit 2; }
  curl -fLSs --retry 2 --connect-timeout 10 --max-time 150 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf' -o "$FONT"
  curl -fLSs --retry 2 --connect-timeout 10 --max-time 30 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/OFL.txt' -o "$LICENSE"
fi
python3 - "$FONT" "$LICENSE" <<'PY'
import sys
from pathlib import Path
f,l=map(Path,sys.argv[1:]); assert f.stat().st_size>1000000
assert f.open('rb').read(4) in (b'\x00\x01\x00\x00', b'OTTO',b'true')
assert 'SIL OPEN FONT LICENSE' in l.read_text()
PY
cat > "$WORK/project/export_presets.cfg" <<'CFG'
[preset.0]
name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="data/*.json"
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
CFG
echo '[IMPORT] in isolated copy:' "$WORK"
"$GODOT" --headless --path "$WORK/project" --editor --import --quit 2>&1 | tee "$WORK/import.log"
if grep -E 'SCRIPT ERROR|Parse Error|Failed loading resource|ERROR:.*script' "$WORK/import.log"; then
  echo '[FAIL] Godot import reported a script/resource failure' >&2; exit 1
fi
"$GODOT" --headless --path "$WORK/project" --script res://tests/first_home_25d_smoke.gd
"$GODOT" --headless --path "$WORK/project" --script res://tests/ambient_godot_smoke.gd
"$GODOT" --headless --path "$WORK/project" --script res://tests/environment_v5_smoke.gd
"$GODOT" --headless --path "$WORK/project" --script res://tests/environment_v6_smoke.gd
"$GODOT" --headless --path "$WORK/project" --script res://tests/resident_v7_smoke.gd
echo '[EXPORT] Web profile:' "$PROFILE"
"$GODOT" --headless --path "$WORK/project" --export-release Web "$WORK/web/index.html"
cp "$LICENSE" "$WORK/web/font-license.txt"
for ext in html js wasm pck; do
  find "$WORK/web" -maxdepth 1 -name "*.$ext" -size +0c -print -quit | grep -q . || {
    echo "[FAIL] missing Web export *.$ext" >&2; exit 1;
  }
done
printf '[PASS] Original 2.5D artwork and Godot interactions exported.\n[WEB_DIR] %s\n' "$WORK/web"
printf '[INFO] No public port opened; use ONLY isolated read-only 8211 proxy.\n'
