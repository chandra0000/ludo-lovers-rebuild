#!/usr/bin/env python3
"""Run the real Flutter integration APK; capture Android's display, never a Flutter image surface."""
import base64
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

SERIAL = os.environ.get('ANDROID_SERIAL', 'emulator-5554')
OUT = Path('test-artifacts/native')
VIDEO = Path('test-artifacts/gameplay')
REMOTE = '/sdcard/ludo-qa-seeded-gameplay.mp4'


def adb(*args, timeout=15, binary=False):
    return subprocess.check_output(['adb', '-s', SERIAL, *args], timeout=timeout,
                                   text=not binary)


def screenshot(name):
    if not re.fullmatch(r'[a-z0-9-]+', name):
        raise ValueError('Invalid capture name')
    data = adb('exec-out', 'screencap', '-p', binary=True)
    if not data.startswith(b'\x89PNG\r\n\x1a\n') or len(data) < 1000:
        raise RuntimeError('Invalid native screenshot: ' + name)
    (OUT / (name + '.png')).write_bytes(data)


class StateChunks:
    """Reassemble sub-logcat-limit Unicode snapshots; reject missing/corrupt data."""
    def __init__(self):
        self.pending = {}

    def accept(self, line):
        match = re.search(r'LUDO_QA_CHUNK:(\d+):(\d+):(\d+):([A-Za-z0-9+/=]+)', line)
        if not match:
            return None
        ident, index, count = map(int, match.group(1, 2, 3))
        if not 0 <= index < count <= 128:
            raise ValueError('Invalid snapshot chunk bounds')
        total, parts = self.pending.setdefault(ident, (count, {}))
        if total != count or index in parts:
            raise ValueError('Inconsistent/duplicate snapshot chunk')
        parts[index] = match[4]
        if len(parts) < count:
            return None
        del self.pending[ident]
        return json.loads(base64.b64decode(''.join(parts[i] for i in range(count)),
                                          validate=True).decode('utf-8'))


class Recorder:
    pid = None
    stopped = False

    def start(self):
        if self.pid is not None:
            raise RuntimeError('Duplicate recording start')
        adb('shell', 'rm', '-f', REMOTE)
        result = adb('shell', 'screenrecord --bit-rate 6000000 --time-limit 120 '
                     + REMOTE + ' >/sdcard/ludo-qa-recorder.log 2>&1 & echo $!')
        self.pid = int(result.strip())
        adb('shell', 'kill', '-0', str(self.pid))

    def stop(self):
        if self.pid is None or self.stopped:
            return
        # SIGINT lets Android screenrecord write the MP4 moov atom before pull.
        adb('shell', 'kill', '-2', str(self.pid))
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline:
            live = adb('shell', f'if kill -0 {self.pid} 2>/dev/null; then cat /proc/{self.pid}/stat; fi', timeout=15).strip()
            if not live or live.split()[2] == 'Z':
                break
            time.sleep(.25)
        else:
            raise RuntimeError('Recorder did not finalize after SIGINT')
        adb('pull', REMOTE, str(VIDEO / 'gameplay-android.mp4'))
        self.stopped = True


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    VIDEO.mkdir(parents=True, exist_ok=True)
    (VIDEO / 'device-properties.txt').write_text(adb('shell', 'getprop'))
    (VIDEO / 'display.txt').write_text(adb('shell', 'wm size; wm density'))
    recorder = Recorder()
    events = []
    chunks = StateChunks()
    # Collect while the emulator is alive; post-mortem ADB may already be offline.
    log_file = (VIDEO / 'android-logcat.txt').open('w')
    logcat = subprocess.Popen(['adb', '-s', SERIAL, 'logcat', '-v', 'threadtime'],
                              stdout=log_file, stderr=subprocess.STDOUT)
    command = ['flutter', 'drive', '--no-pub',
               '--use-application-binary=build/app/outputs/flutter-apk/app-debug.apk',
               '--driver=test_driver/native_capture_driver.dart',
               '--target=integration_test/app_navigation_test.dart',
               '--dart-define=LUDO_ENABLE_UNRELEASED_MODES=true', '-d', SERIAL]
    if os.environ.get('LUDO_SOFTWARE_RENDERING') == 'true':
        command.extend(['--enable-software-rendering', '--no-enable-impeller'])
    (VIDEO / 'launch-configuration.json').write_text(json.dumps({
        'argv': command,
        'renderer': 'Skia software' if os.environ.get('LUDO_SOFTWARE_RENDERING') == 'true'
                    else 'Flutter default (emulator software OpenGL)',
        'buildMode': 'debug integration APK',
    }, indent=2))
    if os.environ.get('LUDO_GAMEPLAY_RECORDING') == 'true':
        command.append('--dart-define=LUDO_RECORD_GAMEPLAY=true')
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, bufsize=1, start_new_session=True)
    # Outer workflow is bounded too; this watchdog also protects local usage.
    import threading
    expired = threading.Event()

    def terminate():
        expired.set()
        os.killpg(proc.pid, signal.SIGTERM)
    watchdog = threading.Timer(360, terminate)
    watchdog.start()
    try:
        with (VIDEO / 'integration.log').open('w') as transcript:
            for line in proc.stdout:
                print(line, end='', flush=True)
                transcript.write(line)
                transcript.flush()
                if 'LUDO_RECORD_START' in line:
                    recorder.start()
                elif 'LUDO_RECORD_STOP' in line:
                    recorder.stop()
                match = re.search(r'LUDO_NATIVE_CAPTURE:(native-[a-z0-9-]+)', line)
                if match:
                    screenshot(match[1])
                snapshot = chunks.accept(line)
                if snapshot is not None:
                    snapshot['hostMonotonic'] = time.monotonic()
                    events.append(snapshot)
                for marker in ['LUDO_QA_EVENT:']:
                    if marker in line:
                        data = json.loads(line.split(marker, 1)[1])
                        data['hostMonotonic'] = time.monotonic()
                        events.append(data)
                        if marker == 'LUDO_QA_EVENT:':
                            screenshot('recording-' + data['stage'])
            if chunks.pending:
                raise RuntimeError('Missing authoritative snapshot chunks')
            result = proc.wait(timeout=10)
            if expired.is_set():
                raise RuntimeError('Integration exceeded bounded 360s execution')
            if result:
                raise subprocess.CalledProcessError(result, command)
            if os.environ.get('LUDO_GAMEPLAY_RECORDING') == 'true' and not recorder.stopped:
                raise RuntimeError('Recording test never finalized a video')
    finally:
        watchdog.cancel()
        (VIDEO / 'authoritative-events.json').write_text(json.dumps(events, indent=2))
        primary_failure = sys.exc_info()[0] is not None
        cleanup_error = None
        try:
            recorder.stop()
        except Exception as error:
            cleanup_error = error
            print('Recorder cleanup failure: ' + repr(error), flush=True)
        finally:
            logcat.terminate()
            logcat.wait(timeout=5)
            log_file.close()
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGTERM)
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid, signal.SIGKILL)
                    proc.wait(timeout=5)
        if cleanup_error is not None and not primary_failure:
            raise cleanup_error


if __name__ == '__main__':
    main()
