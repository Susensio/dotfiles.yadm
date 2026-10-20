/**
 * patch-drift — repair a local patch that is not in effect, and say so.
 *
 * `pi install`/`pi update` run `npm install <spec>`, which skips the project's
 * postinstall, so an update reverts patched files with nothing to reapply them.
 * Reapplying here, then rebuilding the bundles that carry the patched source,
 * closes that gap; the extensions are already loaded, so the repair takes effect
 * on /reload. A patch that no longer applies cleanly is reported instead.
 */

import { execFile, execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { promisify } from "node:util";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";

const run = promisify(execFile);
const PATCHES_DIR = join(getAgentDir(), "patches");
const BUNDLER = join(getAgentDir(), "bundler", "run.sh");
const CHECKED = Symbol.for("patch-drift.checked");

function findDrift(): string[] {
	const problems: string[] = [];
	for (const entry of readdirSync(PATCHES_DIR, { withFileTypes: true })) {
		if (!entry.isDirectory()) continue;
		const dir = join(PATCHES_DIR, entry.name);
		if (!existsSync(join(dir, "target")) || !existsSync(join(dir, "marker"))) continue;
		const target = readFileSync(join(dir, "target"), "utf8").trim();
		const marker = readFileSync(join(dir, "marker"), "utf8").trim();
		if (!existsSync(target)) {
			problems.push(`${entry.name}: target missing`);
			continue;
		}
		// grep, not includes(): apply.sh matches markers as grep patterns.
		try {
			execFileSync("grep", ["-q", "--", marker, target]);
		} catch {
			problems.push(`${entry.name}: not applied`);
		}
	}
	return problems;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		const store = globalThis as Record<symbol, boolean>;
		if (store[CHECKED]) return;
		store[CHECKED] = true;
		if (findDrift().length === 0) return;
		// Patches first so a bundle built afterwards carries what they changed.
		for (const script of [join(PATCHES_DIR, "reapply-all.sh"), BUNDLER]) {
			if (!existsSync(script)) continue;
			try {
				await run("sh", [script], { timeout: 120_000 });
			} catch {
				// The scripts never fail; a throw means the timeout or a missing sh.
			}
		}
		const problems = findDrift();
		if (problems.length === 0) {
			ctx.ui.notify("Local patches were reverted by a package update and are reapplied. Run /reload to load them.", "warning");
			return;
		}
		ctx.ui.notify(
			`Local patches not in effect (run ${join(PATCHES_DIR, "apply.sh")} <name> for details):\n${problems.join("\n")}`,
			"error",
		);
	});
}
