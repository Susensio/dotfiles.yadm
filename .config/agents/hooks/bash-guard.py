#!/usr/bin/env python3
"""PreToolUse/Bash: refuse commands that must not run.

Add a rule by adding a row to BLOCKED: a predicate over a command's token
list, paired with the reason to give when it fires. The predicate decides
what "matches" means -- a bare command name, a flag anywhere after it, a
porcelain reached by any path -- so a rule is free to skip over `git -C
/repo` or `push origin --force` however it needs to. That is the thing
permissions.deny cannot express, its patterns being anchored to the front of
the command.

Matching is on tokens, not text, so a rule catches the command after a
separator, inside a subshell, behind `sh -lc`, and past a wrapper like
`sudo` or `env` -- and never inside a quoted string.
"""

from utils import any_command, bash_command, block, payload

CD = """Bash commands take absolute paths, never a `cd X && ...` prefix.
Leaving the working directory in a compound command defeats sandbox auto-approval and forces a permission prompt.
Instead: pass the path directly (`rg PATTERN /abs/path`), or use the tool's own flag -- `git -C /abs/path`, `yadm -C`, `make -C`, `npm --prefix`."""

FORCE_PUSH = """Force-push blocked: this rewrites published history and can destroy a collaborator's commits.
If you genuinely need it, run it yourself in a terminal -- the hook only governs the agent.
Safer alternative: `--force-with-lease`, which refuses when the remote moved under you, and is deliberately left allowed."""


def is_cd(tokens):
    """A bare `cd`, wherever it sits in the command.

    >>> is_cd(["cd", "/foo"])
    True
    >>> is_cd(["cdrecord", "-v"])
    False
    """
    return bool(tokens) and tokens[0] == "cd"


def is_force_push(tokens):
    """A force-push, however the porcelain, the path, or the flag is written.

    The command is git or yadm, reached by any path:

    >>> is_force_push(["/usr/bin/git", "push", "--force"])
    True
    >>> is_force_push(["yadm", "push", "--mirror", "origin"])
    True

    `push` may sit behind an option that takes a value, like `-C /repo`, and
    the force flag may land anywhere after it -- either side of the
    refspec:

    >>> is_force_push(["git", "-C", "/repo", "push", "-f"])
    True
    >>> is_force_push(["git", "push", "origin", "main", "--force"])
    True

    `--force-with-lease` is a different flag, not a prefix match on `--force`,
    and `push` appearing as an argument rather than the subcommand doesn't
    count:

    >>> is_force_push(["git", "push", "--force-with-lease", "origin", "main"])
    False
    >>> is_force_push(["git", "grep", "-f", "pats.txt", "push"])
    False
    """
    if not tokens or not (tokens[0].endswith("git") or tokens[0].endswith("yadm")):
        return False
    if "push" not in tokens[1:]:
        return False
    after_push = tokens[tokens.index("push", 1) + 1 :]
    return any(flag in after_push for flag in ("--force", "-f", "--mirror"))


# Add a rule here. Nothing below needs touching.
BLOCKED = [
    (is_cd, CD),
    (is_force_push, FORCE_PUSH),
]


def refusal(command):
    r"""Why this command is refused, or None.

    A bare name matches the command wherever it runs, without catching the
    word in passing:

    >>> refusal("cd /foo && ls") is CD
    True
    >>> refusal("bash -lc 'cd /x'") is CD
    True

    A newline separates commands like any other separator, so a rule is not
    escaped by putting the command on its own line:

    >>> refusal("ls\ncd /foo") is CD
    True
    >>> refusal("echo hi\ngit push --force origin") is FORCE_PUSH
    True
    >>> refusal('echo "cd foo"') is None
    True
    >>> refusal("cdrecord -v") is None
    True

    One row covers both porcelains, every force flag, and any path to them:

    >>> refusal("git push origin main --force") is FORCE_PUSH
    True
    >>> refusal("git -C /repo push -f") is FORCE_PUSH
    True
    >>> refusal("yadm push --mirror origin") is FORCE_PUSH
    True
    >>> refusal("/usr/bin/git push --force") is FORCE_PUSH
    True

    A wrapper -- `sudo`, `env`, `timeout` -- does not hide the command it runs:

    >>> refusal("sudo git push --force") is FORCE_PUSH
    True
    >>> refusal("env FOO=bar git push -f") is FORCE_PUSH
    True
    >>> refusal("timeout 5 git push -f") is FORCE_PUSH
    True

    A safe push stays a safe push:

    >>> refusal("git push --force-with-lease origin main") is None
    True
    >>> refusal("git push origin main") is None
    True
    >>> refusal("git grep -f pats.txt push") is None
    True
    """
    return next(
        (reason for predicate, reason in BLOCKED if any_command(command, predicate)),
        None,
    )


def main():
    command = bash_command(payload())
    reason = refusal(command) if command else None
    if reason:
        block(reason)


if __name__ == "__main__":
    main()
