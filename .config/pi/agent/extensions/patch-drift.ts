/**
 * patch-drift — warn at startup when a local patch is not in effect.
 *
 * reapply-all.sh never fails an install, so a patch that stopped applying after a
 * package update otherwise goes unnoticed until its behavior is missed.
 */

import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";

const PATCHES_DIR = join(getAgentDir(), "patches");
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
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		const store = globalThis as Record<symbol, boolean>;
		if (store[CHECKED]) return;
		store[CHECKED] = true;
		const problems = findDrift();
		if (problems.length === 0) return;
		ctx.ui.notify(
			`Local patches not in effect (run ${join(PATCHES_DIR, "apply.sh")} <name> for details):\n${problems.join("\n")}`,
			"error",
		);
	});
}
