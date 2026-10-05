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
             "MsgBox, a`; b\n", 'x := "a ; b"\n', "Send, {;}\n", "MsgBox('a ;b')\n", "x := 'it ;s'\n"]),
    "ahk-apostrophe": ("y.ahk", ["MsgBox, don't ; inline comment\n"], ["MsgBox, don't stop\n"]),
    "js-regex-after-keyword": ("y.js", ["return a; // why\n"],
                               ["function f(s) { return /\\/\\//.test(s); }\n",
                                "if (typeof /x/ === 'object') {}\n"]),
    "mirc-ini": ("remote.ini",
                 ["[script]\nn0=; comment in remote.ini\nn1=on *:TEXT:!a:#:{ msg # hi }\n",
                  "[aliases]\nn0=/*\nn1=block\nn2=*/\n", "[script]\nn0=alias a {\nn1=  ; indented\nn2=}\n"],
                 ["[script]\nn0=alias a { echo -a hi ; there }\n", "[mirc]\n; settings comment, not script\nnick=Dread\n",
                  "[script]\nn0=on *:TEXT:!a:#:{ msg # hi }\n"]),
    "sql": ("x.sql",
            ["SELECT 1; -- why\n", "-- header\nSELECT 1;\n", "/* block */\nSELECT 2;\n"],
            ["SELECT '-- not a comment';\n", "SELECT 'it''s -- still a string';\n",
             'SELECT "a--b" FROM t;\n', "SELECT 4 - -1;\n"]),
    "yaml": ("x.yml",
             ["on: push # trigger\n", "# header\nname: ci\n",
              "steps:\n  - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0\n"],
             ["name: 'a # b'\n", 'url: "https://x/#top"\n', "key: a#b\n",
              "run: |\n  echo # shell text in a block scalar\n  ls\nnext: 1\n",
              "steps:\n  - run: >-\n      echo # folded\n"]),
    "batch": ("x.bat",
              ["REM why\n", "@rem quiet\n", ":: label-style comment\n", "echo hi & rem trailing\n",
               "rem\n"],
              ["echo remember\n", "set REMOTE=1\n", "echo \"a & rem b\"\n", ":label\n"]),
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
            ("x.py", "# -*- coding: utf-8 -*-\nx = 1\n"),
            ("x.py", "# vim: set fileencoding=utf-8 :\nx = 1\n"),
            ("x.ps1", "#Requires -Version 5.1\n"),
            ("x.ps1", "#Requires -Modules Pester, PSReadLine\n"),
            ("x.ps1", "#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }\n"),
            ("x.ps1", "#Requires -PSEdition Core -RunAsAdministrator\n"),
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
            ("x.ps1", "#Requires -Version 5 # and here is a comment\n"),
            ("x.ps1", "#Requires -Version 5 and why we need it\n"),
            ("x.ps1", "#Requires because the server is old\n"),
            ("x.py", "# this is about coding: utf-8 and why we do X\nx = 1\n"),
            ("x.py", "#!/usr/bin/env python3\n# coding: utf-8  because Windows\n"),
            ("x.py", "# -*- coding: utf-8 -*- and a note\n"),
            ("x.sh", "#!/bin/bash # why bash\nls\n"),
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
        self.assertEqual(hits("x.toml", "# toml\n"), [])

    def test_extensionless_files_are_scanned_or_skipped_explicitly(self):
        self.assertIsNone(N.skip_reason("tools/run", "#!/bin/bash\nls\n"))
        self.assertIn("no shebang", N.skip_reason("tools/run", "ls # x\n"))
        self.assertIn("does not know", N.skip_reason("tools/run", "#!/usr/bin/perl\nprint 1; # x\n"))
        self.assertIsNone(N.skip_reason("x.md", "# Title\n"))
        self.assertEqual(hits("tools/run", "ls # x\n"), [])

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

    def test_pure_rename_flags_nothing(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        _git(self.d, "mv", "a.py", "c.py")
        self.commit()
        self.assertEqual(N.run("main", "HEAD"), [])
        self.assertEqual(self.main(), 0)

    def test_rename_with_an_added_comment_flags_only_that_line(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        _git(self.d, "mv", "a.py", "c.py")
        self.write("c.py", "# an old comment stays\nx = 1\ny = 2  # new\n")
        self.commit()
        self.assertEqual(N.run("main", "HEAD"), ["c.py:3: comment added: '# new'"])

    def test_extensionless_skip_is_reported(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        self.write("tools/notes", "plain text # not scanned\n")
        self.write("tools/run", "#!/bin/sh\nls # flagged\n")
        self.commit()
        skipped = []
        self.assertEqual(N.run("main", "HEAD", skipped), ["tools/run:2: comment added: '# flagged'"])
        self.assertEqual(skipped, ["tools/notes: extensionless, no shebang on line 1"])

    def test_every_language_through_git(self):
        _git(self.d, "checkout", "-q", "-b", "pr")
        for lang, (path, bad, _) in CASES.items():
            self.write("src/" + path, bad[0])
        self.commit()
        found = {h.split(":")[0] for h in N.run("main", "HEAD")}
        self.assertEqual(found, {"src/" + p for p, _, _ in CASES.values()})


if __name__ == "__main__":
    unittest.main()
