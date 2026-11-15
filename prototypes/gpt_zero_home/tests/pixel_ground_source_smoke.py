#!/usr/bin/env python3
"""Static companion checks for the first real pixel-material exterior pass.

This is not a substitute for Godot headless or Android Web tests.
"""
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
VIEW = (ROOT / "scripts/public_viewer.gd").read_text("utf-8")
TERRAIN = (ROOT / "scripts/pixel_ground.gd").read_text("utf-8")
assert 'const PixelGround = preload("res://scripts/pixel_ground.gd")' in VIEW
assert 'terrain.name = "PixelTerrainV1"' in VIEW
assert 'terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST' in VIEW
assert 'terrain.visible = scene_id == "exterior"' in VIEW
assert 'terrain.size = art.size' in VIEW
assert "const PIXEL_SIZE := Vector2i(480, 300)" in TERRAIN
assert "static func _bank_x" in TERRAIN and "static func _road_x" in TERRAIN
assert 'return ImageTexture.create_from_image(img)' in TERRAIN

ns = {"svg": "http://www.w3.org/2000/svg"}
for light in ("day", "dusk"):
    path = ROOT / f"art/home_{light}.svg"
    root = ET.parse(path).getroot()
    assert root.attrib["viewBox"] == "0 0 960 600"
    rectangles = root.findall(".//svg:rect", ns)
    assert any(r.attrib.get("fill") == "url(#sky)" and r.attrib.get("height") == "210" for r in rectangles)
    assert not any(r.attrib.get("fill") == "url(#grass)" for r in rectangles)
    path_nodes = root.findall(".//svg:path", ns)
    assert not any(p.attrib.get("fill") == "url(#water)" for p in path_nodes)
    assert not any("M600 379 C595 423" in p.attrib.get("d", "") for p in path_nodes)
    # Foreground cottage, tree and river highlights remain in the original
    # illustration for later independent replacements.
    assert len(path_nodes) > 10

print("PIXEL_GROUND_SOURCE_OK: valid day/dusk SVG, pixel ground beneath preserved structures")
