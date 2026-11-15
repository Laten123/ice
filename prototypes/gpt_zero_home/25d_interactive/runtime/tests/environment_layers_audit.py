"""Pixel provenance and reproducibility checks for the V7 layer assets."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
HASHES = {
    "exterior": "016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610",
    "interior": "4ab46b9870e25e653f4fb94f79fa03c30cce27e55e6f24be724458e12895054b",
}
images = {}
for scene, expected in HASHES.items():
    path = ROOT / f"art/home_25d_{scene}.png"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected
    images[scene] = Image.open(path).convert("RGBA")
manifest = json.loads((ROOT / "data/environment_layer_manifest.json").read_text())
assert len(manifest["occluders"]) == 8
for layer in manifest["occluders"]:
    cutout = Image.open(ROOT / layer["texture"]).convert("RGBA")
    assert list(cutout.size) == layer["size"]
    x, y = layer["origin"]
    original = images[layer["scene"]].crop((x, y, x+cutout.width, y+cutout.height))
    assert ImageChops.difference(cutout.convert("RGB"), original.convert("RGB")).getbbox() is None
    assert set(cutout.getchannel("A").tobytes()) <= {0, 255}
water = Image.open(ROOT / manifest["water_texture"]).convert("RGBA")
delta = ImageChops.difference(water.convert("RGB"), images["exterior"].convert("RGB"))
assert ImageChops.multiply(delta, water.getchannel("A").convert("RGB")).getbbox() is None
assert sum(1 for a in water.getchannel("A").tobytes() if a) > 30000
for xy in [(1004,604), (587,651), (1149,117), (914,277), (180,785)]:
    assert water.getpixel(xy)[3] == 0, ("water touched land/boat", xy)
paths = list((ROOT / "art/layers/environment").glob("*.png")) + [ROOT / "data/environment_layer_manifest.json"]
before = {p: p.read_bytes() for p in paths}
subprocess.run([sys.executable, str(ROOT / "tools/build_environment_layers.py")], check=True)
assert all(p.read_bytes() == data for p, data in before.items()), "layer build is not deterministic"
export = (ROOT / "tools/export_25d_web.sh").read_text()
assert 'include_filter="data/*.json"' in export, "export would omit runtime layer manifests"
print("ENVIRONMENT_LAYER_AUDIT_OK: immutable masters, exact RGB cutouts, water guard, reproducible build")
