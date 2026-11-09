"""Inspect Tilo source, assets and metadata without compiling or running the app."""
from pathlib import Path
import json, plistlib, re, hashlib, struct
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
APP=ROOT/'TiloApp/Tilo'
IDENTITY=json.loads((ROOT/'TiloApp/Configuration/Identity.json').read_text())
ORIGIN='https://'+IDENTITY['backendProjectRef']+'.supabase.co/'
errors=[]
checks=0

def check(condition, message):
    global checks
    checks+=1
    if not condition: errors.append(message)

info=plistlib.loads((APP/'Support/Info.plist').read_bytes())
check(info['CFBundleDisplayName']=='Tilo','Display name must be Tilo')
check(IDENTITY['displayName']==info['CFBundleDisplayName'],'Display name must match Identity.json')
check(IDENTITY['target']=='Tilo' and IDENTITY['scheme']=='Tilo','Target and scheme must be Tilo')
check(info['CFBundleLocalizations']==['en'],'App language must be English')
check(info['UISupportedInterfaceOrientations']==['UIInterfaceOrientationPortrait'],'Portrait-only orientation')
check(info['UIAppFonts']==['Kalam-Bold.ttf','ComicNeue-Regular.ttf'],'Both custom fonts must register')
config=(ROOT/'TiloApp/project.yml').read_text()
for expected in ['TARGETED_DEVICE_FAMILY: "1"','SUPPORTS_MACCATALYST: false','SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: false','SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD: false','PRODUCT_BUNDLE_IDENTIFIER: com.toli.cooking','exactVersion: 2.55.6']:
    check(expected in config,'Missing project setting: '+expected)
for name in info['UIAppFonts']:
    raw=(APP/'Resources/Fonts'/name).read_bytes()
    count=struct.unpack_from('>H',raw,4)[0]
    tables={}
    for index in range(count):
        tag,checksum,offset,length=struct.unpack_from('>4sIII',raw,12+index*16)
        tables[tag]=(offset,length)
    offset,length=tables[b'name']
    fmt,count,string_offset=struct.unpack_from('>HHH',raw,offset)
    names=set()
    for index in range(count):
        platform,encoding,language,name_id,size,start=struct.unpack_from('>HHHHHH',raw,offset+6+index*12)
        if name_id==6:
            value=raw[offset+string_offset+start:offset+string_offset+start+size]
            names.add(value.decode('utf-16-be' if platform in (0,3) else 'mac_roman'))
    check(name[:-4] in names,'Font PostScript name mismatch: '+name)
    check((APP/'Resources/Fonts'/('Kalam-OFL.txt' if name.startswith('Kalam') else 'ComicNeue-OFL.txt')).exists(),'Missing font license')

sources=list(APP.rglob('*.swift'))
combined='\n'.join(p.read_text() for p in sources)
check(combined.count('@main ')==1,'Exactly one application entry required')
check('UIImage(systemName:' not in combined,'System image used')
check(not re.search(r'\b(systemFont|boldSystemFont|italicSystemFont|monospacedSystemFont)\s*\(',combined),'System font used')
for file in sources:
    data=file.read_text()
    check(not re.search(r'[ \t]+$',data,re.MULTILINE),'Trailing source whitespace: '+file.name)
    check(not re.search(r'[\u4e00-\u9fff]',data),'Non-English authored text: '+str(file.relative_to(ROOT)))
    check(not re.search(r'\\u[0-9a-fA-F]{4}',data),'Invalid JSON-style Swift Unicode escape: '+file.name)
    check(not re.search(r'\b(TODO|FIXME|fatalError\("TODO)',data),'Unfinished marker: '+file.name)
    check(not re.search(r'com\.(toti|bibi|teto)|yepycfnkkfrfmuwdekka|gjodhvpzkdnxdjmorjfw',data),'Foreign project configuration: '+file.name)

catalog=APP/'Resources/Assets.xcassets'
for file in catalog.rglob('Contents.json'):
    content=json.loads(file.read_text())
    for item in content.get('images',[]):
        if 'filename' in item: check((file.parent/item['filename']).is_file(),'Missing catalog image '+str(file.parent/item['filename']))
for folder in catalog.glob('icon-*.imageset'):
    image=Image.open(folder/(folder.stem+'.png'))
    check(image.mode=='RGBA' and image.getchannel('A').getextrema()[0]==0,'Icon is not transparent: '+folder.stem)
check(len(list(catalog.glob('icon-*.imageset')))==39,'Expected 39 generated icons')
icon=Image.open(catalog/'AppIcon.appiconset/AppIcon.png')
check(icon.size==(1024,1024) and icon.mode=='RGB','Opaque 1024px app icon')
products=json.loads((APP/'Resources/PurchaseProducts.json').read_text())
fixture=json.loads((ROOT/'TiloApp/Configuration/TiloDiamonds.storekit').read_text())
check(len(products)==9 and all(re.fullmatch('[a-z]{16}',key) and value>0 for key,value in products.items()),'Nine unique 16-letter consumable IDs required')
check(IDENTITY['purchaseProducts']==products,'Identity product mapping mismatch')
check({item['productID']:int(item['localizations'][0]['displayName'].split(' ')[0].replace(',','')) for item in fixture['products']}==products,'Fixture diamond quantities must match delivery configuration')
check(all(item['type']=='Consumable' for item in fixture['products']),'Fixture products must all be consumables')
import csv
reference=list(csv.DictReader((ROOT/'docs/purchase-products.csv').open()))
check({row['product_id']:int(row['diamonds']) for row in reference}==products,'Product comparison quantities mismatch')
check({row['product_id']:row['reference_price_usd'] for row in reference}=={item['productID']:item['displayPrice'] for item in fixture['products']},'Reference price and fixture mismatch')
for name in ['Tilo','TiloAppStore','TiloPurchases','TiloLocalStore']:
    scheme=ROOT/('TiloApp/Tilo.xcodeproj/xcshareddata/xcschemes/'+name+'.xcscheme')
    has_fixture='StoreKitConfigurationFileReference' in scheme.read_text()
    check(has_fixture==(name in ['Tilo','TiloPurchases','TiloLocalStore']),'StoreKit environment mismatch: '+name)
    if has_fixture:
        check('../../Configuration/TiloDiamonds.storekit' in scheme.read_text(),'Invalid local fixture reference: '+name)
check('TiloDiamonds.storekit in Resources' in (ROOT/'TiloApp/Tilo.xcodeproj/project.pbxproj').read_text(),'Purchase test fixture must be copied to the test bundle')

recipes=json.loads((ROOT/'docs/catalog-recipes.json').read_text())
videos=json.loads((ROOT/'docs/catalog-videos.json').read_text())
check(len(recipes)==12 and len({r['id'] for r in recipes})==12,'Recipe count/IDs')
check(len(videos)==6 and len({r['id'] for r in videos})==6,'Replay count/IDs')
for recipe in recipes:
    payload=recipe['payload']
    check(payload['servings']>0 and payload['ingredients'] and payload['steps'],'Incomplete recipe: '+recipe['id'])
    check(recipe['image_url'].startswith(ORIGIN),'Recipe media outside own cloud')
manifest=json.loads((ROOT/'Assets/SourceMedia/manifest.json').read_text())
uploads=json.loads((ROOT/'docs/BackendAPI/media-upload-manifest.json').read_text())
catalog_uploads=[item for item in uploads['objects'] if item['bucket']=='toli-catalog']
expected_media={}
for record in manifest['records']:
    expected_media[record['asset']]=record['SHA256']
    if record['kind']=='video':
        expected_media[record['coverAsset']]=record['coverSHA256']
        check(len(record.get('inspectionTimes',[]))==3 and bool(record.get('visualInspection')),'Video inspection missing: '+record['id'])
check(len(catalog_uploads)==29 and {item['key'] for item in catalog_uploads}==set(expected_media),'Cloud catalog manifest must cover all photos, replays and covers')
for item in catalog_uploads:
    key=item['key']
    check(item['sha256']==expected_media.get(key),'Cloud media manifest hash mismatch: '+key)
    check(item['publicURL']==ORIGIN+'storage/v1/object/public/toli-catalog/'+key,'Cloud media manifest URL mismatch: '+key)
project=(ROOT/'TiloApp/Tilo.xcodeproj/project.pbxproj').read_text()
families=re.findall(r'TARGETED_DEVICE_FAMILY = "?([^";\n]+)"?;',project)
check(bool(families) and all(value.strip()=='1' for value in families),'Generated target settings must remain iPhone-only; platform presets must not override project defaults')
for file in sources:
    check(file.name in project,'Source missing from generated Xcode metadata: '+file.name)
check('cooking-01.mp4' not in project and 'recipe-01.jpg' not in project,'Business media must not be bundled')
check('com.toli.cooking' in project and 'com.teto.dance' not in project,'Generated identity mismatch')
check('SWIFT_VERSION = 5.0' in project,'Swift version mismatch')
check('PRODUCT_NAME = Tilo;' in project and 'path = Tilo.app;' in project,'Generated product must be Tilo.app')
check(not any('Toli' in str(path.relative_to(ROOT/'TiloApp')) for path in (ROOT/'TiloApp').rglob('*') if 'xcuserdata' not in path.parts),'Current project filenames must use Tilo')
legal=json.loads((ROOT/'docs/BackendAPI/legal/manifest.json').read_text())
for item in legal['files']:
    check(hashlib.sha256((ROOT/'docs/BackendAPI/legal'/item['file']).read_bytes()).hexdigest()==item['sha256'],'Legal local hash mismatch: '+item['file'])
    source=ROOT/'docs/BackendAPI/legal'/Path(item['file']).with_suffix('.md')
    check(hashlib.sha256(source.read_bytes()).hexdigest()==item['sourceSHA256'],'Legal source hash mismatch: '+source.name)
    check('Tilo' in source.read_text() and not re.search(r'\bToli\b',source.read_text()),'Legal app name must be Tilo: '+source.name)
previous_legal=json.loads((ROOT/'docs/BackendAPI/legal'/legal['previousVersionArchive']/'manifest.json').read_text())
check([item['publicURL'] for item in legal['files']]==[item['publicURL'] for item in previous_legal['files']],'Legal public URLs must remain unchanged')
legal_digest=hashlib.sha256((ROOT/'docs/BackendAPI/legal/terms.md').read_bytes()+b'\n\n'+(ROOT/'docs/BackendAPI/legal/privacy.md').read_bytes()).hexdigest()[:12]
check(legal['version']==legal['effectiveDate']+'-'+legal_digest,'Legal version must derive from current sources')
check(legal['version'] in (ROOT/'supabase/legal-name-update.sql').read_text(),'Deployment script must match current legal version')
check('cachePolicy: .reloadIgnoringLocalCacheData' in (APP/'Features/Social/SettingsController.swift').read_text(),'Legal viewer must refresh unchanged URLs')
backend_config=(APP/'Backend/TiloBackendConfiguration.swift').read_text()
check(ORIGIN.rstrip('/') in backend_config,'Backend configuration must match the selected project')
check(('agreementVersion = "'+legal['version']+'"') in backend_config,'Consent version must match exact legal content')
result={'scope':'Static files/resources/metadata only; no compilation, typechecking or runtime tests','checks':checks,'failures':errors}
(ROOT/'docs/static-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
raise SystemExit(bool(errors))
