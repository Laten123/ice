"""Reproducible project derivatives of licensed source art. Pillow only, nearest pixels."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json, random, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/derived/home_v3';OUT.mkdir(parents=True,exist_ok=True)
source=(ROOT/'docs/art-review/round2/build_samples.py').read_text().split('# OUTDOOR')[0]
ns={'__file__':str(ROOT/'docs/art-review/round2/build_samples.py')};exec(source,ns)
asset=ns['asset'];F=ns['F'];C=ns['C'];I=ns['I'];P=ns['P'];used=ns['used']
def save(im,n):im.save(OUT/(n+'.png'));return n
for k in ['house','pine','bench','rock','bed','bookcase','desk','chair','lamp','plant']:save(ns[k],k)
save(ns['rug'].crop((12,8,60,44)),'rug')
# Project-drawn interior window in source-derived wood/glass palette, no exterior flowerbox.
win=Image.new('RGBA',(40,28));d=ImageDraw.Draw(win);d.rectangle((1,1,38,25),fill='#59483f');d.rectangle((4,4,35,23),fill='#b8d2c8');d.rectangle((7,5,32,21),fill='#dce8c6');d.rectangle((18,3,21,24),fill='#96765c');d.rectangle((3,13,36,15),fill='#96765c');d.rectangle((0,25,39,27),fill='#bf9977');save(win,'window')
# Wood plank floor: derived palette, long staggered planks, no brick texture.
floor=Image.new('RGBA',(224,176),'#b08b68');d=ImageDraw.Draw(floor)
for y in range(16,160,12):
 d.line((16,y,207,y),fill='#997553');d.line((16,y+1,207,y+1),fill='#c5a27b')
 for x in range(16+(48 if (y//12)%2 else 0),208,96):d.line((x,y,x,y+11),fill='#a17d5a')
for rect in [(0,0,224,16),(0,16,16,160),(208,16,224,160),(0,160,96,176),(128,160,224,176)]:d.rectangle(rect,fill='#e2d6be',outline='#88684f',width=2)
# Pixel contact shadows stay below furniture, not blurred screen overlays.
shade=Image.new('RGBA',floor.size);sd=ImageDraw.Draw(shade)
for box in [(24,86,79,99),(169,65,204,76),(106,57,143,68),(114,78,135,89),(166,124,199,136),(137,137,158,147),(190,157,206,166)]:sd.ellipse(box,fill=(70,53,42,40))
floor=Image.alpha_composite(floor,shade)
save(floor,'interior_ground')
# Ground tiles, colored patches intentionally follow borders and worn routes.
ground=Image.new('RGBA',(416,272),'#a9b982');d=ImageDraw.Draw(ground)
# Coherent broad vegetation variations with irregular/dithered transitions.
import math
for y in range(272):
 for x in range(416):
  v=math.sin(x*.029+y*.017)*2+math.cos(y*.041-x*.011)*2
  noise=((x*17+y*29)%7-3)*.32
  ground.putpixel((x,y),(int(169+v+noise),int(185+v+noise),int(130+v+noise),255))
rng=random.Random(303)
for i in range(700):
 x,y=rng.randrange(416),rng.randrange(272)
 if x<126 or x>286 or y>210:
  col=rng.choice(['#a5b47d','#9fb079','#b0bf88']);d.line((x,y,x+1,y),fill=col)
for x,y,w,h in [(176,128,3,9),(96,176,6,2),(304,176,4,4)]:ns['rect_tiles'](ground,'soil' if x==304 else 'path',x,y,w,h)
# Pond banks: stepped non-rectangular wet-earth shoreline and underwater depth.
pond=[(45,216),(57,207),(88,211),(100,225),(95,242),(76,249),(50,242),(41,229)]
d=ImageDraw.Draw(ground);d.polygon(pond,fill='#8b8e6b');d.line(pond+[pond[0]],fill='#b8b48b',width=2)
# Earth clods and raised rows replace the source tile's plank-like long stripes.
d.polygon([(305,177),(365,177),(368,181),(367,236),(364,239),(306,238),(303,234),(304,181)],fill='#90704e',outline='#7b694b')
soil_rng=random.Random(491)
for i in range(210):
 x,y=soil_rng.randrange(306,366),soil_rng.randrange(180,237)
 d.line((x,y,x+soil_rng.randrange(1,3),y),fill=soil_rng.choice(['#987751','#a28259','#806445']))
for y in [200,216,232]:
 d.polygon([(308,y-5),(312,y-8),(362,y-8),(365,y-4),(362,y),(311,y)],fill='#a17c52')
 for x in range(311,363,7):d.line((x,y,x+4,y),fill='#6f573e');d.point((x+1,y-5),fill='#bb9669')
for row,k in enumerate(['carrot','tomato','wheat']):
 for col in range(3):
  st=[2,3,4][col];crop=asset(F+f'crops/{k}/{k}-{st}-'+{2:'sprout',3:'growing',4:'ready'}[st]+'.png');ground.alpha_composite(crop,(312+col*16,184+row*16-(crop.height-16)))
for x,y in [(16,16),(32,16),(48,16),(64,16),(320,250),(336,250),(352,250)]:ground.alpha_composite(asset(F+'fences/fence-h-post.png',tone='wood'),(x,y))
for x,y in [(113,151),(132,153),(268,152),(286,157),(366,190)]:ground.alpha_composite(asset(F+'props/flowers.png'),(x,y))
for x,y in [(28,111),(42,153),(76,133),(341,146),(366,218),(290,250)]:ground.alpha_composite(asset(C,(7,105,27,120),'green'),(x,y))
# Worn doorstep, eave/contact shadows, natural pond reeds.
shade=Image.new('RGBA',ground.size);sd=ImageDraw.Draw(shade)
sd.polygon([(151,130),(280,130),(286,146),(155,146)],fill=(52,49,37,55))
for box in [(28,72,80,83),(74,111,126,122),(331,85,383,96),(359,156,411,167),(78,187,113,196)]:sd.ellipse(box,fill=(49,63,38,36))
ground=Image.alpha_composite(ground,shade);d=ImageDraw.Draw(ground)
d.rectangle((187,140,215,143),fill='#b7ad8b');d.line((186,144,216,144),fill='#887f65');d.line((188,139,214,139),fill='#d8c9a5')
for x,y in [(44,235),(91,214),(100,236),(53,208)]:
 d.line((x,y,x-2,y-6),fill='#697c54');d.line((x+1,y,x+2,y-8),fill='#788b5b');d.line((x+2,y,x+4,y-4),fill='#b4c18a')
save(ground,'exterior_ground')
# Real sequential water frames from original 13-frame strip, bounded to shoreline.
strip=asset('animations/animated-flowing-water/water_strip13.png',tone='water');waterframes=[]
for n in range(13):
 im=Image.new('RGBA',(64,48));tile=strip.crop((16*n,0,16*n+16,16))
 for y in range(0,48,16):
  for x in range(0,64,16):im.alpha_composite(tile,(x,y))
 mask=Image.new('L',im.size);m=ImageDraw.Draw(mask);m.polygon([(12,7),(23,3),(45,7),(55,20),(50,34),(32,40),(10,33),(6,21)],fill=255);im.putalpha(mask)
 dr=ImageDraw.Draw(im);dr.line((25,30,40,30),fill='#6b9da1');dr.line((29,31,44,31),fill='#6b9da1');save(im,f'water_{n}')
# Authored smoke frames, crown sway and flowers reuse source masks/pixels.
for n in range(6):
 smoke=Image.new('RGBA',(24,40));dr=ImageDraw.Draw(smoke)
 for k in range(3):
  cy=32-((n*3+k*11)%34);cx=10+(k%2)*3+(n//2)%3;dr.ellipse((cx-4,cy-3,cx+3,cy+3),fill=(235,231,210,125-k*22));dr.rectangle((cx-2,cy-4,cx+1,cy+3),fill=(235,231,210,125-k*22))
 save(smoke,f'smoke_{n}')
for n,dx in enumerate([0,1,0,-1]):
 tree=ns['pine'];im=Image.new('RGBA',(58,64));im.alpha_composite(tree.crop((0,48,56,64)),(1,48));im.alpha_composite(tree.crop((0,0,56,48)),(1+dx,0));save(im,f'tree_{n}')
for n in range(4):
 im=asset(F+'props/flowers.png');im=im.transform(im.size,Image.Transform.AFFINE,(1,0,0,0,1,0),Image.Resampling.NEAREST);im.putpixel((6+n%2,5),(243,218,166,255));save(im,f'flowers_{n}')
# Portable skin frames, grounded at (16,36); identity is never part of these names.
base=Image.open(ROOT/'assets/vendor'/P).convert('RGBA')
def body(frame):
 im=Image.new('RGBA',(32,40));im.alpha_composite(frame,(8,12));return im
for direction in range(4):
 for n in range(6):save(body(base.crop((n*16,(direction+4)*24,n*16+16,(direction+5)*24))),f'walk_{direction}_{n}')
 for n in range(2):
  f=base.crop((0,direction*24,16,(direction+1)*24))
  if n and direction==0:
   dr=ImageDraw.Draw(f);dr.rectangle((4,10,6,11),fill='#f2d0b5');dr.rectangle((9,10,11,11),fill='#f2d0b5');dr.line((4,11,6,11),fill='#665244');dr.line((9,11,11,11),fill='#665244')
  if n and direction!=0:
   original=f.copy();f=Image.new('RGBA',(16,24));f.alpha_composite(original.crop((0,0,16,18)),(0,-1));f.alpha_composite(original.crop((0,17,16,24)),(0,17))
  save(body(f),f'idle_{direction}_{n}')
front=base.crop((0,0,16,24))
for phase in ['sit','read','rest','tea']:
 for n in range(4):
  f=front.copy();dr=ImageDraw.Draw(f)
  if phase in ['sit','read','tea']:
   dr.rectangle((2,17,13,23),fill=(0,0,0,0));dr.rectangle((3,17,12,19),fill='#405a69');dr.rectangle((3,20,5,21),fill='#735346');dr.rectangle((10,20,12,21),fill='#735346')
  if phase=='read':
   dr.rectangle((2,12,14,17),fill='#69503c');dr.rectangle((3,12,8,16),fill='#f2e1b1');dr.rectangle((9,12,13,16),fill='#e1ce9f');dr.line((9 if n%2 else 8,12,8,16),fill='#b7a47e');dr.point((2,14),fill='#ecc6a0');dr.point((14,14),fill='#ecc6a0')
  elif phase=='rest':
   f=front.crop((0,0,16,15));dr=ImageDraw.Draw(f);dr.rectangle((4,10,6,11),fill='#f2d0b5');dr.rectangle((9,10,11,11),fill='#f2d0b5');dr.line((4,11,6,11),fill='#6a4f3c');dr.line((9,11,11,11),fill='#6a4f3c');f=body(f);f= f.transform(f.size,Image.Transform.AFFINE,(1,0,0,0,1,-(1 if n==2 else 0)),Image.Resampling.NEAREST)
  elif phase=='tea':dr.rectangle((10,12-(n%2),14,15-(n%2)),fill='#e9ddbf');dr.point((14,13-(n%2)),fill='#97755d')
  if phase!='rest':f=body(f)
  save(f,f'{phase}_{n}')
for n in range(3):
 im=Image.new('RGBA',(32,40));im.alpha_composite(front,(8,12+n*2));save(im,f'sit_down_{n}')
# Furniture occlusion layer is a literal crop from original bed, same native scale.
save(ns['bed'].crop((4,27,49,57)),'blanket')
# Shadow and chimney are project-authored pixel derivatives, documented separately.
chim=Image.new('RGBA',(12,21));dd=ImageDraw.Draw(chim);dd.rectangle((2,2,10,20),fill='#887465');dd.rectangle((0,0,11,3),fill='#b19a80')
for y in [7,12,17]:dd.line((3,y,9,y),fill='#655b54')
save(chim,'chimney')
# Seat fronts are separate occluders, not whole sprites covering the resident.
save(ns['chair'].crop((0,16,19,23)),'chair_front')
save(ns['bench'].crop((0,10,31,15)),'bench_front')
tea=Image.new('RGBA',(32,25));dd=ImageDraw.Draw(tea);dd.rectangle((5,13,8,24),fill='#80634e');dd.rectangle((24,13,27,24),fill='#80634e');dd.ellipse((0,2,31,18),fill='#a78260',outline='#725b49',width=2);dd.rectangle((13,5,18,10),fill='#f0e2be');dd.point((19,7),fill='#f0e2be');save(tea,'tea_table')
# Hand-edited knee folding frames, not merely translating a standing sprite.
for n in range(3):
 f=front.copy();dr=ImageDraw.Draw(f)
 if n:
  dr.rectangle((2,17,13,23),fill=(0,0,0,0));dr.rectangle((3,17,12,20-n),fill='#405a69');dr.rectangle((2,20,5,21),fill='#735346');dr.rectangle((10,20,13,21),fill='#735346')
 im=Image.new('RGBA',(32,40));im.alpha_composite(f,(8,12+n));save(im,f'sit_down_{n}')
for phase in ['open_book','close_book']:
 for n in range(3):
  im=Image.open(OUT/'sit_0.png').convert('RGBA');dr=ImageDraw.Draw(im);width=[3,7,12][n if phase=='open_book' else 2-n];left=16-width//2
  dr.rectangle((left,24,left+width,29),fill='#72553d');dr.rectangle((left+1,24,left+width-1,28),fill='#eedcb0');dr.line((16,24,16,28),fill='#a68c60');save(im,f'{phase}_{n}')

# Final provenance describes actual runtime inputs, not unused helper experiments.
source_assets=[v for v in used.values() if v['path'] not in ['assets/vendor/'+P,'assets/vendor/'+ns['D']]]
source_assets.append({'path':'assets/vendor/'+P,'sha256':hashlib.sha256((ROOT/'assets/vendor'/P).read_bytes()).hexdigest(),'crop':'16x24 native frame grid','treatment':'original palette; project action pixel edits; optional actor tint in Godot'})
(OUT/'sources.json').write_text(json.dumps({'source_assets':source_assets,'project_drawn':['interior window','smoke_0..5','chimney','plank floor','tea table','contact shadows and pond bank','skin action pixel edits and occluders'],'all_frames':'native size; nearest only','note':'Source helper may read other experiments, but these are not runtime action inputs.'},ensure_ascii=False,indent=2)+'\n')
print('Derived art built',len(list(OUT.glob('*.png'))),'PNGs')
