// Bridge for herdr's pane state indicator.
//
// herdr-agent-state.ts (installed by `herdr integration install pi`, and
// overwritten on every herdr update) listens for `herdr:blocked` to flip the
// pane dot to its "agent waiting for user input" state. Nothing inside pi
// emitted that, so an open ask_user_question questionnaire looked like the
// agent was still working.
//
// @juicesharp/rpiv-ask-user-question emits `rpiv:ask-user:blocked`
// ({ active: boolean }) while its questionnaire awaits input; this forwards it
// onto herdr's channel. Keep this file beside herdr-agent-state.ts — it
// survives `herdr integration install pi` reinstalls.
// @ts-nocheck
export default function (pi) {
	pi.events.on("rpiv:ask-user:blocked", (data: unknown) => {
		pi.events.emit("herdr:blocked", {
			active: !!(data as { active?: boolean } | undefined)?.active,
			label: "ask_user_question: waiting for your answer",
		});
	});
}
