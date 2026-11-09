#!/usr/bin/env python3
"""Fetch the licensed Tilo media set and prepare aspect-preserving app copies."""
from pathlib import Path
import concurrent.futures, hashlib, json, subprocess, urllib.request
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Assets/SourceMedia'
RUNTIME = ROOT / 'Assets/PublishedMedia'
LICENSE = 'https://www.pexels.com/license/'
VIDEOS = [
('cooking-01','Skillet pasta','cottonbro studio','pasta-kitchen-cooking-indoors-4253144', '4253144/4253144-uhd_4096_2160_25fps.mp4'),
('cooking-02','Pancakes on the griddle','Vlada Karpovich','cooking-pancakes-7010647','7010647/7010647-uhd_2160_3840_25fps.mp4'),
('cooking-03','Colorful skillet vegetables','Kampus Production','close-up-shot-of-cooking-vegetables-in-the-pan-7963455','7963455/7963455-uhd_3840_2160_25fps.mp4'),
('cooking-04','Seasoning grilled steak','Kuiyibo Campos','a-steak-being-prepared-on-a-cutting-board-28478427','28478427/12393283_1080_1920_30fps.mp4'),
('cooking-05','Kneading homemade dough','Pavel Danilyuk','a-woman-kneading-a-dough-6942824','6942824/6942824-hd_1080_1920_25fps.mp4'),
('cooking-06','Tossing a fresh salad','Mikhail Nilov','a-young-woman-preparing-a-vegetable-salad-6707706','6707706/6707706-hd_1920_1080_25fps.mp4'),
]
PORTRAITS = [
('chef-01','Chef in a restaurant kitchen','Ünal Aslan','portrait-of-a-chef-in-a-restaurant-kitchen-29018150',29018150),
('chef-02','Woman in a home kitchen','Mizuno K','portrait-of-a-woman-standing-in-a-kitchen-12911555',12911555),
('chef-03','Chef at work','Hazel Montero','woman-working-at-kitchen-16816196',16816196),
('chef-04','Cook in a neighborhood kitchen','Kinz-studio Photographe','portrait-of-a-man-working-in-kitchen-18799034',18799034),
('chef-05','Chef in a dark uniform','Tochukwu Ekeh','professional-portrait-of-a-black-chef-in-dark-uniform-32224390',32224390),
]
PHOTOS = [
('recipe-01','Tomato basil spaghetti','cottonbro studio','a-plate-of-spaghetti-on-table-4057752',4057752),
('recipe-02','Berry pancakes','alleksana','a-stack-of-pancakes-on-a-plate-6758389',6758389),
('recipe-03','Cheeseburger and fries','MARIANNE RIXHON','close-up-shot-of-burger-and-fries-11812583',11812583),
('recipe-04','Margherita pizza','Sobee Berly','pizza-on-white-ceramic-plate-5280912',5280912),
('recipe-05','Grilled salmon','Giovanna Kamimura','delicious-grilled-salmon-fillets-on-plate-31043029',31043029),
('recipe-06','Pepper steak','Nadin Sh','close-up-shot-of-a-steak-on-a-plate-15382851',15382851),
('recipe-07','Vegetable soup','Polina Tankilevitch','soup-in-bowl-8601392',8601392),
('recipe-08','Garden salad','Madison Inouye','bowl-of-salad-2821743',2821743),
('recipe-09','Roast chicken and potatoes','Mahmoud Salem','succulent-roasted-chicken-with-vegetables-31233881',31233881),
('recipe-10','Tomato basil bruschetta','Lucie Liz','close-up-photo-of-a-bruschetta-7432986',7432986),
('recipe-11','Roasted tomato mozzarella toast','Nadezhda Moryak','italian-bruschetta-with-roasted-tomatoes-and-mozzarella-cheese-served-on-plate-4409496',4409496),
('recipe-12','Herb chicken tray bake','ArtHouse Studio','cooked-chicken-with-potatoes-on-black-metal-tray-4589139',4589139),
]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def download(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        subprocess.run(['curl','-f','-L','--retry','3','--max-time','240','-sS',url,'-o',str(path)], check=True)
    return path

def prepare(item):
    kind, data = item
    basename,title,author,slug,media = data
    url = ('https://videos.pexels.com/video-files/' + media) if kind=='video' else f'https://images.pexels.com/photos/{media}/pexels-photo-{media}.jpeg?auto=compress&cs=tinysrgb&w=1200'
    original = download(url, SOURCE / 'originals' / (basename + ('.mp4' if kind=='video' else '.jpg')))
    target = RUNTIME / original.name
    RUNTIME.mkdir(parents=True,exist_ok=True)
    record = {'id':basename,'basename':basename,'seconds':None,'kind':kind,'title':title,'asset':target.name,'sourceURL':f'https://www.pexels.com/{kind if kind=="video" else "photo"}/{slug}/','downloadURL':url,'author':author,'license':'Pexels License','licenseURL':LICENSE,'originalPath':str(original.relative_to(ROOT)),'originalSHA256':sha(original),'acquiredDate':'2026-11-03'}
    if kind=='video':
        if not target.exists(): subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(original),'-t','20','-vf','scale=min(720\\,iw):-2','-c:v','libx264','-preset','fast','-crf','24','-c:a','aac','-movflags','+faststart',str(target)],check=True)
        probe=json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_format','-show_streams','-of','json',str(target)]))
        duration=float(probe['format']['duration']); video=next(s for s in probe['streams'] if s['codec_type']=='video')
        record.update(seconds=duration,width=video['width'],height=video['height'],processing='First 20 seconds maximum; proportional width capped at 720 pixels; original playback speed; H.264/AAC MP4.')
        times=[0.1,duration/2,max(0.1,duration-0.2)]
        for n,t in enumerate(times):
            frame=SOURCE/'inspection'/f'{basename}-{n+1}.jpg'
            frame.parent.mkdir(parents=True,exist_ok=True)
            subprocess.run(['ffmpeg','-loglevel','error','-y','-ss',str(t),'-i',str(target),'-frames:v','1','-vf','scale=320:-2',str(frame)],check=True)
        subprocess.run(['ffmpeg','-loglevel','error','-y','-ss',str(duration/2),'-i',str(target),'-frames:v','1',str(target.with_suffix('.jpg'))],check=True)
        record.update(coverAsset=target.with_suffix('.jpg').name,coverSHA256=sha(target.with_suffix('.jpg')),inspectionTimes=times,visualInspection='Pending contact-sheet review')
    else:
        target.write_bytes(original.read_bytes())
        record.update(processing='Pexels proportional 1200-pixel-width JPEG download; no crop.',visualInspection='Pending contact-sheet review')
    record['SHA256']=sha(target)
    print(basename, target.stat().st_size, flush=True)
    return record

def main():
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        records=list(pool.map(prepare,[('video',x) for x in VIDEOS]+[('photo',x) for x in PHOTOS+PORTRAITS]))
    prior_path=SOURCE/'manifest.json'
    if prior_path.exists():
        prior={r['id']:r for r in json.loads(prior_path.read_text())['records']}
        for record in records:
            previous=prior.get(record['id'],{})
            if previous.get('SHA256')==record['SHA256']:
                for field in ('visualInspection','visualInspectionDate','usageBoundary'):
                    if field in previous: record[field]=previous[field]
    (SOURCE/'manifest.json').write_text(json.dumps({'project':'Tilo','licenseVerifiedDate':'2026-11-03','licenseReference':'https://help.pexels.com/hc/en-us/articles/360042295174-What-is-the-license-of-the-photos-and-videos-on-Pexels','records':records},indent=2)+'\n')
if __name__=='__main__': main()
