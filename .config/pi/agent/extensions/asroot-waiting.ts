// While asroot's sudo popup is open for this pane, herdr shows the agent as waiting
// (docs/adr/0139-asroot-popup-marks-agent-waiting.md).
// sudo-askpass writes $XDG_RUNTIME_DIR/asroot-waiting/<HERDR_PANE_ID> holding its PID;
// this forwards it to herdr-agent-state.ts's `herdr:blocked` channel.
// @ts-nocheck
import fs from "node:fs";
import path from "node:path";

export default function (pi) {
	const pane = process.env.HERDR_PANE_ID;
	const runtime = process.env.XDG_RUNTIME_DIR;
	if (!pane || !runtime) return;
	const dir = path.join(runtime, "asroot-waiting");
	const flag = path.join(dir, pane);

	let waiting = false;
	let watcher: fs.FSWatcher | undefined;
	let poll: ReturnType<typeof setInterval> | undefined;

	function popupOpen(): boolean {
		try {
			process.kill(Number(fs.readFileSync(flag, "utf8").trim()), 0);
			return true;
		} catch {
			return false;
		}
	}

	function sync() {
		const open = popupOpen();
		if (open === waiting) return;
		waiting = open;
		pi.events.emit(
			"herdr:blocked",
			open ? { active: true, label: "asroot: password in the sudo popup" } : { active: false },
		);
		// A killed helper leaves its flag behind, so an open popup is also polled.
		if (open) poll ??= setInterval(sync, 2000);
		else if (poll) poll = void clearInterval(poll);
	}

	pi.on("session_start", () => {
		if (watcher) return;
		fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
		watcher = fs.watch(dir, (_event, name) => {
			if (name === pane) sync();
		});
		sync();
	});

	pi.on("session_shutdown", () => {
		watcher?.close();
		watcher = undefined;
		if (poll) poll = void clearInterval(poll);
		if (waiting) {
			waiting = false;
			pi.events.emit("herdr:blocked", { active: false });
		}
	});
}
