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
  mIRC .ini   .ini                  the same rules on mIRC script lines
                                    (n0=, n1=, ... in aliases.ini, remote.ini,
                                    popups.ini); other .ini lines are settings
                                    and are not scanned
  AHK         .ahk .ah2 .ahk2       ';' at the start of a line or after
                                    whitespace (not `;, not inside "..." or a
                                    v2 '...' string), and /* */ blocks
  SQL         .sql                  '--' and '/* */', outside quotes
  YAML        .yml .yaml            '#' at the start of a line or after
                                    whitespace, outside quotes and outside
                                    block scalars; a workflow 'run: |' or
                                    'run: >' block is scanned as bash, or as
                                    PowerShell, batch or Python when the step
                                    says 'shell: pwsh', 'cmd' or 'python'
  batch       .bat .cmd             REM and :: at the start of a command

Extensionless files are scanned by their shebang (python, bash/sh, pwsh,
node). Every other extensionless file, and a shebang naming any other
interpreter, is skipped and listed as skipped in the output. Files with any
other extension are not code this check knows, and are not scanned.
Renames are detected (git diff -M), so a pure rename adds no lines, unless
the rename moves the file into a scanned language it was not in before
(notes.txt -> notes.py, tools/helper -> tools/helper.sh, x.sh -> x.py): then
every line of the new file counts as added.

The only exemptions are this allowlist (ALLOWED below):
  - a shebang on line 1 (any language), with nothing after the command;
  - the PEP 263 encoding line (Python, line 1 or 2), the whole line being
    '# coding: X', '# -*- coding: X -*-' or '# vim: set fileencoding=X :';
  - '# type: ignore' and '# type: ignore[code, ...]', codes being words and
    dashes only (no free text inside the brackets);
  - '# noqa' and '# noqa: CODE[, CODE]';
  - '# pragma: no cover';
  - AHK '#' directives (#Requires, #SingleInstance, #NoEnv, #Include, ...):
    '#' is not a comment in AHK, so they never match;
  - PowerShell '#Requires' at the start of a line, the whole line being
    #Requires parameters (-Version, -PSEdition, -RunAsAdministrator,
    -Modules, -PSSnapin, -Assembly) with nothing else after them; a
    -Modules @{...} table may hold only ModuleName, ModuleVersion,
    RequiredVersion, MaximumVersion and GUID keys with plain values.

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
    ".ini": "mirc-ini",
    ".sql": "sql",
    ".yml": "yaml", ".yaml": "yaml",
    ".bat": "batch", ".cmd": "batch",
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
SHEBANG_RX = re.compile(r"^#![ \t]*/\S+(?:[ \t]+[^\s#]+)*[ \t]*$")
PS_VALUE = r"""(?:'[\w.\-]+'|"[\w.\-]+"|[\w.\-]+)"""
PS_PAIR = r"(?:ModuleName|ModuleVersion|RequiredVersion|MaximumVersion|GUID)[ \t]*=[ \t]*" + PS_VALUE
PS_MODULE = (r"@\{[ \t]*" + PS_PAIR + r"(?:[ \t]*;[ \t]*" + PS_PAIR + r")*[ \t]*;?[ \t]*\}"
             r"|[\w.\-]+")
ALLOWED = {
    "python": (
        re.compile(r"^#\s*type:\s*ignore(?:\[[\w-]+(?:[ \t]*,[ \t]*[\w-]+)*\])?\s*$"),
        re.compile(r"^#\s*noqa(?::\s*[A-Z]+[0-9]+(?:\s*,\s*[A-Z]+[0-9]+)*)?\s*$"),
        re.compile(r"^#\s*pragma:\s*no\s+cover\s*$"),
    ),
    "powershell": (re.compile(
        r"^#requires(?:[ \t]+-(?:version[ \t]+[\d.]+|psedition[ \t]+\w+|runasadministrator"
        r"|modules[ \t]+(?:" + PS_MODULE + r")(?:[ \t]*,[ \t]*(?:" + PS_MODULE + r"))*"
        r"|pssnapin[ \t]+[^\s#]+(?:[ \t]+-version[ \t]+[\d.]+)?|assembly[ \t]+[^\s#]+))+[ \t]*$", re.I),),
}
PEP263_RX = re.compile(
    r"^#[ \t]*(?:-\*-[ \t]*)?(?:en)?coding[:=][ \t]*[-\w.]+[ \t]*(?:-\*-)?[ \t]*$"
    r"|^#[ \t]*vim:[ \t]*set[ \t]+fileencoding=[-\w.]+[ \t]*:[ \t]*$")


def lang_of(path, text=""):
    ext = os.path.splitext(os.path.basename(path))[1].lower()
    if ext in LANG_BY_EXT:
        return LANG_BY_EXT[ext]
    if not ext and text.startswith("#!"):
        first = text.split("\n", 1)[0]
        for rx, lang in SHEBANG_LANG:
            if rx.search(first):
                return lang
    return None


def skip_reason(path, text):
    """Why an extensionless file is skipped, or None when it is scanned or not a candidate."""
    if os.path.splitext(os.path.basename(path))[1] or lang_of(path, text):
        return None
    if text.startswith("#!"):
        return "extensionless, shebang names an interpreter this check does not know"
    return "extensionless, no shebang on line 1"


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
            word, dash, as_comment = heredoc
            end = (l.lstrip("\t") if dash else l) == word
            if as_comment and not end and l.strip():
                out.append((ln, ln, l if l.lstrip().startswith("#") else "# " + l.strip()))
            if end:
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
            if c == "$" and l[i + 1:i + 2] == "'":
                j = i + 2
                while j < len(l):
                    if l[j] == "\\":
                        j += 2
                        continue
                    if l[j] == "'":
                        break
                    j += 1
                i = j + 1
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
                mm = re.match(r"<<(-?)[ \t]*(['\"]?)([A-Za-z_][\w]*)\2", l[i:])
                if mm:
                    before = l[:i].rstrip()
                    as_comment = before == ":" or re.search(r"(?:^|[;&|]\s*):$", before) is not None
                    pending.append((mm.group(3), bool(mm.group(1)), as_comment))
                    i += mm.end()
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


def c_comments(text, line_comments=True, js=True, line0=1, line_tok="//", quotes=None):
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
        if c in (quotes if quotes is not None else ("'\"`" if js else "'\"")):
            if c == "`" and js:
                j = i + 1
                while j < n and text[j] != "`":
                    if text[j] == "\\":
                        j += 2
                        continue
                    if text[j] == "\n":
                        line += 1
                        j += 1
                        continue
                    if text[j] == "$" and text[j + 1:j + 2] == "{":
                        depth, k = 1, j + 2
                        while k < n and depth:
                            if text[k] == "{":
                                depth += 1
                            elif text[k] == "}":
                                depth -= 1
                            k += 1
                        expr = text[j + 2:k - 1 if depth == 0 else k]
                        expr_line = line + text.count("\n", i, j + 2)
                        for a, b, t in c_comments(expr, line_comments=line_comments, js=True, line0=expr_line):
                            out.append((a, b, t))
                        line += text.count("\n", j, k)
                        j = k
                        continue
                    j += 1
                line += text.count("\n", i, j)
                i, last = j + 1, c
                continue
            j = i + 1
            while j < n and text[j] != c:
                if text[j] == "\\" and line_tok == "//":
                    j += 1
                elif text[j] == "\n" and c != "`" and line_tok == "//":
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
        if line_comments and text.startswith(line_tok, i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append((line, line, text[i:j]))
            i = j
            continue
        if js and c == "/" and (last == "" or last in "(,=:[!&|?{};+-*%<>~^" or last == "kw"):
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
        if c.isalpha() or c in "_$":
            mm = re.match(r"[A-Za-z_$][\w$]*", text[i:])
            word = mm.group(0)
            last = "kw" if word in JS_REGEX_KEYWORDS else word[-1]
            i += len(word)
            continue
        last = c
        i += 1
    return out


JS_REGEX_KEYWORDS = {"return", "typeof", "case", "do", "else", "in", "of", "new", "delete",
                     "void", "throw", "yield", "await", "instanceof"}


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


def _ahk_v1_command(l):
    s = l.lstrip()
    if not s or s[0] in ";#/":
        return False
    if ":=" in s or s.lstrip().startswith(("if ", "If ", "while ", "While ", "loop ", "Loop ", "for ", "For ")):
        return False
    if re.match(r"^[A-Za-z_][\w#@$]*\s*\(", s):
        return False
    return bool(re.match(r"^[A-Za-z_][\w#@$]*\s*,", s) or re.match(r"^[A-Za-z_][\w#@$]*\s+\S", s))


def _ahk_line(l):
    if _ahk_v1_command(l):
        for i, c in enumerate(l):
            if c == ";" and (i == 0 or l[i - 1] in " \t"):
                return i
        return None
    q = None
    i = 0
    while i < len(l):
        c = l[i]
        if q:
            if c == "`":
                i += 2
                continue
            if c == q:
                q = None
            i += 1
            continue
        if c == '"' or (c == "'" and (i == 0 or not (l[i - 1].isalnum() or l[i - 1] == "_"))):
            q = c
        elif c == ";" and (i == 0 or l[i - 1] in " \t"):
            return i
        i += 1
    return None



INI_SCRIPT_RX = re.compile(r"^(n\d+=)(.*)$", re.I)


def ini_comments(text):
    lines = text.split("\n")
    script = []
    for l in lines:
        m = INI_SCRIPT_RX.match(l)
        script.append(m.group(2) if m else "")
    return _block_lines("\n".join(script), _mirc_line, False)


YAML_RUN_RX = re.compile(r"^[ \t]*(?:-[ \t]+)?run[ \t]*:[ \t]*[|>][-+0-9]*[ \t]*$")
YAML_SHELL_RX = re.compile(r"^[ \t]*(?:-[ \t]+)?shell[ \t]*:[ \t]*['\"]?([\w-]+)")
YAML_SHELL_LANG = {"pwsh": "powershell", "powershell": "powershell", "cmd": "batch", "python": "python"}


def _key_col(l):
    return re.match(r"^[ \t]*(?:-[ \t]+)?", l).end()


def _indent(l):
    return len(l) - len(l.lstrip(" "))


def _step_shell(lines, i):
    """Language of the `run:` script on line index i, from a sibling `shell:` key."""
    col = _key_col(lines[i])
    j = i
    while j > 0 and not lines[j].lstrip().startswith("-"):
        prev = lines[j - 1]
        if prev.strip() and _key_col(prev) != col and _indent(prev) < col:
            break
        j -= 1
    k = i + 1
    while k < len(lines) and (not lines[k].strip() or _indent(lines[k]) >= col):
        k += 1
    for l in lines[j:k]:
        m = YAML_SHELL_RX.match(l)
        if m and _key_col(l) == col:
            return YAML_SHELL_LANG.get(m.group(1).lower(), "bash")
    return "bash"


def _run_block(lines, first, body, lang):
    """Comments in a workflow `run:` script whose first line is line number `first`."""
    ind = min((_indent(l) for l in body if l.strip()), default=0)
    script = "\n".join(l[ind:] for l in body) + "\n"
    return [(first + a - 1, first + b - 1, t) for a, b, t in comments(lang, script)]


def yaml_comments(text):
    out, block, run = [], None, None
    lines = text.split("\n")
    for ln, l in enumerate(lines, 1):
        ind = _indent(l)
        if block is not None:
            if not l.strip() or ind > block:
                if run is not None:
                    run[2].append(l)
                continue
            block = None
            if run is not None:
                out.extend(_run_block(lines, run[0], run[2], run[1]))
                run = None
        q = None
        for i, c in enumerate(l):
            if q:
                if c == q:
                    q = None
            elif c in "'\"" and (i == 0 or l[i - 1] in " \t:-[{,"):
                q = c
            elif c == "#" and (i == 0 or l[i - 1] in " \t"):
                out.append((ln, ln, l[i:]))
                break
        code = l.split(" #", 1)[0].rstrip()
        if YAML_RUN_RX.match(code):
            block = _key_col(code)
            run = (ln + 1, _step_shell(lines, ln - 1), [])
            continue
        if re.search(r"(?:^|[:\-][ \t]+|^[ \t]*)[|>][-+0-9]*$", code):
            block = _key_col(code)
            if _is_github_script(lines, ln - 1) and re.search(r"\bscript[ \t]*:[ \t]*[|>]", code):
                run = (ln + 1, "js", [])
            continue
        mrun = re.match(r"^([ \t]*(?:-[ \t]+)?run[ \t]*:[ \t]*)(?![|>])(.*\S.*)$", l)
        if mrun:
            script = mrun.group(2).strip()
            if (script.startswith("'") and script.endswith("'")) or (script.startswith('"') and script.endswith('"')):
                script = script[1:-1]
            lang = _step_shell(lines, ln - 1)
            for a, b, t in comments(lang, script + "\n"):
                out.append((ln, ln, t))
    if run is not None:
        out.extend(_run_block(lines, run[0], run[2], run[1]))
    return sorted(out)


def _is_github_script(lines, i):
    j = i
    while j > 0 and not lines[j].lstrip().startswith("-"):
        j -= 1
    ind = _indent(lines[j])
    k = j + 1
    while k < len(lines):
        if lines[k].strip() and _indent(lines[k]) <= ind and lines[k].lstrip().startswith("-"):
            break
        if lines[k].strip() and _indent(lines[k]) < ind:
            break
        k += 1
    return "github-script" in "\n".join(lines[j:k])



BAT_RX = re.compile(r"^[ \t]*@?[ \t]*(?:rem(?=[ \t.;,=/\\]|$)|::)", re.I)
BAT_LABEL_RX = re.compile(r"^[ \t]*:[ \t]*#")
BAT_INLINE_RX = re.compile(r"(?:&&|\|\||&|\()[ \t]*@?[ \t]*rem(?=[ \t.;,=/\\]|$)", re.I)


def batch_comments(text):
    out = []
    for ln, l in enumerate(text.split("\n"), 1):
        if BAT_RX.match(l) or BAT_LABEL_RX.match(l):
            out.append((ln, ln, l.strip()))
            continue
        outside = re.sub(r'"[^"]*"', lambda x: " " * len(x.group(0)), l)
        m = BAT_INLINE_RX.search(outside)
        if m:
            rest = l[m.start():]
            rm = re.search(r"rem(?=[ \t.;,=/\\]|$)", rest, re.I)
            out.append((ln, ln, rest[rm.start():].strip() if rm else rest.strip()))
    return out


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
    if lang == "mirc-ini":
        return ini_comments(text)
    if lang == "sql":
        return c_comments(text, js=False, line_tok="--", quotes="'\"`")
    if lang == "yaml":
        return yaml_comments(text)
    if lang == "batch":
        return batch_comments(text)
    return []


def allowed(lang, start, body, line_text=""):
    s = body.strip()
    if not line_text.strip().startswith(s.split("\n")[0]):
        return False
    if start == 1 and SHEBANG_RX.match(s):
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


def parse_diff(diff):
    """{new path: set(added line numbers)} from a -U0 diff (renames: new path only, even a pure rename)."""
    out, path = {}, None
    for line in diff.split("\n"):
        if line.startswith("diff --git "):
            path = None
        elif line.startswith("rename to "):
            out.setdefault(line[len("rename to "):], set())
        elif line.startswith("+++ "):
            target = line[4:]
            path = target[2:] if target.startswith("b/") else None
            if path is not None:
                out.setdefault(path, set())
        elif line.startswith("@@") and path is not None:
            m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
            if m:
                start, count = int(m.group(1)), int(m.group(2) or 1)
                out[path].update(range(start, start + count))
    return out


def renamed_from(base, head):
    """{new path: old path} for renames between the merge base and head."""
    out = git("-c", "core.quotePath=false", "diff", "-M", "--name-status", "--diff-filter=R", "-z",
              f"{base}...{head}").decode("utf-8", "replace").split("\0")
    pairs, i = {}, 0
    while i + 2 < len(out):
        if out[i].startswith("R"):
            pairs[out[i + 2]] = out[i + 1]
            i += 3
        else:
            i += 1
    return pairs


def changes_language(old, new, base, head, text):
    """True when a rename moves a file into a scanned language it was not in before."""
    mb = git("merge-base", base, head).decode().strip()
    old_text = decode(git("show", f"{mb}:{old}")).replace("\r\n", "\n")
    new_lang = lang_of(new, text.replace("\r\n", "\n"))
    return new_lang is not None and lang_of(old, old_text) != new_lang


def run(base, head, skipped=None):
    diff = git("-c", "core.quotePath=false", "-c", "core.attributesFile=/dev/null",
               "diff", "-a", "-M", "-U0", "--no-color", "--no-ext-diff",
               "--diff-filter=AMR", f"{base}...{head}").decode("utf-8", "replace")
    renames = renamed_from(base, head)
    hits = []
    for path, added in sorted(parse_diff(diff).items()):
        raw = git("show", f"{head}:{path}")
        text = decode(raw)
        if path in renames and changes_language(renames[path], path, base, head, text):
            added = set(range(1, text.replace("\r\n", "\n").count("\n") + 2))
        if not added:
            continue
        why = skip_reason(path, text)
        if why and skipped is not None:
            skipped.append(f"{path}: {why}")
        if not lang_of(path, text):
            continue
        for line, body in added_comments(path, text, added):
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
    skipped = []
    hits = run(base, head, skipped)
    for sk in skipped:
        print("no_new_comments: skipped " + sk)
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
