import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import blast_radius_check as B

SCRIPT = os.path.join(HERE, "blast_radius_check.py")
FIXTURES = os.path.join(HERE, "blast_radius_fixtures")
GOOD = "- The overlay reads `quotes.json`, so the stream overlay shows the new field.\n"


def body(section, before="## For Dread\n**Ask:** Nothing\n\n", after="\nLevel: 2\n"):
    return before + section + after


class Section(unittest.TestCase):
    def test_missing_heading_fails(self):
        self.assertIn("no '## Blast radius' heading", B.problems("## For Dread\nhi\n")[0])

    def test_heading_only_inside_comment_fails(self):
        self.assertTrue(B.problems("<!--\n## Blast radius\n" + GOOD + "-->\n"))

    def test_heading_only_inside_code_fence_fails(self):
        self.assertTrue(B.problems("```\n## Blast radius\n" + GOOD + "```\n"))

    def test_h3_heading_does_not_count(self):
        self.assertTrue(B.problems("### Blast radius\n" + GOOD))

    def test_empty_section_fails(self):
        self.assertIn("empty", B.problems(body("## Blast radius\n\n## Next\n" + GOOD))[0])

    def test_empty_at_end_fails(self):
        self.assertIn("empty", B.problems("## Blast radius\n   \n")[0])

    def test_comment_only_section_is_empty(self):
        self.assertIn("empty", B.problems(body("## Blast radius\n<!-- name callers -->\n"))[0])

    def test_filler_values_fail(self):
        for v in ["none", "None.", "N/A", "n/a", "nothing", "Nothing!", "TBD", "tbd", "-", "--",
                  "- none", "* n/a", "**None**", "`n/a`", "TODO", "- TBD: fill in later", "none\n- n/a\n-"]:
            with self.subTest(v=v):
                errs = B.problems(body("## Blast radius\n" + v + "\n"))
                self.assertTrue(errs and "filler" in errs[0], errs)

    def test_template_prompt_fails(self):
        path = os.path.join(HERE, "..", "..", ".github", "pull_request_template.md")
        if not os.path.exists(path):
            self.skipTest("no template")
        with open(path, encoding="utf-8") as fh:
            self.assertTrue(B.problems(fh.read()))

    def test_too_thin_fails(self):
        errs = B.problems(body("## Blast radius\nthe overlay\n"))
        self.assertTrue(errs and "too thin" in errs[0], errs)

    def test_named_area_passes(self):
        self.assertEqual(B.problems(body("## Blast radius\n" + GOOD)), [])

    def test_why_nothing_depends_passes(self):
        txt = "None: this is a new standalone script, nothing imports or runs it yet.\n"
        self.assertEqual(B.problems(body("## Blast radius\n" + txt)), [])

    def test_section_ends_at_next_h2(self):
        self.assertTrue(B.problems("## Blast radius\nn/a\n## Other\n" + GOOD))

    def test_h3_inside_section_is_content(self):
        self.assertEqual(B.problems("## Blast radius\n### Callers\n" + GOOD), [])

    def test_crlf_and_case(self):
        self.assertEqual(B.problems("## blast RADIUS ##\r\n" + GOOD.replace("\n", "\r\n")), [])

    def test_level_line_is_not_content(self):
        self.assertTrue(B.problems("## Blast radius\nn/a\n\nLevel: 2\n"))
        self.assertTrue(B.problems("## Blast radius\n\n**Level:** 2 extra words here\n"))

    def test_none_body(self):
        self.assertTrue(B.problems(None))


class Bots(unittest.TestCase):
    def test_bots(self):
        for login, kind in [("github-actions[bot]", "Bot"), ("dependabot[bot]", "Bot"),
                            ("dependabot", "User"), ("renovate[bot]", ""), ("someapp", "Bot")]:
            with self.subTest(login=login):
                self.assertTrue(B.is_bot(login, kind))

    def test_humans(self):
        for login in ["DreadfullyDespized", "botanist", ""]:
            with self.subTest(login=login):
                self.assertFalse(B.is_bot(login, "User"))


class Cli(unittest.TestCase):
    def run_event(self, text, login="DreadfullyDespized", kind="User"):
        ev = {"pull_request": {"body": text, "user": {"login": login, "type": kind}}}
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
            json.dump(ev, fh)
        try:
            return subprocess.run([sys.executable, SCRIPT, "--event", fh.name],
                                  capture_output=True, text=True)
        finally:
            os.unlink(fh.name)

    def test_event_fail(self):
        r = self.run_event(body("## Blast radius\nnone\n"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("::error title=Blast radius::", r.stdout)

    def test_event_pass(self):
        r = self.run_event(body("## Blast radius\n" + GOOD))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("OK", r.stdout)

    def test_null_body_fails(self):
        self.assertEqual(self.run_event(None).returncode, 1)

    def test_bot_skipped(self):
        for login in ["github-actions[bot]", "dependabot[bot]"]:
            r = self.run_event("", login=login, kind="Bot")
            self.assertEqual(r.returncode, 0)
            self.assertIn("skipped", r.stdout)

    def test_not_a_pr_event(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
            json.dump({"push": {}}, fh)
        try:
            r = subprocess.run([sys.executable, SCRIPT, "--event", fh.name], capture_output=True, text=True)
        finally:
            os.unlink(fh.name)
        self.assertEqual(r.returncode, 2)

    def test_fixture_bodies(self):
        for name, code in [("fail.md", 1), ("pass.md", 0)]:
            with self.subTest(name=name):
                r = subprocess.run([sys.executable, SCRIPT, "--body-file", os.path.join(FIXTURES, name)],
                                   capture_output=True, text=True)
                self.assertEqual(r.returncode, code, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
