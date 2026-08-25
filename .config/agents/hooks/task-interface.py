#!/usr/bin/env python3
"""SessionStart: name the project's task recipes.

A justfile or Makefile is documentation about how a project is run, and it
gets ignored because nothing makes the agent look at it -- it reaches for
`.venv/bin/python` instead. Listing the recipe names once costs less than one
wrong invocation and the correction after it.

`just` walks up to find its own justfile, so it needs no search here. `make`
does not, so the Makefile is looked for in the git root and then the working
directory, and read rather than run -- `make -qp` would expand `$(shell ...)`
at parse time, which is a side effect a session start has no business having.

Silent where a project has neither, which is most of them.
"""

import re
import subprocess
from pathlib import Path

from utils import inform, payload

TARGET = re.compile(r"^([a-zA-Z0-9][a-zA-Z0-9_.-]*)\s*:(?!=)", re.MULTILINE)


def run(args, cwd):
    """stdout of a command that succeeded, or None. Never raises, never hangs."""
    try:
        done = subprocess.run(
            args, cwd=cwd, capture_output=True, text=True, timeout=3, check=False
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return done.stdout.strip() if done.returncode == 0 else None


def just_recipes(cwd):
    """Recipe names from whatever justfile `just` finds walking up, or None."""
    return run(["just", "--summary"], cwd)


def make_targets(cwd):
    """Target names from a Makefile in the git root or `cwd`, or None.

    >>> TARGET.findall("build:\\n\\t@echo hi\\nclean: build\\n\\trm -rf x\\n")
    ['build', 'clean']

    A variable assignment is not a target, and neither is a path:

    >>> TARGET.findall("CFLAGS := -O2\\nsrc/main.o: src/main.c\\n")
    []
    """
    root = run(["git", "rev-parse", "--show-toplevel"], cwd)
    for directory in filter(None, (root, cwd)):
        for name in ("Makefile", "makefile", "GNUmakefile"):
            path = Path(directory) / name
            try:
                targets = TARGET.findall(path.read_text(errors="replace"))
            except OSError:
                continue
            if targets:
                return " ".join(dict.fromkeys(targets))
    return None


def main():
    data = payload()
    cwd = data.get("cwd") or "."
    for runner, recipes in (("just", just_recipes(cwd)), ("make", make_targets(cwd))):
        if recipes:
            inform(
                f"This project's task interface is `{runner}`: {recipes}.\n"
                f"Run project commands through it -- `{runner} <recipe>` -- and reach "
                "for the underlying tool only where no recipe covers what you need.",
                data,
            )


if __name__ == "__main__":
    main()
