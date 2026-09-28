// Shared helpers for screen.mjs and bundle.mjs.
// The screen and the bundle must use identical esbuild arguments, including any
// per-verdict externals, or the screen would be measuring a different graph than
// the one that ships.
//
// "Clean" means "none of the constructs below are present", not "provably safe":
// a hazard reached through an alias (`new (await import("worker_threads")).Worker`,
// a pooled worker library) is outside what this scan can see.

import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { isAbsolute, join } from "node:path";

export const AGENT_DIR = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".config/pi/agent");
export const NPM_DIR = join(AGENT_DIR, "npm");
export const MODULES_DIR = join(NPM_DIR, "node_modules");
export const PATCH_DIR = join(AGENT_DIR, "patches");
// Ours, and only ours: upstream packages already ship a dist/ of their own
// (pi-usage declares ./dist/index.ts as its entry), so reverting must never
// remove a directory this tool did not create.
export const STATE_DIR = ".pi-bundler";
// Written into the state dir so a revert can tell our directory from one an
// upstream package happened to ship under the same name.
export const MARKER = "owner";
// Written by screen.mjs; read by bundle.mjs, which runs the screen itself so the
// gate cannot be skipped and the graph cannot change between the two.
export const REPORT_PATH = new URL("./screen-report.json", import.meta.url).pathname;

// Pi supplies these to extensions as virtual modules; they must never be inlined.
export const ESBUILD_EXTERNALS = ["--external:@earendil-works/*", "--external:@mariozechner/*"];

export function esbuildArgs(entry, outfile, metafile, externals = []) {
  return [
    entry,
    "--bundle",
    "--format=esm",
    "--platform=node",
    "--target=node22",
    `--outfile=${outfile}`,
    `--metafile=${metafile}`,
    "--log-level=error",
    ...ESBUILD_EXTERNALS,
    ...externals.map((e) => `--external:${e}`),
  ];
}

// verdicts.json keys become path components under node_modules, so they are
// validated before any filesystem mutation rather than trusted.
export const PACKAGE_NAME = /^(@[a-z0-9-~][a-z0-9-._~]*\/)?[a-z0-9-~][a-z0-9-._~]*$/i;

export function isInstalled(name) {
  return statSync(join(MODULES_DIR, name), { throwIfNoEntry: false })?.isDirectory() === true;
}

// esbuild is not installed by pi, so resolution is explicit rather than assumed.
export function findEsbuild() {
  const candidates = [
    process.env.PI_BUNDLER_ESBUILD,
    join(homedir(), "src/pi-automode/node_modules/.bin/esbuild"),
  ].filter(Boolean);
  for (const c of candidates) if (existsSync(c)) return c;
  const which = spawnSync("sh", ["-c", "command -v esbuild"], { encoding: "utf8" });
  if (which.status === 0 && which.stdout.trim()) return which.stdout.trim();
  return null;
}

export function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

// Packages pi actually loads: settings.json is authoritative, not the node_modules listing.
// A version or range suffix is stripped, because pi resolves the installed path
// from the name alone.
export function enabledPackages() {
  const settings = readJson(join(AGENT_DIR, "settings.json"));
  const out = [];
  for (const p of settings.packages ?? []) {
    const source = typeof p === "string" ? p : p.source;
    if (source.startsWith("npm:")) out.push(source.slice(4).replace(/@[^@/]*$/, ""));
  }
  return out;
}

// Resolve every extension entry a package declares, mirroring pi's own manifest read.
// Once bundled, the installed manifest names our artifact instead; the screen must
// judge the pristine graph and a rebuild must start from it, so that copy wins
// whenever it exists.
export function packageEntries(name) {
  const base = join(MODULES_DIR, name);
  if (!statSync(base, { throwIfNoEntry: false })?.isDirectory()) return null;
  const pj = join(base, "package.json");
  if (!existsSync(pj)) return null;
  const current = readJson(pj).pi?.extensions ?? [];
  const pristinePath = join(base, STATE_DIR, "manifest.json.orig");
  const manifest = existsSync(pristinePath) ? readJson(pristinePath).pi?.extensions ?? [] : current;
  const entries = manifest
    .map((rel) => join(base, rel.replace(/^\.\//, "")))
    .filter((p) => existsSync(p));
  return {
    dir: base,
    manifest,
    current,
    bundled: current.some((e) => e.includes(STATE_DIR)),
    marker: existsSync(join(base, STATE_DIR, MARKER)),
    pristinePath,
    entries,
  };
}

// Any package named by a patch target is off limits: a bundle would shadow the
// patched source and the patch would land in a file nobody loads.
export function patchedPackages() {
  const names = new Set();
  if (!existsSync(PATCH_DIR)) return names;
  for (const dir of readdirSync(PATCH_DIR)) {
    const target = join(PATCH_DIR, dir, "target");
    if (!existsSync(target)) continue;
    const files = readFileSync(target, "utf8").trim().split("\n");
    for (const file of files) {
      const m = file.match(/node_modules\/(@[^/]+\/[^/]+|[^@/][^/]*)\//);
      if (m) names.add(m[1]);
    }
  }
  return names;
}

export const HAZARDS = [
  { kind: "import.meta.url", re: /\bimport\.meta\.url\b/ },
  { kind: "import.meta.dirname/filename", re: /\bimport\.meta\.(dirname|filename)\b/ },
  { kind: "__dirname/__filename", re: /\b(__dirname|__filename)\b/ },
  { kind: "createRequire", re: /\bcreateRequire\s*\(/ },
  // Quoted and terminated, so "`.node-version`" is not mistaken for an addon.
  { kind: "asset: .wasm", re: /["'`][^"'`]*\.wasm["'`]/ },
  { kind: "asset: .node", re: /["'`][^"'`]*\.node["'`]/ },
  { kind: "new Worker", re: /new\s+Worker\s*\(/ },
];

// A bare package specifier still resolves upward from <pkg>/dist/, so only
// path-shaped arguments make these calls bundling-relative.
export function classifyDynamicCall(line) {
  const m = line.match(/\b(require|import)\s*\(\s*(["'`])([^"'`]*)\2/);
  if (!m) return null;
  const spec = m[3];
  if (spec.startsWith(".") || spec.startsWith("/")) return "path (breaks)";
  return "bare specifier (survives)";
}

export function scanSource(src) {
  const hits = [];
  src.split("\n").forEach((line, i) => {
    // Comments are not executable, and minified bundles carry prose in them.
    const t = line.trim();
    if (t.startsWith("//") || t.startsWith("*") || t.startsWith("/*")) return;
    for (const h of HAZARDS) {
      // Counted per occurrence, not per line: a minified dependency is one long
      // line, and a second occurrence there is new evidence.
      const n = line.match(new RegExp(h.re.source, "g"))?.length ?? 0;
      if (n > 0) hits.push({ line: i + 1, kind: h.kind, count: n, text: t.slice(0, 140) });
    }
    if (/\b(require|import)\s*\(\s*[^"'`)\s]/.test(line)) {
      hits.push({
        line: i + 1,
        kind: "dynamic require/import",
        text: line.trim().slice(0, 140),
        note: classifyDynamicCall(line) ?? "non-literal specifier (unresolvable at bundle time)",
      });
    }
  });
  return hits;
}

// Build the graph once, for both the screen and the bundle.
export function analyze(esbuild, entry, externals = []) {
  // Probe output goes to a temp dir: it is ours, but node_modules is not the
  // place to leave it.
  const dir = mkdtempSync(join(tmpdir(), "pi-bundler-"));
  const out = join(dir, "probe.mjs");
  const meta = join(dir, "probe.json");
  // Fixed cwd so metafile input paths resolve deterministically.
  const r = spawnSync(esbuild, esbuildArgs(entry, out, meta, externals), {
    encoding: "utf8",
    cwd: MODULES_DIR,
  });
  if (r.status !== 0) {
    rmSync(dir, { recursive: true, force: true });
    return { ok: false, error: (r.stderr || r.stdout || "").trim().split("\n").slice(0, 4).join("\n") };
  }
  const inputs = Object.keys(readJson(meta).inputs).map((p) =>
    isAbsolute(p) ? p : join(MODULES_DIR, p),
  );
  rmSync(dir, { recursive: true, force: true });
  return { ok: true, inputs, probe: out, meta };
}

export { execFileSync };
