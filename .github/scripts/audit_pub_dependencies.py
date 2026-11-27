#!/usr/bin/env python3
"""Check the resolved hosted Pub graph against OSV; errors never mean clean."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import urllib.request


def queries_for(graph):
    packages = graph.get('packages')
    if not isinstance(packages, list) or not packages:
        raise ValueError('Expected nonempty dart pub deps --json packages')
    queries, excluded = [], []
    for package in packages:
        name, version, source = (package.get(key) for key in ('name', 'version', 'source'))
        if not all(isinstance(value, str) and value for value in (name, version, source)):
            raise ValueError('Malformed resolved dependency')
        if source == 'hosted':
            queries.append({'package': {'name': name, 'ecosystem': 'Pub'}, 'version': version})
        elif source in ('sdk', 'root'):
            excluded.append({'name': name, 'source': source})
        else:
            raise ValueError(f'Advisory coverage undefined for {name} ({source})')
    if not queries:
        raise ValueError('No hosted Pub dependencies were found')
    return queries, excluded


def findings_for(queries, response):
    results = response.get('results')
    if not isinstance(results, list) or len(results) != len(queries):
        raise ValueError('OSV response does not cover the complete query batch')
    findings = []
    for query, result in zip(queries, results):
        if not isinstance(result, dict) or result.get('error'):
            raise ValueError('OSV returned an invalid or failed package result')
        vulns = result.get('vulns', [])
        if not isinstance(vulns, list):
            raise ValueError('Invalid OSV vulnerabilities')
        for vuln in vulns:
            if not isinstance(vuln, dict) or not isinstance(vuln.get('id'), str):
                raise ValueError('Invalid OSV advisory identifier')
            findings.append({'package': query['package']['name'], 'version': query['version'],
                             'advisory': vuln['id']})
    return findings


def audit(graph, fetch):
    queries, excluded = queries_for(graph)
    findings = []
    for offset in range(0, len(queries), 1000):
        batch = queries[offset:offset + 1000]
        findings.extend(findings_for(batch, fetch({'queries': batch})))
    return {'status': 'findings' if findings else 'no-known-advisories',
            'checkedHostedPackages': len(queries), 'findings': findings,
            'excludedSdkAndRoot': excluded,
            'scope': 'Public OSV Pub advisories only; not SDK/native code, secrets or runtime security'}


def fetch_osv(payload):
    request = urllib.request.Request('https://api.osv.dev/v1/querybatch',
        data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('dependency_graph', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        report = audit(json.loads(args.dependency_graph.read_text()), fetch_osv)
        exit_code = 1 if report['findings'] else 0
    except (OSError, ValueError, TypeError, AttributeError) as error:
        report = {'status': 'error', 'error': str(error), 'scope': 'Audit incomplete; never a clean result'}
        exit_code = 2
    report['checkedAtUtc'] = datetime.now(timezone.utc).isoformat()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))
    return exit_code


if __name__ == '__main__':
    sys.exit(main())
