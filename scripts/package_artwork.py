"""Package image-model artwork into named iOS asset sets without redrawing it."""
from pathlib import Path
from PIL import Image
import json, hashlib, shutil
ROOT=Path(__file__).resolve().parents[1]
CAT=ROOT/'TiloApp/Tilo/Resources/Assets.xcassets'
CAT.mkdir(parents=True,exist_ok=True)
(CAT/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
names=['live','recipes','kitchen','chats','me','search','back','close','plus','more','heart','bookmark','send','gift','diamond','share','settings','bell','camera','microphone','video','speaker','play','pause','shield','flag','person','group','trash','pencil','check','clock','calendar','list','info','cutlery']
atlas=Image.open(ROOT/'Assets/Generated/tilo-icon-atlas.png').convert('RGBA')
w,h=atlas.size
# Generated rows have asymmetric transparent gutters. Boundaries were visually reviewed.
y_bounds=[0,267,466,677,864,1056,h]
records=[]
def save_set(name,im):
    folder=CAT/(name+'.imageset'); folder.mkdir(exist_ok=True)
    im.save(folder/(name+'.png'))
    (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':name+'.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
for index,name in enumerate(names):
    row,col=divmod(index,6)
    box=(round(col*w/6),y_bounds[row],round((col+1)*w/6),y_bounds[row+1])
    icon=atlas.crop(box)
    bbox=icon.getchannel('A').getbbox()
    if not bbox: raise RuntimeError('Missing alpha pixels: '+name)
    icon=icon.crop(bbox)
    canvas=Image.new('RGBA',(256,256))
    icon.thumbnail((228,228),Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon,((256-icon.width)//2,(256-icon.height)//2))
    save_set('icon-'+name,canvas)
    records.append({'name':'icon-'+name,'atlasBox':box,'alphaBounds':bbox})
save_set('TiloBackground',Image.open(ROOT/'Assets/Generated/tilo-background.png'))
brand_source = ROOT/'Assets/Brand/TiloLogo.png'
with Image.open(brand_source) as original:
    if original.size != (1024, 1024) or original.convert('RGBA').getchannel('A').getextrema() != (255, 255):
        raise RuntimeError('The Tilo brand source must be opaque and 1024 by 1024 pixels.')
    mark = original.convert('RGB')
save_set('TiloBrandLogo',mark)
folder=CAT/'AppIcon.appiconset';folder.mkdir(exist_ok=True)
mark.save(folder/'AppIcon.png')
(folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
brand = {
    'source': str(brand_source.relative_to(ROOT)),
    'provenance': 'Owner-supplied artwork',
    'sha256': hashlib.sha256(brand_source.read_bytes()).hexdigest(),
}
(ROOT/'Assets/Generated/asset-manifest.json').write_text(json.dumps({'tool':'built-in image_gen','date':'2026-11-03','icons':records,'outputs':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'Assets/Generated').glob('*.png')},'activeBrand':brand},indent=2)+'\n')
print('Packaged 36 alpha icons, background, mark and opaque AppIcon.')
