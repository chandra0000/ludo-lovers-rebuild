"""Host recording protocol regression checks; no emulator or generated footage."""
import base64
import json
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    'native_qa', Path(__file__).with_name('android_native_qa.py'))
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)


class RecorderChecks(unittest.TestCase):
    def test_sigint_and_process_exit_precede_pull_and_stop_is_idempotent(self):
        recorder = qa.Recorder()
        recorder.pid = 123
        with patch.object(qa, 'adb', return_value='') as adb:
            recorder.stop()
            recorder.stop()
        self.assertEqual(adb.call_args_list[0].args, ('shell', 'kill', '-2', '123'))
        self.assertIn('/proc/123/stat', adb.call_args_list[1].args[1])
        self.assertEqual(adb.call_args_list[2].args[0], 'pull')
        self.assertEqual(adb.call_count, 3)

    def test_duplicate_start_cannot_replace_a_recording(self):
        recorder = qa.Recorder()
        recorder.pid = 123
        with self.assertRaises(RuntimeError):
            recorder.start()

    def test_bad_capture_name_rejected_before_device_access(self):
        with patch.object(qa, 'adb') as adb:
            with self.assertRaises(ValueError):
                qa.screenshot('../escape')
            adb.assert_not_called()

    def test_invalid_png_is_rejected(self):
        with patch.object(qa, 'adb', return_value=b'not a screenshot'):
            with self.assertRaises(RuntimeError):
                qa.screenshot('native-match')

    def test_active_recorder_is_waited_for_before_pull(self):
        recorder = qa.Recorder()
        recorder.pid = 456
        with patch.object(qa, 'adb', side_effect=['', '456 (screenrecord) S', '', '']) as adb:
            with patch.object(qa.time, 'sleep') as sleep:
                recorder.stop()
        sleep.assert_called_once_with(.25)
        self.assertEqual(adb.call_args_list[-1].args[0], 'pull')


class ChunkChecks(unittest.TestCase):
    def test_long_unicode_snapshot_survives_android_log_limit_and_reordering(self):
        expected = {'name': 'Renée🧡' * 500, 'stateVersion': 9}
        encoded = base64.b64encode(json.dumps(expected).encode()).decode()
        parts = [encoded[i:i + 480] for i in range(0, len(encoded), 480)]
        chunks = qa.StateChunks()
        result = None
        for i in reversed(range(len(parts))):
            line = f'I/flutter: LUDO_QA_CHUNK:7:{i}:{len(parts)}:{parts[i]}'
            self.assertLess(len(line), 900)
            result = chunks.accept(line)
        self.assertEqual(result, expected)
        self.assertFalse(chunks.pending)

    def test_missing_and_duplicate_chunks_are_not_silent_success(self):
        chunks = qa.StateChunks()
        self.assertIsNone(chunks.accept('LUDO_QA_CHUNK:1:0:2:e30='))
        self.assertTrue(chunks.pending)
        with self.assertRaises(ValueError):
            chunks.accept('LUDO_QA_CHUNK:1:0:2:e30=')


if __name__ == '__main__':
    unittest.main()
