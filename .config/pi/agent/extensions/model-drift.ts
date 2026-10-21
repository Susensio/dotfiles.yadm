/**
 * model-drift — warn at startup about configured models that no longer resolve
 * and about models the config's providers added since the last /sync-models.
 *
 * A dead alias target fails its whole chain and a dead enabledModels entry is
 * dropped silently. New models are compared against state/models-seen.txt,
 * which /sync-models rewrites; the first run seeds it without a warning.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";

const SEEN = join(getAgentDir(), "state", "models-seen.txt");
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
		const lines: string[] = [];
		try {
			const refs = configuredRefs();
			const dead = refs.filter((ref) => {
				const slash = ref.indexOf("/");
				return slash < 0 || !ctx.modelRegistry.find(ref.slice(0, slash), ref.slice(slash + 1));
			});
			if (dead.length > 0) lines.push("Configured models not in the catalog:", ...dead);

			const current = ctx.modelRegistry.getAvailable().map((m) => `${m.provider}/${m.id}`);
			if (!existsSync(SEEN)) {
				mkdirSync(dirname(SEEN), { recursive: true });
				writeFileSync(SEEN, `${current.sort().join("\n")}\n`);
			} else {
				const seen = new Set(readFileSync(SEEN, "utf8").split("\n"));
				const providers = new Set(refs.map((ref) => ref.slice(0, ref.indexOf("/"))));
				providers.delete("alias");
				const added = current.filter((id) => providers.has(id.slice(0, id.indexOf("/"))) && !seen.has(id));
				if (added.length > 0) lines.push("New models since the last sync:", ...added);
			}
		} catch {
			return;
		}
		if (lines.length === 0) return;
		ctx.ui.notify(`${lines.join("\n")}\nRun /sync-models.`, "warning");
	});
}
