#!/usr/bin/env node
// Repeatable startup benchmark. Run before and after bundling to compare.
//
//   node benchmark.mjs [runs]        default 5 measured runs, after 1 warmup
//
// Uses pi's own PI_TIMING profiler in non-interactive mode, so the numbers come
// from pi rather than from wall-clock around a TUI. The warmup run matters: a
// freshly built bundle has no jiti cache entry yet, and that one cold import
// would otherwise land in the sample.

import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";

const RUNS = Number(process.argv[2] ?? 5);
const TMP = "/tmp/pi-benchmark-timing.txt";

function once() {
  const start = Date.now();
  const r = spawnSync(
    "pi",
    ["--no-session", "-p", ""],
    { encoding: "utf8", env: { ...process.env, PI_TIMING: "1" }, stdio: ["ignore", "ignore", "pipe"] },
  );
  const wall = Date.now() - start;
  const err = r.stderr ?? "";
  writeFileSync(TMP, err);
  const section = (name) => {
    const m = err.match(new RegExp(`Startup Timings: ${name} ---([\\s\\S]*?)-----`));
    const t = m?.[1].match(/TOTAL:\s*(\d+)ms/);
    return t ? Number(t[1]) : null;
  };
  const main = section("main");
  const extensions = section("extensions");
  // A missing section means pi's output did not match, not that startup was
  // free; medians over nulls would silently report a faster machine.
  if (main === null || extensions === null) {
    throw new Error(
      `no startup timings in pi's output (exit ${r.status}); tail of stderr:\n${err.split("\n").slice(-6).join("\n")}`,
    );
  }
  return { wall, main, extensions };
}

function median(xs) {
  const s = [...xs].sort((a, b) => a - b);
  return s.length % 2 ? s[(s.length - 1) / 2] : Math.round((s[s.length / 2 - 1] + s[s.length / 2]) / 2);
}

process.stdout.write("warmup… ");
const warm = once();
console.log(`${warm.main}ms main / ${warm.extensions}ms extensions`);

const samples = [];
for (let i = 0; i < RUNS; i++) {
  process.stdout.write(`run ${i + 1}/${RUNS}… `);
  const s = once();
  console.log(`${s.main}ms main, ${s.extensions}ms extensions, ${s.wall}ms wall`);
  samples.push(s);
}

const med = (k) => median(samples.map((s) => s[k]));
console.log(`\nmedian over ${RUNS} runs: ${med("main")}ms main, ${med("extensions")}ms extensions, ${med("wall")}ms wall`);
console.log(`per-extension detail from the last run is in ${TMP}`);
