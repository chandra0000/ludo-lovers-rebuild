#!/usr/bin/env python3
"""Decode the complete genuine recording and report stream/change evidence."""
import json
import statistics
from pathlib import Path
import subprocess
import sys


def verify(path):
    probe = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_format', '-show_streams', '-of', 'json', str(path)
    ], text=True, timeout=20))
    video = next(s for s in probe['streams'] if s['codec_type'] == 'video')
    duration = float(probe['format']['duration'])
    numerator, denominator = map(int, video['avg_frame_rate'].split('/'))
    fps = numerator / denominator
    assert 45 <= duration <= 95, ('Unexpected recording duration', duration)
    assert video['height'] > video['width'] >= 320, 'Portrait capture required'
    assert video['codec_name'] == 'h264', 'Broadly compatible H.264 required'
    assert fps > 0, 'Invalid encoded frame rate'
    # Native screenrecord is variable-rate: static screens legitimately produce
    # no new buffers. An average over idle holds is not animation frame cadence.
    timing = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_frames',
        '-show_entries', 'frame=best_effort_timestamp_time', '-of', 'json', str(path)
    ], text=True, timeout=30))
    pts = [float(frame['best_effort_timestamp_time']) for frame in timing['frames']]
    gaps = [right - left for left, right in zip(pts, pts[1:])]
    active = [gap for gap in gaps if 0 < gap <= .15]
    assert len(active) >= 20, 'No sustained changing-frame sequence'
    active_fps = 1 / statistics.median(active)
    # No frame generation, interpolation, crops or transcoding. Decode every frame.
    subprocess.run(['ffmpeg', '-v', 'error', '-xerror', '-i', str(path),
                    '-f', 'null', '-'], check=True, timeout=120)
    # Sparse hashes detect frozen footage; actual motion/readability still needs review.
    hashes = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path), '-vf', 'fps=2',
        '-f', 'framemd5', '-'], text=True, timeout=60)
    unique = {line.split(',')[-1].strip() for line in hashes.splitlines()
              if not line.startswith('#') and ',' in line}
    assert len(unique) >= 20, 'Insufficient changing gameplay frames'
    frames = path.parent / 'review-frames'
    frames.mkdir(exist_ok=True)
    for seconds in [4, 7, 10, 13, 17, 22, 26, 30, 34, 38, 43, 48]:
        if seconds < duration:
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(seconds),
                            '-i', str(path), '-frames:v', '1',
                            str(frames / f'frame-{seconds:02}.png')],
                           check=True, timeout=20)
    report = {'durationSeconds': duration, 'width': video['width'],
              'height': video['height'], 'averageEncodedFps': fps,
              'medianActiveCadenceFps': active_fps,
              'activeCadenceMethod': 'median positive frame interval <=150ms; excludes idle holds',
              'target30FpsMet': active_fps >= 29.5,
              'largestFrameHoldSeconds': max(gaps),
              'codec': video['codec_name'],
              'uniqueHalfSecondFrames': len(unique), 'completeDecode': True,
              'visualApproval': 'PENDING HUMAN/AGENT FRAME REVIEW',
              'capture': 'native Android screenrecord; seeded QA fixture'}
    (path.parent / 'video-verification.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report))


if __name__ == '__main__':
    verify(Path(sys.argv[1]))
