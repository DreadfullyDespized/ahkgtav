#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys

EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+")
EMAIL_ALLOW = re.compile(r"(users\.noreply\.github\.com|noreply@github\.com|example\.(com|org|net))$", re.I)
PHONE = re.compile(r"\(\d{3}\)\s?\d{3}[-. ]\d{4}|\b\d{3}[-. ]\d{3}[-. ]\d{4}\b")
IPV4 = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
PROFILE = re.compile(r"[A-Za-z]:[\\/]Users[\\/](?!username\b)[^\s\\/]+" + "|/home" + r"/[^\s/]+/" + "|/Users" + r"/[^\s/]+/")


def ip_is_pii(token):
    parts = token.split(".")
    try:
        octets = [int(p) for p in parts]
    except ValueError:
        return False
    if len(octets) != 4 or any(o > 255 for o in octets):
        return False
    a, b = octets[0], octets[1]
    if a == 100 and 64 <= b <= 127:
        return True
    if a == 10 or (a == 172 and 16 <= b <= 31) or (a == 192 and b == 168):
        return True
    return False


def load_terms():
    raw = os.environ.get("PII_TERMS", "")
    terms = []
    for line in raw.splitlines():
        term = line.strip()
        if len(term) >= 3:
            terms.append(term.lower())
    return terms


def scan(text, surface, terms):
    terms = [t for t in terms if len(t) >= 3]
    hits = []
    for lineno, line in enumerate(text.splitlines(), 1):
        for m in EMAIL.finditer(line):
            if not EMAIL_ALLOW.search(m.group(0)):
                hits.append((surface, "email", lineno))
        if PHONE.search(line):
            hits.append((surface, "phone", lineno))
        for m in IPV4.finditer(line):
            if ip_is_pii(m.group(0)):
                hits.append((surface, "ipv4", lineno))
        if PROFILE.search(line):
            hits.append((surface, "profile-path", lineno))
        lowered = line.lower()
        for term in terms:
            if term in lowered:
                hits.append((surface, "private-term", lineno))
                break
    return hits


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def added_lines(base, head):
    diff = git("diff", "--unified=0", f"{base}...{head}")
    path = ""
    for raw in diff.splitlines():
        if raw.startswith("+++ b/"):
            path = raw[6:]
        elif raw.startswith("+") and not raw.startswith("+++"):
            yield path, raw[1:]


def from_event(path):
    with open(path, encoding="utf-8") as fh:
        event = json.load(fh)
    pr = event.get("pull_request") or {}
    terms = load_terms()
    hits = scan(pr.get("body") or "", "pr-body", terms)
    base = (pr.get("base") or {}).get("sha", "")
    head = (pr.get("head") or {}).get("sha", "")
    if base and head:
        by_file = {}
        for fpath, line in added_lines(base, head):
            if fpath == "tools/checks/tests/test_pii_check.py":
                continue
            by_file.setdefault(fpath, []).append(line)
        for fpath, lines in by_file.items():
            hits.extend(scan("\n".join(lines), f"diff {fpath}", terms))
        messages = git("log", "--format=%B%x00", f"{base}..{head}")
        for message in messages.split("\x00"):
            if message.strip():
                hits.extend(scan(message, "commit-message", terms))
    return hits


def main(argv=None):
    ap = argparse.ArgumentParser(description="Scan text for PII per the repo PII standard. Reports class and location only.")
    ap.add_argument("--event", help="GitHub pull_request event JSON ($GITHUB_EVENT_PATH)")
    ap.add_argument("--text-file", help="Scan a plain text file")
    ap.add_argument("--stdin", action="store_true", help="Scan text read from stdin")
    args = ap.parse_args(argv)
    terms = load_terms()
    if args.event:
        hits = from_event(args.event)
    elif args.text_file:
        with open(args.text_file, encoding="utf-8", errors="replace") as fh:
            hits = scan(fh.read(), "text", terms)
    elif args.stdin:
        hits = scan(sys.stdin.read(), "text", terms)
    else:
        ap.error("pass --event, --text-file, or --stdin")
    for surface, cls, lineno in hits:
        print(f"pii: {surface} {cls} line {lineno}")
    if hits:
        print(f"pii: {len(hits)} hit(s); remove the identifier(s) or ask Dread for an exception")
        return 1
    print("pii: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
