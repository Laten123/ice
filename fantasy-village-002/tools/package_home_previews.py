"""Package actual Godot capture frames; never synthesizes gameplay poses."""
from pathlib import Path
from PIL import Image, ImageChops
import json, hashlib
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'docs/round3/previews'
result={'source':'Godot viewport captures','frame_duration_ms':100,'animations':{},'pixel_checks':{}}
for prefix,name in [('animation','environment'),('reading','reading'),('resting','resting'),('entering','entering'),('leaving','leaving')]:
    files=sorted(p.glob(prefix+'-*.png'))
    assert files, prefix
    frames=[Image.open(f).convert('RGB') for f in files]
    frames[0].save(p/(name+'.gif'),save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=False)
    result['animations'][name]={'captured_frames':len(frames),'distinct_captured_frames':len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames}),'size':frames[0].size}
for n in ['outdoor','indoor-reading','indoor-rest']:
    im=Image.open(p/(n+'.png')).convert('RGB')
    native=im.resize((im.width//3,im.height//3),Image.Resampling.NEAREST)
    assert ImageChops.difference(im,native.resize(im.size,Image.Resampling.NEAREST)).getbbox() is None, n+' is not exact 3x pixels'
    native.save(p/(n+'-native.png'))
    if n!='outdoor':native.crop((96,48,320,224)).save(p/(n+'-room-native.png'))
    result['pixel_checks'][n]='exact nearest 3x blocks'
(p/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
