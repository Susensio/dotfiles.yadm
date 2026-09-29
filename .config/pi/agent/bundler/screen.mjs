#!/usr/bin/env node
// Gate screen: decides which pi extensions may be replaced by a prebuilt bundle.
//
// Four gates, in order:
//   P  a package named in patches/*/target is refused outright
//   A  the package must bundle at all (proof: esbuild resolves the graph or it does not)
//   C  the built bundle must not deadlock (proof: no async inits that await each other)
//   B  every asset-locating construct in the inlined graph is listed for judgement
//
// The screen never decides a hazard for you. It fails closed instead: a package
// with a hazard and no recorded verdict in verdicts.json is an error, so the
// answer stays deterministic and reviewable.
//
// A package with no hazard, that esbuild resolves, and that no patch targets
// needs no verdict at all: there is nothing to judge, and requiring one would
// make `pi install` fail on every new package.

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { relative } from "node:path";
import {
  AGENT_DIR,
  analyze,
  enabledPackages,
  findEsbuild,
  isInstalled,
  MODULES_DIR,
  packageEntries,
  patchedPackages,
  scanSource,
} from "./lib.mjs";

const VERDICTS = new URL("./verdicts.json", import.meta.url).pathname;
const REPORT = new URL("./screen-report.json", import.meta.url).pathname;

// Whose code a hit lives in is context for the reviewer, not a gate: inlined
// dependency code is relocated by bundling exactly like the package's own.
function isOwnSource(input, pkgDir) {
  if (!input.startsWith(pkgDir + "/")) return false;
  return !input.slice(pkgDir.length).includes("/node_modules/");
}

function label(input) {
  return input.startsWith(MODULES_DIR + "/") ? input.slice(MODULES_DIR.length + 1) : input;
}

// Occurrence counts belong in the key: a second hit of a known kind in a known
// file is new evidence, and a set of file:kind alone would not notice it.
function hitKinds(hits) {
  const counts = new Map();
  for (const h of hits) {
    const k = `${h.file}:${h.kind}`;
    counts.set(k, (counts.get(k) ?? 0) + (h.count ?? 1));
  }
  return [...counts].map(([k, n]) => `${k}×${n}`);
}

const quiet = process.argv.includes("--quiet");

function main() {
  const esbuild = findEsbuild();
  if (!esbuild) {
    console.error("screen: esbuild not found. Set PI_BUNDLER_ESBUILD or put esbuild on PATH.");
    process.exit(2);
  }

  const verdicts = existsSync(VERDICTS) ? JSON.parse(readFileSync(VERDICTS, "utf8")) : {};
  const patched = patchedPackages();
  const report = {};
  const problems = [];

  for (const name of enabledPackages()) {
    const found = packageEntries(name);
    if (!found) {
      report[name] = { gate: "absent", detail: "not installed" };
      continue;
    }
    if (patched.has(name)) {
      report[name] = { gate: "P", decision: "skip", detail: "patch target (patches/*/target)" };
      continue;
    }
    if (found.entries.length === 0) {
      report[name] = { gate: "A", decision: "skip", detail: "manifest declares no existing entry" };
      continue;
    }

    const entry = found.entries[0];
    const verdict = verdicts[name];
    // The same externals the bundle would use, so the screen measures the graph
    // that actually ships.
    const a = analyze(esbuild, entry, verdict?.externals ?? []);
    if (!a.ok) {
      report[name] = { gate: "A", decision: "skip", detail: a.error };
      continue;
    }
    // Ahead of the verdict check: a recorded verdict cannot approve a deadlock.
    if (a.cycles.length > 0) {
      const detail = `awaited init cycle: ${a.cycles.map((c) => c.join(" <-> ")).join("; ")}`;
      report[name] = { gate: "C", decision: "skip", modules: a.inputs.length, detail };
      continue;
    }

    const hits = [];
    for (const input of a.inputs) {
      // Built JS that ships as-is is still inlined; scan everything that is.
      let src;
      try {
        src = readFileSync(input, "utf8");
      } catch {
        continue;
      }
      for (const h of scanSource(src)) {
        hits.push({ file: label(input), own: isOwnSource(input, found.dir), ...h });
      }
    }

    const gate = hits.length === 0 ? "clean" : "B";
    const kinds = hitKinds(hits);

    if (hits.length > 0 && !verdict) {
      problems.push(name);
    }
    if (verdict?.decision === "bundle") {
      const recorded = new Set(verdict.reviewedKinds ?? []);
      const novel = kinds.filter((k) => !recorded.has(k));
      if (novel.length > 0) problems.push(name);
      // A hazard can be inert only because something else is absent. Recording
      // that absence mechanically beats a comment saying so.
      for (const need of verdict.reopenIf?.installed ?? []) {
        if (isInstalled(need)) problems.push(name);
      }
    }

    report[name] = {
      gate,
      modules: a.inputs.length,
      decision: verdict?.decision ?? (hits.length === 0 ? "bundle" : "unjudged"),
      reason: verdict?.reason,
      hits,
      ownHits: hits.filter((h) => h.own).length,
    };
  }

  writeFileSync(REPORT, JSON.stringify(report, null, 2) + "\n");

  if (!quiet) {
    for (const [name, r] of Object.entries(report)) {
      const gate = r.gate.padEnd(6);
      const mods = r.modules === undefined ? "" : `${r.modules} mod`;
      console.log(
        `${name.padEnd(40)} ${gate} ${String(r.decision).padEnd(9)} ${mods.padStart(8)}  ${r.reason ?? r.detail ?? ""}`,
      );
      if (!r.hits?.length) continue;
      for (const h of r.hits.slice(0, 4)) {
        console.log(`      L${h.line} ${h.kind}${h.note ? ` — ${h.note}` : ""}  [${h.own ? "own" : "dep"}]`);
        console.log(`           ${h.file}: ${h.text}`);
      }
      if (r.hits.length > 4) console.log(`      … ${r.hits.length - 4} more`);
    }
    console.log(`\nscreen report: ${relative(AGENT_DIR, REPORT)}`);
  }
  if (problems.length > 0) {
    console.error(
      `screen: ${problems.length} package(s) need a verdict in verdicts.json: ${[...new Set(problems)].join(", ")}`,
    );
    process.exit(1);
  }
  process.exit(0);
}

main();
