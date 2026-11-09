"""Collect only explicitly selected completed XCTest runs into one evidence folder."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
parser.add_argument('bundles', nargs='+', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
expected_device = '26399755-5402-48C1-A2C9-CA26E57505AB'
args.output.mkdir(parents=True, exist_ok=True)
index_file = args.output / 'ui-results.json'
previous = json.loads(index_file.read_text())['runs'] if index_file.exists() else []
paths = list(dict.fromkeys([Path(run['resultBundle']) for run in previous] + args.bundles))


def read_result(kind, bundle):
    return json.loads(subprocess.check_output([
        'xcrun', 'xcresulttool', 'get', 'test-results', kind,
        '--path', str(bundle), '--compact',
    ]))


def cases(nodes):
    for node in nodes:
        if node.get('nodeType') == 'Test Case':
            yield {
                'identifier': node['nodeIdentifier'], 'result': node['result'],
                'durationSeconds': node.get('durationInSeconds'),
            }
        yield from cases(node.get('children', []))


runs = []
latest = {}
for bundle in paths:
    summary = read_result('summary', bundle)
    tests = read_result('tests', bundle)
    if not tests['devices'] or any(device['deviceId'] != expected_device for device in tests['devices']):
        raise SystemExit('Unexpected acceptance device: ' + str(bundle))
    entries = list(cases(tests['testNodes']))
    if not entries or summary['totalTestCount'] != len(entries):
        raise SystemExit('Missing or inconsistent executed case count: ' + str(bundle))
    run = {
        'resultBundle': str(bundle), 'startTime': summary['startTime'],
        'finishTime': summary['finishTime'], 'result': summary['result'],
        'executed': summary['totalTestCount'], 'passed': summary['passedTests'],
        'failed': summary['failedTests'], 'skipped': summary['skippedTests'],
        'devices': tests['devices'], 'cases': entries,
    }
    snapshot = bundle.with_name(bundle.stem + '-source.json')
    if snapshot.exists():
        source = json.loads(snapshot.read_text())
        app_inputs = {name: digest for name, digest in source.items() if not any(
            segment in name for segment in ['/ToliUITests/', '/TiloUITests/']
        )}
        run['currentApplicationInputsMatch'] = all(
            (root / name).exists() and hashlib.sha256((root / name).read_bytes()).hexdigest() == digest
            for name, digest in app_inputs.items()
        )
        shutil.copy2(snapshot, args.output / snapshot.name)
    for label in ['build', 'test']:
        log = bundle.with_name(bundle.stem + '-' + label + '.log')
        if log.exists():
            shutil.copy2(log, args.output / log.name)
            if label == 'build':
                run['buildSucceeded'] = '** BUILD SUCCEEDED **' in log.read_text()
    attachments = args.output / 'attachments' / bundle.stem
    manifest = attachments / 'manifest.json'
    if not manifest.exists():
        exported = subprocess.run([
            'xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(bundle),
            '--output-path', str(attachments),
        ], check=True, capture_output=True, text=True)
        (attachments / 'export.log').write_text(exported.stdout)
    run['attachments'] = str(attachments.relative_to(args.output))
    runs.append(run)
    for entry in entries:
        prior = latest.get(entry['identifier'])
        if prior is None or prior['startTime'] < run['startTime']:
            latest[entry['identifier']] = dict(entry, startTime=run['startTime'], resultBundle=str(bundle))

index = {
    'expectedDeviceID': expected_device, 'runs': sorted(runs, key=lambda run: run['startTime']),
    'latestCases': sorted(latest.values(), key=lambda case: case['identifier']),
    'distinctPassed': sum(case['result'] == 'Passed' for case in latest.values()),
    'distinctNotPassed': sum(case['result'] != 'Passed' for case in latest.values()),
}
index_file.write_text(json.dumps(index, indent=2) + '\n')
print(json.dumps({key: index[key] for key in ['distinctPassed', 'distinctNotPassed']}))
