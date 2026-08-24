"""Shared plumbing for the hooks in this directory.

Python puts a script's own directory on sys.path, so a hook invoked by absolute
path imports this with a plain `from utils import ...` and no path juggling.

A hook either stops the agent or informs it, never both, so it calls `block` or
`inform` and never both. That is the whole output convention, and it keeps each
hook on one mechanism -- which is what the docs ask for ("choose one approach
per hook: either use exit codes alone for signaling, or exit 0 and print JSON").

Run the tests: python3 -m doctest *.py
"""

import json
import shlex
import sys

# Claude Code's documented Bash separators, plus the subshell parens that shlex
# hands back as their own tokens.
SEPARATORS = {"&&", "||", ";", "|", "|&", "&", "\n", "(", ")"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish"}


def commands(line, _depth=0):
    """Every command in a command line, as a list of argument tokens.

    Tokenising the way a shell does means quoting, `(subshells)` and a missing
    space around `&&` all fall out of one pass, instead of each needing its own
    regex to see through.

    >>> list(commands("cd /foo && ls"))
    [['cd', '/foo'], ['ls']]
    >>> list(commands("ls&&cd /x"))
    [['ls'], ['cd', '/x']]

    A quoted argument stays one token, so this is not mistaken for a `cd`:

    >>> list(commands('echo "cd foo"'))
    [['echo', 'cd foo']]

    A shell's -c argument is a command too, and permissions.deny cannot see
    into it at all -- sh is not one of the wrappers Claude Code strips. Short
    flags cluster, so -lc hides a command just as -c does:

    >>> list(commands("sh -c 'git push'"))
    [['sh', '-c', 'git push'], ['git', 'push']]
    >>> list(commands("bash -lc 'cd /x'"))
    [['bash', '-lc', 'cd /x'], ['cd', '/x']]
    """
    lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        tokens = line.split()  # Unbalanced quotes: a rough split beats nothing.

    current = []
    for token in tokens + ["\n"]:
        if token not in SEPARATORS:
            current.append(token)
            continue
        if current:
            yield current
            # Follow a shell's -c argument, but nothing else: recursing into
            # every quoted token would read `echo "cd foo"` as a cd. Short flags
            # cluster, so the command flag is any of -c, -lc, -ec, -ic.
            if _depth < 2 and current[0] in SHELLS:
                flag = next(
                    (
                        i
                        for i, t in enumerate(current)
                        if t.startswith("-")
                        and not t.startswith("--")
                        and t.endswith("c")
                    ),
                    None,
                )
                if flag is not None and flag + 1 < len(current):
                    yield from commands(current[flag + 1], _depth + 1)
        current = []


def any_command(line, predicate):
    """Does any command in this line satisfy the predicate?

    >>> any_command("ls && cd /foo", lambda tokens: tokens[0] == "cd")
    True
    >>> any_command("ls -la", lambda tokens: tokens[0] == "cd")
    False
    """
    return any(predicate(tokens) for tokens in commands(line))


def payload():
    """This hook's stdin. A payload we cannot parse is never worth blocking on."""
    try:
        return json.load(sys.stdin)
    except ValueError:
        sys.exit(0)


def bash_command(data):
    """The command of a Bash tool call, or None for any other tool."""
    if data.get("tool_name") != "Bash":
        return None
    return data.get("tool_input", {}).get("command") or None


def block(reason):
    """Stop the call, and say why.

    Exit 2 blocks whether or not stdout parses, so a guard fails closed; a JSON
    decision needs exit 0 and would let a crashed hook through. stderr becomes
    the blocking message the model reads.
    """
    print(reason, file=sys.stderr)
    sys.exit(2)


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
    transcript as a hook *error*, not as advice. additionalContext suits both
    events -- on PreToolUse it joins the tool call's context, on PostToolUse it
    follows the tool output. The event name comes from the payload so neither
    caller has to restate the event it is already handling.
    """
    json.dump(advice(text, data.get("hook_event_name")), sys.stdout)
    sys.exit(0)
