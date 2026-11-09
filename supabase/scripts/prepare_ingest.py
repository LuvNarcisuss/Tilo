"""Prepare a fixed local allowlist. The temporary token never enters the app or repository."""
from pathlib import Path
import json,hashlib,secrets,time
ROOT=Path(__file__).resolve().parents[2]
APP=ROOT/'TiloApp'
objects=[]
records=json.loads((ROOT/'Assets/SourceMedia/manifest.json').read_text())['records']
expected={record['asset'] for record in records}|{record['coverAsset'] for record in records if record['kind']=='video'}
media=ROOT/'Assets/PublishedMedia'
if any(not (media/name).is_file() for name in expected):
 raise SystemExit('Prepare the complete catalog staging set before generating an import manifest.')
for p in sorted(media/name for name in expected):
 data=p.read_bytes()
 objects.append({'bucket':'toli-catalog','key':p.name,'path':str(p),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'mime':'video/mp4' if p.suffix=='.mp4' else 'image/jpeg' if p.suffix=='.jpg' else 'image/png'})
for kind in ('terms','privacy'):
 p=ROOT/'docs/BackendAPI/legal'/f'{kind}.pdf';data=p.read_bytes()
 objects.append({'bucket':'legal','key':f'2026-11-03/{kind}.pdf','path':str(p),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'mime':'application/pdf'})
token=secrets.token_urlsafe(48)
config={'url':'https://hdapofqufmxlghmcrftg.supabase.co','token':token,'tokenSHA256':hashlib.sha256(token.encode()).hexdigest(),'expires':int(time.time())+7200,'objects':objects}
p=Path('/private/tmp/toli-ingest-config.json');p.write_text(json.dumps(config));p.chmod(0o600)
(ROOT/'docs/BackendAPI/media-upload-manifest.json').write_text(json.dumps({'objects':[{k:v for k,v in x.items() if k!='path'} for x in objects]},indent=2))
print('Prepared',len(objects),'fixed objects;',sum(x['bytes'] for x in objects),'bytes. Temporary authorization stays outside the repository.')
