"""Build licensed native pixel parts and shared rig/action data; no downloads."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
R=Path(__file__).resolve().parents[1];D=R/'data/puppet';D.mkdir(exist_ok=True)
def js(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
joints={'head':[24,26],'hair':[24,24],'torso':[24,32],'arm_l':[20,32],'arm_r':[28,32],'leg_l':[21,37],'leg_r':[26,37]}
js(D/'rig.json',{'version':'1.0','canvas':[48,48],'foot_origin':[24,40],'collision_radius':5,'joints':joints,'directions':['front','left','right','back'],'filter':'nearest','markers':{'eyes':[24,27],'pelvis':[24,35]}})
actions={}
def action(id,label,count,fps=8,loop=False,dirs=None,fixture='blank'):
 frames=[]
 for i in range(count):
  t=i/max(1,count-1);o={};expr='none';book='none'
  if id in ['idle','breathe']:o={'head':[0,-(i%2)],'hair':[0,-(i%2)],'torso':[0,-(i%2)]}
  if id=='blink':expr='blink' if i==1 else 'none'
  if id in ['walk','approach_bed','enter_house','exit_house']:
   step=[0,1,0,0,-1,0][i%6];o={'leg_l':[step,-max(step,0)],'leg_r':[-step,-max(-step,0)],'arm_l':[-step,0],'arm_r':[step,0],'head':[0,-abs(step)],'hair':[0,-abs(step)]}
  if id in ['sit_down','sit_idle','stand_up','take_book','open_book','read','turn_page','close_book','put_book','tea']:
   k=round(2*t) if id=='sit_down' else round(2*(1-t)) if id=='stand_up' else 2
   o={'head':[0,k],'hair':[0,k],'torso':[0,k],'arm_l':[0,k],'arm_r':[0,k],'leg_l':[-1,-k],'leg_r':[1,-k]}
   if id in ['take_book','open_book','read','turn_page','close_book','put_book']:
    book='closed' if id in ['take_book','put_book'] else 'open'
    o['arm_l']=[-1,k-2];o['arm_r']=[1,k-2]
    if id=='take_book':o['book']=[0,round((1-t)*7)]
    if id=='put_book':o['book']=[0,round(t*7)]
  if id in ['lie_down','sleep','wake','get_up']:
   k=round(2*t) if id=='lie_down' else round(2*(1-t)) if id=='get_up' else 2
   o={'head':[0,-k-(i%2 if id=='sleep' else 0)],'hair':[0,-k-(i%2 if id=='sleep' else 0)],'arm_l':[2,1],'arm_r':[-2,1],'leg_l':[1,0],'leg_r':[-1,0]}
   expr='sleep' if id=='sleep' or (id=='lie_down' and t>.5) or (id=='wake' and t<.5) else 'none'
  if id in ['open_door','close_door']:
   k=round(6*(t if id=='open_door' else 1-t));o={'arm_r':[-1,-k]}
  frames.append({'offsets':o,'expression':expr,'book':book,'page':i%4 if id in ['read','turn_page'] else 0,'facing_step':i if id=='turn' else 0,'fold_legs':(t>=.5 if id=='sit_down' else t<.5 if id=='stand_up' else id in ['sit_idle','take_book','open_book','read','turn_page','close_book','put_book','tea'])})
 actions[id]={'label':label,'priority':'P0','implemented':True,'frames':frames,'fps':fps,'loop':loop,'directions':dirs or ['front','left','right','back'],'fixture':fixture,'next':'idle'}
for args in [('idle','待机',2,2,True),('blink','眨眼',3,5,False,['front','left','right']),('breathe','呼吸',4,3,True),('walk','行走',6,8,True),('turn','转身',4,5,False)]:action(*args)
for id,label,n,loop in [('sit_down','坐下',4,False),('sit_idle','坐姿待机',4,True),('stand_up','起身',4,False)]:action(id,label,n,8,loop,['front'],'bench')
for id,label,n,loop in [('take_book','拿书',4,False),('open_book','打开书',4,False),('read','阅读',4,True),('turn_page','翻页',6,False),('close_book','合书',4,False),('put_book','收书',4,False)]:action(id,label,n,8,loop,['front'],'desk')
for id,label,n,loop in [('approach_bed','走近床',6,False),('lie_down','躺下',6,False),('sleep','睡眠',4,True),('wake','醒来',4,False),('get_up','起床',6,False)]:action(id,label,n,8,loop,['front'],'bed')
for id,label in [('open_door','开门'),('enter_house','进屋'),('exit_house','出屋'),('close_door','关门')]:action(id,label,6,8,False,['front','back'],'door')
action('tea','茶座休息',4,4,True,['front'],'tea')
actions['dance']={'label':'舞蹈（P1 未实现）','priority':'P1','implemented':False,'directions':[]}
actions['plant']={'label':'种植（P2 待扩展）','priority':'P2','implemented':False,'directions':[]}
js(D/'actions.json',{'version':'1.0','rig_version':'1.0','actions':actions})
source=R/'assets/vendor/buildings/cozy-town-lite/characters/player-1-walk.png';sheet=Image.open(source).convert('RGBA')
for name,title,variant in [('forest','林间旅人',0),('moon','月白居民',1)]:
 root=R/'skins'/name;(root/'parts').mkdir(parents=True,exist_ok=True);parts={};expressions={};clothing={}
 for di,direction in enumerate(['front','left','right','back']):
  f=sheet.crop((0,di*24,16,(di+1)*24));layers={p:Image.new('RGBA',(48,48)) for p in joints}
  for y in range(24):
   for x in range(16):
    c=f.getpixel((x,y))
    if not c[3]:continue
    r,g,b,a=c
    if variant:
     if y<14 and r>=50 and g<150:c=(100,91,119,a) if (r+g+b)//3<60 else (192,184,207,a) if (r+g+b)//3<110 else (231,224,239,a)
     elif 14<=y<20 and not(r>180 and g>120):c=(96+g//4,64+b//4,145+g//5,a)
    part='head' if y<14 else ('arm_l' if x<6 else 'arm_r' if x>=10 else 'torso') if y<19 else ('leg_l' if x<8 else 'leg_r')
    layers[part].putpixel((16+x,17+y),c)
    if y<9:layers['hair'].putpixel((16+x,17+y),c)
  if variant:
   im=Image.new('RGBA',(48,48));dr=ImageDraw.Draw(im);bx=17 if direction=='left' else 28
   dr.rectangle((bx,25,bx+3,26),fill='#aa547a');dr.point((bx+1,27),fill='#aa547a')
   rel=f'parts/{direction}-headwear.png';im.save(root/rel);clothing.setdefault('headwear',{})[direction]={'path':rel,'anchor':joints['head'],'bind':'head'}
  parts[direction]={}
  for p,im in layers.items():
   rel=f'parts/{direction}-{p}.png';im.save(root/rel);parts[direction][p]={'path':rel,'anchor':joints[p],'z':list(joints).index(p)}
  expressions[direction]={}
  if direction!='back':
   for exp in ['blink','sleep']:
    im=Image.new('RGBA',(48,48));dr=ImageDraw.Draw(im)
    # Side eyes are located from native dark pixels on the face, not front overlays.
    for y in [10,11]:
     for x in range(3,13):
      r,g,b,a=f.getpixel((x,y))
      if a and max(r,g,b)<60:
       dr.point((16+x,17+y),fill='#f2d0b5' if y==10 else '#665244')
    rel=f'parts/{direction}-{exp}.png';im.save(root/rel);expressions[direction][exp]=rel
 manifest={'schema_version':1,'skin_id':'fv.'+name,'version':'1.0.0','display_name':title,'author':'Spaceyyy / FV project derivatives','author_id':'fv-test','source':'https://opengameart.org/content/cozy-town-lite-%E2%80%94-16x16-top-down-street-tiles-caf%C3%A9-and-walking-character','license':'CC-BY-4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','attribution':'Cozy Town Lite by Spaceyyy. Native frames split into parts; palette and action derivatives by FV project.','rig_version':'1.0','canvas':[48,48],'foot_origin':[24,40],'pixel_scale':1,'filter':'nearest','directions':['front','left','right','back'],'parts':parts,'expressions':expressions,'optional_clothing':clothing,'correctives':{},'occlusion':['leg_l','leg_r','torso','head','hair']+(['headwear'] if variant else [])+['book','arm_l','arm_r'],'held_anchors':{'left':[20,32],'right':[28,32]},'actions':[k for k,v in actions.items() if v['implemented']],'unsupported':{'blink:back':'背面无可见眼睛；不伪造正面眨眼'},'modifications':['Split original 16x24 into native transparent parts; 48x48 animation canvas, unchanged 5px collision.', 'White hair, ribbon and violet clothing palette.' if variant else 'Native source palette.'],'content_hash':''}
 js(root/'skin.json',manifest);(root/'LICENSE.txt').write_text('CC BY 4.0 https://creativecommons.org/licenses/by/4.0/legalcode\n'+manifest['attribution']+'\nSource: '+manifest['source']+'\n')
# Shared fixture occlusion uses native home source pixels.
out=R/'assets/derived/puppet';out.mkdir(exist_ok=True)
bed=Image.open(R/'assets/derived/home_v3/bed.png');bed.crop((4,17,49,57)).save(out/'blanket.png')
house=Image.open(R/'assets/derived/home_v3/house.png');house.crop((44,77,76,114)).save(out/'door.png')
js(D/'source.json',{'path':str(source.relative_to(R)),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'author':'Spaceyyy','license':'CC-BY-4.0','modifications':'native part split; moon palette/ribbon; no generative service'})
print('Built rig, shared action templates and two layered skins.')
