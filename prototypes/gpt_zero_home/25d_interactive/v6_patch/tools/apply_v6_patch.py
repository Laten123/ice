#!/usr/bin/env python3
"""Repackage verified V5 Godot art + V6 code/small local lantern layers.

Produces a complete self-contained ZIP, without changing either approved
master image and without requiring Pillow/OpenCV at runtime or in CI.
"""
from pathlib import Path
import sys,zipfile,hashlib

ROOT='fantasia_first_home_25d/'
MUST_MATCH={
 'art/home_25d_exterior.png':'016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610',
 'art/home_25d_interior.png':'4ab46b9870e25e653f4fb94f79fa03c30cce27e55e6f24be724458e12895054b',
}
PATCHES=[
 'index.html','web/ambient_25d.js','web/preview.js',
 'scripts/home_25d_atmosphere.gd','shaders/home_25d_wind.gdshader',
 'art/layers/tree_lantern_clean_plate.png','art/layers/tree_lantern_sprite.png',
 'tests/environment_v6_smoke.mjs','tests/environment_v6_smoke.gd',
 'tools/build_lantern_layers.py','tools/apply_v6_patch.py',
 'V6_ENVIRONMENT_AUDIT.md',
]
def digest(data):return hashlib.sha256(data).hexdigest()
def main(previous,patch_dir,target):
 if not previous.is_file():raise SystemExit('V5 ZIP missing')
 if target.exists():raise SystemExit('Refusing to overwrite an existing ZIP: '+str(target))
 with zipfile.ZipFile(previous) as z:
  if z.testzip() is not None: raise SystemExit('Corrupt V5 ZIP')
  old=set(z.namelist())
  for rel,expected in MUST_MATCH.items():
   path=ROOT+rel
   if path not in old or digest(z.read(path))!=expected:
    raise SystemExit('Approved artwork changed or missing: '+path)
  for rel in ['V5_DYNAMIC_HANDOFF.md','tests/environment_v5_smoke.gd','shaders/home_25d_wind.gdshader']:
   if ROOT+rel not in old:raise SystemExit('V5 provenance missing: '+rel)
  output={name:z.read(name) for name in old if not name.endswith('/')}
 for rel in PATCHES:
  src=patch_dir/rel
  if not src.is_file():raise SystemExit('Patch missing: '+str(src))
  output[ROOT+rel]=src.read_bytes()
 for rel,expected in MUST_MATCH.items():
  if digest(output[ROOT+rel])!=expected:raise SystemExit('Source artwork changed!')
 target.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for name in sorted(output):z.writestr(name,output[name])
 with zipfile.ZipFile(target) as z:
  if z.testzip() is not None:raise SystemExit('Repacked ZIP invalid')
  for rel,expected in MUST_MATCH.items():
   if digest(z.read(ROOT+rel))!=expected:raise SystemExit('Artwork post-package drift')
 print(f'FANTASIA_V6_READY: {target}; bytes={target.stat().st_size}; sha256={digest(target.read_bytes())}')
 print('Original 2.5D exterior and interior art: SHA256 unchanged')

if __name__=='__main__':
 if len(sys.argv)!=4:raise SystemExit('usage: apply_v6_patch.py v5.zip v6_patch_dir out_v6.zip')
 main(*(Path(p) for p in sys.argv[1:]))