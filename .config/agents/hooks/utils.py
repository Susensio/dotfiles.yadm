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
# hands back as their own tokens. The newline is the end-of-segment sentinel
# `_segment_commands` appends, never a token shlex produces -- it splits lines
# first.
SEPARATORS = {"&&", "||", ";", "|", "|&", "&", "\n", "(", ")"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish"}

# Bounds both the sh -c recursion and the wrapper-chain recursion below,
# against a pathological or adversarial chain rather than any real script
# needing the depth.
MAX_DEPTH = 4

# Wrappers that run a command without being it: a rule inspecting tokens[0]
# must see the wrapped command, not the wrapper. No per-tool flag grammar to
# maintain -- `_expand` offers every suffix of the token list as a candidate
# and lets each rule's own predicate, anchored on tokens[0], pick the real one
# out of the noise.
WRAPPERS = {
    "sudo",
    "env",
    "timeout",
    "nice",
    "xargs",
    "nohup",
    "doas",
    "stdbuf",
    "time",
    "ionice",
    "setsid",
    "eval",
}


def commands(line, _depth=0):
    r"""Every command in a command line, as a list of argument tokens.

    Tokenising the way a shell does means quoting, `(subshells)` and a missing
    space around `&&` all fall out of one pass, instead of each needing its own
    regex to see through.

    >>> list(commands("cd /foo && ls"))
    [['cd', '/foo'], ['ls']]
    >>> list(commands("ls&&cd /x"))
    [['ls'], ['cd', '/x']]

    A newline separates commands as surely as `&&` does, and it is how a model
    ordinarily writes a two-step call. shlex consumes it as whitespace, so the
    line is split into segments before tokenising -- without this, every
    command after the first joins its predecessor's tokens and is never tested:

    >>> list(commands("ls\ncd /x"))
    [['ls'], ['cd', '/x']]
    >>> list(commands("echo hi\ngit push --force\n"))
    [['echo', 'hi'], ['git', 'push', '--force']]

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

    A command wrapper -- `sudo`, `env`, `timeout`, `nice`, `xargs`, `nohup`,
    `doas`, `stdbuf`, `time`, `ionice`, `setsid`, `eval` -- doesn't hide the
    command it runs: every suffix of its token list is offered as a candidate,
    and the rule underneath, anchored on tokens[0], picks the real one out of
    the rest without needing to know that wrapper's option grammar. `xargs` is
    the one gap this can't close -- a flag piped into its stdin, as in
    `echo --force | xargs git push`, never reaches this argv at all.

    >>> ['git', 'push', '--force'] in commands("sudo git push --force")
    True
    >>> ['git', 'push', '-f'] in commands("env FOO=bar git push -f")
    True
    >>> ['git', 'push', '-f'] in commands("timeout 5 git push -f")
    True

    A wrapper with nothing after it offers no further candidates:

    >>> list(commands("env"))
    [['env']]
    >>> list(commands("sudo"))
    [['sudo']]

    Wrappers stack, and a wrapper can stand in front of a shell -- both are
    just more suffixes for the same recursion to walk:

    >>> ['git', 'push', '-f'] in commands("sudo timeout 5 git push -f")
    True
    >>> ['git', 'push', '--force'] in commands("sudo sh -c 'git push --force'")
    True

    `eval` re-parses its argument as a shell command line the same way `sh -c`
    does, quoting and all:

    >>> ['git', 'push', '--force'] in commands("eval 'git push --force'")
    True
    """
    for segment in line.splitlines():
        yield from _segment_commands(segment, _depth)


def _segment_commands(line, _depth):
    """Every command in one newline-free segment. See `commands`."""
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
            yield from _expand(current, _depth)
        current = []


def _expand(tokens, depth):
    """`tokens`, plus every suffix a shell -c or a wrapper chain might hide.

    No rule needs to identify *the* wrapped command -- each predicate is
    anchored on tokens[0] and filters the rest, so this only has to offer up
    candidates. Trying every suffix of a wrapper's token list, blind to its
    option grammar, does that: whatever the wrapper's flags are, one of the
    suffixes starts exactly where the wrapped command does.

    >>> list(_expand(["sudo", "git", "push"], 0))
    [['sudo', 'git', 'push'], ['git', 'push'], ['push']]
    """
    yield tokens
    if depth >= MAX_DEPTH:
        return
    if tokens[0] in SHELLS:
        # Short flags cluster, so the command flag is any of -c, -lc, -ec, -ic.
        for i, token in enumerate(tokens[:-1]):
            if (
                token.startswith("-")
                and not token.startswith("--")
                and token.endswith("c")
            ):
                yield from commands(tokens[i + 1], depth + 1)
                break
    if tokens[0] == "eval" and len(tokens) > 1:
        yield from commands(" ".join(tokens[1:]), depth + 1)
    if tokens[0] in WRAPPERS:
        for i in range(1, len(tokens)):
            yield from _expand(tokens[i:], depth + 1)


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
