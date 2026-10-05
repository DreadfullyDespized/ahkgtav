import os
import subprocess
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
CHECKS = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CHECKS))
sys.path.insert(0, CHECKS)
import agents_md_headings as A

FIX = os.path.join(HERE, "fixtures", "agents_md")
CLI = os.path.join(CHECKS, "agents_md_headings.py")


def _read(name):
    with open(os.path.join(FIX, name), encoding="utf-8") as f:
        return f.read()


class AgentsMdHeadingsTest(unittest.TestCase):
    def test_repo_agents_md_passes(self):
        self.assertEqual(A.check_file(ROOT), [])

    def test_good_fixture_passes(self):
        self.assertEqual(A.check(_read("good.md"), "good.md"), [])

    def test_missing_prove_heading_fails(self):
        errs = A.check(_read("missing_prove.md"), "missing_prove.md")
        self.assertEqual(errs, ["missing_prove.md: missing required H2 'Prove a change'"])

    def test_deleting_any_required_heading_fails(self):
        for heading in A.REQUIRED:
            with self.subTest(heading=heading):
                text = _read("good.md").replace(f"## {heading}\n", f"## Renamed {heading}\n")
                errs = A.check(text)
                self.assertTrue(any(heading in e for e in errs), errs)

    def test_missing_file_fails(self):
        self.assertEqual(A.check(None, "AGENTS.md"), ["AGENTS.md: missing"])

    def test_cli_ok_on_repo(self):
        r = subprocess.run([sys.executable, CLI], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("OK", r.stdout)

    def test_cli_fails_on_broken_fixture(self):
        path = os.path.join(FIX, "missing_prove.md")
        r = subprocess.run([sys.executable, CLI, path], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)
        self.assertIn("Prove a change", r.stdout)


if __name__ == "__main__":
    unittest.main()
