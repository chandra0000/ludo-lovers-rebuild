#!/usr/bin/env python3
"""Normal APK process-death acceptance on a disposable emulator, no mock prefs."""
import copy
import json
from pathlib import Path
import subprocess
import time
import xml.etree.ElementTree as ET

import android_native_qa as native

PACKAGE = 'com.ludolovers.ludo_lovers'
OUT = Path('test-artifacts/process-recovery')


def require_disposable_emulator(serial, qemu):
    if not serial.startswith('emulator-') or qemu.strip() != '1':
        raise RuntimeError('Refusing app install/clear/force-stop outside an emulator')


def decode_preferences(text):
    root = ET.fromstring(text)
    entries = [n for n in root.findall('string')
               if n.get('name') == 'flutter.saved_local_match_v1']
    if len(entries) != 1:
        raise ValueError('Expected one actual native saved-match preference')
    value = json.loads(entries[0].text)
    if value.get('schemaVersion') != 4 or not isinstance(value.get('game'), dict):
        raise ValueError('Unexpected native snapshot schema')
    return value


def saved():
    return decode_preferences(native.adb('exec-out', 'run-as', PACKAGE, 'cat',
        'shared_prefs/FlutterSharedPreferences.xml'))


def wait_snapshot(predicate, seconds=15):
    deadline = time.monotonic() + seconds
    last = None
    while time.monotonic() < deadline:
        try:
            last = saved()
            if predicate(last):
                return last
        except (subprocess.SubprocessError, ET.ParseError, ValueError):
            pass  # File may not exist until first acknowledged native write.
        time.sleep(.1)
    raise TimeoutError('Native saved state did not reach expected condition: ' + repr(last))


def ready_nodes():
    try:
        return native.ui_nodes()
    except (subprocess.SubprocessError, ET.ParseError) as error:
        # UIAutomator may start before Android exposes its first window/XML.
        # Retain each failure and let the caller's original deadline bound it.
        with (OUT / 'ui-readiness.jsonl').open('a') as log:
            log.write(json.dumps({'error': repr(error)}) + '\n')
        return []


def find_action(label, seconds=30, scroll=False, activate=True):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        nodes = ready_nodes()
        present = any(label in (n.get('text', '') + n.get('content-desc', '')) for n in nodes)
        if present and (not activate or native.tap_label(label, nodes)):
            return
        if scroll:
            native.adb('shell', 'input', 'swipe', '180', '650', '180', '290', '350')
        time.sleep(.2)
    raise TimeoutError('Actual installed UI action absent: ' + label)


def unchanged_match(before, after, count):
    """Accept only unchanged recovery or one legitimate no-move pass after roll."""
    roster = ['orange', 'magenta'] if count == 2 else ['orange', 'green', 'magenta']
    for snapshot in [before, after]:
        game = snapshot['game']
        assert snapshot['aiPlayers'] == [], 'This acceptance must use all-human seats'
        assert snapshot['configuration']['activePlayers'] == roster
        assert game['configuration'] == snapshot['configuration']
        assert game['winner'] is None
        assert all(p['pawnProgress'] == [-1] * 4 for p in game['players'])
        assert len(set(game['appliedCommandIds'])) == len(game['appliedCommandIds'])
        assert sum(c.endswith('-roll') for c in game['appliedCommandIds']) == 1
        if game['stateVersion'] == 1:
            assert game['diceValue'] in range(1, 7)
            assert game['activePlayer'] == 'orange'
            assert len(game['appliedCommandIds']) == 1
        else:
            assert game['stateVersion'] == 2 and game['diceValue'] is None
            assert game['activePlayer'] == roster[1]
            assert len(game['appliedCommandIds']) == 2
            assert sum(c.endswith('-pass') for c in game['appliedCommandIds']) == 1
    b, a = before['game'], after['game']
    assert b['stateVersion'] in (1, 2), 'One real roll, at most its no-move pass'
    assert len(b['appliedCommandIds']) == b['stateVersion']
    if a == b:
        assert before == after, 'Profiles/settings changed during recovery'
        return 'identical'
    assert b['stateVersion'] == 1 and b['diceValue'] in range(1, 6)
    assert a['stateVersion'] == 2 and a['diceValue'] is None
    assert b['activePlayer'] == 'orange' and a['activePlayer'] == roster[1]
    assert set(b['appliedCommandIds']).issubset(a['appliedCommandIds'])
    assert len(a['appliedCommandIds']) == 2
    assert sum(c.endswith('-roll') for c in a['appliedCommandIds']) == 1
    assert sum(c.endswith('-pass') for c in a['appliedCommandIds']) == 1
    normalized = copy.deepcopy(after)
    for key in ['stateVersion', 'diceValue', 'activePlayer', 'appliedCommandIds']:
        normalized['game'][key] = b[key]
    assert normalized == before, 'Unrelated state changed during automatic pass'
    return 'one-authorized-no-move-pass'


def launch():
    output = native.adb('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
    with (OUT / 'launches.jsonl').open('a') as log:
        log.write(json.dumps({'output': output}) + '\n')
    if 'Error' in output:
        raise RuntimeError('Android rejected application launch: ' + output)


def reach_home():
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        nodes = ready_nodes()
        if any(n.get('package') == PACKAGE and
               'PLAY NOW' in (n.get('text', '') + n.get('content-desc', '')) for n in nodes):
            return
        # Current production startup navigates directly to Home. Do not send
        # legacy SKIP taps into an unrelated Android/launcher window.
        time.sleep(.2)
    raise TimeoutError('Normal startup did not reach home')


def run_count(count):
    assert native.adb('shell', 'pm', 'clear', PACKAGE).strip() == 'Success'
    launch()
    reach_home()
    find_action('PLAY NOW')
    find_action('4 players')
    find_action(f'{count} players')
    find_action('START LOCAL MATCH', scroll=True)
    initial = wait_snapshot(lambda s: s['game']['stateVersion'] == 0)
    assert initial['aiPlayers'] == []
    find_action('Dice, value not rolled')
    accepted = wait_snapshot(lambda s: s['game']['stateVersion'] >= 1)
    old_pid = native.adb('shell', 'pidof', PACKAGE).strip()
    native.adb('shell', 'am', 'force-stop', PACKAGE)
    try:
        alive = native.adb('shell', 'pidof', PACKAGE).strip()
    except subprocess.CalledProcessError:
        alive = ''
    assert old_pid and not alive, 'Process death was not established'
    stopped = saved()
    unchanged_match(accepted, stopped, count)
    launch()
    reach_home()
    find_action('RESUME SAVED MATCH')
    # A pending non-six may legitimately auto-pass once after restoration.
    final = wait_snapshot(lambda s: s['game']['stateVersion'] >= stopped['game']['stateVersion'])
    # Prove the match UI is reachable without opening an obstructing chat sheet.
    find_action('Local Chat', activate=False)
    final = saved()
    outcome = unchanged_match(stopped, final, count)
    new_pid = native.adb('shell', 'pidof', PACKAGE).strip()
    assert new_pid and new_pid != old_pid
    native.screenshot(f'process-recovered-{count}-players')
    return dict(playerCount=count, initial=initial, accepted=accepted,
                stopped=stopped, restored=final, oldPid=old_pid, newPid=new_pid,
                comparison=outcome)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    native.OUT = OUT
    require_disposable_emulator(native.SERIAL, native.adb('shell', 'getprop', 'ro.kernel.qemu'))
    report = {'status': 'failed', 'fixture': 'none: production randomness/native preferences',
              'renderer': 'Flutter default; emulator SwANGLE', 'buildMode': 'normal debug APK',
              'cases': []}
    live_log = (OUT / 'live-logcat.txt').open('w')
    logger = subprocess.Popen(['adb', '-s', native.SERIAL, 'logcat', '-v', 'threadtime'],
                              stdout=live_log, stderr=subprocess.STDOUT)
    try:
        native.adb('install', '-r', 'build/app/outputs/flutter-apk/app-debug.apk', timeout=60)
        (OUT / 'device-properties.txt').write_text(native.adb('shell', 'getprop'))
        for count in [2, 3]:
            report['cases'].append(run_count(count))
        report['status'] = 'passed'
    except Exception as error:
        report['error'] = repr(error)
        try:
            native.screenshot('process-recovery-failure')
            (OUT / 'failure-ui.xml').write_text(native.adb('shell', 'uiautomator', 'dump', '/dev/tty'))
        except Exception as diagnostic_error:
            report['diagnosticError'] = repr(diagnostic_error)
        raise
    finally:
        logger.terminate()
        try:
            logger.wait(timeout=5)
        except subprocess.TimeoutExpired:
            logger.kill()
            logger.wait(timeout=5)
        live_log.close()
        (OUT / 'report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
        try:
            (OUT / 'logcat.txt').write_text(native.adb('logcat', '-d', '-t', '2500'))
            native.adb('shell', 'am', 'force-stop', PACKAGE)
        except subprocess.SubprocessError:
            pass


if __name__ == '__main__':
    main()
