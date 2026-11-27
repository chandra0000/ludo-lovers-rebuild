#!/usr/bin/env python3
"""Export bounded native crash fields, excluding cores and process environment."""
from pathlib import Path

SAFE_FIELDS = {'ProblemType', 'ExecutablePath', 'Signal', 'Architecture',
               'Stacktrace', 'StacktraceTop', 'ThreadStacktrace', 'AssertionMessage'}


def summarize(path):
    output, field, remaining = [], '', 32768
    with path.open(errors='replace') as stream:
        for line in stream:
            if not line.startswith((' ', '\t')):
                field = line.partition(':')[0]
            if field in SAFE_FIELDS and remaining:
                text = line[:min(2000, remaining)]
                output.append(text)
                remaining -= len(text)
    return ''.join(output)


if __name__ == '__main__':
    for report in Path('/var/crash').glob('*qemu*.crash'):
        print(report.name)
        print(summarize(report))
