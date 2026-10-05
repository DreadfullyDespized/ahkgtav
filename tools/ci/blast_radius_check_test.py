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
GOOD = "- The overlay reads `quotes.json`, so the stream overlay shows the new field. Checked with `rg quotes.json`.\n"
PROMPT = ("TBD: list each area outside this diff that this change can break, or explain "
          "why no other part needs it, and name the proof.")
SECTION = "## Blast radius\nThe nightly sync job imports load_points so it could break; rg load_points found it.\n"


def body(section, before="## For Dread\n**Ask:** Nothing\n\n", after="\nLevel: 2\n"):
    return before + section + after


def br(text):
    return body("## Blast radius\n" + text + "\n")


class Section(unittest.TestCase):
    def test_missing_heading_fails(self):
        self.assertIn("no '## Blast radius' heading", B.problems("## For Dread\nhi\n")[0])

    def test_heading_only_inside_comment_fails(self):
        self.assertTrue(B.problems("<!--\n## Blast radius\n" + GOOD + "-->\n"))

    def test_heading_only_inside_unclosed_comment_fails(self):
        self.assertTrue(B.problems("<!--\n## Blast radius\n" + GOOD))

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
                errs = B.problems(br(v))
                self.assertTrue(errs and "filler" in errs[0], errs)

    def test_template_prompt_fails(self):
        path = os.path.join(HERE, "..", "..", ".github", "pull_request_template.md")
        if not os.path.exists(path):
            self.skipTest("no template")
        with open(path, encoding="utf-8") as fh:
            self.assertTrue(B.problems(fh.read()))

    def test_too_thin_fails(self):
        errs = B.problems(br("the overlay"))
        self.assertTrue(errs and "too thin" in errs[0], errs)

    def test_named_area_passes(self):
        self.assertEqual(B.problems(br(GOOD)), [])

    def test_why_nothing_depends_passes(self):
        txt = "None: this is a new standalone script, nothing imports or runs it; `rg new_tool` found no hits."
        self.assertEqual(B.problems(br(txt)), [])

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


class Fences(unittest.TestCase):
    def test_section_outside_fence_passes(self):
        self.assertEqual(B.problems("```\ncode\n```\n" + SECTION), [])
        self.assertEqual(B.problems("````\n```\nstill code\n````\n" + SECTION), [])

    @unittest.expectedFailure
    def test_four_backtick_fence_hides_section(self):
        self.assertTrue(B.problems("````\n" + SECTION + "````\n"))

    @unittest.expectedFailure
    def test_four_backtick_fence_not_closed_by_three(self):
        self.assertTrue(B.problems("````\nx\n```\n" + SECTION + "````\n"))

    @unittest.expectedFailure
    def test_unclosed_backtick_fence_hides_section(self):
        self.assertTrue(B.problems("```\n" + SECTION))

    @unittest.expectedFailure
    def test_unclosed_tilde_fence_hides_section(self):
        self.assertTrue(B.problems("~~~~\n" + SECTION))

    @unittest.expectedFailure
    def test_backtick_fence_not_closed_by_tildes(self):
        self.assertTrue(B.problems("```\nx\n~~~\n" + SECTION))

    @unittest.expectedFailure
    def test_tilde_fence_not_closed_by_backticks(self):
        self.assertTrue(B.problems("~~~\nx\n```\n" + SECTION))

    def test_fence_with_info_string(self):
        self.assertTrue(B.problems("```python\n" + SECTION + "```\n"))

    @unittest.expectedFailure
    def test_closer_with_trailing_text_does_not_close(self):
        self.assertTrue(B.problems("```\nx\n``` not a closer\n" + SECTION))

    @unittest.expectedFailure
    def test_indented_fence_in_list_hides_section(self):
        self.assertTrue(B.problems("1. item\n    ```\n   ## Blast radius\n   " + SECTION.split("\n")[1] + "\n"))

    @unittest.expectedFailure
    def test_deeply_indented_line_does_not_close_fence(self):
        self.assertTrue(B.problems("```\nx\n        ```\n" + SECTION))

    def test_fence_lines_inside_section_are_not_content(self):
        self.assertTrue(B.problems("## Blast radius\n```\n" + GOOD + "```\n"))


class Bots(unittest.TestCase):
    def run_event(self, text, login, kind):
        ev = {"pull_request": {"body": text, "user": {"login": login, "type": kind}}}
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
            json.dump(ev, fh)
        try:
            return subprocess.run([sys.executable, SCRIPT, "--event", fh.name], capture_output=True, text=True)
        finally:
            os.unlink(fh.name)

    @unittest.expectedFailure
    def test_bots_are_not_exempt(self):
        for login, kind in [("cursor[bot]", "Bot"), ("github-actions[bot]", "Bot"), ("github-actions", "User"),
                            ("renovate[bot]", "Bot"), ("renovate", "User"), ("dependabot[bot]", "Bot"),
                            ("dependabot", "User")]:
            with self.subTest(login=login):
                r = self.run_event("## For Dread\nbump\n", login, kind)
                self.assertEqual(r.returncode, 1, r.stdout)
                self.assertNotIn("skipped", r.stdout)


class Substance(unittest.TestCase):
    @unittest.expectedFailure
    def test_noncommittal_phrases_fail(self):
        for v in ["None \u2014 trivial change here", "None - trivial change here", "To be determined later on",
                  "Trivial change, nothing to report here", "Unknown at this point in time",
                  "N/A for this one really", "Not sure yet, will look"]:
            with self.subTest(v=v):
                self.assertTrue(B.problems(br(v)))

    @unittest.expectedFailure
    def test_vague_prose_without_area_fails(self):
        self.assertTrue(B.problems(br("This could affect some other things in the app, I checked.")))

    @unittest.expectedFailure
    def test_area_without_evidence_fails(self):
        errs = B.problems(br("The nightly sync job imports `load_points()` and could break."))
        self.assertTrue(errs and "cite what was checked" in errs[0], errs)

    @unittest.expectedFailure
    def test_no_dependents_without_evidence_fails(self):
        self.assertTrue(B.problems(br("Nothing else imports this new standalone helper script.")))

    def test_no_dependents_with_evidence_passes(self):
        self.assertEqual(B.problems(br("Nothing else imports this new helper; I searched the whole repo.")), [])

    def test_issue_reference_with_evidence_passes(self):
        self.assertEqual(B.problems(br("Open PR #42 will go red on its next push; I checked the open PR list.")), [])

    @unittest.expectedFailure
    def test_template_prompt_without_tbd_fails(self):
        self.assertTrue(B.problems(br(PROMPT.split(": ", 1)[1])))

    @unittest.expectedFailure
    def test_template_prompt_variants_fail(self):
        for v in [PROMPT, "- " + PROMPT, "**" + PROMPT + "**", "> " + PROMPT, "- [ ] " + PROMPT.split(": ", 1)[1]]:
            with self.subTest(v=v):
                self.assertTrue(B.problems(br(v)))

    @unittest.expectedFailure
    def test_template_constant_matches(self):
        self.assertEqual(B.TEMPLATE_PROMPT, PROMPT)

    @unittest.expectedFailure
    def test_question_only_fails(self):
        self.assertTrue(B.problems(br("Does `quotes.json` change anything for the overlay I checked?")))


class Cli(unittest.TestCase):
    def run_event(self, text):
        ev = {"pull_request": {"body": text, "user": {"login": "DreadfullyDespized", "type": "User"}}}
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
            json.dump(ev, fh)
        try:
            return subprocess.run([sys.executable, SCRIPT, "--event", fh.name], capture_output=True, text=True)
        finally:
            os.unlink(fh.name)

    def test_event_fail(self):
        r = self.run_event(br("none"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("::error title=Blast radius::", r.stdout)

    def test_event_pass(self):
        r = self.run_event(br(GOOD))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("OK", r.stdout)

    def test_null_body_fails(self):
        self.assertEqual(self.run_event(None).returncode, 1)

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
