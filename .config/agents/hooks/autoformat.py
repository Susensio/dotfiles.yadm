#!/usr/bin/env python3
"""PostToolUse/Write|Edit: format the file that was just edited.

Like an IDE's format-on-save. Every language below has a sane default, so a
project that declares nothing still gets formatted; a version the project pins
itself wins over that default. A formatter that is not installed is simply
skipped.
"""

import hashlib
import re
import shutil
import subprocess
from pathlib import Path

from utils import inform, payload

# Biome's domain, minus what it cannot parse. Leaving yaml out is deliberate:
# biome reports an unsupported path as exit 1, which would read here as the
# file having failed to format.
BIOME = (".json", ".jsonc", ".js", ".jsx", ".ts", ".tsx", ".css")

# What to run when the project pins nothing. Duplicated from helix's
# languages.toml on purpose -- two small tables beat one shared parser. `ruff
# format` is black-compatible by design, so a black project needs no entry.
#
# No style flags here: biome resolves biome.json from the working directory,
# which `main` sets to the project root, so each project's own file decides.
DEFAULTS = {
    ".py": ["ruff", "format"],
    ".rs": ["rustfmt"],
    ".go": ["gofmt", "-w"],
    **dict.fromkeys(BIOME, ["biome", "format", "--write"]),
}

# Where a project keeps the formatter versions it pins.
BIN_DIRS = ("node_modules/.bin", ".venv/bin")

# Any of these means a project starts here. A file in no project at all is
# formatted where it sits.
ROOT_MARKERS = (".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod")

TIMEOUT = 20  # Under the hook's own timeout, so this guard fires first.
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")  # Formatters colour diagnostics; strip it.


def project_root(path):
    """Where this file's project starts, or its own directory if it is in none."""
    return next(
        (d for d in path.parents if any((d / m).exists() for m in ROOT_MARKERS)),
        path.parent,
    )


def resolve(command, root):
    """The command with its binary resolved, or None if it is not installed.

    A version the project pins wins over a global install, so a repo holding a
    formatter to a known version gets that one. Asking the filesystem which
    binary a project ships beats parsing whatever config file declares it.
    """
    if not command:
        return None
    for bindir in BIN_DIRS:
        local = root / bindir / command[0]
        if local.exists():
            return [str(local), *command[1:]]
    return command if shutil.which(command[0]) else None


def digest(path):
    return hashlib.sha256(path.read_bytes()).digest()


def main():
    data = payload()
    path = Path(data.get("tool_input", {}).get("file_path", ""))
    if not path.is_file():
        return
    root = project_root(path)
    command = resolve(DEFAULTS.get(path.suffix), root)
    if not command:
        return  # No formatter for this type, or none installed.

    before = digest(path)
    try:
        proc = subprocess.run(
            command + [str(path)],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            cwd=root,
        )
    except (OSError, subprocess.TimeoutExpired):
        return  # Formatter vanished or hung: never punish the edit for it.

    name = Path(command[0]).name
    try:
        rel = path.relative_to(root)
    except ValueError:
        rel = path
    match proc.returncode, digest(path) != before:
        case 0, False:
            pass  # Already conformant. Nothing worth saying.
        case 0, True:
            # The model believes the file still says what it wrote. Left unsaid,
            # its next edit builds old_string from stale text and fails.
            inform(
                f"`{name}` reformatted {rel}. Disk no longer matches what "
                f"you wrote -- re-read before editing it again.",
                data,
            )
        case _:
            # A non-zero formatter usually means the file no longer parses --
            # the most useful thing the model can learn about its own edit.
            detail = ANSI_RE.sub("", proc.stderr or proc.stdout).strip()[:1500]
            inform(f"`{name}` failed on {rel}:\n{detail}", data)


if __name__ == "__main__":
    main()
