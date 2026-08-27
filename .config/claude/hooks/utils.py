"""Shared plumbing for the hooks in this directory.

Python puts a script's own directory on sys.path, so a hook invoked by absolute
path imports this with a plain `from utils import ...` and no path juggling.

A hook either stops the agent or informs it, never both, so it calls `block` or
`inform` and never both. That is the whole output convention, and it keeps each
hook on one mechanism -- which is what the docs ask for ("choose one approach
per hook: either use exit codes alone for signaling, or exit 0 and print JSON").

Run the tests: uv run --with python-frontmatter --with pyyaml python3 -m doctest *.py
"""

import json
import os
import shlex
import sys
from pathlib import Path

# Claude Code's documented Bash separators, plus the subshell parens that shlex
# hands back as their own tokens. The newline is the end-of-segment sentinel
# `_segment_commands` appends, never a token shlex produces -- it splits lines
# first.
SEPARATORS = {"&&", "||", ";", "|", "|&", "&", "\n", "(", ")"}


def commands(line):
    r"""Every command in a command line, as a list of argument tokens.

    Tokenising the way a shell does means quoting, `(subshells)` and a missing
    space around `&&` all fall out of one pass, instead of each needing its own
    regex to see through.

    >>> list(commands("rg pattern /abs && ls"))
    [['rg', 'pattern', '/abs'], ['ls']]
    >>> list(commands("ls&&grep -r x /abs"))
    [['ls'], ['grep', '-r', 'x', '/abs']]

    A newline separates commands as surely as `&&` does, and it is how a model
    ordinarily writes a two-step call. shlex consumes it as whitespace, so the
    line is split into segments before tokenising -- without this, every
    command after the first joins its predecessor's tokens and is never seen:

    >>> list(commands("ls\ngrep -r x /abs"))
    [['ls'], ['grep', '-r', 'x', '/abs']]

    A quoted argument stays one token, so a command named inside a string is
    not mistaken for one being run:

    >>> list(commands('echo "grep -r x"'))
    [['echo', 'grep -r x']]

    What this deliberately does not do is see through a wrapper (`sudo`, `env`,
    `timeout`) or into a shell's `-c` argument. Those existed to stop a rule
    being evaded, and nothing here is a guard any more -- the hooks that use
    this only propose a better tool, and an agent writing `sudo sh -c '...'` is
    not one a nudge was ever going to reach.
    """
    for segment in line.splitlines():
        yield from _segment_commands(segment)


def _segment_commands(line):
    """Every command in one newline-free segment. See `commands`."""
    lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        tokens = line.split()  # Unbalanced quotes: a rough split beats nothing.

    current = []
    for token in tokens + ["\n"]:
        if token in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)


def any_command(line, predicate):
    """Does any command in this line satisfy the predicate?

    >>> any_command("ls && grep -r x /abs", lambda tokens: tokens[0] == "grep")
    True
    >>> any_command("ls -la", lambda tokens: tokens[0] == "grep")
    False
    """
    return any(predicate(tokens) for tokens in commands(line))


def payload():
    """This hook's stdin. A payload we cannot parse is never worth acting on."""
    try:
        return json.load(sys.stdin)
    except ValueError:
        sys.exit(0)


def bash_command(data):
    """The command of a Bash tool call, or None for any other tool."""
    if data.get("tool_name") != "Bash":
        return None
    return data.get("tool_input", {}).get("command") or None


def advice(text, event):
    """The payload shape that carries `text` to the model.

    additionalContext only reaches the model nested under hookSpecificOutput,
    which in turn requires hookEventName. A top-level additionalContext fails
    schema validation, and a non-blocking hook whose output fails validation is
    discarded in silence -- the hook still runs, the message never lands.

    >>> advice("re-read it", "PostToolUse")
    {'hookSpecificOutput': {'hookEventName': 'PostToolUse', 'additionalContext': 're-read it'}}
    """
    return {
        "hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": text,
        }
    }


def inform(text, data):
    """Tell the model something without stopping it.

    The only channel that does this: a non-zero exit that is not 2 reaches the
    transcript as a hook *error*, not as advice. additionalContext suits every
    event -- on PreToolUse it joins the tool call's context, on PostToolUse it
    follows the tool output, on SessionStart it opens the session. The event
    name comes from the payload so no caller has to restate the event it is
    already handling.
    """
    json.dump(advice(text, data.get("hook_event_name")), sys.stdout)
    sys.exit(0)


NUDGES = Path(os.environ.get("TMPDIR", "/tmp")) / "claude-hook-nudge"


def first_time(*key):
    """True the first time this key is seen, False after.

    A stamp file per key under TMPDIR; the caller's key is what scopes it
    (to a session, an agent, whatever it's built from). A hook that cannot
    write its stamp still speaks; it repeats.
    """
    stamp = NUDGES / ".".join(key)
    try:
        NUDGES.mkdir(parents=True, exist_ok=True)
        if stamp.exists():
            return False
        stamp.touch()
    except OSError:
        pass
    return True


def agent_key(data):
    """The dedup identity: the main thread and each subagent get their own.

    `session_id` and `transcript_path` are both shared with the parent, so
    keying dedup on either lets the first agent to run consume the stamp for
    every other agent. `agent_id` is what actually varies (see
    `harness-design/references/runtime-facts.md`, "What reaches a subagent").
    """
    return data.get("agent_id") or data.get("session_id", "nosession")


# Any of these means a project starts here. A file in no project at all is
# rooted at its own directory.
ROOT_MARKERS = (".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod")


def project_root(path):
    """Where this file's project starts, or its own directory if it is in none."""
    return next(
        (d for d in path.parents if any((d / m).exists() for m in ROOT_MARKERS)),
        path.parent,
    )
