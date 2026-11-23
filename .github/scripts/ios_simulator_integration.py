#!/usr/bin/env python3
"""Bound build/install/launch/attach separately; never silently wait after Xcode."""
import json
import os
from pathlib import Path
import plistlib
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

DIAGNOSTICS = Path('../../simulator-diagnostics')


def run(stage, args, seconds, capture=False, env=None):
    print(f'IOS STAGE: {stage}', flush=True)
    return subprocess.run(args, check=True, timeout=seconds, text=True, env=env,
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
        # Keep Xcode/Flutter compilation out of the running simulator's resource budget.
        run('build integration app', ['flutter', 'build', 'ios', '--simulator', '--debug', '--no-codesign', '--no-pub',
            '--target=integration_test/app_navigation_test.dart', '--dart-define=LUDO_ENABLE_UNRELEASED_MODES=true'], 300)
        device_id = run('create isolated simulator', ['xcrun', 'simctl', 'create',
                        'Ludo CI ' + os.environ.get('GITHUB_RUN_ID', 'local'),
                        type_ids[template['name']], runtime], 30, True).strip()
        (DIAGNOSTICS / 'selected-simulator.json').write_text(json.dumps(
            dict(id=device_id, name=template['name'], runtime=runtime), indent=2))
        print(f'Selected {template["name"]}, {runtime}, {device_id}', flush=True)
        run('boot', ['xcrun', 'simctl', 'boot', device_id], 30)
        run('boot readiness', ['xcrun', 'simctl', 'bootstatus', device_id, '-b'], 180)
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
        launch_args = ['xcrun', 'simctl', 'launch',
            device_id, bundle_id, '--enable-dart-profiling',
            f'--vm-service-port={port}', '--disable-service-auth-codes', '--disable-vm-service-publication']
        (DIAGNOSTICS / 'launch-configuration.json').write_text(json.dumps(launch_args, indent=2))
        # The fresh simulator has no previous Runner. Wait for the service
        # directly so a delayed simctl acknowledgement cannot mask a ready VM.
        with (DIAGNOSTICS / 'integration-console.txt').open('w') as console:
            launch = subprocess.Popen(launch_args, stdout=console, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 60
                while not vm_ready(uri):
                    status = launch.poll()
                    if status not in (None, 0):
                        raise subprocess.CalledProcessError(status, launch_args)
                    if time.monotonic() >= deadline:
                        raise TimeoutError('Simulator VM service did not become ready within 60s')
                    time.sleep(.25)
            finally:
                if launch.poll() is None:
                    launch.terminate()
                    try:
                        launch.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        launch.kill()
                        launch.wait(timeout=5)
        # Run the same Dart host driver used by Flutter's startTest directly.
        # run45016648518 completed all four on-device tests, but flutter drive
        # spent ~172s in attach/tool setup before its host connected, exhausting
        # the existing 180s result window. The app and VM are already ready here;
        # do not repeat device discovery/DDS setup or enlarge the timeout.
        run('attach integration driver', ['dart',
            'test_driver/native_capture_driver.dart'], 180,
            env={**os.environ, 'VM_SERVICE_URL': uri})
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
        if device_id:
            if sys.exc_info()[0] is not None:
                for label, command in [
                    ('failure-state.png', ['xcrun','simctl','io',device_id,'screenshot',str(DIAGNOSTICS/'failure-state.png')]),
                    ('failure-services.txt', ['xcrun','simctl','spawn',device_id,'log','show','--last','2m','--style','compact',
                        '--predicate','process == "Runner" OR process == "SpringBoard" OR process == "launchd_sim"']),
                ]:
                    try:
                        captured = run('failure diagnostic '+label, command, 10, True)
                        if label.endswith('.txt'):
                            (DIAGNOSTICS/label).write_text(captured)
                    except (subprocess.SubprocessError, OSError) as error:
                        print('Failure diagnostic unavailable: '+str(error), flush=True)
            for action in ['shutdown', 'delete']:
                try:
                    run('cleanup ' + action, ['xcrun', 'simctl', action, device_id], 20)
                except (subprocess.SubprocessError, OSError) as error:
                    print(f'Cleanup diagnostic: {error}', flush=True)


if __name__ == '__main__':
    main()
