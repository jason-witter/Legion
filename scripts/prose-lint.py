#!/usr/bin/env python3
"""Scan a branch's own comments and docstrings for register tells and volume smells.

Reports only lines the branch added, measured against its merge base, so pre-existing prose in files
the branch merely touches is out of scope. Prints file:line for every hit, so a pass can be driven
to a known residual instead of spot-checked.

    python3 scripts/prose-lint.py <repo-path> [base-ref]

Checks map to protocols/asimov-catalog.md and rules/code-comment-register.md:

    DASH        em/en dash                                    catalog 1.1
    XNOTY       decorative "X, not Y" contrast                 catalog 1.4
    COLONGLOSS  colon or semicolon gloss mid-sentence          catalog 1.11
    THROAT      throat-clearing opener                         catalog 1.6
    EMPHASIS    emphasis crutch                                catalog 1.7
    INFLATION   significance inflation                         catalog 1.14
    ARMLEG      arm/leg for a system or code path              catalog 3.6
    LOADBEARING load-bearing                                   catalog 3.7
    STAMP       stamp as a verb                                catalog 3.5
    HOUSENOUN   undefined house noun ("the gate", "the freeze")
    PRIVATEREF  bare private symbol referenced in passing
    REUSES      explaining why a value is shared not dedicated
    LONGDOC     docstring over 8 lines
    RESTATES    docstring first line restates the symbol name

HOUSENOUN and PRIVATEREF exist because a short comment can still be opaque: it names something to
whoever wrote it and sends the reader to another file. Observed 2026-09-04 on a comment reading
"Reuses SETTLEMENT_ABSENT; without this check _build_deferral's assert fires past the gate", which
cost three lookups on a line whose code already read plainly.

Every check is a prompt to look, not a verdict. Some hits are correct as written.
"""

import ast
import io
import re
import subprocess
import sys
import tokenize
from pathlib import Path

LINE_CHECKS = [
    ("DASH", re.compile(r"[\u2013\u2014]")),
    ("XNOTY", re.compile(r",\s+not\s+\w|\bnot\s+\w[\w\s]{0,30},\s+but\b")),
    ("COLONGLOSS", re.compile(r"\w:\s+[a-z]|\w;\s+[a-z]")),
    ("THROAT", re.compile(r"\b(Note that|It is worth noting|Importantly|Crucially|Of course)\b", re.I)),
    ("EMPHASIS", re.compile(r"\b(simply|merely|actually|precisely|exactly what|the whole)\b", re.I)),
    ("INFLATION", re.compile(r"\b(what makes this|the key to|critically|the whole point|is what matters)\b", re.I)),
    ("ARMLEG", re.compile(r"(^|[^a-z])(in.?arm|out.of.arm|arms?|legs?)([^a-z]|$)", re.I)),
    ("LOADBEARING", re.compile(r"load.bearing", re.I)),
    ("STAMP", re.compile(r"\bstamp(s|ed|ing)?\b", re.I)),
    (
        "HOUSENOUN",
        re.compile(
            r"\bthe (gate|freeze|read-back|readback|spine|balance identity|identity|tally|arm|leg)\b",
            re.I,
        ),
    ),
    # An explicit "see _x" pointer is fine: it sends the reader somewhere rather than assuming they
    # are already there.
    ("PRIVATEREF", re.compile(r"(?<!see )(?<!See )(^|[^\w.])_[a-z][a-z0-9_]{3,}\b")),
    ("REUSES", re.compile(r"\b(reuses|borrows|shares) [A-Z_]{4,}\b")),
]

# Tool directives and shell invocations are not prose; they carry colons and underscores by design.
PRAGMA = re.compile(r"(pyrefly|mypy|pylint|ruff|noqa|type|fmt|isort|coverage):|^\s*#?\s*(\./|https?://)")

MAX_DOC_LINES = 8
STOPWORDS = {"the", "a", "an", "of", "for", "to", "and", "is", "in", "on", "by", "its", "this", "one"}


def git(repo, *args):
    return subprocess.run(
        ["git", *args], cwd=repo, capture_output=True, text=True, check=True
    ).stdout


def added_lines(repo, base, rel):
    added = set()
    for line in git(repo, "diff", base, "-U0", "--", rel).split("\n"):
        m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
        if m:
            start, count = int(m.group(1)), int(m.group(2) or 1)
            added.update(range(start, start + count))
    return added


def prose_spans(src):
    spans = []
    try:
        for tok in tokenize.generate_tokens(io.StringIO(src).readline):
            if tok.type == tokenize.COMMENT:
                spans.append((tok.start[0], tok.string))
    except (tokenize.TokenError, IndentationError):
        pass

    try:
        tree = ast.parse(src)
    except SyntaxError:
        return spans, []

    docs = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            continue
        if not node.body:
            continue
        first = node.body[0]
        if not (
            isinstance(first, ast.Expr)
            and isinstance(first.value, ast.Constant)
            and isinstance(first.value.value, str)
        ):
            continue
        text = first.value.value
        for offset, line in enumerate(text.splitlines()):
            spans.append((first.lineno + offset, line))
        docs.append((getattr(node, "name", "<module>"), first.lineno, text))
    return spans, docs


def restates_name(name, text):
    if name == "<module>":
        return False
    words = {w for w in re.split(r"_+", name.lower()) if w and w not in STOPWORDS}
    words.discard("test")
    if len(words) < 2:
        return False
    stripped = text.strip()
    if not stripped:
        return False
    doc_words = {w for w in re.findall(r"[a-z]+", stripped.splitlines()[0].lower()) if w not in STOPWORDS}
    if not doc_words:
        return False
    return len(words & doc_words) / len(words) >= 0.7


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    repo = Path(sys.argv[1]).resolve()
    upstream = sys.argv[2] if len(sys.argv) > 2 else "origin/main"

    # The merge base, not the upstream tip: upstream has usually moved since the branch last merged
    # it, and diffing against the tip makes upstream's own commits look like the branch's changes.
    base = git(repo, "merge-base", upstream, "HEAD").strip()

    total, by_kind = 0, {}
    for rel in [f for f in git(repo, "diff", base, "--name-only").split("\n") if f.endswith(".py")]:
        path = repo / rel
        if not path.exists():
            continue
        src = path.read_text()
        mine = added_lines(repo, base, rel)
        spans, docs = prose_spans(src)

        hits = []
        for lineno, text in spans:
            if lineno not in mine or PRAGMA.search(text):
                continue
            for kind, pattern in LINE_CHECKS:
                if pattern.search(text):
                    hits.append((lineno, kind, text.strip()[:96]))

        for name, start, text in docs:
            if start not in mine:
                continue
            n = len(text.splitlines())
            if n > MAX_DOC_LINES:
                hits.append((start, "LONGDOC", f"{name} ({n} lines)"))
            if restates_name(name, text):
                hits.append((start, "RESTATES", f"{name}: {text.strip().splitlines()[0][:70]}"))

        if hits:
            print(f"\n{rel}")
            for lineno, kind, text in sorted(hits):
                print(f"  {lineno:>5} {kind:<12} {text}")
                by_kind[kind] = by_kind.get(kind, 0) + 1
                total += 1

    print("\n" + "=" * 100)
    if not total:
        print(f"No hits on lines added since {base[:12]}.")
        return 0
    for kind, n in sorted(by_kind.items(), key=lambda kv: -kv[1]):
        print(f"  {n:>4}  {kind}")
    print(f"  {total:>4}  TOTAL")
    return 0


if __name__ == "__main__":
    sys.exit(main())
