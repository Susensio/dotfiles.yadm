#!/usr/bin/env node
// Replace a package's declared entry with a prebuilt bundle, in place.
//
// Bundling is a post-install transform of node_modules, so it composes with the
// patch library by ordering: patches first, then this. A bundle therefore
// carries whatever the patches changed.
//
// Everything this writes lives in <pkg>/.pi-bundler/, so reverting restores the
// manifest and removes only that directory.
//
//   node bundle.mjs            build every package with verdict "bundle"
//   node bundle.mjs --only X   build one package
//   node bundle.mjs --revert   restore every package to its declared source
//
// The original manifest is kept beside the package so --revert never needs to
// guess, and a fresh install overwrites both, so the hook is idempotent.

import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import {
  esbuildArgs,
  findEsbuild,
  MODULES_DIR,
  NPM_DIR,
  PACKAGE_NAME,
  MARKER,
  STATE_DIR,
  VERDICTS_PATH,
  packageEntries,
  patchedPackages,
  screenAll,
} from "./lib.mjs";

const OUT = `${STATE_DIR}/bundle.mjs`;

const argv = process.argv.slice(2);
const revert = argv.includes("--revert");
// Postinstall mode: report only what changed, so a no-op install stays silent.
const quiet = argv.includes("--quiet");
const onlyIdx = argv.indexOf("--only");
const only = onlyIdx >= 0 ? argv[onlyIdx + 1] : null;

const esbuild = findEsbuild();
if (!esbuild && !revert) {
  console.error("bundle: esbuild not found. Set PI_BUNDLER_ESBUILD or put esbuild on PATH.");
  process.exit(2);
}
const verdicts = JSON.parse(readFileSync(VERDICTS_PATH, "utf8"));
const patched = patchedPackages();

// A postinstall run can race a manual one. Only tool-owned state is at stake,
// but a half-applied pair of writes is confusing to unwind by hand.
const LOCK = join(NPM_DIR, ".pi-bundler.lock");
const LOCK_STALE_MS = 10 * 60 * 1000;
function acquireLock() {
  try {
    mkdirSync(LOCK);
    writeFileSync(join(LOCK, "pid"), String(process.pid));
    return true;
  } catch {
    const age = Date.now() - (statSync(LOCK, { throwIfNoEntry: false })?.mtimeMs ?? 0);
    // A live holder is never preempted, however long it has been running.
    if (age < LOCK_STALE_MS || holderAlive()) return false;
    rmSync(LOCK, { recursive: true, force: true });
    mkdirSync(LOCK, { recursive: true });
    writeFileSync(join(LOCK, "pid"), String(process.pid));
    return true;
  }
}
function holderAlive() {
  try {
    const pid = Number(readFileSync(join(LOCK, "pid"), "utf8").trim());
    if (!pid) return false;
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}
function releaseLock() {
  rmSync(LOCK, { recursive: true, force: true });
}

// Every package under node_modules that carries our state dir, whether or not it
// still has a verdict: reverting must not depend on verdicts.json still naming it.
function statefulPackages() {
  // Nothing to sweep before pi has installed anything.
  if (!existsSync(MODULES_DIR)) return [];
  const names = [];
  for (const entry of readdirSync(MODULES_DIR, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith("@")) {
      for (const sub of readdirSync(join(MODULES_DIR, entry.name), { withFileTypes: true })) {
        if (sub.isDirectory()) names.push(`${entry.name}/${sub.name}`);
      }
    } else {
      names.push(entry.name);
    }
  }
  // Ownership, not the directory's name: a package that happens to ship a
  // .pi-bundler of its own is not ours to remove.
  return names.filter((n) => {
    const found = packageEntries(n);
    return found && (found.marker || found.bundled);
  });
}

function restore(name) {
  const found = packageEntries(name);
  if (!found) return [`${name.padEnd(40)} absent`, false];
  const pj = join(found.dir, "package.json");
  const backup = join(found.dir, STATE_DIR, "manifest.json.orig");
  // Manifest repointed but the pristine copy is gone. Report the dead end
  // rather than reporting success and leaving the bundle active.
  if (!existsSync(backup)) {
    return [
      `${name.padEnd(40)} ${found.bundled ? "STUCK (bundled, backup missing)" : "already source"}`,
      found.bundled,
    ];
  }
  renameSync(backup, pj);
  // Only ever remove a state dir this tool made: the marker, or a manifest that
  // points at our bundle, is the evidence of ownership.
  if (found.marker || found.bundled) rmSync(join(found.dir, STATE_DIR), { recursive: true, force: true });
  return [`${name.padEnd(40)} restored`, true];
}

function build(name, verdict) {
  if (patched.has(name)) return [`${name.padEnd(40)} REFUSED (patch target)`, true];
  const found = packageEntries(name);
  if (!found || found.entries.length === 0) return [`${name.padEnd(40)} skipped (no entry)`, false];

  // Bundling one entry leaves any sibling entry loading from source, which pi
  // would treat as two extensions; refuse rather than half-apply.
  if (found.manifest.length > 1) {
    return [`${name.padEnd(40)} REFUSED (${found.manifest.length} entries; bundler handles one)`, true];
  }

  const entry = found.entries[0];
  const pj = join(found.dir, "package.json");
  const stateDir = join(found.dir, STATE_DIR);
  const backup = join(stateDir, "manifest.json.orig");
  // Idempotent like apply.sh: a re-run must not bundle the bundle. The artifact
  // is checked too, so a manifest pointing at a bundle that was deleted does not
  // read as done while pi fails to load it.
  if (found.bundled && existsSync(join(found.dir, OUT))) {
    writeFileSync(join(stateDir, MARKER), "pi-bundler\n");
    return [`${name.padEnd(40)} already bundled`, false];
  }
  // The backup is written once per upstream install, so a rebuild cannot
  // overwrite the pristine manifest with a bundled one.
  mkdirSync(stateDir, { recursive: true });
  writeFileSync(join(stateDir, MARKER), "pi-bundler\n");
  if (!existsSync(backup)) writeFileSync(backup, readFileSync(pj));

  const outfile = join(found.dir, OUT);
  const externals = (verdict.externals ?? []).map((e) => `--external:${e}`);
  const r = spawnSync(
    esbuild,
    [...esbuildArgs(entry, outfile, join(stateDir, "metafile.json"), verdict.externals ?? [])],
    { encoding: "utf8", cwd: found.dir },
  );
  if (r.status !== 0) {
    writeFileSync(pj, readFileSync(backup));
    return [`${name.padEnd(40)} FAILED: ${(r.stderr || "").trim().split("\n")[0]}`, true];
  }

  const manifest = JSON.parse(readFileSync(backup, "utf8"));
  manifest.pi.extensions = [`./${OUT}`];
  writeFileSync(pj, JSON.stringify(manifest, null, 2) + "\n");
  const kb = Math.round(readFileSync(outfile).length / 1024);
  const ext = externals.length ? `, external ${verdict.externals.join(",")}` : "";
  return [`${name.padEnd(40)} bundled ${String(kb).padStart(4)} KB${ext}`, true];
}

if (!acquireLock()) {
  console.error("bundle: another run holds " + LOCK + "; skipping");
  process.exit(0);
}
process.on("exit", releaseLock);

// Verdict keys become path components under node_modules; validate before any
// filesystem mutation rather than trusting a hand-edited file.
for (const name of Object.keys(verdicts)) {
  if (!PACKAGE_NAME.test(name)) {
    console.error(`bundle: refusing verdict key that is not a package name: ${JSON.stringify(name)}`);
    process.exit(2);
  }
}

// The gate runs here rather than in run.sh, so it cannot be skipped by invoking
// this file directly and the graph cannot change between screening and building.
// Revert never screens: undoing must not depend on esbuild or on a passing gate.
function screenNow() {
  const { report, problems } = screenAll(esbuild);
  if (problems.length > 0) {
    console.error(`bundle: ${problems.length} package(s) need a verdict in verdicts.json: ${problems.join(", ")}`);
    console.error("bundle: screen refused; leaving node_modules alone; run `node screen.mjs` for details");
    process.exit(0);
  }
  return report;
}

const names = revert
  ? [...new Set([...Object.keys(verdicts), ...statefulPackages()])]
  : // The report decides, not verdicts.json: a package with no hazard needs no
    // verdict, and would otherwise be screened, approved, and then never built.
    Object.entries(screenNow())
    .filter(([, r]) => r.decision === "bundle")
    .map(([name]) => name);

for (const name of names) {
  if (only && name !== only) continue;
  if (revert) {
    const [line, changed] = restore(name);
    if (!quiet || changed) console.log(line);
    continue;
  }
  const [line, changed] = build(name, verdicts[name] ?? {});
  if (!quiet || changed) console.log(line);
}

// A bundle built under an earlier screen must not outlive the screen refusing it.
if (!revert) {
  for (const name of statefulPackages()) {
    if (names.includes(name) || (only && name !== only)) continue;
    const [line, changed] = restore(name);
    if (!quiet || changed) console.log(line);
  }
}

if (only && !revert && !names.includes(only)) {
  console.error(`bundle: ${only} is not bundleable per the screen; run \`node screen.mjs\` for why`);
  process.exit(1);
}

if (!only && !revert && !quiet) {
  console.log(`\nrun \`node screen.mjs\` to re-screen; bundles live in each package's ${OUT}`);
}
