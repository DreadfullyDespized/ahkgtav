#!/usr/bin/env python3
"""Fail if cleartext password/secret literals are present in the tree.

Dread hard rule (2026-10-05): never commit passwords/secrets (cleartext or
documented in-repo). Use env vars or a secret store. This check scans the
working tree (not git history). Output is path + kind only — never the value.
"""
from __future__ import annotations

import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SKIP_DIRS = {
    ".git", ".hg", ".svn", ".venv", "venv", "node_modules", "__pycache__",
    ".mypy_cache", ".pytest_cache", ".tox", "dist", "build",
}
SKIP_DIR_PREFIXES = (
    "evidence-",
    "evidence_",
)
SKIP_EXT = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".bmp", ".svg",
    ".zip", ".7z", ".gz", ".bz2", ".xz", ".tar", ".rar",
    ".sqlite", ".db", ".bin", ".exe", ".dll", ".so", ".dylib",
    ".pyc", ".pyo", ".whl", ".egg",
    ".mp3", ".mp4", ".wav", ".ogg", ".webm", ".mov", ".avi",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".blend", ".blend1", ".fbx", ".glb", ".gltf",
    ".pdf", ".lock", ".log",
}
MAX_FILE_BYTES = 1_500_000

ALLOW_PREFIXES = (
    "tools/checks/fixtures/no_secrets/",
)

QUOTED = r"(?P<q>['\"])(?P<val>(?:(?!(?P=q)).){4,})(?P=q)"

KEY = (
    r"(?i)(?<![A-Za-z0-9_])"
    r"(?P<key>password|passwd|client[_-]?secret|api[_-]?key|apikey|"
    r"access[_-]?token|refresh[_-]?token|"
    r"secret|token)"
    r"(?![A-Za-z0-9_])"
)

RULES = (
    ("password_assign", re.compile(KEY + r"\s*[=:]\s*" + QUOTED)),
    ("pass_eq", re.compile(
        r"""(?i)(?<![A-Za-z0-9_])PASS\s*=\s*(?P<q>['"])(?P<val>(?:(?!(?P=q)).){4,})(?P=q)"""
    )),
    ("unzip_pass", re.compile(
        r"""(?i)unzip\s+-P\s+(?P<q>['"]?)(?P<val>(?![\$%{])[^\s'"]{4,})(?P=q)"""
    )),
    ("refs_password", re.compile(
        r"""(?i)Password\s*:\s*(?:standing[^\n`('"]{0,40})?(?P<q>[`'"])(?P<val>[^`'"]{4,})(?P=q)"""
    )),
    ("oauth_prefix", re.compile(r"(?i)(?P<val>oauth:[A-Za-z0-9]{20,})")),
    ("bearer_literal", re.compile(
        r"(?i)Bearer\s+(?P<val>(?![\$%{\\])[A-Za-z0-9._\-]{16,})"
    )),
    ("discord_webhook", re.compile(
        r"(?i)(?P<val>https://discord(?:app)?\.com/api/webhooks/\d+/[A-Za-z0-9_\-]+)"
    )),
)

PLACEHOLDER = re.compile(
    r"(?i)^(your_[a-z0-9_]+|<[^>]+>|\$\{[A-Za-z_][A-Za-z0-9_]*\})$"
)


def kind_for(rule_id, key):
    if rule_id == "password_assign" and key:
        return key.lower().replace("-", "_")
    return rule_id


def allowed_path(rel):
    rel = rel.replace("\\", "/")
    return any(rel == p.rstrip("/") or rel.startswith(p) for p in ALLOW_PREFIXES)


def skip_dir(name):
    if name in SKIP_DIRS or name.startswith("."):
        return True
    return any(name.startswith(p) for p in SKIP_DIR_PREFIXES)


def skip_value(val):
    if not val or len(val) < 4:
        return True
    if PLACEHOLDER.match(val):
        return True
    if val.lower() in {"true", "false", "none", "null", "undefined", "password", "secret", "token"}:
        return True
    return False


def findings_in_text(rel, text):
    out = []
    seen = set()
    for rule_id, rx in RULES:
        for m in rx.finditer(text):
            val = m.group("val")
            if skip_value(val):
                continue
            key = ""
            if "key" in m.groupdict() and m.group("key"):
                key = m.group("key")
            kind = kind_for(rule_id, key)
            line = text.count("\n", 0, m.start()) + 1
            hit = (rel, line, kind)
            if hit in seen:
                continue
            seen.add(hit)
            out.append({"path": rel, "line": line, "kind": kind})
    return out


def iter_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if not skip_dir(d))
        for fn in filenames:
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, root).replace("\\", "/")
            if allowed_path(rel):
                continue
            ext = os.path.splitext(fn)[1].lower()
            if ext in SKIP_EXT:
                continue
            try:
                if os.path.getsize(path) > MAX_FILE_BYTES:
                    continue
            except OSError:
                continue
            yield path, rel


def scan_tree(root=ROOT):
    findings = []
    for path, rel in iter_files(root):
        try:
            text = open(path, "r", encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        findings.extend(findings_in_text(rel, text))
    findings.sort(key=lambda f: (f["path"], f["line"], f["kind"]))
    return findings


def format_finding(f):
    return f"{f['path']}:{f['line']}: cleartext secret kind={f['kind']}"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--root", default=None, help="tree root (default: repo root)")
    ap.add_argument("path", nargs="?", default=None,
                    help="optional single file or directory to scan")
    a = ap.parse_args(argv)
    root = os.path.abspath(a.root or ROOT)
    if a.path:
        target = os.path.abspath(a.path)
        if os.path.isfile(target):
            rel = os.path.relpath(target, root).replace("\\", "/")
            try:
                text = open(target, "r", encoding="utf-8", errors="ignore").read()
            except OSError as e:
                print(f"{rel}: read error: {e}", file=sys.stderr)
                return 2
            findings = findings_in_text(rel, text)
        elif os.path.isdir(target):
            findings = scan_tree(target)
        else:
            print(f"no_secrets: path not found: {a.path}", file=sys.stderr)
            return 2
    else:
        findings = scan_tree(root)
    for f in findings:
        print(format_finding(f))
    if findings:
        print(f"no_secrets: {len(findings)} cleartext secret finding(s).", file=sys.stderr)
        return 1
    print("no_secrets: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
