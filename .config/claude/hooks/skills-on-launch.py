#!/usr/bin/env python3
"""SessionStart: deliver the `skills:` an agent launched with --agent declares.

`skills:` fires when an agent is spawned and not when the same definition is
launched as the main thread, so a launch-only agent never receives what its own
frontmatter names (runtime-facts.md, "Skills: reach and cost"). This reads the
launched agent's definition and injects each body under the header the runtime
writes, which the model reads as already loaded rather than calling `Skill` for
it again.

Only fires on `startup`: a skill loaded twice is injected twice, and nothing
deduplicates it. Frontmatter is parsed here rather than through PyYAML so the
hook carries no dependency into a session's startup path.
"""

import sys
from pathlib import Path

from utils import inform, payload

CONFIG = Path(__file__).resolve().parent.parent


def split_frontmatter(text):
    """(frontmatter block, body). A file without a block is all body."""
    if not text.startswith("---\n"):
        return "", text
    block, sep, body = text[4:].partition("\n---\n")
    if not sep:
        return "", text
    return block, body.lstrip("\n")


def declared_skills(agent):
    """The names under an agent's `skills:` key, in order."""
    definition = CONFIG / "agents" / f"{agent}.md"
    if not definition.is_file():
        return []

    block, _ = split_frontmatter(definition.read_text(encoding="utf-8"))
    names, collecting = [], False
    for line in block.splitlines():
        if not line.strip():
            continue
        if collecting and line.lstrip().startswith("- "):
            names.append(line.lstrip()[2:].strip().strip("\"'"))
            continue
        # Any other unindented key ends the list.
        collecting = line.rstrip() == "skills:"
    return names


def body_of(name):
    """A skill's text under the header the runtime writes, or None if absent."""
    skill = CONFIG / "skills" / name / "SKILL.md"
    if not skill.is_file():
        return None
    _, body = split_frontmatter(skill.read_text(encoding="utf-8"))
    return f"Base directory for this skill: {skill.parent}\n\n{body}"


def main():
    data = payload()

    # Absent on a default launch, which declares no agent to read.
    agent = data.get("agent_type")
    if not agent or data.get("source") != "startup":
        sys.exit(0)

    bodies = [b for b in map(body_of, declared_skills(agent)) if b]
    if bodies:
        inform("\n\n".join(bodies), data)
    sys.exit(0)


main()
