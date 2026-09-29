// Shows running top-level Pi subagents beside herdr's agent name.
//
// herdr-agent-state.ts (installed by `herdr integration install pi`, and
// overwritten on every herdr update) owns the pane's lifecycle state. When the
// parent settles it reports idle, so a pane with subagents still running reads
// as idle. It has no supported input for extra working activity, and a second
// `pane.report_agent` source competes with it rather than composing — so this
// extension reports display-only metadata instead and leaves that state alone.
// The "idle plus dots" a user sees is the accepted trade; see ADR-0074.
//
// Keep this file beside herdr-agent-state.ts — it survives
// `herdr integration install pi` reinstalls. The dots come from pi-subagents'
// events and only cover the top-level agents it reports.

import net from "node:net";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SOURCE = "user:pi-subagents";
// A dot outlives a missed completion event only this long; a running subagent
// refreshes it well inside that window.
const TTL_MS = 180_000;
const REFRESH_MS = 60_000;
// herdr caps display_agent at 80 characters, so the dot run is bounded.
const MAX_DOTS = 32;

const paneId = process.env.HERDR_PANE_ID;
const socketPath = process.env.HERDR_SOCKET_PATH;
const socketEndpoint =
	process.platform === "win32" && socketPath ? `\\\\.\\pipe\\${socketPath}` : socketPath;

/**
 * One request/response round trip over herdr's socket; a failure is silent
 * because the indicator is advisory and the next report corrects it.
 */
function report(displayAgent: string | null, seq: number): void {
	if (!socketEndpoint || !paneId) return;

	let socket: net.Socket;
	try {
		socket = net.createConnection(socketEndpoint);
	} catch {
		return;
	}

	const timer = setTimeout(() => socket.destroy(), 500);
	timer.unref?.();
	const finish = () => {
		clearTimeout(timer);
		socket.destroy();
	};
	socket.on("error", finish);
	socket.on("data", finish);
	socket.on("end", finish);
	socket.on("connect", () => {
		socket.write(
			JSON.stringify({
				id: `${SOURCE}:${seq}`,
				method: "pane.report_metadata",
				params: {
					pane_id: paneId,
					source: SOURCE,
					agent: "pi",
					// Only present on the pane while herdr's own integration is the
					// authoritative reporter; the guard keeps this display-only.
					applies_to_source: "herdr:pi",
					seq,
					// `display_agent: null` is rejected as "missing metadata field to
					// set or clear", so clearing uses its own field.
					...(displayAgent
						? { display_agent: displayAgent, ttl_ms: TTL_MS }
						: { clear_display_agent: true }),
				},
			}) + "\n",
		);
	});
}

function indicator(count: number): string {
	const dots = "● ".repeat(Math.min(count, MAX_DOTS)).trimEnd();
	const overflow = count > MAX_DOTS ? ` +${count - MAX_DOTS}` : "";
	return `└─ ${dots}${overflow} pi`;
}

export default function (pi: ExtensionAPI) {
	if (process.env.HERDR_ENV !== "1" || !paneId || !socketPath) return;

	// TUI only: RPC, JSON, and print modes are headless (no pane herdr displays).
	let rootSession = false;
	let seq = Date.now() * 1000;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	const running = new Set<string>();

	function publish() {
		report(running.size ? indicator(running.size) : null, ++seq);

		if (running.size && !refreshTimer) {
			refreshTimer = setInterval(publish, REFRESH_MS);
			refreshTimer.unref?.();
		} else if (!running.size && refreshTimer) {
			clearInterval(refreshTimer);
			refreshTimer = undefined;
		}
	}

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		rootSession = true;
		// A previous Pi process or extension reload may have left dots behind.
		publish();
	});

	pi.events.on("subagents:started", (data) => {
		const id = (data as { id?: string } | undefined)?.id;
		if (!rootSession || !id || running.has(id)) return;
		running.add(id);
		publish();
	});

	function finished(data: unknown) {
		const id = (data as { id?: string } | undefined)?.id;
		if (rootSession && id && running.delete(id)) publish();
	}
	pi.events.on("subagents:completed", finished);
	pi.events.on("subagents:failed", finished);

	pi.on("session_shutdown", () => {
		if (!rootSession) return;
		// session_shutdown also fires on reload, where the reloaded extension
		// re-clears; ids rebuilt from a fresh process need not be carried over.
		running.clear();
		publish();
		rootSession = false;
	});
}
