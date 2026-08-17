#!/usr/bin/env python3
"""Create a new ADR skeleton in docs/adr/.

Usage:
  new.py "<title>"
  new.py "<title>" --supersedes 3
"""
import argparse
import datetime
import re
import sys
from pathlib import Path


def find_adr_dir() -> Path:
    # Walk up for an existing docs/adr so the script runs from any subdirectory.
    # Not git rev-parse: under yadm the worktree root is $HOME, not the config dir.
    cwd = Path.cwd()
    for base in (cwd, *cwd.parents):
        candidate = base / "docs" / "adr"
        if candidate.is_dir():
            return candidate
    return cwd / "docs" / "adr"


ADR_DIR = find_adr_dir()
STATUS_RE = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)


def slugify(title: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.strip().lower()).strip("-")
    return slug[:50].rstrip("-")


def existing_adrs() -> list[Path]:
    if not ADR_DIR.exists():
        return []
    return sorted(ADR_DIR.glob("[0-9][0-9][0-9][0-9]-*.md"))


def adr_number(path: Path) -> int:
    # existing_adrs() globs four leading digits, so the prefix is always parseable
    return int(path.name[:4])


def next_number() -> int:
    return max((adr_number(p) for p in existing_adrs()), default=0) + 1


def find_adr(number: int) -> Path:
    for p in existing_adrs():
        if adr_number(p) == number:
            return p
    sys.exit(f"error: no ADR numbered {number:04d} found in {ADR_DIR}")


def flip_to_superseded(old_path: Path, new_number: int, new_slug: str) -> None:
    text = old_path.read_text()
    if not STATUS_RE.search(text):
        sys.exit(f"error: {old_path} has no Status line to flip")
    new_status = f"Status: Superseded by [ADR-{new_number:04d}]({new_number:04d}-{new_slug}.md)"
    old_path.write_text(STATUS_RE.sub(new_status, text, count=1))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("title")
    parser.add_argument("--supersedes", type=int, metavar="N", help="ADR number this decision replaces")
    args = parser.parse_args()

    ADR_DIR.mkdir(parents=True, exist_ok=True)
    number = next_number()
    slug = slugify(args.title)
    if not slug:
        sys.exit("error: title produced an empty slug")
    path = ADR_DIR / f"{number:04d}-{slug}.md"

    supersedes_line = ""
    if args.supersedes is not None:
        old_path = find_adr(args.supersedes)
        supersedes_line = f"Supersedes: [ADR-{args.supersedes:04d}]({old_path.name})\n"
        flip_to_superseded(old_path, number, slug)

    path.write_text(
        f"# ADR-{number:04d}: {args.title}\n\n"
        f"Status: Accepted\n"
        f"Date: {datetime.date.today().isoformat()}\n"
        f"{supersedes_line}"
        f"\n## Context\n\n\n## Decision\n\n\n## Consequences\n\n"
    )
    print(path)


if __name__ == "__main__":
    main()
