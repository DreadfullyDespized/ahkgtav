#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys

HEADING_RX = re.compile(r"^[ \t]{0,3}(#{1,2})[ \t]+(.*?)[ \t#]*$", re.M)
TITLE_RX = re.compile(r"^blast[ \t]+radius$", re.I)
COMMENT_RX = re.compile(r"<!--.*?(?:-->|\Z)", re.S)
FENCE_RX = re.compile(r"^[ \t]*(```|~~~).*?^[ \t]*\1[ \t]*$", re.S | re.M)
LIST_RX = re.compile(r"^[ \t]*(?:>[ \t]*)*(?:(?:[-*+]|\d+[.)])[ \t]+)?")
PLACEHOLDER_RX = re.compile(r"^(?:tbd|tba|todo)\b", re.I)
LEVEL_RX = re.compile(r"^[ \t]*(?:\*\*|__)?level(?:\*\*|__)?[ \t]*:.*$", re.I | re.M)
FILLER = {
    "", "none", "n/a", "na", "n.a", "nothing", "tbd", "tba", "todo", "nil", "null",
    "no", "nope", "not applicable", "no impact", "none expected", "nothing else",
    "minimal", "low", "small", "see diff", "same as diff", "none known", "unknown",
}
MIN_WORDS = 4
BOT_LOGINS = {"dependabot", "dependabot-preview", "github-actions", "renovate"}
HOW = ("Name at least one area outside the diff this PR can affect (a caller, script, "
       "workflow, scheduled job, config, user-facing flow), or say why nothing else depends on it.")


def is_bot(login, user_type=""):
    login = (login or "").strip().lower()
    if (user_type or "").lower() == "bot":
        return True
    return login.endswith("[bot]") or login in BOT_LOGINS


def clean(body):
    text = (body or "").replace("\r\n", "\n")
    text = COMMENT_RX.sub("", text)
    return FENCE_RX.sub("", text)


def section(body):
    text = clean(body)
    heads = list(HEADING_RX.finditer(text))
    for i, h in enumerate(heads):
        if len(h.group(1)) == 2 and TITLE_RX.match(h.group(2).strip()):
            end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
            return LEVEL_RX.sub("", text[h.end():end])
    return None


def normalize(line):
    line = LIST_RX.sub("", line, count=1)
    line = re.sub(r"[*_`~]", "", line).strip().lower()
    return line.strip(" \t.,;:!?-–—=()[]\"'")


def meaningful_lines(sec):
    out = []
    for raw in sec.splitlines():
        norm = normalize(raw)
        if norm in FILLER or PLACEHOLDER_RX.match(norm):
            continue
        out.append(norm)
    return out


def problems(body):
    sec = section(body)
    if sec is None:
        return ["the PR body has no '## Blast radius' heading. " + HOW]
    if not sec.strip():
        return ["the '## Blast radius' section is empty. " + HOW]
    lines = meaningful_lines(sec)
    if not lines:
        return ["the '## Blast radius' section is only filler (none, n/a, nothing, TBD, -). " + HOW]
    words = re.findall(r"[a-z0-9][\w./#-]*", " ".join(lines))
    if len(words) < MIN_WORDS:
        return [f"the '## Blast radius' section is too thin ({len(words)} words). " + HOW]
    return []


def from_event(path):
    with open(path, encoding="utf-8") as fh:
        event = json.load(fh)
    pr = event.get("pull_request")
    if not pr:
        return None, None, None
    user = pr.get("user") or {}
    return pr.get("body") or "", user.get("login", ""), user.get("type", "")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Require a filled-in '## Blast radius' section in the PR body.")
    ap.add_argument("--event", help="GitHub event JSON ($GITHUB_EVENT_PATH)")
    ap.add_argument("--body-file", help="a PR body in a file, for local runs")
    ap.add_argument("--author", default="", help="PR author login, for local runs")
    args = ap.parse_args(argv)
    login, user_type = args.author, ""
    if args.event:
        body, login, user_type = from_event(args.event)
        if body is None:
            print("blast_radius_check: not a pull_request event", file=sys.stderr)
            return 2
    elif args.body_file:
        with open(args.body_file, encoding="utf-8") as fh:
            body = fh.read()
    else:
        ap.error("pass --event or --body-file")
    if is_bot(login, user_type):
        print(f"blast_radius_check: skipped, PR opened by bot {login}")
        return 0
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
