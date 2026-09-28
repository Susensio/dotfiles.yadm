// Names a session from its first prompt, so /resume and the footer show a title
// instead of a truncated prompt. A name set by hand (`/name`, `--name`) wins.
//
// Two provider facts this file depends on, both verified here on pi 0.87.1:
// opencode gateways reject extension side calls with 400 MissingSessionID
// without `x-opencode-session`, which pi-ai derives from `options.sessionId`
// (#9326); the extension surface never sets one, so those calls fail silently.
// The title instruction also has to sit in the user turn: opencode-go drops a
// bare system prompt, and the model then answers the prompt instead of titling.

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";

// Fast and cheap for a one-shot title; falls back to the session model when the
// session's model scope excludes it.
const TITLE_MODEL = { provider: "opencode-go", model: "gpt-6-luna" };

const INSTRUCTION =
	"Generate a short, descriptive, relevant title (between 3 and 8 words max) for an AI prompting session based on the following message:";

const MAX_PROMPT_CHARS = 500;
const MAX_TITLE_CHARS = 80;

/** First line of the response, stripped of the formatting models add anyway. */
function normalizeTitle(text: string) {
	const line = text.split(/\r?\n/).find((candidate) => candidate.trim().length > 0) ?? "";
	return line
		.trim()
		.replace(/\*\*/g, "")
		.replace(/^["'“”‘’`]+|["'“”‘’`]+$/g, "")
		.replace(/[\s.,!?;:，。！？；：、…—–-]+$/g, "")
		.trim()
		.slice(0, MAX_TITLE_CHARS)
		.trim();
}

function pickModel(ctx: ExtensionContext): Model<unknown> | undefined {
	const scoped = ctx.scopedModels.map((entry) => entry.model);
	const inScope = (model: Model<unknown>) =>
		scoped.length === 0 || scoped.some((candidate) => candidate.provider === model.provider && candidate.id === model.id);

	const pinned = ctx.modelRegistry.find(TITLE_MODEL.provider, TITLE_MODEL.model);
	if (pinned && inScope(pinned) && ctx.modelRegistry.hasConfiguredAuth(pinned)) return pinned;
	return ctx.model;
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

	const title = normalizeTitle(
		response.content
			.filter((block): block is { type: "text"; text: string } => block.type === "text")
			.map((block) => block.text)
			.join(""),
	);
	// A manual name set while the title was in flight outranks the generated one.
	if (title && !pi.getSessionName()) {
		pi.setSessionName(title);
	}
}

export default function (pi: ExtensionAPI) {
	let firstPrompt: string | undefined;
	let naming = false;

	// The expanded prompt, so a skill or template invocation is titled by its own
	// text rather than by the slash command that pulled it in.
	pi.on("before_agent_start", (event) => {
		firstPrompt ??= event.prompt.trim();
	});

	pi.on("agent_end", async (_event, ctx) => {
		if (!firstPrompt || naming || pi.getSessionName()) return;
		naming = true;
		const prompt = firstPrompt.slice(0, MAX_PROMPT_CHARS);

		// The TUI session outlives the turn, so naming must not delay the next
		// prompt. One-shot modes tear the session down right after agent_end, so
		// there it has to finish inline or the write is lost.
		if (ctx.mode === "tui") {
			void nameSession(pi, ctx, prompt).catch(() => {});
			return;
		}
		try {
			await nameSession(pi, ctx, prompt);
		} catch {
			// No name is a cosmetic loss; leaving the session unnamed is the
			// documented failure mode of every namer on this provider.
		}
	});
}
