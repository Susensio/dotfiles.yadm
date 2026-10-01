/**
 * tui-output-guard — keep extensions' stray console/stderr writes off the TUI.
 *
 * Extensions run in pi's process, so console.* and process.stderr.write reach the
 * terminal around the differential renderer and land in the editor until a redraw
 * (earendil-works/pi#10002). While a TUI session runs, those writes go to a log and
 * a notification instead. process.stdout stays untouched: the renderer draws there.
 * Drop this when earendil-works/pi#10050 ships.
 */

import { appendFileSync } from "node:fs";
import { join } from "node:path";
import { format } from "node:util";
import { type ExtensionAPI, type ExtensionContext, getAgentDir } from "@earendil-works/pi-coding-agent";

const LOG_PATH = join(getAgentDir(), "tui-captured-output.log");
const CONSOLE_METHODS = ["log", "info", "warn", "error", "debug", "trace"] as const;

type Guard = {
	ui: ExtensionContext["ui"];
	restore: () => void;
};

// Shared across every copy in the process (subagents load their own) and across /reload.
const KEY = Symbol.for("tui-output-guard");
const store = globalThis as Record<symbol, Guard | undefined>;

function capture(text: string): void {
	const guard = store[KEY];
	if (!guard || text.trim().length === 0) return;
	try {
		appendFileSync(LOG_PATH, `${new Date().toISOString()} ${text.endsWith("\n") ? text : `${text}\n`}`);
	} catch {}
	const firstLine = text.trim().split("\n", 1)[0].slice(0, 200);
	guard.ui.notify(`Stray output (see ${LOG_PATH}): ${firstLine}`, "warning");
}

function install(ui: ExtensionContext["ui"]): void {
	const existing = store[KEY];
	if (existing) {
		existing.ui = ui;
		return;
	}
	const originalConsole = CONSOLE_METHODS.map((m) => [m, console[m]] as const);
	const originalStderrWrite = process.stderr.write;
	let capturing = false;
	const guarded = (text: string) => {
		// A notify that itself writes to stderr must not recurse.
		if (capturing) return;
		capturing = true;
		try {
			capture(text);
		} finally {
			capturing = false;
		}
	};
	for (const m of CONSOLE_METHODS) console[m] = (...args: unknown[]) => guarded(format(...args));
	process.stderr.write = ((chunk: unknown, encodingOrCallback?: unknown, callback?: unknown) => {
		guarded(typeof chunk === "string" ? chunk : Buffer.from(chunk as Uint8Array).toString());
		const done = typeof encodingOrCallback === "function" ? encodingOrCallback : callback;
		if (typeof done === "function") queueMicrotask(() => (done as () => void)());
		return true;
	}) as typeof process.stderr.write;
	store[KEY] = {
		ui,
		restore: () => {
			for (const [m, fn] of originalConsole) console[m] = fn;
			process.stderr.write = originalStderrWrite;
		},
	};
}

function uninstall(ui: ExtensionContext["ui"]): void {
	const guard = store[KEY];
	if (!guard || guard.ui !== ui) return;
	guard.restore();
	store[KEY] = undefined;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		install(ctx.ui);
	});
	pi.on("session_shutdown", (_event, ctx) => {
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		uninstall(ctx.ui);
	});
}
