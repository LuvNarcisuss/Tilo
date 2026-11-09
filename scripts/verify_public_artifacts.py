"""Read-only verification of public Tilo agreements and one inspected replay."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
IDENTITY = json.loads((ROOT/'TiloApp/Configuration/Identity.json').read_text())
ORIGIN = 'https://' + IDENTITY['backendProjectRef'] + '.supabase.co'
LEGAL = json.loads((ROOT/'docs/BackendAPI/legal/manifest.json').read_text())
MEDIA = json.loads((ROOT/'docs/BackendAPI/media-upload-manifest.json').read_text())['objects']
items = [dict(name=x['file'], url=x['publicURL'], expected=x['sha256']) for x in LEGAL['files']]
replay = next(x for x in MEDIA if x['key'] == 'cooking-01.mp4')
items.append(dict(name=replay['key'], url=ORIGIN+'/storage/v1/object/public/'+replay['bucket']+'/'+replay['key'], expected=replay['sha256']))
results = []
with tempfile.TemporaryDirectory(prefix='toli-public-check-') as temporary:
    for item in items:
        path = Path(temporary)/item['name']
        subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location', '--max-time', '30', '--output', str(path), item['url']], check=True)
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != item['expected']:
            raise ValueError('Public bytes differ from the inspected artifact: '+item['name'])
        if item['name'].endswith('.pdf') and not data.startswith(b'%PDF-'):
            raise ValueError('Expected a real PDF: '+item['name'])
        results.append(dict(file=item['name'], anonymousGET='passed', sha256=digest, bytes=len(data)))
(ROOT/'docs/public-artifact-verification.json').write_text(json.dumps(dict(projectRef=IDENTITY['backendProjectRef'], legalVersion=LEGAL['version'], objects=results), indent=2)+'\n')
print(json.dumps(results, indent=2))
