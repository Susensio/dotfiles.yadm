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
# `commands` appends, never a token shlex produces -- it splits lines first.
SEPARATORS = {"&&", "||", ";", "|", "|&", "&", "\n", "(", ")"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish"}

# Nested `sh -c 'sh -c ...'` recurses; this bounds it against a pathological
# or adversarial chain rather than any real script needing the depth.
MAX_SHELL_C_DEPTH = 2

# Wrappers that run a command without being it: a rule inspecting tokens[0]
# must see the wrapped command, not the wrapper. Maps each to the flags that
# take a separate argument, so skipping past them doesn't eat the command.
WRAPPERS = {
    "sudo": {"-u", "-g", "-p", "-h", "-C", "-D", "-R", "-T", "-U"},
    "env": {"-u", "-C", "-S"},
    "timeout": {"-k", "-s"},
    "nice": {"-n"},
    "command": set(),
    "xargs": {"-I", "-i", "-L", "-l", "-n", "-P", "-s", "-a", "-d", "-E"},
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

    A command wrapper -- `sudo`, `env`, `timeout`, `nice`, `command`, `xargs`
    -- is stripped the same way, its own flags and arguments included, so the
    rule underneath sees the command it actually runs:

    >>> list(commands("sudo git push --force"))
    [['sudo', 'git', 'push', '--force'], ['git', 'push', '--force']]
    >>> list(commands("env FOO=bar git push -f"))
    [['env', 'FOO=bar', 'git', 'push', '-f'], ['git', 'push', '-f']]
    >>> list(commands("timeout 5 git push -f"))
    [['timeout', '5', 'git', 'push', '-f'], ['git', 'push', '-f']]

    A wrapper with nothing to wrap is left alone rather than crashed on:

    >>> list(commands("env"))
    [['env']]
    >>> list(commands("sudo"))
    [['sudo']]
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
            yield current
            # Follow a shell's -c argument, but nothing else: recursing into
            # every quoted token would read `echo "cd foo"` as a cd. Short flags
            # cluster, so the command flag is any of -c, -lc, -ec, -ic.
            if _depth < MAX_SHELL_C_DEPTH and current[0] in SHELLS:
                flag = _shell_c_index(current)
                if flag is not None and flag + 1 < len(current):
                    yield from commands(current[flag + 1], _depth + 1)
            unwrapped = _unwrap(current)
            if unwrapped != current:
                yield unwrapped
        current = []


def _shell_c_index(tokens):
    """Index of a clustered -c flag (-c, -lc, -ec, ...), or None."""
    for i, token in enumerate(tokens):
        if token.startswith("-") and not token.startswith("--") and token.endswith("c"):
            return i
    return None


def _unwrap(tokens):
    """The tokens of the command a chain of wrappers runs.

    Unchanged if `tokens` names no wrapper. `env`'s leading NAME=value
    assignments are skipped like flags; `timeout`'s bare DURATION is its own
    positional argument, skipped once, before the wrapped command.
    """
    while tokens and tokens[0] in WRAPPERS:
        name = tokens[0]
        arg_flags = WRAPPERS[name]
        skip_duration = name == "timeout"
        i = 1
        while i < len(tokens):
            token = tokens[i]
            if name == "env" and not token.startswith("-") and "=" in token:
                i += 1
            elif token.startswith("-") and token != "-":
                i += 2 if token in arg_flags else 1
            elif skip_duration:
                skip_duration = False
                i += 1
            else:
                break
        if i >= len(tokens):
            return tokens  # A wrapper with nothing after it wraps nothing.
        tokens = tokens[i:]
    return tokens


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
