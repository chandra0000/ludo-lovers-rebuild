"""Host recording protocol regression checks; no emulator or generated footage."""
import base64
import json
import importlib.util
from pathlib import Path
import unittest
import subprocess
import tempfile
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    'native_qa', Path(__file__).with_name('android_native_qa.py'))
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)


class DisplayReadinessChecks(unittest.TestCase):
    def result(self, output, code=0, error=''):
        return subprocess.CompletedProcess([], code, output, error)

    def test_transient_failure_is_logged_then_both_services_must_reply(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(qa, 'VIDEO', Path(directory)), \
                    patch.dict(qa.os.environ, {'LUDO_CAPTURE_SIZE': '360x800'}), \
                    patch.object(qa.time, 'sleep'), \
                    patch.object(qa.subprocess, 'run', side_effect=[
                        self.result('', 255, 'WindowManager unavailable'),
                        self.result('Physical density: 160'),
                        self.result('Physical size: 1080x1920\nOverride size: 360x800'),
                        self.result('Physical density: 420\nOverride density: 160'),
                    ]) as run:
                text = qa.wait_for_display()
                self.assertIn('Override size: 360x800', text)
                self.assertEqual(run.call_count, 4)
                entries = [json.loads(x) for x in
                           (Path(directory) / 'display-readiness.jsonl').read_text().splitlines()]
                self.assertEqual(entries[0]['code'], 255)
                self.assertEqual(entries[0]['stderr'], 'WindowManager unavailable')

    def test_permanent_failure_is_bounded_and_keeps_output(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(qa, 'VIDEO', Path(directory)), \
                    patch.object(qa.time, 'monotonic', side_effect=[0, 0, 1, 2, 29, 30]), \
                    patch.object(qa.time, 'sleep'), \
                    patch.object(qa.subprocess, 'run', return_value=self.result('', 255, 'offline')) as run:
                with self.assertRaisesRegex(RuntimeError, 'application not installed'):
                    qa.wait_for_display()
                self.assertEqual(run.call_count, 2)
                self.assertIn('offline', (Path(directory) / 'display-readiness.jsonl').read_text())

    def test_wrong_viewport_is_rejected_without_retry(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(qa, 'VIDEO', Path(directory)), \
                    patch.dict(qa.os.environ, {'LUDO_CAPTURE_SIZE': '360x800'}), \
                    patch.object(qa.subprocess, 'run', side_effect=[
                        self.result('Physical size: 1080x1920'),
                        self.result('Physical density: 420'),
                    ]):
                with self.assertRaisesRegex(RuntimeError, 'requested viewport'):
                    qa.wait_for_display()

    def test_timeout_output_is_retained_and_next_attempt_can_recover(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(qa, 'VIDEO', Path(directory)), \
                    patch.dict(qa.os.environ, {'LUDO_CAPTURE_SIZE': '360x800'}), \
                    patch.object(qa.time, 'sleep'), \
                    patch.object(qa.subprocess, 'run', side_effect=[
                        subprocess.TimeoutExpired(['adb'], 5, output='slow service', stderr='probe timeout'),
                        self.result('Physical density: 160'),
                        self.result('Physical size: 360x800'),
                        self.result('Physical density: 160'),
                    ]):
                self.assertIn('360x800', qa.wait_for_display())
                entries = (Path(directory) / 'display-readiness.jsonl').read_text()
                self.assertIn('probe timeout', entries)
                self.assertIn('"timeout": true', entries)


class RecorderChecks(unittest.TestCase):
    def test_finalized_recorder_exiting_before_kill_still_pulls(self):
        recorder = qa.Recorder()
        recorder.pid = 123
        recorder.process = Mock()
        recorder.process.poll.return_value = None
        failure = subprocess.CalledProcessError(1, ['kill', '-9'])
        with patch.object(qa, 'VIDEO'), \
                patch.object(recorder, 'finalized_file_size', return_value=2048), \
                patch.object(recorder, 'close') as close, \
                patch.object(qa, 'adb', side_effect=['', failure, 'exited', '']) as adb:
            recorder.stop()
            self.assertTrue(recorder.stopped)
            self.assertEqual(adb.call_args_list[-1].args[0], 'pull')
            close.assert_called_once()

    def test_failed_final_kill_with_live_pid_does_not_pull(self):
        recorder = qa.Recorder()
        recorder.pid = 123
        recorder.process = Mock()
        recorder.process.poll.return_value = None
        failure = subprocess.CalledProcessError(1, ['kill', '-9'])
        with patch.object(qa, 'VIDEO'), \
                patch.object(recorder, 'finalized_file_size', return_value=2048), \
                patch.object(qa, 'adb', side_effect=['', failure, 'alive']) as adb:
            with self.assertRaises(subprocess.CalledProcessError):
                recorder.stop()
            self.assertFalse(recorder.stopped)
            self.assertFalse(any(call.args[0] == 'pull' for call in adb.call_args_list))

    def test_sigint_and_process_exit_precede_pull_and_stop_is_idempotent(self):
        recorder = qa.Recorder()
        recorder.pid = 123
        recorder.process = Mock()
        recorder.process.poll.return_value = 0
        order = Mock()
        order.attach_mock(recorder.process.poll, 'poll')
        with patch.object(qa, 'VIDEO') as video, patch.object(qa, 'adb', return_value='') as adb:
            order.attach_mock(adb, 'adb')
            recorder.stop()
            recorder.stop()
        self.assertEqual(order.mock_calls[0].args, ('shell', 'kill', '-2', '123'))
        self.assertEqual(order.mock_calls[-1].args[0], 'pull')
        self.assertEqual(adb.call_count, 2)

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

    def test_failed_recorder_exit_never_pulls_unfinalized_video(self):
        recorder = qa.Recorder()
        recorder.pid = 456
        recorder.process = Mock()
        recorder.process.poll.return_value = 1
        with patch.object(recorder, 'finalized_file_size', return_value=None):
            with patch.object(qa, 'adb', return_value='') as adb:
                with self.assertRaises(RuntimeError):
                    recorder.stop()
        self.assertEqual(adb.call_count, 1)

    def test_timeout_without_durable_file_is_rejected(self):
        recorder = qa.Recorder()
        recorder.pid = 456
        recorder.process = Mock()
        recorder.process.poll.return_value = None
        with patch.object(recorder, 'finalized_file_size', return_value=None):
            with patch.object(qa.time, 'monotonic', side_effect=[0, 13]):
                with patch.object(qa, 'adb', return_value='') as adb:
                    with self.assertRaises(RuntimeError):
                        recorder.stop()
        self.assertEqual(adb.call_count, 1)

    def test_stuck_codec_cleanup_requires_proven_file_before_kill_and_pull(self):
        recorder = qa.Recorder()
        recorder.pid = 456
        recorder.process = Mock()
        recorder.process.poll.side_effect = [None, None, -15]
        recorder.process.wait.return_value = -15
        with patch.object(recorder, 'finalized_file_size', return_value=2628699):
            with patch.object(qa, 'VIDEO'), patch.object(qa, 'adb', return_value='') as adb:
                recorder.stop()
        self.assertEqual(adb.call_args_list[0].args, ('shell', 'kill', '-2', '456'))
        self.assertEqual(adb.call_args_list[1].args, ('shell', 'kill', '-9', '456'))
        self.assertEqual(adb.call_args_list[2].args[0], 'pull')
        recorder.process.terminate.assert_called_once()
        recorder.process.wait.assert_called_once_with(timeout=3)

    def test_finalized_size_must_match_remote_file(self):
        recorder = qa.Recorder()
        recorder.pid = 456
        logs = 'MOOV atom was written to the file\nfinal fsync() takes 0 ms, file size 2628699'
        with patch.object(qa, 'VIDEO'), patch.object(qa, 'adb', side_effect=[logs, '2628000']):
            self.assertIsNone(recorder.finalized_file_size())

    def test_native_finalization_parser_requires_moov_then_fsync(self):
        self.assertIsNone(qa.finalized_size('estimated moov size 3192'))
        self.assertIsNone(qa.finalized_size('MOOV atom was written to the file'))
        self.assertIsNone(qa.finalized_size('final fsync() takes 0 ms, file size 9999'))
        self.assertEqual(qa.finalized_size(
            'MOOV atom was written to the file\nfinal fsync() takes 0 ms, file size 2628699'), 2628699)


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
