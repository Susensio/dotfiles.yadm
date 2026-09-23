#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "tomlkit>=0.13,<1",
#   "typer>=0.15,<1",
# ]
# ///
"""Discover version-pinned completion and manpage sources for mise tools."""

from __future__ import annotations

import base64
import gzip
import json
import os
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from functools import cache
from pathlib import Path
from urllib.parse import quote

import tomlkit
import typer
from tomlkit.items import InlineTable, Item, Table

app = typer.Typer(add_completion=False, no_args_is_help=True)
TOOLS_ARGUMENT = typer.Argument(..., help="Installed global tools to inspect.")
DRY_RUN_OPTION = typer.Option(
    False,
    "--dry-run",
    help="Print discoveries without writing TOML or applying assets.",
)


@dataclass(frozen=True)
class Tool:
    name: str
    version: str
    path: Path
    repo: str | None

    @property
    def spec(self) -> str:
        return f"{self.name}@{self.version}"


def run(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=check, text=True, capture_output=True)


def mise(*args: str) -> str:
    return run("mise", *args).stdout


def installed_tool_versions(names: Iterable[str]) -> dict[str, str]:
    installed = json.loads(mise("list", "--installed", "--global", "--json"))
    versions: dict[str, str] = {}
    for name in names:
        tool_versions = installed.get(name, [])
        if not tool_versions:
            msg = f"{name} is not installed globally"
            raise typer.BadParameter(msg)
        versions[name] = tool_versions[-1]["version"]
    return versions


def tool_context(name: str, version: str) -> Tool:
    info = json.loads(mise("tool", name, "--json"))
    backend = info["backend"]
    repo = (
        backend.split(":", maxsplit=1)[1]
        if backend.startswith(("aqua:", "github:"))
        else None
    )
    return Tool(name, version, Path(mise("where", f"{name}@{version}").strip()), repo)


def tool_binaries(tool: Tool) -> list[Path]:
    paths = mise("bin-paths", tool.spec).splitlines()
    binaries: list[Path] = []
    for path in paths:
        bin_path = Path(path)
        if not bin_path.is_dir():
            continue
        binaries.extend(
            candidate
            for candidate in bin_path.iterdir()
            if candidate.is_file() and os.access(candidate, os.X_OK)
        )
    return binaries


def installed_file_names(tool: Tool) -> set[str]:
    return {
        filename
        for _, _, files in os.walk(tool.path, followlinks=True)
        for filename in files
    }


def has_local_completion(binary: Path, filenames: set[str]) -> bool:
    return bool({"completion.fish", f"{binary.name}.fish"} & filenames)


def resolve_tag(tool: Tool) -> tuple[str, str] | None:
    if tool.repo is None:
        return None
    for prefix in ("v", ""):
        tag = f"{prefix}{tool.version}"
        endpoint = f"/repos/{tool.repo}/git/ref/tags/{quote(tag, safe='')}"
        result = run("gh", "api", endpoint, check=False)
        if result.returncode == 0:
            return tag, prefix
        if "HTTP 404" not in result.stderr:
            raise RuntimeError(result.stderr.strip())
    return None


def repository_files(tool: Tool, tag: str) -> set[str]:
    assert tool.repo is not None
    endpoint = f"/repos/{tool.repo}/git/trees/{quote(tag, safe='')}?recursive=1"
    tree = json.loads(run("gh", "api", endpoint).stdout)
    if tree["truncated"]:
        msg = f"cannot inspect {tool.repo}@{tag}: GitHub tree is truncated"
        raise RuntimeError(msg)
    return {entry["path"] for entry in tree["tree"] if entry["type"] == "blob"}


def matches_remote_asset(kind: str, binary: Path, source_path: str) -> bool:
    filename = Path(source_path).name
    if kind == "completion":
        return filename in {"completion.fish", f"{binary.name}.fish"}
    filename = filename.removesuffix(".gz")
    return filename.startswith((f"{binary.name}.", f"{binary.name}-")) and (
        filename.rsplit(".", maxsplit=1)[-1] in "123456789"
    )


@cache
def is_manpage(repo: str, path: str, tag: str) -> bool:
    endpoint = f"/repos/{repo}/contents/{path}?ref={quote(tag, safe='')}"
    payload = json.loads(run("gh", "api", endpoint).stdout)
    content = base64.b64decode(payload["content"])
    if path.endswith(".gz"):
        content = gzip.decompress(content)
    result = subprocess.run(
        ("file", "--brief", "--mime-type", "-"),
        check=True,
        input=content,
        capture_output=True,
    )
    return result.stdout.strip() == b"text/troff"


def discover_kind(
    tool: Tool,
    binaries: Iterable[Path],
    filenames: set[str],
    source_paths: Iterable[str],
    kind: str,
    tag: str,
    prefix: str,
) -> tuple[set[str], dict[str, set[str]]]:
    assert tool.repo is not None
    assets: set[str] = set()
    candidates: dict[str, set[str]] = {}
    local_manpages = {filename.removesuffix(".gz") for filename in filenames}

    for binary in binaries:
        if kind == "completion" and has_local_completion(binary, filenames):
            continue
        for path in source_paths:
            destination = Path(path).name
            if kind == "manpage" and destination.removesuffix(".gz") in local_manpages:
                continue
            if matches_remote_asset(kind, binary, path) and (
                kind == "completion" or is_manpage(tool.repo, path, tag)
            ):
                candidates.setdefault(destination, set()).add(path)

    ambiguous = {name: paths for name, paths in candidates.items() if len(paths) > 1}
    for paths in candidates.values():
        if len(paths) == 1:
            assets.add(f"raw://{prefix}@{next(iter(paths))}")
    return assets, ambiguous


def config_path_for(tool_name: str) -> Path:
    configs = json.loads(mise("config", "ls", "--json"))
    paths = [entry["path"] for entry in configs if tool_name in entry["tools"]]
    if len(paths) != 1:
        msg = f"expected one config declaration for {tool_name}, found {len(paths)}"
        raise RuntimeError(msg)
    return Path(paths[0])


def add_assets(config_path: Path, tool_name: str, assets: set[str]) -> list[str]:
    document = tomlkit.parse(config_path.read_text())
    tools = document["tools"]
    entry: Item = tools[tool_name]
    if isinstance(entry.unwrap(), str):
        replacement = tomlkit.inline_table()
        replacement["version"] = entry
        tools[tool_name] = replacement
        entry = replacement
    if not isinstance(entry, (InlineTable, Table)):
        msg = f"cannot add extra_assets to {tool_name}: unsupported tool declaration"
        raise TypeError(msg)

    existing = [str(asset) for asset in entry.get("extra_assets", [])]
    additions = sorted(assets.difference(existing))
    if not additions:
        return []
    entry["extra_assets"] = [*existing, *additions]
    config_path.write_text(tomlkit.dumps(document))
    return additions


def apply_assets(tool_names: Iterable[str]) -> None:
    installer = Path(__file__).with_name("system-install")
    command = [str(installer)]
    for tool_name in tool_names:
        command.extend(("--filter", tool_name))
    subprocess.run(command, check=True)


@app.command()
def discover(
    tools: list[str] = TOOLS_ARGUMENT,
    dry_run: bool = DRY_RUN_OPTION,
) -> None:
    """Materialize discovered upstream assets, then apply them sequentially."""
    updated_tools: list[str] = []
    for name, version in installed_tool_versions(tools).items():
        tool = tool_context(name, version)
        if tool.repo is None:
            typer.echo(f"skip {name}: backend has no GitHub repository")
            continue
        tag_info = resolve_tag(tool)
        if tag_info is None:
            typer.echo(f"skip {name}: no v{version} or {version} tag")
            continue
        tag, prefix = tag_info
        binaries = tool_binaries(tool)
        filenames = installed_file_names(tool)
        source_paths = repository_files(tool, tag)
        assets, completion_ambiguities = discover_kind(
            tool, binaries, filenames, source_paths, "completion", tag, prefix
        )
        manpage_assets, manpage_ambiguities = discover_kind(
            tool, binaries, filenames, source_paths, "manpage", tag, prefix
        )
        assets.update(manpage_assets)
        ambiguities = completion_ambiguities | manpage_ambiguities
        for destination, paths in sorted(ambiguities.items()):
            typer.echo(
                f"skip {name}: ambiguous {destination}: {', '.join(sorted(paths))}",
                err=True,
            )
        if dry_run:
            for asset in sorted(assets):
                typer.echo(f"would add {name}: {asset}")
            continue
        additions = add_assets(config_path_for(name), name, assets)
        for asset in additions:
            typer.echo(f"discovered {name}: {asset}")
        if additions:
            updated_tools.append(name)

    if updated_tools:
        apply_assets(updated_tools)


if __name__ == "__main__":
    app()
