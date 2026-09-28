// Names a session from its first prompt, so /resume and the footer show a title
// instead of a truncated prompt. A name set by hand (`/name`, `--name`) wins.
// The same call also yields a one-word herdr tab label, renamed over the socket
// only while the tab still carries its default number label.
//
// Two provider facts this file depends on, both verified here on pi 0.87.1:
// opencode gateways reject extension side calls with 400 MissingSessionID
// without `x-opencode-session`, which pi-ai derives from `options.sessionId`
// (#9326); the extension surface never sets one, so those calls fail silently.
// The title instruction also has to sit in the user turn: opencode-go drops a
// bare system prompt, and the model then answers the prompt instead of titling.

import net from "node:net";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";

// Fast and cheap for a one-shot title; falls back to the session model when the
// session's model scope excludes it.
const TITLE_MODEL = { provider: "opencode-go", model: "gpt-6-luna" };

// Line 2 exists because the herdr tab bar has room for one word, and a second
// side call for it is not worth the latency; a model that answers with one line
// falls back to the title's own first word.
// Plain text is asked for rather than scrubbed afterwards, so decoration the
// model adds anyway shows up as-is instead of being half-removed.
const INSTRUCTION =
	"Name an AI prompting session from the message below. Reply with two plain-text lines and nothing else — no markdown, quotes, numbering, or field names.\n" +
	"First line: a short, descriptive title of 3 to 8 words, with no trailing period.\n" +
	"Second line: the single lowercase word a human would scan for in a tab bar, hyphenated only if one word will not do (e.g. permissions, auth, backups).";

const MAX_PROMPT_CHARS = 500;
const MAX_TITLE_CHARS = 80;
const MAX_LABEL_CHARS = 24;
const HERDR_TIMEOUT_MS = 1000;

/** One line of the model's reply, as the session title. */
function plainTitle(line: string) {
	return line.trim().slice(0, MAX_TITLE_CHARS).trim();
}

/** A single-token herdr tab name. Slugging is format coercion rather than
 *  decoration cleanup: the label has to be one word either way. */
function tabLabel(line: string) {
	return line
		.trim()
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, MAX_LABEL_CHARS)
		.replace(/-+$/g, "");
}

function pickModel(ctx: ExtensionContext): Model<unknown> | undefined {
	const scoped = ctx.scopedModels.map((entry) => entry.model);
	const inScope = (model: Model<unknown>) =>
		scoped.length === 0 || scoped.some((candidate) => candidate.provider === model.provider && candidate.id === model.id);

	const pinned = ctx.modelRegistry.find(TITLE_MODEL.provider, TITLE_MODEL.model);
	if (pinned && inScope(pinned) && ctx.modelRegistry.hasConfiguredAuth(pinned)) return pinned;
	return ctx.model;
}

/** One request/response round trip over herdr's socket; resolves undefined on any failure. */
function herdrRequest(method: string, params: Record<string, unknown>) {
	return new Promise<unknown>((resolve) => {
		const socketPath = process.env.HERDR_SOCKET_PATH;
		if (!socketPath) {
			resolve(undefined);
			return;
		}

		let socket: net.Socket;
		try {
			socket = net.createConnection(socketPath);
		} catch {
			resolve(undefined);
			return;
		}

		let buffer = "";
		let timer: ReturnType<typeof setTimeout> | undefined;
		let settled = false;
		const finish = (value: unknown) => {
			if (settled) return;
			settled = true;
			if (timer) clearTimeout(timer);
			socket.destroy();
			resolve(value);
		};
		timer = setTimeout(() => finish(undefined), HERDR_TIMEOUT_MS);
		timer.unref?.();
		socket.on("error", () => finish(undefined));
		socket.on("connect", () =>
			socket.write(`${JSON.stringify({ id: `session-name:${Date.now()}`, method, params })}\n`),
		);
		socket.on("data", (chunk) => {
			buffer += chunk.toString();
			const newline = buffer.indexOf("\n");
			if (newline === -1) return;
			try {
				finish(JSON.parse(buffer.slice(0, newline)));
			} catch {
				finish(undefined);
			}
		});
	});
}

// An unnamed tab is labelled with a bare number (its creation position in the
// workspace, not the global tab number), so a numeric label is the only signal
// that the tab name is still free; a hand-set name always wins. Outside herdr,
// or when the tab was renamed meanwhile, this is a no-op.
async function renameTab(label: string) {
	const tabId = process.env.HERDR_TAB_ID;
	if (process.env.HERDR_ENV !== "1" || !tabId || !label) return;

	const info = (await herdrRequest("tab.get", { tab_id: tabId })) as
		| { result?: { tab?: { label?: string } } }
		| undefined;
	if (!/^\d+$/.test(info?.result?.tab?.label ?? "")) return;

	await herdrRequest("tab.rename", { tab_id: tabId, label });
}

async function nameSession(pi: ExtensionAPI, ctx: ExtensionContext, prompt: string) {
	const model = pickModel(ctx);
	if (!model) return;

	const response = await ctx.modelRegistry.complete(
		model,
		{
			messages: [
				{
					role: "user",
					content: [{ type: "text", text: `${INSTRUCTION}\n"${prompt}"` }],
					timestamp: Date.now(),
				},
			],
		},
		{
			temperature: 0.2,
			// Required on opencode gateways; harmless elsewhere.
			sessionId: ctx.sessionManager.getSessionId?.(),
		},
	);

	const lines = response.content
		.filter((block): block is { type: "text"; text: string } => block.type === "text")
		.map((block) => block.text)
		.join("")
		.split(/\r?\n/)
		.map((line) => line.trim())
		.filter(Boolean);
	const title = plainTitle(lines[0] ?? "");
	// A model that answers with one line still leaves the tab a single word.
	const label = tabLabel(lines[1] ?? title.split(/\s+/)[0] ?? "");
	// A manual name set while the title was in flight outranks the generated one.
	if (title && !pi.getSessionName()) {
		pi.setSessionName(title);
	}
	await renameTab(label);
}

export default function (pi: ExtensionAPI) {
	// Set once naming has started, so later turns never start it again.
	let naming: Promise<void> | undefined;

	// The expanded prompt, so a skill or template invocation is titled by its own
	// text rather than by the slash command that pulled it in. Starting the call
	// here overlaps it with the first turn; waiting for agent_end added the call's
	// own latency on top of a turn the user had already waited through.
	pi.on("before_agent_start", (event, ctx) => {
		if (naming || pi.getSessionName()) return;
		const prompt = event.prompt.trim();
		if (!prompt) return;
		naming = nameSession(pi, ctx, prompt.slice(0, MAX_PROMPT_CHARS)).catch(() => {
			// No name is a cosmetic loss; leaving the session unnamed is the
			// documented failure mode of every namer on this provider.
		});
	});

	pi.on("agent_end", async (_event, ctx) => {
		// One-shot modes tear the session down right after agent_end, so there the
		// call has to finish inline or the write is lost. A TUI session outlives
		// the turn, so it must not block on a call that is still in flight.
		if (ctx.mode === "tui") return;
		await naming;
	});
}
