"""Upload the fixed local manifest and verify public bytes. Requires temporary import authorization."""
import concurrent.futures,hashlib,json,ssl,urllib.request
from pathlib import Path
import certifi
config=json.loads(Path('/private/tmp/toli-ingest-config.json').read_text())
context=ssl.create_default_context(cafile=certifi.where())
def upload(item):
 data=Path(item['path']).read_bytes()
 if len(data)!=item['bytes'] or hashlib.sha256(data).hexdigest()!=item['sha256']:raise ValueError('Local bytes changed: '+item['key'])
 req=urllib.request.Request(config['url']+'/functions/v1/catalog-ingest',data=data,method='POST',headers={'Authorization':'Bearer '+config['token'],'X-Tilo-Object':item['bucket']+'/'+item['key'],'Content-Type':item['mime']})
 with urllib.request.urlopen(req,context=context,timeout=90) as response:result=json.load(response)
 url=config['url']+'/storage/v1/object/public/'+item['bucket']+'/'+item['key']
 with urllib.request.urlopen(url,context=context,timeout=90) as response:
  remote=response.read();mime=response.headers.get_content_type()
 if len(remote)!=item['bytes'] or hashlib.sha256(remote).hexdigest()!=item['sha256'] or mime!=item['mime']:raise ValueError('Public bytes mismatch: '+item['key'])
 return {**{k:v for k,v in item.items() if k!='path'},'publicURL':url,'status':'verified'}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(upload,config['objects']))
out=Path(__file__).resolve().parents[2]/'docs/BackendAPI/media-upload-manifest.json'
out.write_text(json.dumps({'objects':results},indent=2))
print(json.dumps({'objectsVerified':len(results),'bytes':sum(x['bytes'] for x in results)}))
