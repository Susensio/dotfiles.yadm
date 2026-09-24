#!/usr/bin/env python3
"""PostToolUse/Bash: resolve sandbox device-mount noise instead of hinting at it.

The sandbox bind-mounts /dev/null over paths it protects -- seen so far as
`.bashrc`/`.gitconfig` in a directory listing and `.git/config.lock` in a git
lock error. Naming the known paths is a losing game; the next one is always a
surprise. Pattern-matching the error text instead ("could not lock",
"Permission denied") is unsafe the other way -- a real stale `.git/index.lock`
produces the same words, and a hook that waves those away teaches the model to
ignore a genuine blocker.

The one fact that can't lie is the inode itself: extract every path-like token
Bash's output mentions and stat it. Only a confirmed character device gets the
note; every other candidate (a URL fragment, a version number, a real file)
fails the stat check silently and costs nothing.
"""

import os
import re
import stat

from utils import agent_key, first_time, inform, payload

PATH_TOKEN = re.compile(r"""(?:~|\.{1,2})?/[^\s'"]+|\.[\w.-]+(?:/[^\s'"]*)?""")

NULL_RDEV = (1, 3)  # major, minor of /dev/null

NOTE = (
    "`{path}` is a character device (major {major} minor {minor}) -- the sandbox "
    "bind-mounts /dev/null over it. It isn't a stale lock, a stray file, or a repo "
    "finding; it doesn't exist outside the sandbox and there's nothing to fix."
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


def null_device(path):
    """(major, minor) if `path` is a character device, else None."""
    try:
        st = os.stat(path)
    except OSError:
        return None
    if not stat.S_ISCHR(st.st_mode):
        return None
    return os.major(st.st_rdev), os.minor(st.st_rdev)


def main():
    data = payload()
    if data.get("tool_name") != "Bash":
        return
    response = data.get("tool_response", {})
    if not isinstance(response, dict):
        return
    output = "\n".join(
        value
        for key in ("stdout", "stderr")
        if isinstance(value := response.get(key), str)
    )
    for token in candidates(output):
        found = null_device(os.path.expanduser(token))
        if found == NULL_RDEV and first_time(agent_key(data), "sandbox-noise", token):
            inform(NOTE.format(path=token, major=found[0], minor=found[1]), data)


if __name__ == "__main__":
    main()
