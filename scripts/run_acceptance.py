"""Build, install and run current Tilo on the owner-selected iPhone simulator."""
from pathlib import Path
import argparse, hashlib, json, re, subprocess, time

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['build','test','launch'])
parser.add_argument('--only', action='append', default=[])
parser.add_argument('--label', default='acceptance')
parser.add_argument('--evidence-dir', type=Path, help='Store build logs, source hashes and XCTest results in a durable directory.')
parser.add_argument('--case-timeout', type=int, default=420, help='Maximum XCTest execution time per case, in seconds.')
args = parser.parse_args()
if args.case_timeout < 60:
    parser.error('--case-timeout must be at least 60 seconds')
methods = set(re.findall(r'func (test\w+)\(', (ROOT/'TiloApp/TiloUITests/TiloAcceptanceTests.swift').read_text()))
for selected in args.only:
    method = selected.rsplit('/', 1)[-1]
    if method.startswith('test') and method not in methods:
        raise SystemExit('Unknown acceptance test method: '+method)

DEVICES = json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))['devices']
match = [(runtime, device) for runtime, devices in DEVICES.items() for device in devices if device['name']=='Tilo UI Acceptance']
if len(match)!=1 or 'iPhone' not in match[0][1].get('deviceTypeIdentifier',''):
    raise SystemExit('Exactly one iPhone simulator named Tilo UI Acceptance is required.')
runtime, device = match[0]
if device['state']!='Booted': raise SystemExit('Tilo UI Acceptance must be booted before acceptance.')
identifier = device['udid']
# A second runner can terminate this job's app even when each suite is serial.
processes=subprocess.check_output(['ps','-axo','pid=,command='],text=True)
for line in processes.splitlines():
    match=re.match(r'\s*(\d+)\s+(\S*/xcodebuild)\s+(.*)',line)
    if match and identifier in match[3] and re.search(r'(^|\s)(test|test-without-building)(\s|$)',match[3]):
        raise SystemExit('Acceptance simulator is busy with another xcodebuild test (PID '+match[1]+'). Wait for that job to release '+device['name']+'.')

stamp=time.strftime('%Y%m%d-%H%M%S',time.gmtime())
evidence_dir = args.evidence_dir.resolve() if args.evidence_dir else Path('/private/tmp')
evidence_dir.mkdir(parents=True, exist_ok=True)
prefix = evidence_dir / ('toli-' + args.label + '-' + stamp)
if args.mode != 'launch':
    inputs = list((ROOT/'TiloApp/Tilo').rglob('*.swift')) + list((ROOT/'TiloApp/TiloUITests').rglob('*.swift'))
    inputs += [ROOT/'TiloApp/project.yml', ROOT/'TiloApp/Tilo/Resources/PurchaseProducts.json']
    snapshot = {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(inputs)}
    Path(str(prefix)+'-source.json').write_text(json.dumps(snapshot, indent=2)+'\n')

base=['xcodebuild','-project',str(ROOT/'TiloApp/Tilo.xcodeproj'),'-scheme','Tilo','-configuration','Debug','-sdk','iphonesimulator','-destination','id='+identifier,'-derivedDataPath','/private/tmp/TiloAcceptanceDerivedData','-clonedSourcePackagesDirPath','/private/tmp/TiloAcceptancePackages','-disableAutomaticPackageResolution','-skipPackageUpdates','CODE_SIGNING_ALLOWED=YES','CODE_SIGN_IDENTITY=-']

def run(command,label):
    log=Path(str(prefix)+'-'+label+'.log')
    print('Starting '+label+': '+str(log),flush=True)
    with log.open('w') as stream: result=subprocess.run(command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT)
    lines=log.read_text().splitlines()
    signal=[line for line in lines if 'error:' in line or '** BUILD' in line or '** TEST' in line or 'Test Case' in line or 'Executed ' in line]
    print('\n'.join(signal[-45:]),flush=True)
    print('Exit: '+str(result.returncode),flush=True)
    if result.returncode: raise SystemExit(result.returncode)

if args.mode!='launch':
    subprocess.run(['xcodegen','generate','--spec',str(ROOT/'TiloApp/project.yml')],cwd=ROOT,check=True)
    run(base+['build'],'build')
app=Path('/private/tmp/TiloAcceptanceDerivedData/Build/Products/Debug-iphonesimulator/Tilo.app')
if not app.exists(): raise SystemExit('Current-source Tilo.app is missing.')
subprocess.run(['xcrun','simctl','install',identifier,str(app)],check=True)
subprocess.run(['xcrun','simctl','launch',identifier,'com.toli.cooking'],check=True)
if args.mode=='test':
    result_path=str(prefix)+'.xcresult'
    command = base + [
        '-parallel-testing-enabled', 'NO',
        '-maximum-concurrent-test-simulator-destinations', '1',
        '-test-timeouts-enabled', 'YES',
        '-default-test-execution-time-allowance', str(args.case_timeout),
        '-maximum-test-execution-time-allowance', str(args.case_timeout),
        '-resultBundlePath', result_path, 'test',
    ]
    command += ['-only-testing:'+name for name in args.only]
    run(command,'test')
    print('Result: '+result_path,flush=True)
print('Device: '+device['name']+' / '+identifier,flush=True)
print('Built package: '+str(app),flush=True)
