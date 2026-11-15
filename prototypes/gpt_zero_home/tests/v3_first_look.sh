#!/usr/bin/env bash
# V3 first-look validation and isolated Web export; NEVER deploy to production.
# Safe for a small Linux build host: all writes go to /tmp, not /main or 8080.
set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/.." && pwd)"
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT" ]]; then
  echo "[FAIL] Godot 4.6.3 not found; set GODOT_BIN." >&2
  exit 2
fi
if [[ "$("$GODOT" --version)" != 4.6.3* ]]; then
  echo "[FAIL] Expected Godot 4.6.3; found $("$GODOT" --version)" >&2
  exit 2
fi

WORK="$(mktemp -d /tmp/fantasia-v3-first-look.XXXXXXXX)"
cp -a "$ROOT/." "$WORK/project/"
PROJECT="$WORK/project"
echo "[V3] Isolated test copy: $PROJECT"

# Deterministic, original pixel data and four independent daylight/room PNGs.
python3 "$PROJECT/tools/export_pixel_art_v3.py" --check
python3 "$PROJECT/tools/export_pixel_art_v3.py" --output-dir "$WORK/png-preview"
python3 "$PROJECT/tests/unpack_pixel_tile_atlas.py"

"$GODOT" --headless --path "$PROJECT" --editor --import --quit
for case_name in \
    pixel_home_v3_smoke.gd \
    public_viewer_smoke.gd \
    home_room_smoke.gd \
    pixel_ground_smoke.gd \
    art_pack_smoke.gd; do
  echo "[TEST] $case_name"
  "$GODOT" --headless --path "$PROJECT" --script "res://tests/$case_name"
done
python3 "$PROJECT/tests/pixel_ground_source_smoke.py"
python3 "$PROJECT/tests/preview_public_server_smoke.py"

echo "[V3] Godot tests complete. Web export next; no public port opened."
# The original export helper copies to another /tmp directory and packages
# the required OFL-licensed CJK font. It NEVER changes the production server.
FANTASIA_BUILD_PROFILE=demo \
  GODOT_BIN="$GODOT" \
  bash "$PROJECT/tests/export_staging_web.sh"

echo "[PASS] V3 first-look staging build ready"
echo "[PIXEL_PREVIEWS] $WORK/png-preview"
echo "[NEXT] In the export helper's [WEB_DIR], use only the existing"
echo "       test-resident read-only proxy on 127.0.0.1:8211; not port 8200."
echo "[REMINDER] No deployment, no main merge, no extra land grant."
