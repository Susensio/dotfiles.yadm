// Bridge for herdr's pane state indicator.
//
// herdr-agent-state.ts (installed by `herdr integration install pi`, and
// overwritten on every herdr update) listens for `herdr:blocked` to flip the
// pane dot to its "agent waiting for user input" state. Nothing inside pi
// emitted that, so an open ask_user questionnaire looked like the agent was
// still working.
//
// @eko24ive/pi-ask emits `@eko24ive/pi-ask:started` / `:completed` around each
// flow; this forwards them onto herdr's channel.
// Keep this file beside herdr-agent-state.ts — it survives
// `herdr integration install pi` reinstalls.
//
// pi-permission-system's permission dialog (bash asks, sandbox prompts) is a
// separate UI that nothing reported, so a session waiting at "Approve? [y/s/b/n]"
// also looked like the agent was still working. Two wires fix that:
//
// - `permissions:ui_prompt` fires immediately before the dialog renders —
//   used to set active with a display label ("bash: git push origin main").
// - `permissions:decision` fires when the gate resolves — used to clear,
//   but only when a prompt actually opened in this session, because the
//   decision channel also carries behind-the-scenes policy_allow/
//   policy_deny rows that never showed a dialog and must not emit a stray
//   inactive event.
// @ts-nocheck
export default function (pi) {
	// -- ask_user (@eko24ive/pi-ask) ---------------------------------------
	// pi-ask has no "blocked" event; a flow is open from `started` to `completed`.
	// Track flow ids so concurrent flows do not clear each other.
	const openAsks = new Set<string>();
	pi.events.on("@eko24ive/pi-ask:started", (e: { flowId?: string } | undefined) => {
		if (!e?.flowId) return;
		openAsks.add(e.flowId);
		pi.events.emit("herdr:blocked", {
			active: true,
			label: "ask_user: waiting for your answer",
		});
	});
	pi.events.on("@eko24ive/pi-ask:completed", (e: { flowId?: string } | undefined) => {
		if (!e?.flowId || !openAsks.delete(e.flowId) || openAsks.size > 0) return;
		pi.events.emit("herdr:blocked", { active: false, label: "ask_user answered" });
	});
	// pi-ask disposes open flows on shutdown without emitting `completed`.
	pi.on("session_shutdown", () => openAsks.clear());

	// -- pi-permission-system (bash/permission dialog) --------------------
	let permissionDialogOpen = false;
	pi.events.on("permissions:ui_prompt", () => {
		permissionDialogOpen = true;
	});
	pi.events.on(
		"permissions:ui_prompt",
		(event: { surface?: string | null; value?: string | null } | undefined) => {
			pi.events.emit("herdr:blocked", {
				active: true,
				label: `permission ask: ${event?.surface ?? "tool"}: ${event?.value ?? ""}`.trim(),
			});
		},
	);
	pi.events.on("permissions:decision", () => {
		if (!permissionDialogOpen) return;
		permissionDialogOpen = false;
		pi.events.emit("herdr:blocked", {
			active: false,
			label: "permission dialog resolved",
		});
	});
}
