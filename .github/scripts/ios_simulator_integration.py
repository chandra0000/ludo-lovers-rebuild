#!/usr/bin/env python3
"""Bound build/install/launch/attach separately; never silently wait after Xcode."""
import json
import os
from pathlib import Path
import plistlib
import socket
import subprocess
import time
import urllib.error
import urllib.request

DIAGNOSTICS = Path('../../simulator-diagnostics')


def run(stage, args, seconds, capture=False):
    print(f'IOS STAGE: {stage}', flush=True)
    return subprocess.run(args, check=True, timeout=seconds, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def vm_ready(uri):
    try:
        with urllib.request.urlopen(uri + 'getVM', timeout=1) as response:
            return json.load(response).get('result', {}).get('type') == 'VM'
    except (OSError, ValueError, urllib.error.URLError):
        return False


def main():
    DIAGNOSTICS.mkdir(parents=True, exist_ok=True)
    device_id = None
    console = None
    log = None
    unified = None
    unified_log = None
    try:
        devices = json.loads(run('discover runtimes', ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], 30, True))['devices']
        types = json.loads(run('discover device types', ['xcrun', 'simctl', 'list', 'devicetypes', '-j'], 30, True))['devicetypes']
        type_ids = {item['name']: item['identifier'] for item in types}
        choices = [(runtime, device) for runtime, rows in devices.items() if 'iOS' in runtime
                   for device in rows if device.get('isAvailable') and device['name'].startswith('iPhone')
                   and device['name'] in type_ids]
        if not choices:
            raise RuntimeError('No compatible available iPhone simulator runtime')
        runtime, template = choices[0]
        device_id = run('create isolated simulator', ['xcrun', 'simctl', 'create',
                        'Ludo CI ' + os.environ.get('GITHUB_RUN_ID', 'local'),
                        type_ids[template['name']], runtime], 30, True).strip()
        (DIAGNOSTICS / 'selected-simulator.json').write_text(json.dumps(
            dict(id=device_id, name=template['name'], runtime=runtime), indent=2))
        print(f'Selected {template["name"]}, {runtime}, {device_id}', flush=True)
        run('boot', ['xcrun', 'simctl', 'boot', device_id], 30)
        run('boot readiness', ['xcrun', 'simctl', 'bootstatus', device_id, '-b'], 180)
        run('build integration app', ['flutter', 'build', 'ios', '--simulator', '--debug', '--no-codesign', '--no-pub',
            '--target=integration_test/app_navigation_test.dart', '--dart-define=LUDO_ENABLE_UNRELEASED_MODES=true'], 300)
        app = Path('build/ios/iphonesimulator/Runner.app').resolve()
        with (app / 'Info.plist').open('rb') as stream:
            bundle_id = plistlib.load(stream)['CFBundleIdentifier']
        run('install', ['xcrun', 'simctl', 'install', device_id, str(app)], 90)
        # Flutter's engine publishes the VM-service URI through Apple's unified
        # logging on modern iOS, not necessarily the simctl console stdout pipe.
        # Match the SDK log reader's channel and start it before launching Runner.
        unified_path = DIAGNOSTICS / 'integration-unified.txt'
        unified_log = unified_path.open('w')
        unified = subprocess.Popen(['xcrun', 'simctl', 'spawn', device_id,
            'log', 'stream', '--style', 'compact', '--level', 'debug',
            '--predicate', 'process == "Runner"'], stdout=unified_log,
            stderr=subprocess.STDOUT, text=True)
        # Avoid a race with the engine's one-shot startup log announcement.
        # This isolated CI simulator exposes its debug service on loopback only;
        # no auth relaxation is applied to production apps or device builds.
        with socket.socket() as reservation:
            reservation.bind(('127.0.0.1', 0))
            port = reservation.getsockname()[1]
        uri = f'http://127.0.0.1:{port}/'
        # A console-attached simctl launch stalled without acknowledging a PID
        # in run45011448495. Separate launch acknowledgement from VM readiness;
        # retain unified logs rather than blocking launch on console attachment.
        launch_args = ['xcrun', 'simctl', 'launch', '--terminate-running-process',
            device_id, bundle_id, '--enable-dart-profiling',
            f'--vm-service-port={port}', '--disable-service-auth-codes', '--disable-vm-service-publication']
        result = subprocess.run(launch_args, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=30)
        (DIAGNOSTICS / 'integration-console.txt').write_text(result.stdout)
        print('IOS STAGE: launch acknowledgement\n' + result.stdout, flush=True)
        result.check_returncode()
        deadline = time.monotonic() + 60
        ready = False
        while time.monotonic() < deadline:
            ready = vm_ready(uri)
            if ready:
                break
            time.sleep(.1)
        if not ready:
            raise TimeoutError('No VM service within 60s; see integration-console.txt and integration-unified.txt')
        # Attach directly to the ready local service instead of Flutter's
        # implicit install/launch/log-discovery path that stalled in the failed run.
        run('attach integration driver', ['flutter', 'drive', '--no-pub',
            '--driver=test_driver/native_capture_driver.dart', '--use-existing-app=' + uri,
            '--no-keep-app-running', '-d', device_id], 180)
        run('verify native PNGs', ['python3', 'tool/verify_responsive_screenshots.py',
            '--native-directory', 'test-artifacts/native'], 30)
    finally:
        if unified is not None and unified.poll() is None:
            unified.terminate()
            try:
                unified.wait(timeout=5)
            except subprocess.TimeoutExpired:
                unified.kill()
                unified.wait(timeout=5)
        if unified_log is not None:
            unified_log.close()
        if console is not None and console.poll() is None:
            console.terminate()
            try:
                console.wait(timeout=5)
            except subprocess.TimeoutExpired:
                console.kill()
                console.wait(timeout=5)
        if log is not None:
            log.close()
        if device_id:
            for action in ['shutdown', 'delete']:
                try:
                    run('cleanup ' + action, ['xcrun', 'simctl', action, device_id], 20)
                except (subprocess.SubprocessError, OSError) as error:
                    print(f'Cleanup diagnostic: {error}', flush=True)


if __name__ == '__main__':
    main()
