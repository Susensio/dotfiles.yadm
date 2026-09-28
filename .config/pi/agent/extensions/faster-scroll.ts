/**
 * faster-scroll — raise Pi's base mouse-wheel/trackpad scroll step.
 *
 * Pi's alt-screen renderer defaults `wheelScrollLines` to 1, so one wheel
 * notch or trackpad tick moves a single transcript line in fullscreen mode.
 * The field is a plain own property read by `getWheelScrollLines()`, and the
 * widget factory is the only handle an extension gets on the renderer
 * instance (no public setting exists).
 *
 * Internals dependency: if pi renames the field this silently no-ops;
 * Alt+wheel (hardcoded 5x in the renderer) keeps working regardless.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const WHEEL_SCROLL_LINES = 3;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		ctx.ui.setWidget("faster-scroll", (tui) => {
			(tui as { wheelScrollLines: number }).wheelScrollLines = WHEEL_SCROLL_LINES;
			return { render: () => [], invalidate: () => {} };
		});
	});
}
