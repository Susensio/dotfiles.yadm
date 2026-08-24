#!/usr/bin/env python3
"""PreToolUse/Bash: propose the richer CLI. Never blocks.

This is a preference, not a prohibition, and a deny would be wrong
wherever the POSIX tool is the right one -- grep inside a pipeline, find with
-exec. Exiting without a decision lets the call through the normal permission
flow while the reminder still reaches the model.
"""

import os
import shutil
from collections import namedtuple
from pathlib import Path

from utils import any_command, bash_command, inform, payload

GREP = "Prefer `rg` over `grep -r` where installed (rg is on PATH). Not enforced -- grep stays correct inside a pipeline."
FIND = "Prefer `fd` over `find -name` where installed (fd is on PATH). Not enforced -- find stays correct for -exec and complex predicates."

Proposal = namedtuple("Proposal", "clause binary reminder")


def recursive_grep(tokens):
    """A recursive grep, however the flag is written.

    Matching the flag by hand rather than by glob: `-*r*` also catches --color
    and --perl-regexp, and misses -R because fnmatch is case-sensitive.

    >>> [t for t in ["-r", "-rn", "-nR", "--recursive"] if _recursive_flag(t)]
    ['-r', '-rn', '-nR', '--recursive']
    >>> [t for t in ["--color=always", "--perl-regexp", "-i"] if _recursive_flag(t)]
    []
    """
    return tokens[0] == "grep" and any(map(_recursive_flag, tokens[1:]))


def _recursive_flag(token):
    if token.startswith("--"):
        return token in ("--recursive", "--dereference-recursive")
    return token.startswith("-") and ("r" in token or "R" in token)


def named_find(tokens):
    return tokens[0] == "find" and "-name" in tokens


PROPOSALS = [
    Proposal(recursive_grep, "rg", GREP),
    Proposal(named_find, "fd", FIND),
]

NUDGES = Path(os.environ.get("TMPDIR", "/tmp")) / "claude-hook-nudge"


def proposal(command):
    """The proposal this command earns, or None.

    >>> proposal("grep -rn pattern /abs").reminder is GREP
    True
    >>> proposal("find /abs -name '*.md'").reminder is FIND
    True

    A plain grep is not a recursive one, and the preferred tool never
    proposes itself:

    >>> proposal("grep pattern file.txt") is None
    True
    >>> proposal("rg pattern /abs") is None
    True
    """
    return next((p for p in PROPOSALS if any_command(command, p.clause)), None)


def first_time(session, binary):
    """One reminder per session per tool, so a preference is not nagging."""
    stamp = NUDGES / f"{session}.{binary}"
    try:
        NUDGES.mkdir(parents=True, exist_ok=True)
        if stamp.exists():
            return False
        stamp.touch()
    except OSError:
        pass  # A hook that cannot write its stamp still nudges; it repeats.
    return True


def main():
    data = payload()
    command = bash_command(data)
    found = proposal(command) if command else None
    if found and shutil.which(found.binary):
        if first_time(data.get("session_id", "nosession"), found.binary):
            inform(found.reminder, data)


if __name__ == "__main__":
    main()
