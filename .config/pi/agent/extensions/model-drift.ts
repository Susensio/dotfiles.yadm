/**
 * model-drift — warn at startup about configured models that no longer resolve.
 *
 * A dead alias target fails its whole chain and a dead enabledModels entry is
 * dropped silently, which is the failure this catches: both are silent by
 * default and neither is visible until a turn falls through the chain.
 *
 * Tracking "models added since the last sync" used to live here, through
 * state/models-seen.txt. It is gone: the catalog gains models constantly and
 * most are never placed, so the nudge fired on churn, needed a machine-local
 * file rewritten in two places, and now duplicates what `pi-model-cost` lists
 * on demand — every Go model, priced, with the unplaced ones in the same table.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";

const CHECKED = Symbol.for("model-drift.checked");

function readJson(file: string): any {
	return JSON.parse(readFileSync(join(getAgentDir(), file), "utf8"));
}

function configuredRefs(): string[] {
	const aliases = readJson("model-alias.json");
	const refs: string[] = [];
	for (const value of Object.values<any>(aliases)) {
		if (Array.isArray(value)) refs.push(...value);
		else if (Array.isArray(value?.targets)) refs.push(...value.targets);
	}
	refs.push(...(readJson("settings.json").enabledModels ?? []));
	return [...new Set(refs)].filter((ref) => typeof ref === "string" && !ref.startsWith("alias/") && !ref.includes("*"));
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		const store = globalThis as Record<symbol, boolean>;
		if (store[CHECKED]) return;
		store[CHECKED] = true;
		let dead: string[];
		try {
			dead = configuredRefs().filter((ref) => {
				const slash = ref.indexOf("/");
				return slash < 0 || !ctx.modelRegistry.find(ref.slice(0, slash), ref.slice(slash + 1));
			});
		} catch {
			return;
		}
		if (dead.length === 0) return;
		ctx.ui.notify(`Configured models not in the catalog:\n${dead.join("\n")}\nRun /sync-models.`, "warning");
	});
}
