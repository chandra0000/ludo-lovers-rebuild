#!/usr/bin/env python3
"""Reject mutable remote action/reusable-workflow and container references."""
from pathlib import Path
import re
import sys


def violations(text):
    failures = []
    for number, line in enumerate(text.splitlines(), 1):
        match = re.match(r'^\s*(?:-\s*)?uses:\s*([^\s#]+)', line)
        if not match:
            continue
        reference = match.group(1).strip('\"\'')
        if reference.startswith('./'):
            continue
        valid = (re.fullmatch(r'docker://[^@]+@sha256:[a-f0-9]{64}', reference)
                 if reference.startswith('docker://')
                 else re.fullmatch(r'[^@]+@[a-f0-9]{40}', reference))
        if not valid:
            failures.append(number)
    return failures


def main():
    failures = []
    for path in sorted(Path('.github/workflows').glob('*')):
        if path.suffix in ('.yml', '.yaml'):
            failures.extend(f'{path}:{line}: mutable uses reference' for line in violations(path.read_text()))
    if failures:
        print('\n'.join(failures))
        return 1
    print('All remote workflow uses references are immutable')
    return 0


if __name__ == '__main__':
    sys.exit(main())
