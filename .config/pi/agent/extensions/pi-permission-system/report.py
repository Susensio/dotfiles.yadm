#!/usr/bin/env python3
"""Report on pi-permission-system's decision log vs its config.json.

Standalone, stdlib-only: the deterministic parsing lives here so the agent
(or a terminal) only reads the output. The heavy lifting — correlation,
grouping, rule evaluation — is not something a model should redo each time.

Usage: report.py [denied|review]
  (no arg)  full optimization report
  denied    only the denial clusters section
  review    only the reviewer section
"""

import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOG = HERE / "logs" / "pi-permission-system-permission-review.jsonl"
CONFIG = HERE / "config.json"

WHO = {
    "yolo": "yolo", "user": "you", "rule": "rule", "session_approval": "session",
    "authorizer": "review", "unavailable": "no-auth", "infrastructure_read": "infra",
}
TERMINAL = {"auto_approved", "approved", "session_approved", "infrastructure_auto_allowed", "denied", "blocked"}


def load():
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
            if since is None:
                since = j.get("timestamp")
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
                k = (j.get("decidedBy") or {}).get("kind")
                r["who"] = WHO.get(k, k or "")
                r["denial"] = j.get("denialReason") or (j.get("decidedBy") or {}).get("reason")
                r["externalPaths"] = j.get("externalPaths") or []
    allr = list(recs.values())
    done = [r for r in allr if r.get("event") not in (None, "waiting", "open")]
    opens = [r for r in allr if r.get("event") in (None, "waiting", "open")]
    return done, opens, since


def pattern_regex(pat):
    """Approximate the package's wildcard semantics: `~` expands, `*` is greedy."""
    p = os.path.expanduser(pat)
    return re.compile("^" + ".*".join(re.escape(part) for part in p.split("*")) + "$")


def evaluate_config_rules(config):
    """Which configured non-ask patterns would allow a given absolute path
    (external_directory + read/write members)? Mirrors the package's
    last-match-wins per surface; good enough to flag inert allows."""
    compiled = []
    for surface in ("external_directory", "external_directory_read", "external_directory_write"):
        for pat, action in (config.get(surface) or {}).items():
            act = action if isinstance(action, str) else action.get("action")
            compiled.append((surface, pat, act, pattern_regex(pat)))
    return compiled


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


def section_hot(done, lines):
    hot = Counter(r["pattern"] for r in done if r.get("pattern") and r["pattern"] != "*")
    lines.append("\nHottest patterns:")
    entries = hot.most_common(10)
    lines += [f"  {n:4d}  {p}" for p, n in entries] or ["  (only the catch-all '*' matched)"]


def section_asks(done, cfg, lines):
    asks = [r for r in done if (r["event"] == "approved" and r["who"] == "you") or r["event"] == "session_approved"]
    path_grants = [r for r in asks if not r.get("pattern")]
    bash_asks = [r for r in asks if r.get("pattern")]

    # Where do the external-directory grants point? Bucket by first 3 components.
    buckets = Counter()
    for r in path_grants:
        for p in r.get("externalPaths") or []:
            buckets["/".join(p.split("/")[:4]) or p] += 1
    lines.append(f"\nExternal-directory grants (session-approved): {len(path_grants)}")
    lines += [f"  {n:4d}  {k}" for k, n in buckets.most_common(8)]

    # Flag config allows that the runtime ignored: a path covered by an
    # external_directory allow that still went through a dialog.
    compiled = evaluate_config_rules(cfg)
    prevented = Counter()
    for r in path_grants:
        for p in r.get("externalPaths") or []:
            hit = any(
                rx.match(os.path.expanduser(p)) and act == "allow"
                for _, pat, act, rx in compiled
            )
            if hit:
                parts = os.path.expanduser(p).split("/")[1:3]
                prevented["/".join(parts)] += 1
    if prevented:
        lines.append("  ! config allows MATCHED these paths but the gate asked anyway (upstream bug candidate):")
        lines += [f"    {n:4d}  {k}/*" for k, n in prevented.most_common(6)]

    allow_prefixes = [
        p.rstrip("*")
        for p, a in (cfg.get("bash") or {}).items()
        if (a if isinstance(a, str) else a.get("action")) == "allow"
    ]
    groups = Counter()
    examples = {}
    for r in [r for r in asks if r.get("pattern")]:
        s = r.get("snippet") or ""
        if not s or any(p and s.startswith(p) for p in allow_prefixes):
            continue
        key = " ".join(s.split()[:2])
        groups[key] += 1
        examples.setdefault(key, s)
    lines.append("\nRepeated asks worth an allow rule (bash, human-resolved):")
    rows = [(n, k) for k, n in groups.items() if n >= 2]
    lines += [f'  {n:4d}  "{k}*"  e.g. {examples[k][:70]}' for n, k in sorted(rows, reverse=True)[:10]] or ["  (none)"]


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
    cfg = json.loads(Path(CONFIG).read_text()).get("permission", {})
    done, opens, since = load()
    mode = (sys.argv[1] if len(sys.argv) > 1 else "all").lstrip("-")
    lines = []
    if mode == "denied":
        section_denials(done, lines)
    elif mode == "review":
        section_reviewer(done, lines)
    else:
        section_volume(done, opens, since, lines)
        section_dead_rules(cfg, done, lines)
        section_hot(done, lines)
        section_asks(done, cfg, lines)
        section_denials(done, lines)
        section_reviewer(done, lines)
    print("\n".join(lines) + "\n", end="")


if __name__ == "__main__":
    main()
