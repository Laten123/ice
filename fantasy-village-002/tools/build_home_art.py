"""Reproducible project derivatives of licensed source art. Pillow only, nearest pixels."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json, random
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
 for x in range(16+(24 if (y//12)%2 else 0),208,48):d.line((x,y,x,y+11),fill='#a17d5a')
for rect in [(0,0,224,16),(0,16,16,160),(208,16,224,160),(0,160,96,176),(128,160,224,176)]:d.rectangle(rect,fill='#e2d6be',outline='#88684f',width=2)
save(floor,'interior_ground')
# Ground tiles, colored patches intentionally follow borders and worn routes.
ground=Image.new('RGBA',(416,272),'#9dab78');d=ImageDraw.Draw(ground)
for poly,col in [([(0,0),(136,0),(111,74),(40,124),(0,110)],'#96a573'), ([(298,0),(416,0),(416,154),(373,161),(302,94)],'#8c9d6a'), ([(18,193),(121,185),(155,272),(0,272)],'#a5b17e')]:d.polygon(poly,fill=col)
rng=random.Random(303)
for i in range(700):
 x,y=rng.randrange(416),rng.randrange(272)
 if x<126 or x>286 or y>210:
  col=rng.choice(['#a4b17d','#91a16f','#acb886']);d.line((x,y,x+1,y),fill=col)
for x,y,w,h in [(176,128,3,9),(96,176,6,2),(304,176,4,4)]:ns['rect_tiles'](ground,'soil' if x==304 else 'path',x,y,w,h)
# Pond banks: stepped non-rectangular wet-earth shoreline and underwater depth.
pond=[(45,216),(57,207),(88,211),(100,225),(95,242),(76,249),(50,242),(41,229)]
d=ImageDraw.Draw(ground);d.polygon(pond,fill='#8b8e6b');d.line(pond+[pond[0]],fill='#b8b48b',width=2)
# Soil furrows and distinct crops, not inventory icons.
for y in [188,204,220]:d.line((311,y+5,361,y+5),fill='#816244',width=2)
for row,k in enumerate(['carrot','tomato','wheat']):
 for col in range(3):
  st=[2,3,4][col];crop=asset(F+f'crops/{k}/{k}-{st}-'+{2:'sprout',3:'growing',4:'ready'}[st]+'.png');ground.alpha_composite(crop,(312+col*16,184+row*16-(crop.height-16)))
for x,y in [(16,16),(32,16),(48,16),(64,16),(320,250),(336,250),(352,250)]:ground.alpha_composite(asset(F+'fences/fence-h-post.png',tone='wood'),(x,y))
for x,y in [(113,151),(132,153),(268,152),(286,157),(366,190)]:ground.alpha_composite(asset(F+'props/flowers.png'),(x,y))
for x,y in [(28,111),(42,153),(76,133),(341,146),(366,218),(290,250)]:ground.alpha_composite(asset(C,(7,105,27,120),'green'),(x,y))
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
  cy=32-((n*3+k*11)%34);cx=10+(k%2)*3+(n//2)%3;dr.rectangle((cx-3,cy-3,cx+3,cy+3),fill=(224,219,199,150-k*25))
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
  if n and direction!=3:
   dr=ImageDraw.Draw(f);dr.line((5,8,6,8),fill='#665244');dr.line((10,8,11,8),fill='#665244')
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
   f=front.crop((0,0,16,12));dr=ImageDraw.Draw(f);dr.line((4,8,6,8),fill='#6a4f3c');dr.line((10,8,12,8),fill='#6a4f3c');f=body(f);f= f.transform(f.size,Image.Transform.AFFINE,(1,0,0,0,1,-(1 if n==2 else 0)),Image.Resampling.NEAREST)
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
(OUT/'sources.json').write_text(json.dumps({'source_assets':list(used.values()),'project_drawn':['window','smoke_0..5','chimney','plank floor','skin action pixel edits'],'all_frames':'native size; nearest only'},ensure_ascii=False,indent=2)+'\n')
print('Derived art built',len(list(OUT.glob('*.png'))),'PNGs')
# Seat fronts are separate occluders, not whole sprites covering the resident.
save(ns['chair'].crop((0,16,19,23)),'chair_front')
save(ns['bench'].crop((0,10,31,15)),'bench_front')
tea=Image.new('RGBA',(32,25));dd=ImageDraw.Draw(tea);dd.rectangle((5,13,8,24),fill='#80634e');dd.rectangle((24,13,27,24),fill='#80634e');dd.ellipse((0,2,31,18),fill='#a78260',outline='#725b49',width=2);dd.rectangle((13,5,18,10),fill='#f0e2be');dd.point((19,7),fill='#f0e2be');save(tea,'tea_table')
