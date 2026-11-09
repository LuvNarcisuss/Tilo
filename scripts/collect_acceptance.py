"""Collect actual completed Xcode test outcomes without running or changing the app."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('results', nargs='+', type=Path)
args = parser.parse_args()
output = ROOT/'docs/runtime-acceptance/results'
output.mkdir(parents=True, exist_ok=True)
previous_index = output/'index.json'
previous_paths = [Path(run['resultBundle']) for run in json.loads(previous_index.read_text())['runs']] if previous_index.exists() else []
result_paths = list(dict.fromkeys(previous_paths + args.results))
expected_device = '26399755-5402-48C1-A2C9-CA26E57505AB' 
runs = []
latest = {}

def report(kind, path):
    return json.loads(subprocess.check_output(['xcrun','xcresulttool','get','test-results',kind,'--path',str(path),'--compact']))

def cases(nodes):
    for node in nodes:
        if node.get('nodeType') == 'Test Case':
            yield {'identifier':node['nodeIdentifier'], 'result':node['result'], 'durationSeconds':node.get('durationInSeconds')}
        yield from cases(node.get('children', []))

for path in result_paths:
    summary = report('summary',path)
    tests = report('tests',path)
    if any(device['deviceId'] != expected_device for device in tests['devices']):
        raise SystemExit('Unexpected device in '+str(path))
    entries = list(cases(tests['testNodes']))
    if not entries or summary['totalTestCount'] != len(entries):
        raise SystemExit('Missing or inconsistent executed case count in '+str(path))
    run = {'resultBundle':str(path), 'startTime':summary['startTime'], 'finishTime':summary['finishTime'],
           'result':summary['result'], 'executed':summary['totalTestCount'], 'passed':summary['passedTests'],
           'failed':summary['failedTests'], 'skipped':summary['skippedTests'], 'devices':tests['devices'], 'cases':entries}
    source = path.with_name(path.stem+'-source.json')
    if source.exists():
        snapshot = json.loads(source.read_text())
        run['sourceSnapshot'] = source.name
        run['currentSourceMatches'] = all((ROOT/name).exists() and hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == digest for name,digest in snapshot.items())
        (output/source.name).write_text(json.dumps(snapshot,indent=2)+'\n')
    build = path.with_name(path.stem+'-build.log')
    run['buildSucceeded'] = build.exists() and '** BUILD SUCCEEDED **' in build.read_text()
    (output/(path.stem+'.json')).write_text(json.dumps(run,indent=2)+'\n')
    runs.append(run)
    for entry in entries:
        previous = latest.get(entry['identifier'])
        if previous is None or previous['startTime'] < run['startTime']:
            latest[entry['identifier']] = dict(entry, startTime=run['startTime'], resultBundle=str(path))
index = {'generatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(), 'expectedDeviceID':expected_device,
         'runs':sorted(runs,key=lambda run:run['startTime']), 'latestCases':sorted(latest.values(),key=lambda case:case['identifier'])}
index['uniqueLatestPassed'] = sum(case['result']=='Passed' for case in latest.values())
index['uniqueLatestFailed'] = sum(case['result']!='Passed' for case in latest.values())
(output/'index.json').write_text(json.dumps(index,indent=2)+'\n')
print(json.dumps({'completedRuns':len(runs),'uniqueLatestPassed':index['uniqueLatestPassed'],'uniqueLatestFailed':index['uniqueLatestFailed']}))
