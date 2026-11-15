#!/usr/bin/env python3
"""Deterministic pixel extraction, never resampling or repainting the masters.

Pillow is an offline build/test dependency only. Runtime consumes committed PNGs.
Foreground masks are a first set of visual silhouettes, not collision geometry.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
HASHES = {
    "exterior": "016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610",
    "interior": "4ab46b9870e25e653f4fb94f79fa03c30cce27e55e6f24be724458e12895054b",
}


def build():
    definition = json.loads((ROOT / "data/environment_layers.json").read_text())
    images = {}
    for scene, digest in HASHES.items():
        path = ROOT / f"art/home_25d_{scene}.png"
        assert hashlib.sha256(path.read_bytes()).hexdigest() == digest
        images[scene] = Image.open(path).convert("RGBA")
    output = ROOT / "art/layers/environment"
    output.mkdir(parents=True, exist_ok=True)
    manifest = {"version": 1, "occluders": []}
    for item in definition["occluders"]:
        source = images[item["scene"]]
        mask = Image.new("L", source.size)
        ImageDraw.Draw(mask).polygon([tuple(p) for p in item["polygon"]], fill=255)
        box = mask.getbbox()
        layer = source.copy()
        layer.putalpha(mask)
        layer.crop(box).save(output / f'{item["id"]}.png')
        manifest["occluders"].append({
            "id": item["id"], "scene": item["scene"], "depth": item["depth"],
            "origin": list(box[:2]), "size": [box[2]-box[0], box[3]-box[1]],
            "texture": f'art/layers/environment/{item["id"]}.png',
        })
    source = images["exterior"]
    water = definition["water"]
    mask = Image.new("L", source.size)
    draw = ImageDraw.Draw(mask)
    draw.polygon([tuple(p) for p in water["polygon"]], fill=255)
    for polygon in water["exclude"]:
        draw.polygon([tuple(p) for p in polygon], fill=0)
    # Colour guard excludes warm banks, foam, flowers, timber and reflections.
    # Erosion reserves a safe sampling border around every retained water patch.
    pixels, alpha = source.load(), mask.load()
    for y in range(source.height):
        for x in range(source.width):
            r, g, b, _ = pixels[x, y]
            if not (b > r + 24 and g > r + 12 and b > g - 8):
                alpha[x, y] = 0
    mask = mask.filter(ImageFilter.MinFilter(7))
    # Nearest-filtered water needs no hidden RGB outside its binary mask.
    # Keep those pixels empty so the extra layer stays compact on disk.
    river = Image.new("RGBA", source.size)
    river.paste(source, (0, 0), mask)
    river.save(output / "river_surface.png")
    manifest["water_texture"] = "art/layers/environment/river_surface.png"
    (ROOT / "data/environment_layer_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f'ENVIRONMENT_LAYERS_BUILT: {len(manifest["occluders"])} silhouettes + water; master bytes unchanged')


if __name__ == "__main__":
    build()
