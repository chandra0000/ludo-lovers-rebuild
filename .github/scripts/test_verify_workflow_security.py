import unittest

from verify_workflow_security import violations


class ImmutableWorkflowTest(unittest.TestCase):
    def test_mutable_tags_branches_and_images_are_rejected(self):
        for reference in ['actions/checkout@v4', 'org/repo@main',
                          'org/repo/.github/workflows/job.yml@v1', 'docker://alpine:3']:
            with self.subTest(reference=reference):
                self.assertEqual(violations('  - uses: ' + reference), [1])

    def test_commit_and_container_digest_are_allowed(self):
        for reference in ['actions/checkout@' + 'a' * 40, 'docker://alpine@sha256:' + 'b' * 64]:
            self.assertEqual(violations('uses: ' + reference + ' # reviewed'), [])

    def test_local_reviewed_workflow_is_allowed(self):
        self.assertEqual(violations('uses: ./.github/workflows/local.yml'), [])

    def test_comments_do_not_count_as_actions(self):
        self.assertEqual(violations('# uses: owner/repo@v1'), [])


if __name__ == '__main__':
    unittest.main()
