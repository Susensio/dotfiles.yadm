#!/usr/bin/env python3
"""PreToolUse/Bash: refuse commands that must not run.

Add a rule by adding a row to BLOCKED. A rule is words that must appear in
order, with anything allowed between them:

    "cd"                              the command `cd`
    "git push --force"                a force-push, wherever the flag sits
    "*git|*yadm push --force|-f"      either porcelain, either flag, any path

The gaps are implicit, so a rule never has to say "and anything else here" --
which is what lets one row cover `git push --force origin` and `git push
origin --force` alike. That is the thing permissions.deny cannot express, its
patterns being anchored to the front of the command.

Matching is on tokens, not text, so a rule catches the command after a
separator, inside a subshell and behind `sh -lc`, and never inside a quoted
string.
"""

from fnmatch import fnmatchcase

from utils import any_command, bash_command, block, payload

CD = """Bash commands take absolute paths, never a `cd X && ...` prefix.
Leaving the working directory in a compound command defeats sandbox auto-approval and forces a permission prompt.
Instead: pass the path directly (`rg PATTERN /abs/path`), or use the tool's own flag -- `git -C /abs/path`, `yadm -C`, `make -C`, `npm --prefix`."""

FORCE_PUSH = """Force-push blocked: this rewrites published history and can destroy a collaborator's commits.
If you genuinely need it, run it yourself in a terminal -- the hook only governs the agent.
Safer alternative: `--force-with-lease`, which refuses when the remote moved under you, and is deliberately left allowed."""

# Add a rule here. Nothing below needs touching.
BLOCKED = [
    ("cd", CD),
    ("*git|*yadm push --force|-f|--mirror", FORCE_PUSH),
]


def matches(tokens, pattern):
    """Do these words appear in this command, in order?

    The first word is the command itself; the rest may sit anywhere after it:

    >>> matches(["git", "push", "origin", "--force"], "git push --force")
    True
    >>> matches(["git", "push", "--force", "origin"], "git push --force")
    True

    Implicit gaps also step over a flag that takes a value, so `git -C` needs
    no special case:

    >>> matches(["git", "-C", "/repo", "push", "--force"], "git push --force")
    True

    Words match whole tokens, so a longer flag is a different flag, and a
    subcommand that is not the one named does not match:

    >>> matches(["git", "push", "--force-with-lease"], "git push --force")
    False
    >>> matches(["git", "grep", "-f", "pats.txt", "push"], "git push --force|-f")
    False
    """
    first, *wanted = pattern.split()
    if not _any_of(tokens[0], first):
        return False
    rest = tokens[1:]
    for word in wanted:
        while rest and not _any_of(rest[0], word):
            rest = rest[1:]
        if not rest:
            return False
        rest = rest[1:]
    return True


def _any_of(token, word):
    """Does the token match the word, or any of its `a|b` alternatives?"""
    return any(fnmatchcase(token, alternative) for alternative in word.split("|"))


def refusal(command):
    """Why this command is refused, or None.

    A bare name matches the command wherever it runs, without catching the
    word in passing:

    >>> refusal("cd /foo && ls") is CD
    True
    >>> refusal("bash -lc 'cd /x'") is CD
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

    A safe push stays a safe push:

    >>> refusal("git push --force-with-lease origin main") is None
    True
    >>> refusal("git push origin main") is None
    True
    >>> refusal("git grep -f pats.txt push") is None
    True
    """
    return next(
        (
            reason
            for pattern, reason in BLOCKED
            if any_command(command, lambda tokens, p=pattern: matches(tokens, p))
        ),
        None,
    )


def main():
    command = bash_command(payload())
    reason = refusal(command) if command else None
    if reason:
        block(reason)


if __name__ == "__main__":
    main()
