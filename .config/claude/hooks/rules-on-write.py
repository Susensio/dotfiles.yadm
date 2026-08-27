#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["python-frontmatter", "pyyaml"]
# ///
"""PreToolUse/Write: back-fill a rule Write bypassed.

Native rule delivery fires on Read only (tracked upstream,
anthropics/claude-code#88565), so a file authored fresh through Write never
sees the rule governing how it should be written. `PreToolUse` fires after
the model has already produced `content`, so this lands the rule one file
late -- in time for the next matching Write, not the one that triggered it --
with the same once-per-agent-per-rule dedup the Read path has.
"""

from pathlib import Path

import yaml

from utils import agent_key, first_time, inform, payload, project_root

RULES_DIRS = (
    # cwd, not project_root(): a session is scoped to one project the same
    # way native rule loading is, so project-local discovery follows the
    # session's own directory. Narrower wins over the global dir below.
    Path(".claude/rules"),
    Path.home() / ".claude" / "rules",
)


def parse(text):
    """A rule file's (paths, body), or None if it carries no usable `paths:`.

    A single path can be written as a bare string instead of a one-item list;
    both spellings are normalised to a list here so `matches` always iterates
    patterns, never characters. Anything that isn't a list of strings after
    that -- an int, a nested list, frontmatter that wasn't a mapping at all --
    is treated as absent rather than raising downstream.

    >>> parse("---\\npaths:\\n  - '*.py'\\n---\\nBe terse.\\n")
    (['*.py'], 'Be terse.')
    >>> parse("---\\npaths: '*.py'\\n---\\nBe terse.\\n")
    (['*.py'], 'Be terse.')
    >>> parse("# unscoped, no frontmatter") is None
    True
    >>> parse("---\\npaths: 123\\n---\\nBe terse.\\n") is None
    True
    """
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    try:
        metadata = yaml.safe_load(parts[1])
    except yaml.YAMLError:
        return None
    if not isinstance(metadata, dict):
        return None
    paths = metadata.get("paths")
    if isinstance(paths, str):
        paths = [paths]
    if not isinstance(paths, list):
        return None
    paths = [p for p in paths if isinstance(p, str)]
    content = parts[2].strip()
    if not paths or not content:
        return None
    return paths, content


def rules():
    """Every rule file carrying `paths:`, as (name, patterns, body).

    A name seen in the first dir wins, so a project-local rule shadows a
    same-named global one rather than the other way round. A rule file that
    fails to read or parse is skipped rather than taking every future `Write`
    down with it.
    """
    seen = set()
    for d in RULES_DIRS:
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.md")):
            if f.name in seen:
                continue
            seen.add(f.name)
            try:
                parsed = parse(f.read_text(encoding="utf-8"))
            except (yaml.YAMLError, OSError, UnicodeDecodeError):
                continue
            if parsed:
                paths, body = parsed
                yield f.name, paths, body


def matches(rel_path, patterns):
    """Does `rel_path` satisfy any of `patterns`?

    `PurePath.full_match` implements real glob semantics -- `**` matches zero
    or more whole path segments, `*` never crosses `/` -- unlike `fnmatch`,
    whose `*` crosses `/` freely and has no concept of `**` at all. Needs
    3.13+; the hook resolves to 3.14.7 through `uv run --script`.

    >>> matches("pyproject.toml", ["**/pyproject.toml"])
    True
    >>> matches("skills/SKILL.md", ["**/skills/**/*.md"])
    True
    >>> matches("agents/hooks/notes.md", ["**/agents/*.md"])
    False
    """
    path = Path(rel_path)
    return any(path.full_match(p, case_sensitive=True) for p in patterns)


def main():
    data = payload()
    path = data.get("tool_input", {}).get("file_path")
    if not path:
        return
    target = Path(path).resolve()
    rel = str(target.relative_to(project_root(target)))
    agent = agent_key(data)
    bodies = []
    for name, patterns, body in rules():
        if matches(rel, patterns) and first_time(agent, "rule", name):
            bodies.append(body)  # first_time stamps as a side effect of matching
    if bodies:
        inform("\n\n".join(bodies), data)


if __name__ == "__main__":
    main()
