import copy
import json
import unittest
from unittest.mock import patch
import subprocess
import tempfile
from pathlib import Path

from android_process_recovery import decode_preferences, require_disposable_emulator, unchanged_match, ready_nodes


def snapshot(count=2, dice=6):
    roster = ['orange', 'magenta'] if count == 2 else ['orange', 'green', 'magenta']
    config = dict(id='local-current', version=2, activePlayers=roster)
    return dict(schemaVersion=4, configuration=config, aiPlayers=[], profiles=['stable identity'],
                game=dict(configuration=config, winner=None, activePlayer='orange',
                          players=[dict(pawnProgress=[-1] * 4) for _ in range(4)],
                          stateVersion=1, appliedCommandIds=['match-0-roll'], diceValue=dice))


class RecoveryContractTest(unittest.TestCase):
    def test_first_window_xml_unavailable_is_bounded_readiness_not_app_crash(self):
        nodes = ['ready window']
        with tempfile.TemporaryDirectory() as folder:
            with patch('android_process_recovery.OUT', Path(folder)):
                with patch('android_native_qa.ui_nodes', side_effect=[
                    subprocess.CalledProcessError(1, ['adb', 'cat', 'window.xml']), nodes,
                ]):
                    self.assertEqual([], ready_nodes())
                    self.assertEqual(nodes, ready_nodes())
                    self.assertIn('CalledProcessError', (Path(folder) / 'ui-readiness.jsonl').read_text())

    def test_destructive_actions_require_actual_emulator(self):
        require_disposable_emulator('emulator-5554', '1\n')
        for serial, qemu in [('physical-device', '1'), ('emulator-5554', '0')]:
            with self.assertRaises(RuntimeError):
                require_disposable_emulator(serial, qemu)

    def test_native_xml_is_required(self):
        value = snapshot()
        xml = '<map><string name="flutter.saved_local_match_v1">' + json.dumps(value) + '</string></map>'
        self.assertEqual(value, decode_preferences(xml))
        with self.assertRaises(ValueError):
            decode_preferences('<map/>')

    def test_exact_restoration_and_single_no_move_pass(self):
        for count in [2, 3]:
            before = snapshot(count)
            self.assertEqual('identical', unchanged_match(before, copy.deepcopy(before), count))
            before = snapshot(count, 3)
            after = copy.deepcopy(before)
            after['game'].update(stateVersion=2, diceValue=None,
                                 activePlayer=before['configuration']['activePlayers'][1],
                                 appliedCommandIds=['match-0-roll', 'match-1-pass'])
            self.assertEqual('one-authorized-no-move-pass', unchanged_match(before, after, count))

    def test_illegal_recovery_mutations_fail(self):
        before = snapshot()
        for mutation in [
            lambda s: s['game'].update(stateVersion=3),
            lambda s: s['game'].update(diceValue=4),
            lambda s: s['game'].update(activePlayer='magenta'),
            lambda s: s.update(profiles=['different identity']),
            lambda s: s.update(aiPlayers=['magenta']),
            lambda s: s['game']['players'][0].update(pawnProgress=[0, -1, -1, -1]),
            lambda s: s['game'].update(appliedCommandIds=['match-0-roll', 'match-0-roll']),
        ]:
            after = copy.deepcopy(before)
            mutation(after)
            with self.assertRaises(AssertionError):
                unchanged_match(before, after, 2)

    def test_identically_invalid_state_is_not_accepted(self):
        for mutation in [
            lambda s: s['game'].update(diceValue=0),
            lambda s: s['game'].update(activePlayer='magenta'),
            lambda s: s['game'].update(stateVersion=2, appliedCommandIds=['a-roll', 'b-roll']),
        ]:
            invalid = snapshot()
            mutation(invalid)
            with self.assertRaises(AssertionError):
                unchanged_match(invalid, copy.deepcopy(invalid), 2)


if __name__ == '__main__':
    unittest.main()
