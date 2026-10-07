#!/usr/bin/env python3
"""PostToolUse and PostToolUseFailure: name the sandbox's /dev/null mounts.

The sandbox bind-mounts /dev/null over paths it protects, which shows up as a
character device in a listing, a lock git cannot take, or a dotfile that reads
empty and swallows writes. Matching error text would also wave away a real
stale lock, so the hook stats every path the call named or printed and speaks
only for a confirmed /dev/null device. A failed call, such as git's lock
error, arrives as PostToolUseFailure.
"""

import os
import re
import stat

from utils import agent_key, first_time, inform, payload

PATH_TOKEN = re.compile(r"""(?:~|\.{1,2})?/[^\s'"]+|\.[\w.-]+(?:/[^\s'"]*)?""")
PATH_KEYS = ("file_path", "path", "notebook_path")
NULL_RDEV = (1, 3)

NOTE = (
    "`{path}` is the sandbox's /dev/null mount: reads come back empty, writes "
    "are discarded and it cannot be locked. It is not a stale lock, a stray "
    "file or a repo finding, and it does not exist outside the sandbox. Do not "
    "mention it to the user; carry on without that path."
)


def candidates(text):
    r"""Path-like tokens in `text`; a non-path just fails the stat later.

    >>> list(candidates("could not lock config file .git/config: File exists"))
    ['.git/config']
    >>> list(candidates("crw-rw-rw- 1 root root 1, 3 Jan 1 00:00 /home/u/.bashrc"))
    ['/home/u/.bashrc']
    """
    for match in PATH_TOKEN.finditer(text):
        yield match.group().rstrip("'\",.:;)")


def texts(value):
    """Every string in a tool payload value: responses are strings or objects.

    >>> list(texts({"stdout": "a", "n": 3, "more": ["b", {"c": "d"}]}))
    ['a', 'b', 'd']
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
    """Paths in the call's input fields, then every token in its command, output or error."""
    tool_input = data.get("tool_input")
    if not isinstance(tool_input, dict):
        tool_input = {}
    for key in PATH_KEYS:
        if isinstance(tool_input.get(key), str):
            yield tool_input[key]
    for value in (
        tool_input.get("command"),
        data.get("tool_response"),
        data.get("error"),
    ):
        for text in texts(value):
            yield from candidates(text)


def is_null_mount(path):
    """True for a /dev/null device standing in for a file; /dev/null itself is not one.

    >>> is_null_mount("/dev/null")
    False
    """
    if os.path.realpath(path).startswith("/dev/"):
        return False
    try:
        st = os.stat(path)
    except OSError:
        return False
    return (
        stat.S_ISCHR(st.st_mode)
        and (os.major(st.st_rdev), os.minor(st.st_rdev)) == NULL_RDEV
    )


def main():
    data = payload()
    for path in named_paths(data):
        path = os.path.expanduser(path)
        # Stamp names cannot hold slashes; first_time would fail open and repeat.
        if is_null_mount(path) and first_time(
            agent_key(data), "sandbox-noise", path.replace("/", "%2F")
        ):
            inform(NOTE.format(path=path), data)


if __name__ == "__main__":
    main()
