#!/usr/bin/env python3
"""Patch the known original V3 ZIP to form an isolated V4 archive.

No source image alteration; original PNG bytes verified after patching.
"""
from pathlib import Path
import zipfile
import hashlib
import shutil
import tempfile
import sys

BASE = Path(__file__).resolve().parents[1]
ARCHIVE_NAME = 'fantasia_first_home_25d_interactive.zip'
ROOT_NAME = 'fantasia_first_home_25d'
EXPECTED_SIZE = 3992641
EXPECTED_SHA = '821538f39beab8d541eea2f8d22abfe4a5a46682ed0b98775fb980e82950d5b0'
PATCHES = [
    'index.html', 'web/preview.js', 'web/ambient_25d.js',
    'scripts/first_home_25d.gd', 'scripts/home_25d_atmosphere.gd',
    'tests/ambient_browser_smoke.mjs', 'tests/ambient_godot_smoke.gd',
    'tools/export_25d_web.sh', 'V4_AMBIENCE_HANDOFF.md',
]

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def build(original_zip: Path, patch_dir: Path, output: Path):
    if original_zip.stat().st_size != EXPECTED_SIZE or sha(original_zip) != EXPECTED_SHA:
        raise ValueError('Original ZIP byte hash/size mismatch; aborting before patch')
    with tempfile.TemporaryDirectory(prefix='fantasia-v4-') as d:
        tmp=Path(d)
        with zipfile.ZipFile(original_zip) as z:
            if z.testzip() is not None: raise ValueError('Corrupt V3 archive')
            names=z.namelist()
            if any(Path(name).is_absolute() or '..' in Path(name).parts or not name.startswith(ROOT_NAME+'/') for name in names):
                raise ValueError('Unexpected or unsafe V3 archive member')
            z.extractall(tmp)
        root=tmp/ROOT_NAME
        old_pngs={p:sha(root/p) for p in ['art/home_25d_exterior.png', 'art/home_25d_interior.png']}
        for rel in PATCHES:
            src=patch_dir/rel
            if not src.is_file(): raise FileNotFoundError(str(src))
            dest=root/rel
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dest)
        for p,v in old_pngs.items():
            if sha(root/p)!=v: raise ValueError(f'Original art modified: {p}')
        output.parent.mkdir(parents=True,exist_ok=True)
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=7) as z:
            for p in sorted(root.rglob('*')):
                if p.is_file(): z.write(p, p.relative_to(tmp).as_posix())
    with zipfile.ZipFile(output) as z:
        if z.testzip() is not None: raise ValueError('V4 ZIP CRC failure')
    print(f'FANTASIA_V4_READY {output} bytes={output.stat().st_size} sha256={sha(output)}')
    print('Unchanged source artwork:',old_pngs)

if __name__=='__main__':
    if len(sys.argv)!=4:
        sys.exit('usage: apply_v4_patch.py <original.zip> <patch-dir> <output.zip>')
    build(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]))