"""Tests for tools/checks/no_secrets.py (stdlib unittest)."""
import os
import subprocess
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "tools", "checks"))
import no_secrets as N

FIX = os.path.join(ROOT, "tools", "checks", "fixtures", "no_secrets")
CLI = os.path.join(ROOT, "tools", "checks", "no_secrets.py")

BAD = {
    "bad_password.env": "password",
    "bad_client_secret.py": "client_secret",
    "bad_api_key.txt": "api_key",
    "bad_pass_eq.sh": "pass_eq",
    "bad_unzip.sh": "unzip_pass",
    "bad_bearer.txt": "bearer_literal",
    "bad_oauth.txt": "oauth_prefix",
    "bad_discord.txt": "discord_webhook",
    "bad_refs_password.md": "refs_password",
}


def _read(name):
    return open(os.path.join(FIX, name), encoding="utf-8").read()


class NoSecrets(unittest.TestCase):
    def test_repo_tree_passes(self):
        self.assertEqual(N.scan_tree(ROOT), [])

    def test_bad_fixtures_fail(self):
        for name, kind in BAD.items():
            hits = N.findings_in_text(name, _read(name))
            self.assertTrue(hits, name)
            self.assertTrue(any(h["kind"] == kind for h in hits), (kind, hits))

    def test_clean_env_pointers_pass(self):
        self.assertEqual(
            N.findings_in_text("clean_env_pointers.py", _read("clean_env_pointers.py")),
            [],
        )

    def test_output_redacts_value(self):
        hits = N.findings_in_text("bad_password.env", _read("bad_password.env"))
        self.assertTrue(hits)
        line = N.format_finding(hits[0])
        self.assertNotIn("REPLACE_ME", line)
        self.assertIn("kind=password", line)

    def test_cli_ok_on_repo(self):
        r = subprocess.run([sys.executable, CLI], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("OK", r.stdout)

    def test_cli_fails_on_bad_fixture(self):
        path = os.path.join(FIX, "bad_password.env")
        r = subprocess.run([sys.executable, CLI, path], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)
        self.assertIn("kind=password", r.stdout)
        self.assertNotIn("REPLACE_ME", r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
