#!/usr/bin/env python3
"""Rebase one patch of this library onto a drifted target.

`apply.sh` only touches a byte-identical pristine target, so a package update
moves a patched file back to a shape the kept `.orig` no longer matches and the
patch stops applying. This rebuilds the patched form from the patch's own
`.orig`, three-way merges it into the new upstream file, and on a clean merge
refreshes `.orig` from the new upstream file and regenerates the `.patch`, so
the next update is byte-identical again.

A conflict changes nothing and warns: an unpatched file that still loads beats
a half-merged one on a security boundary. Files the patch creates are rewritten
onto the target only when absent and byte-identical to the patch's own copy, so
a release that ships the same path is reported rather than clobbered.

Exit 0: nothing needed (not drifted, already applied, no target) or rebased.
Exit 1: a conflict or a shape this script will not rewrite; message on stderr.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# A patch that deletes or rewrites a second existing file is outside the shape
# .orig + .patch + target models, so it is reported instead of guessed at.
SUPPORTED = ("-u",)


def proceed(message: str | None = None) -> int:
    if message:
        print(message)
    return 0


def conflict(name: str, reason: str, hint: str) -> int:
    print(f"rebase.py [{name}]: {reason}", file=sys.stderr)
    print(f"  {hint}", file=sys.stderr)
    return 1


def run(argv: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(argv, check=False, cwd=cwd, capture_output=True, text=True)


def is_applied(target: Path, marker: str) -> bool:
    # apply.sh matches the marker as a grep pattern, so match it the same way.
    return run(["grep", "-q", "--", marker, str(target)]).returncode == 0


def package_version(target: Path) -> str:
    for parent in (target.parent, *target.parents):
        manifest = parent / "package.json"
        if not manifest.is_file():
            continue
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            break
        if isinstance(data, dict) and data.get("name"):
            return f"{data['name']}@{data.get('version', 'unknown')}"
    return "unknown"


def touched_files(patch_text: str) -> tuple[list[str], list[str]]:
    """Split a patch's headers into files it edits and files it creates."""
    edited: list[str] = []
    created: list[str] = []
    lines = patch_text.splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("+++ "):
            continue
        after = line[4:].split("\t")[0].strip()
        if after == "/dev/null":
            continue
        before = lines[index - 1][4:].split("\t")[0].strip() if index else ""
        # `--- /dev/null` is a creation; anything else edits a file that exists.
        (created if before == "/dev/null" else edited).append(after)
    return edited, created


def patched_form(patch: Path, orig: Path, workdir: Path, target_name: str) -> list[str]:
    """Materialize the patch against .orig inside workdir; return created names."""
    # The patch's headers are bare target names, so the pristine copy has to
    # appear under that name, not under its own `<target>.orig`.
    shutil.copy2(orig, workdir / target_name)
    shutil.copy2(patch, workdir / patch.name)
    result = run(
        ["patch", "-p0", "--forward", "--quiet", "-i", patch.name], cwd=workdir
    )
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip() or result.stdout.strip() or "patch failed"
        )
    return sorted(
        path.name
        for path in workdir.iterdir()
        if path.name not in (target_name, patch.name)
    )


def merge(target: Path, orig: Path, patched: Path) -> tuple[str | None, int]:
    """Three-way merge the patched form into the new upstream file."""
    result = run(
        [
            "git",
            "merge-file",
            "-p",
            "--diff3",
            "-L",
            "upstream",
            "-L",
            "original",
            "-L",
            "patched",
            str(target),
            str(orig),
            str(patched),
        ]
    )
    # merge-file counts conflicts as its exit status and reserves negative
    # values (reported as a large unsigned value) for its own failures.
    if result.returncode < 0 or result.returncode >= 128:
        return None, result.returncode
    return result.stdout, result.returncode


def write_atomic(path: Path, text: str) -> None:
    handle, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as stream:
            stream.write(text)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def regenerate(orig: Path, target: Path, created: list[str], target_dir: Path) -> str:
    """The patch as it now reads: the target's diff, then each created file."""
    chunks: list[str] = []
    edited = run(
        [
            "diff",
            "-u",
            "--label",
            target.name,
            "--label",
            target.name,
            str(orig),
            str(target),
        ]
    )
    if edited.returncode not in (0, 1):
        raise RuntimeError(edited.stderr.strip() or "diff failed")
    chunks.append(edited.stdout)
    for name in created:
        added = run(
            [
                "diff",
                "-uN",
                "--label",
                "/dev/null",
                "--label",
                name,
                "/dev/null",
                str(target_dir / name),
            ]
        )
        if added.returncode not in (0, 1):
            raise RuntimeError(added.stderr.strip() or "diff failed")
        chunks.append(added.stdout)
    return "".join(chunk for chunk in chunks if chunk)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: rebase.py <patch-name>", file=sys.stderr)
        return 1
    name = argv[1]
    directory = Path(__file__).resolve().parent / name
    for required in ("target", "marker"):
        if not (directory / required).is_file():
            print(
                f"rebase.py [{name}]: {directory / required} missing", file=sys.stderr
            )
            return 1

    target = Path((directory / "target").read_text(encoding="utf-8").strip())
    marker = (directory / "marker").read_text(encoding="utf-8").strip()
    origs = sorted(directory.glob("*.orig"))
    patches = sorted(directory.glob("*.patch"))
    if len(origs) != 1 or len(patches) != 1:
        print(
            f"rebase.py [{name}]: needs exactly one .orig and one .patch",
            file=sys.stderr,
        )
        return 1
    orig, patch = origs[0], patches[0]

    if not target.is_file() or is_applied(target, marker):
        return proceed()
    if target.read_bytes() == orig.read_bytes():
        # Pristine: apply.sh's own job.
        return proceed()

    patch_text = patch.read_text(encoding="utf-8", errors="surrogateescape")
    edited, _created = touched_files(patch_text)
    if "+++ /dev/null" in patch_text:
        return conflict(
            name,
            "deletes a file, which this script will not rewrite",
            "rebase it by hand against the new upstream file.",
        )
    if len(edited) > 1:
        return conflict(
            name,
            f"edits {len(edited)} existing files, which this script models as one",
            "rebase it by hand against the new upstream file.",
        )

    new_upstream = target.read_bytes()
    version = package_version(target)
    with tempfile.TemporaryDirectory(prefix="pi-rebase-") as temporary:
        workdir = Path(temporary)
        try:
            patched_names = patched_form(patch, orig, workdir, target.name)
        except RuntimeError as error:
            return conflict(
                name,
                f"its own patch no longer applies to the kept .orig ({error})",
                "refresh the .orig from the new upstream file and regenerate the patch.",
            )
        patched = workdir / target.name
        merged, conflicts = merge(target, orig, patched)
        if merged is None:
            return conflict(
                name,
                "git merge-file could not run",
                "rebase it by hand against the new upstream file.",
            )
        if conflicts:
            return conflict(
                name,
                f"{conflicts} conflicting hunk(s) against {version}",
                f"{target} is left unpatched; rebase it by hand against the new upstream file.",
            )

        # A created file already on disk must be the patch's own copy: identical
        # means the release has not taken the path over.
        for created_name in patched_names:
            destination = target.parent / created_name
            source = workdir / created_name
            if destination.exists() and destination.read_bytes() != source.read_bytes():
                return conflict(
                    name,
                    f"creates {created_name}, which {version} now ships with different contents",
                    "the patch may have landed upstream; check before regenerating it.",
                )

        for created_name in patched_names:
            destination = target.parent / created_name
            if not destination.exists():
                shutil.copy2(workdir / created_name, destination)

        write_atomic(target, merged)
        write_atomic(orig, new_upstream.decode("utf-8", "surrogateescape"))
        write_atomic(patch, regenerate(orig, target, patched_names, target.parent))
        write_atomic(directory / "base", f"{version}\n")

    # The `rebased:` tag is load-bearing: pi-postinstall treats any other output
    # from reapply-all.sh as a patch needing attention (ADR-0112).
    return proceed(f"rebase.py [{name}]: rebased: onto {version}")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
