"""Deterministic review composites from checked-in PNGs; never changes game assets.
Run: python docs/art-review/round2/build_samples.py (requires Pillow).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import colorsys, hashlib, json, random
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
V=ROOT/'assets/vendor'
used={}
def asset(path,box=None,tone='soft'):
 p=V/path;im=Image.open(p).convert('RGBA')
 key=path+(':'+str(box) if box else '')+':'+tone
 used[key]={'path':'assets/vendor/'+path,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'crop':box,'treatment':tone}
 if box:im=im.crop(box)
 # Uniform pixel-preserving palette map, never interpolating shapes.
 if tone!='original':
  px=[]
  for r,g,b,a in (im.get_flattened_data() if hasattr(im,"get_flattened_data") else im.getdata()):
   h,l,s=colorsys.rgb_to_hls(r/255,g/255,b/255)
   if tone=='wood':
    if (h>.94 or h<.12) and s>.2: h=.045+((h if h<.12 else h-1)*.2)
    l=min(.91,l*.9+.15);s*=.72
   elif tone=='green':h=.215+(h-.215)*.55;l=min(.86,l*.82+.15);s*=.7
   elif tone=='water':h=.49+(h-.49)*.35;l=min(.85,l*.88+.06);s*=.48
   else:l=min(.94,l*.94+.035);s*=.78
   rr,gg,bb=colorsys.hls_to_rgb(h,l,s);px.append((int(rr*255),int(gg*255),int(bb*255),a))
  im.putdata(px)
 return im
F='terrain/cozy-farm-lite/'
C='buildings/cottage-topdown-optional/cabin.png'
I='interiors/cottage-core-furniture/cottage_core.png'
P='buildings/cozy-town-lite/characters/player-1-walk.png'
D='characters/cozy-town-actions/actions_sit_read_rest.png'
def paste(im,s,x,y):im.alpha_composite(s,(int(x),int(y)))
def tile(im,path,x,y,tone='soft'):paste(im,asset(path,tone=tone),x,y)
def rect_tiles(im,kind,x,y,w,h):
 for j in range(h):
  for i in range(w):
   edge=('n' if j==0 else 's' if j==h-1 else '')+('w' if i==0 else 'e' if i==w-1 else '')
   tile(im,F+'tiles/tile-'+kind+'-'+(edge or 'c')+'.png',x+i*16,y+j*16)
def sprite_shadow(im,s,x,y):
 # Shadow is derived from the actual sprite alpha; same lower-right offset everywhere.
 sh=Image.new('RGBA',s.size,(58,64,50,0));sh.putalpha(s.getchannel('A').point(lambda a:int(a*.12)))
 paste(im,sh,x+3,y+3);paste(im,s,x,y)
def save(im,name):
 im.convert('RGB').save(OUT/(name+'-1x.png'))
 im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST).convert('RGB').save(OUT/(name+'-4x.png'))

# Character samples: original 16x24 frames, no stretching to match furnishings.
stand=asset(P,(0,0,16,24))
sit=asset(D,(0,24,18,48)) # discard the neighboring-frame remnant at x18..23
read=asset(D,(0,48,18,72))
rest=asset(D,(0,72,18,96))
house=asset(C,(105,11,248,125),'wood')
pine=asset(C,(292,14,348,78),'green')
bench=asset(C,(112,171,143,186),'wood')
rock=asset(C,(8,10,26,21))
flower=asset(C,(39,135,59,154))
# These atlas crops are kept at native size across all three deliverables.
bed=asset(I,(0,4,53,64))
bookcase=asset(I,(54,1,86,50))
desk=asset(I,(190,31,226,61))
chair=asset(I,(158,35,177,58))
lamp=asset(I,(192,1,206,30))
rug=asset(I,(242,5,314,62))
plant=asset(I,(91,17,104,42))

# OUTDOOR 26x17, 416x272 pixels.
scene=Image.new('RGBA',(416,272))
grass=asset(F+'tiles/tile-grass-1.png',tone='green')
base=max(grass.getcolors(256),key=lambda x:x[0])[1]
scene.paste(base,(0,0,416,272))
grass.putalpha(65)
for y in range(17):
 for x in range(26):paste(scene,grass,x*16,y*16)
rect_tiles(scene,'path',176,128,3,9)
rect_tiles(scene,'path',96,176,7,2)
rect_tiles(scene,'soil',304,176,4,4)
# Low fence fragments, with a proper south opening and visible natural boundaries.
for x in list(range(16,112,16))+list(range(304,384,16)):
 tile(scene,F+'fences/fence-h-post.png',x,16,'wood')
for x in list(range(48,128,16))+list(range(304,384,16)):
 tile(scene,F+'fences/fence-h-post.png',x,252,'wood')
for y in range(64,160,16):tile(scene,F+'fences/fence-v-post.png',8,y,'wood')
for y in range(160,208,16):tile(scene,F+'fences/fence-v-post.png',400,y,'wood')
# Pond: original water first frame, clipped to stepped pixel shoreline.
water=Image.new('RGBA',(48,32))
for y in range(0,32,16):
 for x in range(0,48,16):paste(water,asset('animations/animated-flowing-water/water_strip13.png',(0,0,16,16),'water'),x,y)
mask=Image.new('L',(48,32),0);md=ImageDraw.Draw(mask);md.polygon([(8,0),(35,0),(35,4),(44,4),(44,10),(48,10),(48,24),(40,24),(40,30),(10,30),(10,26),(0,26),(0,9),(8,9)],fill=255)
water.putalpha(mask)
# Soil bank is the original path ground, exposed around the water silhouette.
bank=Image.new('RGBA',(64,48));rect_tiles(bank,'path',0,0,4,3)
bankmask=Image.new('L',(64,48),0);bankmask.paste(mask,(8,7));bank.putalpha(bankmask.filter(ImageFilter.MaxFilter(9)))
paste(scene,bank,40,208);paste(scene,water,48,215)
for x,y in [(33,208),(92,236),(53,245)]:sprite_shadow(scene,rock,x,y)
# Crops use world growth sprites rather than inventory icons.
for row,kind in enumerate(['carrot','tomato','wheat']):
 for col in range(3):
  crop=asset(F+f'crops/{kind}/{kind}-{3 if col==0 else 4}-'+('growing' if col==0 else 'ready')+'.png')
  paste(scene,crop,312+col*16,184+row*16-(crop.height-16))
# Foreground flowers are clustered, not sprinkled evenly over the whole grass.
for x,y in [(112,150),(130,150),(258,150),(274,150),(286,220),(370,190),(94,92)]:
 tile(scene,F+'props/flowers.png',x,y)
for x,y in [(28,32),(70,61),(330,33),(354,92)]:sprite_shadow(scene,pine,x,y)
sprite_shadow(scene,house,140,28)
# Reading nook is subordinate to the house, visible from the central path.
sprite_shadow(scene,bench,79,178);paste(scene,read,86,163)
paste(scene,stand,198,126)
for x,y in [(34,128),(352,152),(369,239),(115,231)]:tile(scene,F+'props/bush.png',x,y,'green')
for x,y in [(45,150),(323,244)]:sprite_shadow(scene,rock,x,y)
for x,y in [(26,96),(61,137),(95,123),(312,126),(370,137),(361,214),(286,249),(113,226),(43,191),(116,66)]:
 paste(scene,asset(C,(7,105,27,120),'green'),x,y)
for x,y in [(40,163),(65,160),(283,166),(366,231),(128,227)]:
 paste(scene,asset(C,(39,135,59,149),'green'),x,y)
save(scene,'outdoor')

# INTERIOR 14x11. Walls and floor use actual InThePixel atlas cells.
room=Image.new('RGBA',(224,176),(69,60,53,255))
S='interiors/interior-spritesheet/interior_0.png'
for y in range(16,160,16):
 for x in range(16,208,16):paste(room,asset(S,(48,48,64,64),'wood'),x,y)
for x in range(16,208,16):paste(room,asset(S,(48,0,64,16),'wood'),x,0)
for y in range(16,160,16):
 paste(room,asset(S,(0,48,16,64),'wood'),0,y)
 paste(room,asset(S,(96,48,112,64),'wood'),208,y)
for x in range(16,208,16):paste(room,asset(S,(48,96,64,112),'wood'),x,160)
# Reuse the actual cabin window without stretching; its flower box is retained.
window=asset(C,(120,83,151,105),'wood');paste(room,window,88,2)
paste(room,asset(S,(48,48,64,64),'wood'),96,160);paste(room,asset(S,(48,48,64,64),'wood'),112,160)
paste(room,rug,87,82)
sprite_shadow(room,bed,23,35)
sprite_shadow(room,bookcase,169,24)
sprite_shadow(room,desk,105,34)
sprite_shadow(room,chair,114,63)
paste(room,read,113,53)
sprite_shadow(room,plant,190,120)
sprite_shadow(room,lamp,78,35)
paste(room,stand,104,129)
save(room,'interior')

# Proportion proof uses the SAME crops at 1x. Static scenes, not animation frames.
proof=Image.new('RGBA',(416,176),(241,233,213,255))
font=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',10,index=2)
d=ImageDraw.Draw(proof)
paste(proof,house,8,20);paste(proof,stand,59,117)
d.text((14,147),'门前站立 · 原生人物16×24',font=font,fill='#51473f')
paste(proof,chair,191,88);paste(proof,sit,191,78)
d.text((161,147),'坐姿实验 · 非动画',font=font,fill='#51473f')
paste(proof,bed,302,70)
# Pillow head and original blanket occlusion show a lying resident without enlarging them.
paste(proof,rest.crop((0,3,18,13)),320,83)
paste(proof,bed.crop((4,27,49,57)),306,97)
d.text((279,147),'卧床遮挡实验 · 非动画',font=font,fill='#51473f')
for x in [163,271]:d.line((x,20,x,137),fill='#bbae95')
d.text((10,4),'人物—门—椅—床：同一原生像素密度，未单独缩放',font=font,fill='#51473f')
save(proof,'proportions')
(OUT/'sources.json').write_text(json.dumps({'basis':'3fb887a9c8efceec0b151084d5ae61b4d0adf4ca','outputs':{'outdoor':[416,272],'interior':[224,176],'proportions':[416,176]},'scale':4,'filter':'NEAREST','assets':list(used.values())},ensure_ascii=False,indent=2)+'\n')
print('Wrote six PNGs and source manifest; original game assets untouched.')
