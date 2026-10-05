#!/usr/bin/env python3
r"""no-new-comments: a PR must not ADD a code comment (Dread's standing rule).

Dread's rule (2026-10-04): no code comments, ever, from any bot. This check
fails a pull request whose diff adds a comment. Only added lines count;
existing comments are left for a separate cleanup pass.

Languages, by file extension (extensionless files by their shebang):
  Python      .py .pyw              '#' comments, found with tokenize, so a '#'
                                    inside a string is not a comment and
                                    docstrings are not comments
  bash/sh     .sh .bash             '#' at the start of a word, outside quotes,
                                    $#, ${#x} and heredoc bodies
  PowerShell  .ps1 .psm1 .psd1      '#' at the start of a token and <# ... #>
  JS/TS       .js .mjs .cjs .jsx    '//' and '/* */', outside strings, template
              .ts .tsx .mts .cts    literals and regex literals
  CSS         .css                  '/* */'
  HTML        .html .htm            '<!-- -->', plus JS comments inside <script>
                                    and CSS comments inside <style>
  mIRC        .mrc .als             a line starting with ';', and /* */ blocks
  AHK         .ahk .ah2 .ahk2       ';' at the start of a line or after
                                    whitespace (not `;), and /* */ blocks

The only exemptions are this allowlist (ALLOWED below):
  - a shebang on line 1 (any language);
  - the PEP 263 encoding line (Python, line 1 or 2);
  - '# type: ignore' and '# type: ignore[code, ...]';
  - '# noqa' and '# noqa: CODE[, CODE]';
  - '# pragma: no cover';
  - AHK '#' directives (#Requires, #SingleInstance, #NoEnv, #Include, ...):
    '#' is not a comment in AHK, so they never match;
  - PowerShell '#Requires' at the start of a line.

Usage (same locally and in CI):
  python3 tools/checks/no_new_comments.py --base origin/main --head HEAD
  python3 tools/checks/no_new_comments.py --event "$GITHUB_EVENT_PATH"
"""
from __future__ import annotations

import argparse
import io
import json
import os
import re
import subprocess
import sys
import tokenize

LANG_BY_EXT = {
    ".py": "python", ".pyw": "python",
    ".sh": "bash", ".bash": "bash",
    ".ps1": "powershell", ".psm1": "powershell", ".psd1": "powershell",
    ".js": "js", ".mjs": "js", ".cjs": "js", ".jsx": "js",
    ".ts": "js", ".tsx": "js", ".mts": "js", ".cts": "js",
    ".css": "css",
    ".html": "html", ".htm": "html",
    ".mrc": "mirc", ".als": "mirc",
    ".ahk": "ahk", ".ah2": "ahk", ".ahk2": "ahk",
}
SHEBANG_LANG = (
    (re.compile(r"^#!.*\bpython[0-9.]*\b"), "python"),
    (re.compile(r"^#!.*\b(?:bash|sh|dash|zsh)\b"), "bash"),
    (re.compile(r"^#!.*\bpwsh\b"), "powershell"),
    (re.compile(r"^#!.*\bnode\b"), "js"),
)
AHK_DIRECTIVES = (
    "#Requires", "#SingleInstance", "#NoEnv", "#Include", "#IncludeAgain", "#Persistent",
    "#Warn", "#HotIf", "#IfWinActive", "#IfWinExist", "#If", "#MaxThreads",
    "#MaxThreadsPerHotkey", "#UseHook", "#InstallKeybdHook", "#InstallMouseHook",
    "#NoTrayIcon", "#KeyHistory", "#Hotstring", "#ErrorStdOut", "#ClipboardTimeout",
    "#WinActivateForce", "#MaxHotkeysPerInterval", "#HotkeyInterval", "#Ahk2Exe",
)
ALLOWED = {
    "python": (
        re.compile(r"^#\s*type:\s*ignore(?:\[[^\]\n]*\])?\s*$"),
        re.compile(r"^#\s*noqa(?::\s*[A-Z]+[0-9]+(?:\s*,\s*[A-Z]+[0-9]+)*)?\s*$"),
        re.compile(r"^#\s*pragma:\s*no\s+cover\s*$"),
    ),
    "powershell": (re.compile(r"^#requires\b", re.I),),
}
PEP263_RX = re.compile(r"^[ \t\f]*#.*?coding[:=][ \t]*[-\w.]+")


def lang_of(path, text=""):
    ext = os.path.splitext(path)[1].lower()
    if ext in LANG_BY_EXT:
        return LANG_BY_EXT[ext]
    if not ext and text.startswith("#!"):
        first = text.split("\n", 1)[0]
        for rx, lang in SHEBANG_LANG:
            if rx.search(first):
                return lang
    return None


def _hash_scan(text, word_start):
    out, line = [], 1
    for ln, l in enumerate(text.split("\n"), 1):
        q = None
        i = 0
        while i < len(l):
            c = l[i]
            if q:
                if c == "\\" and q == '"':
                    i += 2
                    continue
                if c == q:
                    q = None
            elif c in "'\"":
                q = c
            elif c == "#" and (i == 0 or l[i - 1] in word_start):
                out.append((ln, ln, l[i:]))
                break
            i += 1
    return out


def python_comments(text):
    out = []
    try:
        for tok in tokenize.generate_tokens(io.StringIO(text).readline):
            if tok.type == tokenize.COMMENT:
                out.append((tok.start[0], tok.start[0], tok.string))
    except (tokenize.TokenError, IndentationError, SyntaxError):
        return _hash_scan(text, " \t;([{,")
    return out


def bash_comments(text):
    out, lines = [], text.split("\n")
    q, heredoc, pending = None, None, []
    for ln, l in enumerate(lines, 1):
        if heredoc:
            word, dash = heredoc
            if (l.lstrip("\t") if dash else l) == word:
                heredoc = pending.pop(0) if pending else None
            continue
        i = 0
        while i < len(l):
            c = l[i]
            if q:
                if c == "\\" and q == '"':
                    i += 2
                    continue
                if c == q:
                    q = None
                i += 1
                continue
            if c == "\\":
                i += 2
                continue
            if c in "'\"":
                q = c
            elif c == "$" and l[i + 1:i + 2] == "#":
                i += 2
                continue
            elif c == "$" and l[i + 1:i + 2] == "{":
                j = l.find("}", i)
                i = len(l) if j < 0 else j + 1
                continue
            elif l.startswith("<<<", i):
                i += 3
                continue
            elif l.startswith("<<", i):
                m = re.match(r"<<(-?)[ \t]*(['\"]?)([A-Za-z_][\w]*)\2", l[i:])
                if m:
                    pending.append((m.group(3), bool(m.group(1))))
                    i += m.end()
                    continue
            elif c == "#" and (i == 0 or l[i - 1] in " \t;|&()"):
                out.append((ln, ln, l[i:]))
                break
            i += 1
        if pending and not q:
            heredoc = pending.pop(0)
    return out


def powershell_comments(text):
    out, i, n, line = [], 0, len(text), 1
    prev = "\n"
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            prev = c
            i += 1
            continue
        if text.startswith("@'", i) or text.startswith('@"', i):
            close = "\n" + text[i + 1] + "@"
            j = text.find(close, i + 2)
            j = n if j < 0 else j + len(close)
            line += text.count("\n", i, j)
            i, prev = j, "@"
            continue
        if c in "'\"":
            j = i + 1
            while j < n:
                if c == '"' and text[j] == "`":
                    j += 2
                    continue
                if text[j] == c:
                    if text[j + 1:j + 2] == c:
                        j += 2
                        continue
                    break
                j += 1
            line += text.count("\n", i, j)
            i, prev = j + 1, c
            continue
        if text.startswith("<#", i):
            j = text.find("#>", i + 2)
            j = n if j < 0 else j + 2
            seg = text[i:j]
            out.append((line, line + seg.count("\n"), seg))
            line += seg.count("\n")
            i, prev = j, ">"
            continue
        if c == "#" and (prev in " \t\n;|&(){}=," or i == 0):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append((line, line, text[i:j]))
            i = j
            continue
        prev = c
        i += 1
    return out


def c_comments(text, line_comments=True, js=True, line0=1):
    out, i, n, line = [], 0, len(text), line0
    last = ""
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r":
            i += 1
            continue
        if c in ("'\"`" if js else "'\""):
            j = i + 1
            while j < n and text[j] != c:
                if text[j] == "\\":
                    j += 1
                elif text[j] == "\n" and c != "`":
                    break
                j += 1
            line += text.count("\n", i, j)
            i, last = j + 1, c
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            seg = text[i:j]
            out.append((line, line + seg.count("\n"), seg))
            line += seg.count("\n")
            i = j
            continue
        if line_comments and text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append((line, line, text[i:j]))
            i = j
            continue
        if js and c == "/" and (last == "" or last in "(,=:[!&|?{};+-*%<>~^"):
            j, cls = i + 1, False
            while j < n and text[j] != "\n":
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == "[":
                    cls = True
                elif text[j] == "]":
                    cls = False
                elif text[j] == "/" and not cls:
                    break
                j += 1
            if j < n and text[j] == "/":
                i, last = j + 1, "/"
                continue
        last = c
        i += 1
    return out


def _blank(text, a, b):
    return text[:a] + re.sub(r"[^\n]", " ", text[a:b]) + text[b:]


def html_comments(text):
    out, masked = [], text
    for tag, js in (("script", True), ("style", False)):
        for m in re.finditer(rf"(<{tag}\b[^>]*>)(.*?)(</{tag}\s*>|\Z)", text, re.S | re.I):
            line0 = text.count("\n", 0, m.start(2)) + 1
            out += c_comments(m.group(2), line_comments=js, js=js, line0=line0)
            masked = _blank(masked, m.start(2), m.end(2))
    for m in re.finditer(r"<!--.*?(?:-->|\Z)", masked, re.S):
        line = masked.count("\n", 0, m.start()) + 1
        out.append((line, line + m.group(0).count("\n"), m.group(0)))
    return sorted(out)


def _block_lines(text, line_rx, ahk):
    out, block = [], None
    for ln, l in enumerate(text.split("\n"), 1):
        s = l.strip()
        if block is not None:
            block[2].append(l)
            if s.startswith("*/") or s.endswith("*/"):
                out.append((block[0], ln, "\n".join(block[2])))
                block = None
            continue
        if s.startswith("/*"):
            if s.endswith("*/") and len(s) >= 4:
                out.append((ln, ln, l))
            else:
                block = [ln, ln, [l]]
            continue
        m = line_rx(l)
        if m is not None:
            out.append((ln, ln, l[m:]))
    if block is not None:
        out.append((block[0], len(text.split("\n")), "\n".join(block[2])))
    return out


def _mirc_line(l):
    return len(l) - len(l.lstrip()) if l.lstrip().startswith(";") else None


def _ahk_line(l):
    q = False
    for i, c in enumerate(l):
        if c == '"':
            q = not q
        elif c == ";" and not q and (i == 0 or l[i - 1] in " \t") and (i == 0 or l[i - 1] != "`"):
            return i
    return None


def comments(lang, text):
    if lang == "python":
        return python_comments(text)
    if lang == "bash":
        return bash_comments(text)
    if lang == "powershell":
        return powershell_comments(text)
    if lang == "js":
        return c_comments(text)
    if lang == "css":
        return c_comments(text, line_comments=False, js=False)
    if lang == "html":
        return html_comments(text)
    if lang == "mirc":
        return _block_lines(text, _mirc_line, False)
    if lang == "ahk":
        return _block_lines(text, _ahk_line, True)
    return []


def allowed(lang, start, body, line_text=""):
    s = body.strip()
    if not line_text.strip().startswith(s.split("\n")[0]):
        return False
    if start == 1 and s.startswith("#!"):
        return True
    if lang == "python" and start in (1, 2) and PEP263_RX.match(s):
        return True
    if lang == "powershell" and not line_text.lstrip().lower().startswith("#requires"):
        return False
    return any(rx.match(s) for rx in ALLOWED.get(lang, ()))


def added_comments(path, text, added):
    """[(line, text)] for comments that touch an added line and are not allowed."""
    text = text.replace("\r\n", "\n")
    lang = lang_of(path, text)
    if not lang or not added:
        return []
    hits, lines = [], text.split("\n")
    for start, end, body in comments(lang, text):
        line_text = lines[start - 1] if start <= len(lines) else ""
        if allowed(lang, start, body, line_text if lang != "python" else body):
            continue
        touched = [x for x in range(start, end + 1) if x in added]
        if touched:
            hits.append((touched[0], body.strip().split("\n")[0][:120]))
    return hits


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True).stdout


def decode(raw):
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16", "replace")
    return raw.decode("utf-8-sig", "replace")


def added_lines(base, head, path):
    diff = git("diff", "-U0", "--no-color", "--no-ext-diff", f"{base}...{head}", "--", path)
    out = set()
    for m in re.finditer(rb"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", diff, re.M):
        start, count = int(m.group(1)), int(m.group(2) or 1)
        out.update(range(start, start + count))
    return out


def run(base, head):
    names = git("diff", "--name-only", "-z", "--diff-filter=AMR", f"{base}...{head}").split(b"\0")
    hits = []
    for raw_name in names:
        path = raw_name.decode("utf-8", "replace")
        if not path:
            continue
        raw = git("show", f"{head}:{path}")
        if b"\0" in raw[:8000] and not raw.startswith((b"\xff\xfe", b"\xfe\xff")):
            continue
        text = decode(raw)
        if not lang_of(path, text):
            continue
        for line, body in added_comments(path, text, added_lines(base, head, path)):
            hits.append(f"{path}:{line}: comment added: {body!r}")
    return hits


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--event", help="GitHub event JSON ($GITHUB_EVENT_PATH)")
    ap.add_argument("--base")
    ap.add_argument("--head", default="HEAD")
    a = ap.parse_args(argv)
    base, head = a.base, a.head
    if a.event:
        with open(a.event, encoding="utf-8") as f:
            pr = json.load(f).get("pull_request")
        if not pr:
            print("no_new_comments: not a pull_request event; nothing to check")
            return 0
        base, head = pr["base"]["sha"], pr["head"]["sha"]
    if not base:
        ap.error("--base (or --event) is required")
    hits = run(base, head)
    for h in hits:
        print("no-new-comments: " + h)
    if hits:
        print(f"no_new_comments: {len(hits)} added comment(s). Dread's rule: no code comments. "
              "Put the why in the PR body or a commit message. Allowed only: shebang, PEP 263 "
              "encoding line, '# type: ignore[...]', '# noqa[: code]', '# pragma: no cover', "
              "AHK # directives, PowerShell #Requires.", file=sys.stderr)
        return 1
    print("no_new_comments: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
