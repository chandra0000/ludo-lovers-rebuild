"""Host recording protocol regression checks; no emulator or generated footage."""
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


if __name__ == '__main__':
    unittest.main()
