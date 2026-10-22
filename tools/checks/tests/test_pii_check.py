import io
import os
import sys
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pii_check


def classes(hits):
    return sorted({cls for _, cls, _ in hits})


class TestGenericClasses(unittest.TestCase):
    def test_email_hit(self):
        hits = pii_check.scan("contact someone@gmail.com today", "text", [])
        self.assertEqual(classes(hits), ["email"])

    def test_email_allowlist_clean(self):
        text = "DreadfullyDespized@users.noreply.github.com\nnoreply@github.com\nhelp@example.com"
        self.assertEqual(pii_check.scan(text, "text", []), [])

    def test_phone_shapes_hit(self):
        for sample in ("(304) 555-0142", "304-555-0142", "304.555.0142", "call 304 555 0142 now"):
            hits = pii_check.scan(sample, "text", [])
            self.assertIn("phone", classes(hits), sample)

    def test_phone_placeholder_and_short_numbers_clean(self):
        text = "phone = (###) ###-####\nphone = 00030\nmyid = 7"
        self.assertEqual(pii_check.scan(text, "text", []), [])

    def test_ipv4_cgnat_and_lan_hit(self):
        for sample in ("100.64.3.17", "100.127.0.1", "192.168.1.40", "10.0.0.5", "172.16.4.4", "172.31.255.1"):
            hits = pii_check.scan(sample, "text", [])
            self.assertIn("ipv4", classes(hits), sample)

    def test_ipv4_public_and_exclusions_clean(self):
        text = "8.8.8.8\n127.0.0.1\n0.0.0.0\n255.255.255.255\n192.0.2.10\n198.51.100.4\n203.0.113.9\n100.63.0.1\n100.128.0.1\n172.32.0.1"
        self.assertEqual(pii_check.scan(text, "text", []), [])

    def test_ipv4_invalid_octet_clean(self):
        self.assertEqual(pii_check.scan("999.12.1.1", "text", []), [])

    def test_profile_path_hit(self):
        for sample in (r"C:\Users\someone\file.txt", "C:/Users/someone/file", "/home/someone/x", "/Users/someone/x"):
            hits = pii_check.scan(sample, "text", [])
            self.assertIn("profile-path", classes(hits), sample)

    def test_profile_placeholder_clean(self):
        self.assertEqual(pii_check.scan(r"C:\Users\username\file.txt", "text", []), [])


class TestSelfScan(unittest.TestCase):
    def test_checker_source_scans_clean(self):
        path = os.path.join(os.path.dirname(__file__), "..", "pii_check.py")
        with open(path, encoding="utf-8") as fh:
            self.assertEqual(pii_check.scan(fh.read(), "text", []), [])


class TestPrivateTerms(unittest.TestCase):
    def test_term_hit_case_insensitive(self):
        hits = pii_check.scan("tested on MYHOSTNAME today", "text", ["myhostname"])
        self.assertEqual(classes(hits), ["private-term"])

    def test_short_terms_ignored(self):
        hits = pii_check.scan("ab cd", "text", ["ab"])
        self.assertEqual(hits, [])


class TestNoPrintRule(unittest.TestCase):
    def run_main(self, argv, stdin_text, env_terms):
        out = io.StringIO()
        with patch.dict(os.environ, {"PII_TERMS": env_terms}), \
             patch.object(sys, "stdin", io.StringIO(stdin_text)), \
             redirect_stdout(out):
            rc = pii_check.main(argv)
        return rc, out.getvalue()

    def test_canary_never_in_output(self):
        canary = "CANARY-TERM-12345"
        rc, output = self.run_main(["--stdin"], f"the value {canary} appears", canary)
        self.assertEqual(rc, 1)
        self.assertNotIn(canary, output)
        self.assertIn("private-term", output)

    def test_email_value_never_in_output(self):
        rc, output = self.run_main(["--stdin"], "mail person@realdomain.net", "")
        self.assertEqual(rc, 1)
        self.assertNotIn("person@realdomain.net", output)
        self.assertIn("email", output)

    def test_clean_stdin_passes(self):
        rc, output = self.run_main(["--stdin"], "nothing to see here", "")
        self.assertEqual(rc, 0)
        self.assertIn("clean", output)


if __name__ == "__main__":
    unittest.main()
