#!/usr/bin/env python3
"""Create and list ADRs in docs/adr/.

Usage:
  adr.py list
  adr.py new "<title>"
  adr.py new "<title>" --supersedes 3
"""

import argparse
import datetime
import re
import sys
from pathlib import Path


def find_adr_dir(init: bool, override: str | None = None) -> Path:
    if override is not None:
        path = Path(override).expanduser().resolve()
        if not path.is_dir() and not init:
            sys.exit(f"error: {path} does not exist. Pass --init to create it.")
        return path

    # Walk up for an existing docs/adr so the script runs from any subdirectory.
    # Deliberately not a VCS root: a worktree root is not always the directory
    # the project's docs live under, and guessing wrong writes them somewhere
    # nobody will look.
    cwd = Path.cwd()
    for base in (cwd, *cwd.parents):
        candidate = base / "docs" / "adr"
        if candidate.is_dir():
            return candidate
    if init:
        return cwd / "docs" / "adr"
    searched = " -> ".join(str(b) for b in (cwd, *cwd.parents))
    sys.exit(
        f"error: no docs/adr found. Looked in: {searched}\n"
        f"       Run from inside the project that owns the records, or pass "
        f"--init to start a new set at {cwd / 'docs' / 'adr'}."
    )


STATUS_RE = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)
TITLE_RE = re.compile(r"^# ADR-\d+:\s*(.+)$", re.MULTILINE)
SUPERSEDED_BY_RE = re.compile(r"Superseded by \[ADR-(\d+)\]")
REF_RE = re.compile(r"ADR-(\d{4})")
ADR_DIR: Path  # resolved in main() once --init is known


def slugify(text: str, max_len: int = 50) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.strip().lower()).strip("-")
    if len(slug) <= max_len:
        return slug
    # cut at the last word boundary within max_len, not mid-word
    truncated = slug[:max_len]
    boundary = truncated.rfind("-")
    return (truncated[:boundary] if boundary > 0 else truncated).rstrip("-")


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
    new_status = (
        f"Status: Superseded by [ADR-{new_number:04d}]({new_number:04d}-{new_slug}.md)"
    )
    old_path.write_text(STATUS_RE.sub(new_status, text, count=1))


def back_references() -> dict[int, list[int]]:
    """Map each ADR to the later ADRs that name it without superseding it.

    Derived at read time, never written into the older record: a pointer kept by
    hand is one more thing to forget, and the forward reference already sits in
    the prose of whichever ADR did the touching. Only a later ADR naming an
    earlier one is news -- it may have narrowed or reversed part of it, which the
    older record has no other way to advertise.
    """
    refs: dict[int, set[int]] = {}
    statuses: dict[int, str] = {}
    for path in existing_adrs():
        text = path.read_text()
        number = adr_number(path)
        status_match = STATUS_RE.search(text)
        statuses[number] = status_match.group(1) if status_match else ""
        for found in REF_RE.findall(text):
            target = int(found)
            # A record names itself in its own heading, and an earlier record
            # cannot have known about a later one.
            if target >= number:
                continue
            refs.setdefault(target, set()).add(number)
    for target, sources in refs.items():
        # Total replacement already shows as "-> N" on the target's own row.
        superseder = SUPERSEDED_BY_RE.search(statuses.get(target, ""))
        if superseder:
            sources.discard(int(superseder.group(1)))
    return {t: sorted(s) for t, s in refs.items() if s}


def cmd_list() -> None:
    backrefs = back_references()
    rows = []
    for path in existing_adrs():
        text = path.read_text()
        status_match = STATUS_RE.search(text)
        status = status_match.group(1).strip() if status_match else "no Status line"
        # Superseded records carry a whole markdown link; the number is the part
        # worth seeing in a list, and it doubles as the pointer to what replaced it.
        superseded = SUPERSEDED_BY_RE.search(status)
        if superseded:
            status = f"-> {int(superseded.group(1)):04d}"
        title_match = TITLE_RE.search(text)
        # Fall back to the filename so a record with a malformed heading still lists.
        title = title_match.group(1).strip() if title_match else f"({path.name})"
        number = adr_number(path)
        touched = backrefs.get(number, [])
        back = "<- " + ",".join(f"{n:04d}" for n in touched) if touched else ""
        rows.append((number, status, back, title))

    if not rows:
        print(f"no ADRs in {ADR_DIR}")
        return
    width = max(len(status) for _, status, _, _ in rows)
    back_width = max(len(back) for _, _, back, _ in rows)
    for number, status, back, title in sorted(rows):
        # The column vanishes when nothing references anything, so a fresh set of
        # records does not list a blank gutter.
        gutter = f"{back:<{back_width}}  " if back_width else ""
        print(f"{number:04d}  {status:<{width}}  {gutter}{title}")


def cmd_new(args: argparse.Namespace) -> None:
    ADR_DIR.mkdir(parents=True, exist_ok=True)
    number = next_number()
    slug = slugify(args.slug) if args.slug else slugify(args.title)
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser(
        "list",
        help="print every ADR as number, status, the later ADRs naming it, and title",
    )
    p_list.add_argument(
        "--dir",
        metavar="PATH",
        help="the ADR directory, instead of searching upward for one",
    )

    p_new = sub.add_parser("new", help="create a new ADR skeleton")
    p_new.add_argument("title")
    p_new.add_argument(
        "--slug",
        metavar="SLUG",
        help="short (3-6 word) filename slug; defaults to a truncated version of the title",
    )
    p_new.add_argument(
        "--supersedes", type=int, metavar="N", help="ADR number this decision replaces"
    )
    p_new.add_argument(
        "--dir",
        metavar="PATH",
        help="the ADR directory, instead of searching upward for one",
    )
    p_new.add_argument(
        "--init",
        action="store_true",
        help="create the ADR directory; without it, a missing one is an error",
    )

    args = parser.parse_args()

    global ADR_DIR
    ADR_DIR = find_adr_dir(getattr(args, "init", False), args.dir)
    if args.command == "list":
        cmd_list()
    else:
        cmd_new(args)


if __name__ == "__main__":
    main()
