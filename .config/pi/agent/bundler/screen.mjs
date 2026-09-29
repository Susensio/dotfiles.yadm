#!/usr/bin/env node
// Gate screen: shows which pi extensions may be replaced by a prebuilt bundle.
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
//
// This is the human view of screenAll(); bundle.mjs calls it in-process, so
// nothing is written to disk.

import { findEsbuild, screenAll } from "./lib.mjs";

const esbuild = findEsbuild();
if (!esbuild) {
  console.error("screen: esbuild not found. Set PI_BUNDLER_ESBUILD or put esbuild on PATH.");
  process.exit(2);
}

const { report, problems } = screenAll(esbuild);

for (const [name, r] of Object.entries(report)) {
  const mods = r.modules === undefined ? "" : `${r.modules} mod`;
  console.log(
    `${name.padEnd(40)} ${r.gate.padEnd(6)} ${String(r.decision).padEnd(9)} ${mods.padStart(8)}  ${r.reason ?? r.detail ?? ""}`,
  );
  if (!r.hits?.length) continue;
  for (const h of r.hits.slice(0, 4)) {
    console.log(`      L${h.line} ${h.kind}${h.note ? ` — ${h.note}` : ""}  [${h.own ? "own" : "dep"}]`);
    console.log(`           ${h.file}: ${h.text}`);
  }
  if (r.hits.length > 4) console.log(`      … ${r.hits.length - 4} more`);
  // Ready to paste into the verdict once the new hits are judged.
  if (problems.includes(name)) console.log(`      reviewedKinds: ${JSON.stringify(r.kinds)}`);
}

if (problems.length > 0) {
  console.error(`screen: ${problems.length} package(s) need a verdict in verdicts.json: ${problems.join(", ")}`);
  process.exit(1);
}
