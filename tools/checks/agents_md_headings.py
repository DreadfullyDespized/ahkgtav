#!/usr/bin/env python3
"""Fail if AGENTS.md is missing or missing any Required H2 heading."""
from __future__ import annotations

import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AGENTS = "AGENTS.md"
REQUIRED = (
    "What this repo is for",
    "What is allowed in this repo",
    "What is NOT allowed",
    "Prove a change",
    "Pointers",
)
H2_RX = re.compile(r"^##[ \t]+(.+?)[ \t]*#*[ \t]*$", re.M)


def headings(text):
    return [m.group(1).strip() for m in H2_RX.finditer(text or "")]


def check(text, path=AGENTS):
    if text is None:
        return [f"{path}: missing"]
    found = set(headings(text))
    return [f"{path}: missing required H2 {h!r}" for h in REQUIRED if h not in found]


def check_file(root=ROOT, rel=AGENTS):
    path = os.path.join(root, rel)
    if not os.path.isfile(path):
        return check(None, rel)
    return check(open(path, encoding="utf-8").read(), rel)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("path", nargs="?", default=None,
                    help="AGENTS.md to check (default: repo-root AGENTS.md)")
    a = ap.parse_args(argv)
    if a.path:
        if not os.path.isfile(a.path):
            errs = check(None, a.path)
        else:
            errs = check(open(a.path, encoding="utf-8").read(), a.path)
    else:
        errs = check_file()
    for e in errs:
        print(e)
    if errs:
        print(f"agents_md_headings: {len(errs)} problem(s).", file=sys.stderr)
        return 1
    print("agents_md_headings: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
