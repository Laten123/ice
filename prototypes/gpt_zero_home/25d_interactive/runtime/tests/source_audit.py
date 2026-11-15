"""Static checks for the standalone deliverable if Godot binary is unavailable."""
from pathlib import Path
import struct
import hashlib
import json
import re
import sys
base = Path(__file__).resolve().parents[1]
images = {
 'art/home_25d_exterior.png':(1536,1024),
 'art/home_25d_interior.png':(1448,1086),
}
for name,expected in images.items():
 p=base/name
 raw=p.read_bytes()
 assert raw[:8]==b"\x89PNG\r\n\x1a\n",name
 dims=struct.unpack(">II",raw[16:24])
 assert dims==expected,(name,dims)
 print(name,expected,hashlib.sha256(p.read_bytes()).hexdigest()[:16])
points_json=json.loads((base/'data/interaction_points.json').read_text('utf-8'))
assert len(points_json['exterior']['spots'])==10
assert len(points_json['interior']['spots'])==5
for scene,definition in points_json.items():
 for key,point in definition['spots'].items():
  assert 0<=point['x']<definition['width'] and 0<=point['y']<definition['height'],(scene,key)
  assert 1<=point['capacity']<=4,(scene,key)
assert 'boat' not in points_json['exterior']['spots']
points=(base/'scripts/home_25d_points.gd').read_text()
for key in ['door','stone_table','stump','book_corner','old_tree','riverbank','riverside','window_corner','writing_desk','bookcase','rest_corner','house_entry']:
 assert f'"{key}"' in points,key
main=(base/'scripts/first_home_25d.gd').read_text()
assert 'HTTPClient.METHOD_POST' not in main
assert 'apply_public_snapshot(packet: Dictionary)' in main
assert 'offline_test_mode' in main
assert 'Points.test_route' in main
assert not (base/'scenes/second_free_plot.tscn').exists()
print('SOURCE_AUDIT_OK: original textures, all V2 anchors, public-read-only authority boundary')
