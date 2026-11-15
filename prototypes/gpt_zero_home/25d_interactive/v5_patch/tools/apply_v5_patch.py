#!/usr/bin/env python3
"""Create V5 with new environment dynamics from verified GitHub V4 ZIP.

Neither approved PNG is recompressed, changed, or resized (same bytes in ZIP).
No model/network/server files touched. Archives are extracted to temporary dirs.
"""
import hashlib
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT_NAME = 'fantasia_first_home_25d'
EXPECTED_V4_SHA256 = 'abbdd2adbb9c2559a0353758f8039a60c60d01ecc5113975bdc8cebd4423b3f3'
EXPECTED_PNG = {
    'art/home_25d_exterior.png': '016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610',
    'art/home_25d_interior.png': '4ab46b9870e25e653f4fb94f79fa03c30cce27e55e6f24be724458e12895054b',
}
FILES = [
    'index.html', 'web/preview.js', 'web/ambient_25d.js',
    'scripts/first_home_25d.gd', 'scripts/home_25d_atmosphere.gd',
    'shaders/home_25d_wind.gdshader',
    'tests/ambient_browser_smoke.mjs', 'tests/environment_v5_smoke.mjs',
    'tests/environment_v5_smoke.gd', 'tools/export_25d_web.sh',
    'tools/apply_v5_patch.py', 'V5_DYNAMIC_HANDOFF.md',
]

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main(original_zip: Path, patch_dir: Path, output: Path):
    if not original_zip.is_file() or sha(original_zip) != EXPECTED_V4_SHA256:
        raise ValueError('V4 input ZIP SHA-256 mismatch; refusing unknown base')
    with tempfile.TemporaryDirectory(prefix='fantasia-v5-') as tmp:
        tmp_path = Path(tmp)
        with zipfile.ZipFile(original_zip) as archive:
            if archive.testzip() is not None:
                raise ValueError('V4 ZIP failed CRC')
            for item in archive.infolist():
                name = Path(item.filename)
                if name.is_absolute() or '..' in name.parts or not item.filename.startswith(ROOT_NAME + '/'):
                    raise ValueError('Unsafe archive member: ' + item.filename)
            archive.extractall(tmp_path)
        root = tmp_path/ROOT_NAME
        for rel,expected in EXPECTED_PNG.items():
            if sha(root/rel) != expected:
                raise ValueError('Approved image changed in V4 base: ' + rel)
        for rel in FILES:
            source = patch_dir/rel
            if not source.is_file():
                raise FileNotFoundError(source)
            target = root/rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        for rel,expected in EXPECTED_PNG.items():
            if sha(root/rel) != expected:
                raise ValueError('Approved image was modified: ' + rel)
        sums = []
        for f in sorted(root.rglob('*')):
            if f.is_file() and f.name != 'SHA256SUMS.txt':
                sums.append(f'{sha(f)}  {f.relative_to(root).as_posix()}')
        (root/'SHA256SUMS.txt').write_text('\n'.join(sums)+'\n', encoding='utf-8')
        output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
            for f in sorted(root.rglob('*')):
                if f.is_file():
                    archive.write(f, f.relative_to(tmp_path).as_posix())
    with zipfile.ZipFile(output) as check:
        if check.testzip() is not None:
            raise ValueError('New ZIP failed CRC')
        for rel,expected in EXPECTED_PNG.items():
            contents = check.read(f'{ROOT_NAME}/{rel}')
            if hashlib.sha256(contents).hexdigest() != expected:
                raise ValueError('Published ZIP changed approved image bytes')
    print('FANTASIA_V5_READY:', output)
    print('ZIP size:', output.stat().st_size)
    print('ZIP SHA256:', sha(output))
    print('Original 2.5D art: unchanged')

if __name__ == '__main__':
    if len(sys.argv) != 4:
        raise SystemExit('usage: apply_v5_patch.py <V4.zip> <v5_patch_dir> <out_v5.zip>')
    main(*(Path(a) for a in sys.argv[1:]))