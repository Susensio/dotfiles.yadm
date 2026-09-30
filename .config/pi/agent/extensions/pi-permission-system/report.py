#!/usr/bin/env python3
"""Report on pi-permission-system's decision log vs its config.json.

Standalone, stdlib-only: the deterministic parsing lives here so the agent
(or a terminal) only reads the output. The heavy lifting — correlation,
grouping, rule evaluation — is not something a model should redo each time.
Rule resolution mirrors the package's evaluator — load-time sugar expansion,
last-match-wins, the universal `*` fallback — so which entry actually decides a
given path is computed rather than guessed from the file.

By default the report covers only decisions made under the CURRENT config, so
evidence never mixes config generations. The window starts at config.json's
mtime, which any rewrite of that file moves — including one that changes
nothing, since the extension rewrites it on a UI save. `--all` lifts the window
to the whole log history.

Usage: report.py [denied|review] [--all]
  (no arg)  full optimization report over the current-config window
  denied    only the denial clusters section
  review    only the reviewer section
  --all     ignore the config-change window, report the whole log
"""

import json
import os
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOG = HERE / "logs" / "pi-permission-system-permission-review.jsonl"
CONFIG = HERE / "config.json"

WHO = {
    "yolo": "yolo", "user": "you", "rule": "rule", "session_approval": "session",
    "authorizer": "review", "unavailable": "no-auth", "infrastructure_read": "infra",
}
TERMINAL = {"auto_approved", "approved", "session_approved", "infrastructure_auto_allowed", "denied", "blocked"}


def load(window_epoch=None):
    recs = {}
    since = None
    with open(LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                j = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts = j.get("timestamp")
            if window_epoch and ts:
                try:
                    if datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp() < window_epoch:
                        continue
                except ValueError:
                    pass
            if since is None:
                since = ts
            rid = j.get("requestId")
            if not rid:
                continue
            r = recs.setdefault(rid, {"rationale": None, "risk": None, "who": "", "denial": None})
            e = j.get("event", "")
            if e == "pi_auto_review_decision":
                r["rationale"] = j.get("rationale")
                r["risk"] = j.get("riskLevel")
            elif e.startswith("permission_request."):
                short = e.replace("permission_request.", "")
                if short == "waiting":
                    r.setdefault("event", "open")
                    continue
                r["event"] = short
                r["ts"] = j.get("timestamp")
                r["tool"] = j.get("toolName") or j.get("surface") or ""
                r["pattern"] = j.get("matchedPattern")
                r["agent"] = j.get("agentName")
                raw = j.get("command") or j.get("path") or j.get("toolInputPreview") or j.get("target") or ""
                r["snippet"] = " ".join(str(raw).split())
                d = j.get("decidedBy") or {}
                k = d.get("kind")
                r["who"] = WHO.get(k, k or "")
                r["surface"] = j.get("surface") or d.get("surface")
                r["denial"] = j.get("denialReason") or d.get("reason")
                r["externalPaths"] = j.get("externalPaths") or []
    allr = list(recs.values())
    done = [r for r in allr if r.get("event") not in (None, "waiting", "open")]
    opens = [r for r in allr if r.get("event") in (None, "waiting", "open")]
    return done, opens, since


# The bare keys that are sugar for a read/write pair, in the package's
# normative member order (ADR 0013 §4).
FAMILIES = {
    "path": ("path_read", "path_write"),
    "external_directory": ("external_directory_read", "external_directory_write"),
}


def expand_home(pat):
    """`~`/`$HOME`/`${HOME}` prefix expansion, as the package's rule does."""
    home = os.path.expanduser("~")
    for token in ("~", "$HOME", "${HOME}"):
        if pat == token:
            return home
        if pat.startswith(token + "/"):
            return home + pat[len(token):]
    return pat


@lru_cache(maxsize=None)
def compile_pattern(pat):
    """The package's wildcard semantics: `*` is greedy across separators, `?`
    is exactly one character, and a trailing ` *` is optional (`"git *"`
    matches `git`)."""
    expanded = expand_home(pat)
    optional_tail = expanded.endswith(" *")
    if optional_tail:
        expanded = expanded[:-2]
    rx = ".*".join(
        re.escape(part).replace("\\?", ".") for part in expanded.split("*")
    )
    if optional_tail:
        rx += "( .*)?"
    return re.compile("^" + rx + "$", re.S)


def to_pattern_map(value):
    """A surface's value as {pattern: action}; a bare string means `{"*": v}`."""
    if isinstance(value, str):
        return {"*": value}
    if not isinstance(value, dict):
        return {}
    out = {}
    for pat, action in value.items():
        act = action if isinstance(action, str) else (action or {}).get("action")
        if act:
            out[pat] = act
    return out


def expanded_rule_lists(permission):
    """Surface -> ordered [(pattern, action)] as the package composes it.

    Mirrors `expandDirectionalSugar` (src/policy/normalize.ts): a bare family
    key's entries come FIRST, then the explicit directional entries, with a
    pattern the explicit key redefines emitted once at the explicit position —
    so last-match-wins always gives the explicit entry the final say.
    """
    surfaces = {}
    for family, members in FAMILIES.items():
        sugar = to_pattern_map(permission.get(family))
        for member in members:
            explicit = to_pattern_map(permission.get(member))
            merged = {p: a for p, a in sugar.items() if p not in explicit}
            merged.update(explicit)
            surfaces[member] = list(merged.items())
    for surface, value in permission.items():
        if surface not in surfaces:
            surfaces[surface] = list(to_pattern_map(value).items())
    return surfaces


def resolve_state(cfg, surfaces, surface, path):
    """(action, pattern) the package's evaluator returns for `path` on `surface`.

    `evaluate()` scans last-match-wins over the composed ruleset, whose first
    entry is the universal fallback — the root `"*"` key, or the built-in
    "ask" default when it is absent — and whose later entries are the queried
    surface's own rules in load order.
    """
    rules = list(surfaces.get(surface, ()))
    universal = cfg.get("*")
    if isinstance(universal, str):
        rules.insert(0, ("*", universal))
    path = expand_home(path)
    for pattern, action in reversed(rules):
        if compile_pattern(pattern).match(path):
            return action, pattern
    return "ask", None


def section_volume(done, opens, since, lines):
    lines.append(f"Decisions since {since} — {len(done)} resolved, {len(opens)} never resolved")
    ev = Counter(r["event"] for r in done)
    wh = Counter(r["who"] for r in done)
    for e, n in ev.most_common():
        lines.append(f"  {e}: {n}")
    lines.append("  decided by: " + ", ".join(f"{w} {n}" for w, n in wh.most_common()))
    if opens:
        lines.append(f"  ! {len(opens)} asks never resolved — check reviewer availability")


def section_dead_rules(cfg, done, lines):
    seen = {r["pattern"] for r in done if r.get("pattern")}
    dead = []
    for surface in ("bash", "path", "external_directory", "external_directory_read", "external_directory_write"):
        for pat, action in (cfg.get(surface) or {}).items():
            act = action if isinstance(action, str) else action.get("action")
            if pat == "*" or act == "ask":
                continue
            if pat not in seen:
                dead.append((surface, pat, act))
    lines.append(f"\nDead rules (no match in log — {len(dead)}):")
    lines += [f"  - {s}: {p} ({a})" for s, p, a in dead[:20]]
    if not dead:
        lines.append("  (none)")
    yolos = sum(1 for r in done if r["who"] == "yolo")
    if yolos and dead:
        lines.append(
            f"  note: yoloMode resolved {yolos} decisions at the '*' catch-all, so allow rules look dead"
            " even when commands ran — only dead DENY rules are prunable findings"
        )


def section_shadowed(cfg, lines):
    """Bare-family entries a directional rule shadows into inertness.

    A bare `path`/`external_directory` key is sugar: its entries are placed
    first at load, so an explicit directional catch-all (`"*": "ask"`) is
    evaluated after them and wins wherever its own pattern matches. The entry
    then decides nothing on that direction — the usual reason an allow that
    reads correctly in the file still prompts.
    """
    surfaces = expanded_rule_lists(cfg)
    inert = []
    for family, members in FAMILIES.items():
        for pattern, action in to_pattern_map(cfg.get(family)).items():
            if pattern == "*":
                continue
            witness = expand_home(pattern.replace("*", "x").replace("?", "x"))
            for member in members:
                decided, decider = resolve_state(cfg, surfaces, member, witness)
                if decider != pattern and decided != action:
                    inert.append((family, pattern, action, member, decider, decided))
    lines.append(f"\nShadowed entries (bare-family rule never decides — {len(inert)}):")
    lines += [
        f"  - {family}: {pat} ({act}) — {member} decides {decided}"
        f" via {decider or '(built-in default)'}"
        for family, pat, act, member, decider, decided in inert[:10]
    ]
    if not inert:
        lines.append("  (none)")


def section_hot(done, lines):
    hot = Counter(r["pattern"] for r in done if r.get("pattern") and r["pattern"] != "*")
    lines.append("\nHottest patterns:")
    entries = hot.most_common(10)
    lines += [f"  {n:4d}  {p}" for p, n in entries] or ["  (only the catch-all '*' matched)"]


def section_asks(done, cfg, lines):
    # Session-grant records: the runtime already covered the command, so the
    # record lists every external path the command touched and means a standing
    # grant applied — not that a dialog appeared. Live dialogs are the
    # `approved` records below; those name the deciding surface, but the
    # boundary gate logs no path for them, so "the config allows this yet the
    # gate asked" is not decidable from this log.
    grants = [r for r in done if r["event"] == "session_approved"]
    buckets = Counter()
    for r in grants:
        for p in r.get("externalPaths") or []:
            buckets["/".join(p.split("/")[:4]) or p] += 1
    lines.append(f"\nExternal-directory grants applied (session-covered): {len(grants)}")
    lines += [f"  {n:4d}  {k}" for k, n in buckets.most_common(8)]

    dialogs = [r for r in done if r["event"] == "approved" and r["who"] in ("you", "review")]
    if dialogs:
        by_surface = Counter(r.get("surface") or "(unrecorded)" for r in dialogs)
        lines.append(f"\nLive asks by deciding surface ({len(dialogs)}):")
        lines += [f"  {n:4d}  {s}" for s, n in by_surface.most_common()]

    # Only the deciding rule knows why the ask happened: a pattern that is not
    # the catch-all means a rule asked, which no allow of ours could have
    # covered. Anything the catch-all decided is a candidate for one.
    allow_prefixes = [
        p.rstrip("*")
        for p, a in to_pattern_map(cfg.get("bash")).items()
        if a == "allow"
    ]
    groups = Counter()
    examples = {}
    for r in dialogs:
        if not r.get("pattern"):
            continue
        s = r.get("snippet") or ""
        if not s or any(p and s.startswith(p) for p in allow_prefixes):
            continue
        key = " ".join(s.split()[:2])
        groups[key] += 1
        examples.setdefault(key, s)
    lines.append("\nRepeated asks worth an allow rule (bash):")
    rows = [(n, k) for k, n in groups.items() if n >= 2]
    lines += [
        f'  {n:4d}  "{k}*"  e.g. {examples[k][:70]}'
        for n, k in sorted(rows, reverse=True)[:10]
    ] or ["  (none)"]


def section_denials(done, lines):
    den = [r for r in done if r["event"] in ("denied", "blocked")]
    if not den:
        return
    lines.append("\nDenials/blocks:")
    dg = Counter(
        f"{r['who'] or '?'} · {r.get('pattern') or '—'}" + (f" · risk {r['risk']}" if r["risk"] else "")
        for r in den
    )
    lines += [f"  {n:4d}  {k}" for k, n in dg.most_common(8)]
    for r in den:
        if r["who"] == "review" and r.get("rationale"):
            lines.append(f"  review deny: {(r.get('snippet') or '')[:60]} — {(r['rationale'] or '')[:100]}")


def section_reviewer(done, lines):
    rev = [r for r in done if r["who"] == "review" or r.get("rationale")]
    if not rev:
        return
    risks = Counter(r["risk"] for r in rev if r["risk"])
    spread = ", ".join(f"{k} {n}" for k, n in sorted(risks.items())) or "none reported"
    lines.append(f"\nReviewer: {len(rev)} decisions (risk: {spread})")


def main():
    if not LOG.exists():
        sys.exit(f"no log at {LOG}")
    args = [a for a in sys.argv[1:]]
    show_all = "--all" in args
    args = [a for a in args if a != "--all"]
    mode = (args[0] if args else "all").lstrip("-")

    # Default window: decisions made under the CURRENT config. Its mtime is
    # the generation marker — any rewrite moves it, including a rewrite that
    # changes nothing, so the failure mode is fewer decisions reported, never
    # evidence from two configs mixed.
    window = None
    if not show_all:
        window = CONFIG.stat().st_mtime
    cfg = json.loads(Path(CONFIG).read_text()).get("permission", {})
    done, opens, since = load(window)
    lines = []
    if not done:
        print(
            f"No decisions since the config changed at "
            f"{datetime.fromtimestamp(window, timezone.utc).isoformat()}."
            " Use --all for the full log history.\n"
        )
        return
    if mode == "denied":
        section_denials(done, lines)
        lines = lines or ["No denials in this window."]
    elif mode == "review":
        section_reviewer(done, lines)
        lines = lines or ["No reviewer decisions in this window."]
    else:
        section_volume(done, opens, since, lines)
        section_dead_rules(cfg, done, lines)
        section_shadowed(cfg, lines)
        section_hot(done, lines)
        section_asks(done, cfg, lines)
        section_denials(done, lines)
        section_reviewer(done, lines)
    if not show_all:
        lines.append(
            f"(window: decisions since the config changed at "
            f"{datetime.fromtimestamp(window, timezone.utc).isoformat()}; --all for full history)"
        )
    print("\n".join(lines) + "\n", end="")


if __name__ == "__main__":
    main()
