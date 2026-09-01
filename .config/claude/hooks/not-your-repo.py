#!/usr/bin/env python3
"""PreToolUse/Write|Edit: nudge before writing a record file you do not own.

`project-docs` says a finding travels in the report where the repository is
not the user's, and that `docs/ROADMAP.md` is the user's to write. Both are
decidable from the remote and the path, and prose alone is the weakest place
to hold a decidable rule (R-enforcement) -- an agent that skipped the skill
never sees it.

A nudge, not a block: creating a stray file is reversible, and a block would
eventually refuse a README fix someone was asked to make.

The two arms differ on whether the file already exists. Creating a record file
in someone else's repo is the whole harm, so that arm skips anything on disk.
The roadmap arm cannot: overflow means a project that has a roadmap has one on
disk already, so checking only creation would never fire in a real project.

Same once-per-agent-per-reason dedup as the other hooks here.
"""

import subprocess
from pathlib import Path

from utils import agent_key, first_time, inform, payload, project_root

# Record files this user's conventions would create (grow-project-docs).
# Matched against the repo-relative path, so a `docs/` tree nested inside a
# vendored dependency does not count.
RECORD_FILES = (
    "**/README.md",
    "**/CLAUDE.md",
    "**/AGENTS.md",
    "docs/**",
    ".scratch/**",
)

# Record files that stay the user's to write even in the user's own repo.
# Root-level too: other people's repos commonly put ROADMAP.md there.
THEIRS_ALONE = ("docs/ROADMAP.md", "ROADMAP.md")

# Compared lower-cased: the forge preserves the case you signed up with, so
# `Susensio` and `susensio` are one account and a literal match misses one.
OWNERS = ("susensio",)


def remotes(cwd):
    """`git remote -v` as {name: url}, or {} where this is not a repo."""
    try:
        out = subprocess.run(
            ["git", "remote", "-v"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=5,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return {}
    return {
        parts[0]: parts[1]
        for line in out.splitlines()
        if len(parts := line.split()) >= 2
    }


def theirs(cwd):
    """Is this repository someone else's?

    An `upstream` remote means yes even where `origin` is the user's fork --
    that is the case a bare owner check reads backwards. No remote at all
    means a new local project, which is the user's.
    """
    found = remotes(cwd)
    if not found:
        return False
    if "upstream" in found:
        return True
    origin = found.get("origin")
    if not origin:
        return False
    owner = owner_of(origin)
    # No owner is a local path, not a stranger: absence must not read as theirs.
    return owner is not None and owner.lower() not in OWNERS


def owner_of(url):
    """The owner segment of a git remote URL, or None if it has none.

    >>> owner_of("git@github.com:susensio/dotfiles.yadm.git")
    'susensio'
    >>> owner_of("https://gitlab.com/group/sub/proj")
    'group'

    A local path has no owner and yields None, so a bare repo on disk reads as
    the user's rather than as a stranger named after its first directory.

    >>> owner_of("/srv/local/bare.git") is None
    True
    >>> owner_of("../sibling/proj.git") is None
    True
    """
    if url.startswith(("/", ".", "~")):
        return None
    tail = url.split(":", 1)[-1] if url.startswith("git@") else url
    for prefix in ("https://", "http://", "ssh://", "git://"):
        if tail.startswith(prefix):
            tail = tail[len(prefix) :].split("/", 1)[-1]
            break
    parts = [p for p in tail.strip("/").split("/") if p]
    return parts[0] if len(parts) >= 2 else None


def matches(rel, patterns):
    """Does this repo-relative path match any pattern?

    >>> matches("docs/BACKLOG.md", ["docs/**/*.md"])
    True
    >>> matches("src/docs/x.md", ["docs/**/*.md"])
    False
    """
    path = Path(rel)
    return any(path.full_match(p, case_sensitive=True) for p in patterns)


def main():
    data = payload()
    path = data.get("tool_input", {}).get("file_path")
    if not path:
        return
    target = Path(path).resolve()
    root = project_root(target)
    rel = str(target.relative_to(root))
    agent = agent_key(data)

    if matches(rel, THEIRS_ALONE) and not theirs(root):
        if first_time(agent, "notyours", "roadmap"):
            inform(
                f"`{rel}` is the user's to write. Read it, and do not create or "
                "edit it unasked -- what is open and unclaimed goes in the "
                "backlog instead. See the `project-docs` skill.",
                data,
            )
        return

    if target.exists():
        return  # Editing what is already there is not creating a convention.

    if matches(rel, RECORD_FILES) and theirs(root):
        if first_time(agent, "notyours", "repo"):
            inform(
                f"`{rel}` would be a new record file in a repository that is not "
                "yours -- it has an `upstream` remote, or an `origin` you do not "
                "own. Their conventions are not yours to set: what you found "
                "travels in your report instead, and anything that would post in "
                "public is the user's to send. See the `project-docs` skill.",
                data,
            )


if __name__ == "__main__":
    main()
