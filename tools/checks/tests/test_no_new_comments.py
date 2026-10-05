"""Tests for tools/checks/no_new_comments.py (stdlib unittest).

Run: python3 -m unittest discover -s <this folder> -p "test_no_new_comments.py" -v
"""
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "tools", "checks"))
import no_new_comments as N  # noqa: E402


def hits(path, text, added=None):
    lines = text.split("\n")
    return N.added_comments(path, text, set(range(1, len(lines) + 1)) if added is None else added)


CASES = {
    "python": ("x.py",
               ["x = 1  # set x\n", "# a comment line\n", "def f():\n    # inside\n    return 1\n"],
               ["s = '# not a comment'\n", 'def f():\n    """Docstring # with hash."""\n    return 1\n',
                "u = f\"{'#'}\"\n", "x = 1\n"]),
    "bash": ("x.sh",
             ["echo hi # say hi\n", "# comment\n", "  # indented\nls\n", "ls;# after semicolon\n"],
             ["echo '# quoted'\n", 'echo "a # b"\n', "echo $#\n", "n=${#arr[@]}\n", "echo a#b\n",
              "cat <<EOF\n# heredoc text\nEOF\n", "echo \\# escaped\n"]),
    "powershell": ("x.ps1",
                   ["Get-Item . # note\n", "# comment\n", "<# block\n comment #>\n", "$a = 1;# x\n"],
                   ["Write-Host '# quoted'\n", 'Write-Host "a # b"\n', "$h = @'\n# here-string\n'@\n",
                    "Write-Host a#b\n", '$s = "it``s # in string"\n']),
    "js": ("x.js",
           ["let a = 1; // note\n", "/* block */\nlet b = 2;\n", "/**\n * doc\n */\nfunction f() {}\n"],
           ["const u = 'https://example.com';\n", 'const s = "/* not */";\n', "const t = `// not ${1}`;\n",
            "const r = /\\/\\/+/g;\n", "const d = a / b / c;\n"]),
    "ts": ("x.ts",
           ["const n: number = 1; // n\n", "/* t */ type A = string;\n"],
           ["const u: string = 'a//b';\n"]),
    "css": ("x.css",
            ["/* header */\nbody { color: red; }\n", "a { color: blue; /* inline */ }\n"],
            ["a { background: url('http://x/y.png'); }\n", 'a::after { content: "/* no */"; }\n']),
    "html": ("x.html",
             ["<!-- note -->\n<p>x</p>\n", "<script>\nlet a = 1; // js note\n</script>\n",
              "<style>\n/* css */\np{}\n</style>\n"],
             ["<p>// not a comment</p>\n", "<script>\nconst u = 'https://x';\n</script>\n",
              '<a href="https://x/#top">x</a>\n']),
    "mirc": ("x.mrc",
             ["; comment\nalias a { echo -a hi }\n", "  ; indented comment\n",
              "/*\nblock comment\n*/\n"],
             ["alias a { echo -a hi ; there }\n", "on *:TEXT:!a:#:{ msg # hi }\n",
              "alias b { return $calc(4 / 2) }\n"]),
    "ahk": ("x.ahk",
            ["; comment\n", "MsgBox, hi ; inline\n", "/*\nblock\n*/\n", "x := 1\t; tab inline\n"],
            ["#Requires AutoHotkey v2.0\n", "#SingleInstance Force\n", "#NoEnv\n", "#Include lib.ahk\n",
             "MsgBox, a`; b\n", 'x := "a ; b"\n', "Send, {;}\n"]),
}


class EachLanguage(unittest.TestCase):
    def test_added_comment_fails(self):
        for lang, (path, bad, _) in CASES.items():
            for text in bad:
                self.assertTrue(hits(path, text), (lang, text))

    def test_code_without_comments_passes(self):
        for lang, (path, _, good) in CASES.items():
            for text in good:
                self.assertEqual(hits(path, text), [], (lang, text))


class Allowlist(unittest.TestCase):
    def test_allowed_forms_pass(self):
        for path, text in [
            ("x.py", "#!/usr/bin/env python3\nx = 1\n"),
            ("x.py", "#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\nx = 1\n"),
            ("x.py", "# coding: latin-1\nx = 1\n"),
            ("x.py", "import x  # type: ignore\n"),
            ("x.py", "import x  # type: ignore[import-untyped]\n"),
            ("x.py", "import x  # noqa\n"),
            ("x.py", "import x  # noqa: E402\n"),
            ("x.py", "import x  # noqa: E402, F401\n"),
            ("x.py", "if x:  # pragma: no cover\n    pass\n"),
            ("x.sh", "#!/usr/bin/env bash\nls\n"),
            ("x.ps1", "#Requires -Version 7\nGet-Item .\n"),
            ("x.ps1", "#requires -RunAsAdministrator\n"),
            ("x.ahk", "#Requires AutoHotkey v2.0\n#SingleInstance Force\n"),
            ("x.js", "#!/usr/bin/env node\nlet a = 1;\n"),
        ]:
            self.assertEqual(hits(path, text), [], (path, text))

    def test_look_alikes_of_allowed_forms_fail(self):
        for path, text in [
            ("x.py", "x = 1\n#!/usr/bin/env python3\n"),
            ("x.py", "x = 1\ny = 2\n# coding: utf-8\n"),
            ("x.py", "import x  # type: ignore  because reasons\n"),
            ("x.py", "import x  # noqa: this is fine\n"),
            ("x.py", "x = 1  # pragma: no cover, slow\n"),
            ("x.py", "x = 1  # TODO\n"),
            ("x.ps1", "Get-Item .\n# Requires a note\n"),
            ("x.ps1", "Get-Item . #Requires inline\n"),
        ]:
            self.assertTrue(hits(path, text), (path, text))


class OnlyAddedLines(unittest.TestCase):
    def test_existing_comment_is_not_flagged(self):
        text = "# old comment\nx = 1\ny = 2\n"
        self.assertEqual(hits("x.py", text, added={3}), [])
        self.assertEqual(hits("x.py", text, added={1}), [(1, "# old comment")])

    def test_line_inside_an_old_block_comment_counts(self):
        text = "/*\nold\nnew line\n*/\nlet a;\n"
        self.assertEqual(hits("x.js", text, added={5}), [])
        self.assertTrue(hits("x.js", text, added={3}))

    def test_unknown_extensions_are_skipped(self):
        self.assertEqual(hits("README.md", "<!-- template help -->\n# Title\n"), [])
        self.assertEqual(hits("x.yml", "# yaml\n"), [])

    def test_extensionless_script_by_shebang(self):
        self.assertTrue(hits("tools/run", "#!/bin/bash\nls # list\n"))
        self.assertEqual(hits("tools/run", "#!/bin/bash\nls\n"), [])


def _git(cwd, *a):
    return subprocess.run(["git", *a], cwd=cwd, check=True, capture_output=True, text=True).stdout


class Cli(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp(prefix="nnc_")
        _git(self.d, "init", "-q", "-b", "main")
        _git(self.d, "config", "user.email", "t@t")
        _git(self.d, "config", "user.name", "t")
        self.write("a.py", "# an old comment stays\nx = 1\n")
        _git(self.d, "add", "-A")
        _git(self.d, "commit", "-qm", "base")
        self.cwd = os.getcwd()
        os.chdir(self.d)

    def tearDown(self):
        os.chdir(self.cwd)

    def write(self, name, text):
        p = os.path.join(self.d, name)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            f.write(text)

    def commit(self):
        _git(self.d, "add", "-A")
        _git(self.d, "commit", "-qm", "change")

    def main(self):
        from contextlib import redirect_stderr, redirect_stdout
        import io
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            return N.main(["--base", "main", "--head", "HEAD"])

    def test_pr_adding_code_next_to_old_comment_passes(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        self.write("a.py", "# an old comment stays\nx = 1\ny = 2\n")
        self.write("b.sh", "#!/bin/bash\nls\n")
        self.commit()
        self.assertEqual(self.main(), 0)

    def test_pr_adding_a_comment_fails(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        self.write("a.py", "# an old comment stays\nx = 1\ny = 2  # new comment\n")
        self.commit()
        self.assertEqual(self.main(), 1)
        self.assertEqual(N.run("main", "HEAD"), ["a.py:3: comment added: '# new comment'"])

    def test_every_language_through_git(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        for lang, (path, bad, _) in CASES.items():
            self.write("src/" + path, bad[0])
        self.commit()
        found = {h.split(":")[0] for h in N.run("main", "HEAD")}
        self.assertEqual(found, {"src/" + p for p, _, _ in CASES.values()})


if __name__ == "__main__":
    unittest.main()
