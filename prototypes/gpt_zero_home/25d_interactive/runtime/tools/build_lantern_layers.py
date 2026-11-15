#!/usr/bin/env python3
"""Generate a local clean plate and animated lantern cutout from the approved art.

This is an offline artist-side build utility. Output PNGs are checked in; the
Godot/Web runtime needs no OpenCV, Pillow or Python dependencies. The master
exterior image is NEVER edited.
"""
from pathlib import Path
import hashlib
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'art/home_25d_exterior.png'
OUT=ROOT/'art/layers'
SHA='016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610'
if hashlib.sha256(SRC.read_bytes()).hexdigest()!=SHA: raise SystemExit('Original approved art mismatch')
OUT.mkdir(parents=True,exist_ok=True)
# Very small affected region: surrounding exterior artwork retains identical bytes.
box=(570,330,647,434)
orig=np.asarray(Image.open(SRC).convert('RGB'))
mask_img=Image.new('L',(orig.shape[1],orig.shape[0]),0)
d=ImageDraw.Draw(mask_img)
# Ring, roof, glass, feet: hand-mapped directly on 1536x1024 original.
d.polygon([(599,347),(608,347),(614,353),(615,364),(628,371),(635,379),(631,385),(630,415),(624,424),(591,424),(582,419),(580,385),(577,378),(586,372),(595,362)], fill=255)
# The lower hanging cord is redrawn every frame between fixed branch anchor
# and swinging lantern ring; upper rigid branch is retained.
d.polygon([(599,329),(608,329),(608,353),(599,354)],fill=255)
# All background reconstruction happens in the original image coordinates.
mask=np.array(mask_img)
filled=cv2.inpaint(cv2.cvtColor(orig,cv2.COLOR_RGB2BGR),mask,5,cv2.INPAINT_TELEA)
filled=cv2.cvtColor(filled,cv2.COLOR_BGR2RGB)
patch=Image.fromarray(filled[box[1]:box[3],box[0]:box[2]],'RGB')
patch.save(OUT/'tree_lantern_clean_plate.png',optimize=True)
# Slight one-pixel feather to retain the underlying soft edges without a halo.
lo=(571,346,643,431)
alpha=mask_img.crop(lo).filter(ImageFilter.GaussianBlur(.55))
sprite=Image.fromarray(orig[lo[1]:lo[3],lo[0]:lo[2]],'RGB').convert('RGBA')
sprite.putalpha(alpha)
sprite.save(OUT/'tree_lantern_sprite.png',optimize=True)
print('LANTERN_LAYERS_OK: ',box,lo)