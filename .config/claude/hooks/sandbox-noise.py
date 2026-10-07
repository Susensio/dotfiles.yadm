#!/usr/bin/env python3
"""PostToolUse and PostToolUseFailure: resolve sandbox device-mount noise.

The sandbox bind-mounts /dev/null over paths it protects -- seen so far as
`.bashrc`/`.gitconfig` in a directory listing, `.git/config.lock` in a git
lock error, and a dotfile that reads back empty or swallows a write. Naming the
known paths is a losing game; the next one is always a surprise.
Pattern-matching the error text instead ("could not lock", "Permission
denied") is unsafe the other way -- a real stale `.git/index.lock` produces the
same words, and a hook that waves those away teaches the model to ignore a
genuine blocker.

The one fact that can't lie is the inode itself: stat every path the call
named or printed -- its input, its output, its error -- and speak only for a
confirmed /dev/null character device. Every other candidate (a URL fragment, a
version number, a real file) fails the stat check silently and costs nothing.

A failed call arrives as PostToolUseFailure, not PostToolUse: a git command
that cannot take its lock exits non-zero, so the failure event is where the
lock error is. This hook replaces the CLAUDE.md paragraph that asked the model
to recognise the signature itself.
"""

import os
import re
import stat

from utils import agent_key, first_time, inform, payload

PATH_TOKEN = re.compile(r"""(?:~|\.{1,2})?/[^\s'"]+|\.[\w.-]+(?:/[^\s'"]*)?""")

NULL_RDEV = (1, 3)  # major, minor of /dev/null

# Tool-input keys that hold a path outright, for tools whose output never echoes it.
PATH_KEYS = ("file_path", "path", "notebook_path")

NOTE = (
    "`{path}` is a character device (major {major} minor {minor}): the sandbox "
    "bind-mounts /dev/null over it, so reads come back empty, writes are "
    "discarded, and a lock on it cannot be taken. It is not a stale lock, a "
    "stray file, a surprise diff or a repo finding, and it does not exist "
    "outside the sandbox. Nothing to fix and nothing to tell the user: do not "
    "mention it, and carry on without that path."
)


def candidates(output):
    r"""Every path-like token in `output`, in order of first appearance.

    Over-generates on purpose: a token that isn't a real path just fails the
    stat check downstream, so casting wide here costs nothing.

    >>> list(candidates("could not lock config file .git/config: File exists"))
    ['.git/config']
    >>> list(candidates("crw-rw-rw- 1 root root 1, 3 Jan 1 00:00 /home/u/.bashrc"))
    ['/home/u/.bashrc']
    >>> list(candidates("plain text, no paths here"))
    []
    """
    seen = set()
    for match in PATH_TOKEN.finditer(output):
        token = match.group().rstrip("'\",.:;)")
        if token not in seen:
            seen.add(token)
            yield token


def texts(value):
    """Every string inside a tool payload value, depth first.

    Tool responses are a bare string for some tools and nested objects for
    others (Bash's stdout/stderr, Read's file record), so walk them all.

    >>> list(texts({"stdout": "a", "stderr": "", "n": 3, "more": ["b", {"c": "d"}]}))
    ['a', '', 'b', 'd']
    >>> list(texts("plain"))
    ['plain']
    """
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from texts(item)
    elif isinstance(value, list):
        for item in value:
            yield from texts(item)


def named_paths(data):
    """Paths the call names: input path fields first, then every token printed.

    >>> list(named_paths({"tool_input": {"file_path": "/x/.gitconfig"},
    ...                   "error": "EACCES: /x/.gitconfig"}))
    ['/x/.gitconfig', '/x/.gitconfig']
    """
    tool_input = data.get("tool_input") or {}
    if isinstance(tool_input, dict):
        for key in PATH_KEYS:
            if isinstance(value := tool_input.get(key), str) and value:
                yield value
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    for value in (data.get("tool_response"), data.get("error"), command):
        for text in texts(value):
            yield from candidates(text)


def null_device(path):
    """(major, minor) if `path` is a character device masking a file, else None.

    A real device node under /dev -- the `> /dev/null` in a command -- is
    itself, not a mount over something; a bind mount keeps its own path.

    >>> null_device("/dev/null") is None
    True
    """
    if os.path.realpath(path).startswith("/dev/"):
        return None
    try:
        st = os.stat(path)
    except OSError:
        return None
    if not stat.S_ISCHR(st.st_mode):
        return None
    return os.major(st.st_rdev), os.minor(st.st_rdev)


def main():
    data = payload()
    for token in named_paths(data):
        found = null_device(os.path.expanduser(token))
        # A stamp name cannot hold the path's slashes; first_time would fail open.
        stamp = token.replace("/", "%2F")
        if found == NULL_RDEV and first_time(agent_key(data), "sandbox-noise", stamp):
            inform(NOTE.format(path=token, major=found[0], minor=found[1]), data)


if __name__ == "__main__":
    main()
