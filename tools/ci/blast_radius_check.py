#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys

from markdown_it import MarkdownIt

TITLE_RX = re.compile(r"^blast radius$", re.I)
LIST_RX = re.compile(r"^[ \t]*(?:>[ \t]*)*(?:(?:[-*+]|\d+[.)])[ \t]+)?(?:\[[ xX]\][ \t]+)?")
LEVEL_RX = re.compile(r"^[ \t]*(?:\*\*|__)?level(?:\*\*|__)?[ \t]*:", re.I)
NONCOMMITTAL_RX = re.compile(
    r"^(?:tbd|tba|todo|to be (?:determined|decided|confirmed|done)|unknown|not sure|unsure|maybe|"
    r"later|pending|trivial|n/?a|none\W+(?:trivial|small|minor|simple|obvious|cosmetic))\b", re.I)
FILLER = {
    "", "none", "n/a", "na", "n.a", "nothing", "tbd", "tba", "todo", "nil", "null",
    "no", "nope", "not applicable", "no impact", "none expected", "nothing else",
    "minimal", "low", "small", "see diff", "same as diff", "none known", "unknown",
}
TEMPLATE_PROMPT = ("TBD: list each area outside this diff that this change can break, or explain "
                   "why no other part needs it, and name the proof.")
MIN_WORDS = 4
CONCRETE_RX = re.compile(
    r"`[^`\n]+`"
    r"|(?<![\w/])[\w.-]+/[\w./-]+"
    r"|\b[\w-]+\.(?:py|pyw|sh|bash|ps1|psm1|psd1|js|mjs|cjs|jsx|ts|tsx|css|html?|mrc|als|ahk|ah2|ahk2"
    r"|ini|json|ya?ml|toml|md|txt|sql|bat|cmd|cs|lock|cfg|conf|db|csv|xml)\b"
    r"|(?:\b[\w.-]+/[\w.-]+)?#\d+\b"
    r"|https?://\S+"
    r"|\b[a-z][a-z0-9]*_[a-z0-9_]+\b"
    r"|\b[a-z]+[A-Z][A-Za-z0-9]*\b|\b[A-Z][a-z0-9]+[A-Z][A-Za-z0-9]*\b"
    r"|\b\w+\(\)")
NO_DEPENDENTS_RX = re.compile(
    r"\b(?:nothing|no (?:other )?(?:code|file|script|module|job|workflow|caller|consumer|user|one|repo|"
    r"service|system|test)s?|nobody|no one)\b(?:\s+else)?\s+(?:else\s+)?(?:\w+\s+){0,3}?"
    r"(?:depends?|imports?|calls?|uses?|reads?|references?|runs?|loads?|includes?|sources?|needs?|relies)\b"
    r"|\bnot (?:imported|called|used|referenced|read|loaded|included|sourced|run)\b"
    r"|\bno (?:callers?|dependents?|consumers?|references?|importers?|hits|matches|usages?)\b", re.I)
EVIDENCE_RX = re.compile(
    r"\b(?:checked|searched|search(?:ing)?|grep(?:ped)?|rg|git grep|ran|tested|verified|confirmed|"
    r"found|finds|looked|reviewed|traced|inspected|audited|listed|compared)\b", re.I)
HOW = ("Name at least one concrete area outside the diff this PR can affect (a file, path, `module`, "
       "feature, #N or system), or say why nothing else depends on it, and cite what you checked "
       "(for example: `rg load_points` finds only this file and the nightly job).")


def parser():
    return MarkdownIt("commonmark").enable(["table", "strikethrough"])


def inline_text(tok):
    out = []
    for c in tok.children or []:
        if c.type in ("text", "text_special"):
            out.append(c.content)
        elif c.type == "code_inline":
            out.append("`" + c.content + "`")
        elif c.type in ("softbreak", "hardbreak"):
            out.append("\n")
    return "".join(out)


def is_section_end(tok):
    return tok.type == "heading_open" and tok.level == 0 and tok.tag in ("h1", "h2")


def section(body):
    toks = parser().parse((body or "").replace("\r\n", "\n").replace("\r", "\n"))
    start = None
    for i, tok in enumerate(toks):
        if (tok.type == "heading_open" and tok.tag == "h2" and tok.level == 0 and tok.markup == "##"
                and i + 1 < len(toks) and toks[i + 1].type == "inline"
                and TITLE_RX.match(re.sub(r"[ \t]+", " ", inline_text(toks[i + 1])).strip())):
            start = i + 3
            break
    if start is None:
        return None
    lines = []
    blocks = 0
    for tok in toks[start:]:
        if is_section_end(tok):
            break
        if tok.type in ("list_item_open", "hr"):
            blocks += 1
        if tok.type == "inline":
            lines.extend(inline_text(tok).split("\n"))
    lines = [l for l in lines if not LEVEL_RX.match(l)]
    if blocks and not "".join(lines).strip():
        return ["-"]
    return lines


def normalize(line):
    line = LIST_RX.sub("", line, count=1)
    line = re.sub(r"[*_`~]", "", line).strip().lower()
    line = re.sub(r"\s+", " ", line)
    return line.strip(" \t.,;:!?-\u2013\u2014=()[]\"'")


def prompt_forms():
    full = normalize(TEMPLATE_PROMPT)
    bare = normalize(re.sub(r"^\s*tbd\s*:\s*", "", TEMPLATE_PROMPT, flags=re.I))
    return {full, bare}


def meaningful_lines(sec):
    prompts = prompt_forms()
    out = []
    for raw in sec:
        norm = normalize(raw)
        if norm in FILLER or norm in prompts or NONCOMMITTAL_RX.match(norm):
            continue
        if raw.strip().endswith("?"):
            continue
        out.append(raw.strip())
    return out


def problems(body):
    sec = section(body)
    if sec is None:
        return ["the PR body has no '## Blast radius' heading. " + HOW]
    if not "".join(sec).strip():
        return ["the '## Blast radius' section is empty. " + HOW]
    lines = meaningful_lines(sec)
    if not lines:
        return ["the '## Blast radius' section is only filler, a placeholder or the template prompt "
                "(none, n/a, nothing, TBD, -, trivial). " + HOW]
    text = "\n".join(lines)
    words = re.findall(r"[A-Za-z0-9][\w./#-]*", text)
    if len(words) < MIN_WORDS:
        return [f"the '## Blast radius' section is too thin ({len(words)} words). " + HOW]
    if not (CONCRETE_RX.search(text) or NO_DEPENDENTS_RX.search(text)):
        return ["the '## Blast radius' section names no concrete area (a file, path, `module`, "
                "feature, #N or system) and does not say why nothing else depends on the change. " + HOW]
    if not EVIDENCE_RX.search(text):
        return ["the '## Blast radius' section does not cite what was checked (searched, ran, "
                "verified, `rg ...` found ...). " + HOW]
    return []


def from_event(path):
    with open(path, encoding="utf-8") as fh:
        event = json.load(fh)
    pr = event.get("pull_request")
    if not pr:
        return None
    return pr.get("body") or ""


def main(argv=None):
    ap = argparse.ArgumentParser(description="Require a filled-in '## Blast radius' section in the PR body.")
    ap.add_argument("--event", help="GitHub event JSON ($GITHUB_EVENT_PATH)")
    ap.add_argument("--body-file", help="a PR body in a file, for local runs")
    args = ap.parse_args(argv)
    if args.event:
        body = from_event(args.event)
        if body is None:
            print("blast_radius_check: not a pull_request event", file=sys.stderr)
            return 2
    elif args.body_file:
        with open(args.body_file, encoding="utf-8") as fh:
            body = fh.read()
    else:
        ap.error("pass --event or --body-file")
    errs = problems(body)
    if errs:
        for e in errs:
            print(f"::error title=Blast radius::{e}")
            print(f"blast_radius_check: FAIL: {e}", file=sys.stderr)
        return 1
    print("blast_radius_check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
