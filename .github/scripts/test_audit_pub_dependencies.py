import unittest

from audit_pub_dependencies import audit, findings_for, queries_for


class DependencyAuditTest(unittest.TestCase):
    def setUp(self):
        self.graph = {'packages': [{'name': 'example', 'version': '1.2.3', 'source': 'hosted'},
                                   {'name': 'flutter', 'version': '0.0.0', 'source': 'sdk'}]}

    def test_clean_report_discloses_excluded_sdk(self):
        report = audit(self.graph, lambda _: {'results': [{}]})
        self.assertEqual(report['status'], 'no-known-advisories')
        self.assertEqual(report['checkedHostedPackages'], 1)
        self.assertEqual(report['excludedSdkAndRoot'], [{'name': 'flutter', 'source': 'sdk'}])

    def test_advisories_are_preserved_with_exact_package_version(self):
        report = audit(self.graph, lambda _: {'results': [{'vulns': [{'id': 'OSV-TEST-1'}]}]})
        self.assertEqual(report['findings'], [{'package': 'example', 'version': '1.2.3', 'advisory': 'OSV-TEST-1'}])
        self.assertEqual(report['status'], 'findings')

    def test_missing_or_failed_results_never_pass(self):
        queries, _ = queries_for(self.graph)
        for response in [{}, {'results': []}, {'results': [None]}, {'results': [{'error': 'unavailable'}]},
                         {'results': [{'vulns': [None]}]}]:
            with self.subTest(response=response), self.assertRaises(ValueError):
                findings_for(queries, response)

    def test_unknown_dependency_source_never_silently_disappears(self):
        self.graph['packages'][0]['source'] = 'git'
        with self.assertRaises(ValueError):
            queries_for(self.graph)

    def test_transport_failure_is_not_a_clean_report(self):
        def offline(_):
            raise OSError('offline')
        with self.assertRaises(OSError):
            audit(self.graph, offline)

    def test_empty_or_malformed_graph_rejected(self):
        for graph in [{}, {'packages': []}, {'packages': [{}]}]:
            with self.subTest(graph=graph), self.assertRaises(ValueError):
                queries_for(graph)


if __name__ == '__main__':
    unittest.main()
