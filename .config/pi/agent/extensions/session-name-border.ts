// Paints the session name on the editor's top border, beside the prompt it
// belongs to, instead of leaving it only in the footer and /resume.
//
// Local rather than npm:pi-session-name-border: that package replaces the whole
// top border line, which in fullscreen drops the working status pi embeds there
// (embedWorkingStatus), and it refreshes from lifecycle events only, so a name
// that lands mid-turn shows up a turn late. ADR-0062 keeps this code in the
// harness for the same reasons it kept the naming itself here.

import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const MAX_LABEL_CHARS = 60;
/** Below this the label would eat the border it sits on. */
const MIN_LABEL_CHARS = 6;
/** The glyph pi-footer's own session-name segment rendered, kept so the title
 *  reads the same now that it lives on the border. */
const LABEL_ICON = "\u{f0379}";
/** borderColor wraps the fill, and a theme may add no escapes at all. */
const ANSI = /\x1b\[[0-9;]*m/g;

/** Columns of plain fill ending the drawn border: the only columns a label may take. */
function trailingFillWidth(border: string): number {
	const fill = /─+$/.exec(border.replace(ANSI, ""));
	return fill ? fill[0].length : 0;
}

class SessionNameEditor extends CustomEditor {
	private sessionName: string | undefined;

	setSessionName(name: string | undefined): void {
		// Model-generated (session-name.ts) or typed into /name; either way it is
		// one line, and a raw newline or escape would be drawn as border width.
		const next = name?.replace(/\s+/g, " ").trim();
		if (next === this.sessionName) return;
		this.sessionName = next || undefined;
		this.tui.requestRender();
	}

	// Composed rather than overwritten: the parent's line carries the working
	// spinner at its left and the scrolling "↑ N more" indicator mid-line, so
	// only trailing fill is traded away and the rest of the border survives.
	protected override renderTopBorder(width: number, hiddenLineCount: number): string {
		const border = super.renderTopBorder(width, hiddenLineCount);
		if (!this.sessionName) return border;

		const available = Math.min(MAX_LABEL_CHARS, trailingFillWidth(border) - 1);
		if (available < MIN_LABEL_CHARS) return border;

		// The space and closing dash hold the name off the right edge, where a
		// flush label reads as the end of the line rather than part of the border.
		const label = truncateToWidth(` ${LABEL_ICON} ${this.sessionName} ─`, available, "…");
		return truncateToWidth(border, width - visibleWidth(label), "") + this.borderColor(label);
	}
}

export default function (pi: ExtensionAPI) {
	let editor: SessionNameEditor | undefined;

	const refresh = (ctx: ExtensionContext) => editor?.setSessionName(pi.getSessionName());

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			// Opting into the embed keeps the working spinner on the border line
			// this editor also writes, instead of pushing it to a row of its own.
			editor = new SessionNameEditor(tui, theme, keybindings, { embedWorkingStatus: true });
			editor.setSessionName(pi.getSessionName());
			return editor;
		});
	});

	// The name arrives mid-turn, from the first prompt, so react to the record
	// itself; the lifecycle hooks the published package polls would catch it a
	// turn later.
	pi.on("session_info_changed", (_event, ctx) => refresh(ctx));

	pi.on("session_shutdown", () => {
		editor = undefined;
	});
}
