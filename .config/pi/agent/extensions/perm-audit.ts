// /perm-audit and /perm-report — surfaces for pi-permission-system's JSONL
// decision log, the inspection pi-automode's SQL audit used to provide.
//
// /perm-audit [denied|review] browses recent decisions; /perm-report analyzes
// the log against config.json (dead rules, repeated asks, denial clusters,
// reviewer health) and also writes /tmp/perm-report.txt so the agent or user
// can act on it. No model call.
//
// Both render through a small scrollable overlay (ctx.ui.custom), not
// ctx.ui.select: a picker drops rows off the viewport and long commands get
// truncated, while a viewer owns the whole width and scrolls.
// @ts-nocheck
import { readFileSync, existsSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const dirUrl = new URL("./pi-permission-system/", import.meta.url);
const logPath = fileURLToPath(new URL("logs/pi-permission-system-permission-review.jsonl", dirUrl));
const configPath = fileURLToPath(new URL("config.json", dirUrl));

const OUTCOMES = {
	auto_approved: "allow",
	approved: "allow",
	session_approved: "allow*",
	infrastructure_auto_allowed: "allow",
	denied: "DENY",
	blocked: "BLOCK",
};

function hhmm(iso) {
	const d = new Date(iso);
	return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function snippet(j) {
	const raw = j.command || j.path || j.toolInputPreview || j.target || "";
	return raw.replace(/\s+/g, " ").trim();
}

function who(j) {
	const k = j.decidedBy?.kind;
	if (k === "yolo") return "yolo";
	if (k === "user") return "you";
	if (k === "rule") return "rule";
	if (k === "session_approval") return "session";
	if (k === "authorizer") return "review";
	if (k === "unavailable") return "no-auth";
	if (k === "infrastructure_read") return "infra";
	return k || "";
}

// Correlate: one record per requestId, last state wins; authorizer
// rationale/risk attach where the chain decided; waiting-only stays "open"
// (an ask that never resolved — reliability finding).
function parseLog() {
	if (!existsSync(logPath)) return { recs: [], since: null };
	const byId = new Map();
	let since = null;
	for (const line of readFileSync(logPath, "utf8").split("\n")) {
		if (!line.trim()) continue;
		let j;
		try {
			j = JSON.parse(line);
		} catch {
			continue;
		}
		if (!since) since = j.timestamp;
		const id = j.requestId;
		if (!id) continue;
		const rec = byId.get(id) || { id, rationale: null, risk: null, who: "", denialReason: null };
		const e = j.event;
		if (e === "pi_auto_review_decision") {
			rec.rationale = j.rationale;
			rec.risk = j.riskLevel;
		} else if (e.startsWith("permission_request.")) {
			const short = e.replace("permission_request.", "");
			rec.event = short === "waiting" ? rec.event || "open" : short;
			rec.ts = j.timestamp;
			rec.tool = j.toolName || j.surface || "";
			rec.pattern = j.matchedPattern;
			rec.agent = j.agentName;
			rec.snippet = snippet(j);
			rec.who = who(j);
			rec.denialReason = j.denialReason || j.decidedBy?.reason || null;
		}
		byId.set(id, rec);
	}
	const recs = [...byId.values()].filter((r) => r.event && r.event !== "waiting");
	recs.reverse(); // newest first
	return { recs, since };
}

// Scrollable read-only line viewer as an overlay. Keys: arrows/j/k, PgUp/PgDn,
// Home/End, g/G; Enter fires onPick (audit detail) if given; Esc/q closes.
class LineViewer {
	lines;
	title;
	scroll = 0;
	sel = 0;
	tui;
	onPick;
	onExit;
	viewH = 18;

	constructor(lines, title, tui, onExit, onPick) {
		this.lines = lines;
		this.title = title;
		this.tui = tui;
		this.onExit = onExit;
		this.onPick = onPick;
	}

	handleInput(data) {
		const max = this.lines.length;
		const page = this.viewH;
		const move = (d) => {
			this.sel = Math.min(max - 1, Math.max(0, this.sel + d));
		};
		if (data === "\x1b[A" || data === "k") move(-1);
		else if (data === "\x1b[B" || data === "j") move(1);
		else if (data === "\x1b[5~") move(-page);
		else if (data === "\x1b[6~") move(page);
		else if (data === "\x1b[H" || data === "\x1b[1~" || data === "g") this.sel = 0;
		else if (data === "\x1b[F" || data === "\x1b[4~" || data === "G") this.sel = max - 1;
		else if (data === "\x1b" || data === "q" || data === "Q") return this.onExit();
		else if (data === "\r" || data === "\n") {
			if (this.onPick) return this.onExit(this.sel);
			return;
		} else return;
		// Keep the selection inside the viewport.
		if (this.sel < this.scroll) this.scroll = this.sel;
		if (this.sel >= this.scroll + this.viewH) this.scroll = this.sel - this.viewH + 1;
		this.scroll = Math.max(0, Math.min(this.scroll, Math.max(0, max - this.viewH)));
		this.tui.requestRender();
	}

	render(width) {
		const dim = (s) => `\x1b[2m${s.slice(0, width)}\x1b[0m`;
		const out = [dim(this.title.slice(0, width))];
		const viewH = Math.min(this.viewH, this.lines.length);
		for (let i = this.scroll; i < this.scroll + viewH; i++) {
			const line = this.lines[i] ?? "";
			const marker = i === this.sel ? "\x1b[7m >" : "  ";
			const body = line.length > width - 3 ? line.slice(0, width - 3) : line;
			const l = `${marker} ${body}${i === this.sel ? "\x1b[0m" : ""}`;
			out.push(l.slice(0, width));
		}
		const from = Math.min(this.scroll + 1, this.lines.length);
		const to = Math.min(this.scroll + viewH, this.lines.length);
		out.push(dim(` ${from}–${to} of ${this.lines.length} · ↑↓ scroll · g/G ends${this.onPick ? " · enter detail" : ""} · esc close`));
		return out;
	}

	invalidate() {}
	dispose() {}
}

export default function (pi) {
	pi.registerCommand("perm-audit", {
		description: "Browse the permission system's decision log",
		getArgumentCompletions: (prefix) => {
			const opts = ["", "denied", "review"].filter((o) => o.startsWith(prefix));
			return opts.map((o) => ({ value: o, label: o || "(all)" }));
		},
		handler: async (args, ctx) => {
			if (!existsSync(logPath)) {
				if (ctx.hasUI) ctx.ui.notify("No permission review log found", "info");
				return;
			}
			const { recs } = parseLog();
			const filter = args.trim();
			let view = recs;
			if (filter === "denied") view = view.filter((r) => r.event === "denied" || r.event === "blocked");
			if (filter === "review") view = view.filter((r) => r.who === "review" || r.rationale);

			if (!ctx.hasUI) return;
			if (view.length === 0) {
				ctx.ui.notify(`No matching decisions (filter: ${filter || "all"})`, "info");
				return;
			}
			const counts = {};
			for (const r of view) counts[r.event] = (counts[r.event] || 0) + 1;
			const summary = Object.entries(counts)
				.map(([e, n]) => `${e}:${n}`)
				.join("  ");

			// Newest first; agents shown inline. Width comes from the overlay.
			const rows = view.slice(0, 120).map((r) => {
				const agent = r.agent ? `[${r.agent}] ` : "";
				return `${hhmm(r.ts)}  ${(OUTCOMES[r.event] || r.event).padEnd(6)}  ${(r.who || "").padEnd(7)}  ${agent}${(r.tool || "").padEnd(5)}  ${(r.snippet || "").slice(0, 110)}`;
			});

			let picked = -1;
			await ctx.ui.custom(
				(tui, _theme, _keybindings, done) =>
					new LineViewer(rows, `perm-audit — ${summary}`, tui, (sel) => {
						picked = sel;
						done(undefined);
					}, true),
				{
					overlay: true,
					overlayOptions: { width: "100%", maxHeight: "90%", anchor: "center" },
				},
			);
			if (picked < 0) return;
			const r = view[picked];
			const detail = [
				`${r.ts}   ${r.event}   decided by: ${r.who || who(r)}${r.risk ? `   risk: ${r.risk}` : ""}`,
				r.agent ? `agent: ${r.agent}` : null,
				`${r.tool}   pattern: ${r.pattern ?? "—"}`,
				r.snippet || "(no command/path)",
				r.rationale ? `rationale: ${String(r.rationale).slice(0, 300)}` : null,
				r.denialReason ? `reason: ${String(r.denialReason).slice(0, 200)}` : null,
				`request: ${r.id}`,
			]
				.filter(Boolean)
				.join("\n");
			ctx.ui.notify(detail, "info");
		},
	});

	pi.registerCommand("perm-report", {
		description: "Analyze the permission log against config.json and suggest rule changes",
		handler: async (args, ctx) => {
			if (!existsSync(logPath)) {
				if (ctx.hasUI) ctx.ui.notify("No permission review log found", "info");
				return;
			}
			const { recs, since } = parseLog();
			if (recs.length === 0) {
				if (ctx.hasUI) ctx.ui.notify("Log has no resolved decisions yet", "info");
				return;
			}

			// Terminal decisions only; "open" asks are reliability findings, not volume.
			const done = recs.filter((r) => r.event !== "open");
			const lines = [];

			// 1) Volume by outcome and deciding authority.
			lines.push(`Decisions since ${since} — ${done.length} resolved of ${recs.length}`);
			const byEvent = {};
			const byWho = {};
			for (const r of done) {
				byEvent[r.event] = (byEvent[r.event] || 0) + 1;
				byWho[r.who || "?"] = (byWho[r.who || "?"] || 0) + 1;
			}
			for (const [e, n] of Object.entries(byEvent).sort((a, b) => b[1] - a[1])) lines.push(`  ${e}: ${n}`);
			lines.push(`  decided by: ${Object.entries(byWho).sort((a, b) => b[1] - a[1]).map(([w, n]) => `${w} ${n}`).join(", ")}`);
			const opens = recs.filter((r) => r.event === "open");
			if (opens.length) lines.push(`  ! ${opens.length} asks never resolved ("open") — check reviewer availability`);

			// 2) Dead rules: configured patterns that never matched anything logged.
			if (existsSync(configPath)) {
				const cfg = JSON.parse(readFileSync(configPath, "utf8")).permission || {};
				const seen = new Set(done.map((r) => r.pattern).filter(Boolean));
				const dead = [];
				for (const surface of ["bash", "path", "external_directory", "external_directory_read"]) {
					for (const [pat, action] of Object.entries(cfg[surface] || {})) {
						const act = typeof action === "string" ? action : action.action;
						if (pat === "*" || act === "ask") continue; // catch-alls and asks are routing, not rules
						if (!seen.has(pat)) dead.push(`${surface}: ${pat}`);
					}
				}
				lines.push("", `Dead rules (no match since ${since || "log start"} — ${dead.length}):`);
				lines.push(...dead.slice(0, 20).map((d) => `  - ${d}`));
				if (!dead.length) lines.push("  (none)");
				const yolos = done.filter((r) => r.who === "yolo").length;
				if (yolos && dead.length)
					lines.push(
						`  note: yoloMode resolved ${yolos} decisions at the '*' catch-all, so allow rules look dead even when commands ran — dead deny rules are the ones worth pruning`,
					);
			}

			// 3) Hottest configured patterns.
			const byPattern = {};
			for (const r of done) if (r.pattern && r.pattern !== "*") byPattern[r.pattern] = (byPattern[r.pattern] || 0) + 1;
			const hot = Object.entries(byPattern).sort((a, b) => b[1] - a[1]).slice(0, 8);
			lines.push("", "Hottest patterns:");
			lines.push(...(hot.length ? hot.map(([p, n]) => `  ${String(n).padStart(4)}  ${p}`) : ["  (only the catch-all '*' matched)"]));

			// 4) Repeated human-resolved asks → allow-rule candidates. Path grants
			// (session approvals with no pattern) are not bash asks; report their
			// volume separately.
			const asks = done.filter(
				(r) => (r.event === "approved" && r.who === "you") || r.event === "session_approved",
			);
			const pathGrants = asks.filter((r) => !r.pattern).length;
			const bashAsks = asks.filter((r) => r.pattern);
			if (existsSync(configPath)) {
				const bashRules = JSON.parse(readFileSync(configPath, "utf8")).permission?.bash || {};
				const allowPrefixes = Object.entries(bashRules)
					.filter(([p, a]) => (typeof a === "string" ? a === "allow" : a.action === "allow"))
					.map(([p]) => p.replace(/\*$/, ""));
				const groups = new Map();
				for (const r of bashAsks) {
					const s = r.snippet;
					if (!s || allowPrefixes.some((p) => p && s.startsWith(p))) continue;
					const key = s.split(/\s+/).slice(0, 2).join(" ");
					const g = groups.get(key) || { n: 0, ex: new Set() };
					g.n++;
					if (g.ex.size < 2) g.ex.add(s.slice(0, 90));
					groups.set(key, g);
				}
				const top = [...groups.entries()].filter(([, g]) => g.n >= 2).sort((a, b) => b[1].n - a[1].n).slice(0, 10);
				lines.push("", "Repeated asks worth an allow rule (resolved by you/session):");
				if (pathGrants) lines.push(`  (plus ${pathGrants} session path grants — external-directory asks, not bash rules)`);
				lines.push(...(top.length
					? top.map(([k, g]) => `  ${String(g.n).padStart(4)}  "${k}*"  e.g. ${[...g.ex][0].slice(0, 80)}`)
					: ["  (none)"]));
			}

			// 5) Denial clusters.
			const denials = done.filter((r) => r.event === "denied" || r.event === "blocked");
			if (denials.length) {
				lines.push("", "Denials/blocks:");
				const dg = {};
				for (const r of denials) {
					const key = `${r.who || "?"}${r.pattern ? ` · ${r.pattern}` : ""}${r.risk ? ` · risk ${r.risk}` : ""}`;
					dg[key] = (dg[key] || 0) + 1;
				}
				lines.push(...Object.entries(dg).sort((a, b) => b[1] - a[1]).slice(0, 8).map(([k, n]) => `  ${String(n).padStart(4)}  ${k}`));
				const rev = denials.filter((r) => r.rationale && r.who === "review").slice(0, 4);
				for (const r of rev) lines.push(`  review deny: ${r.snippet.slice(0, 70)} — ${String(r.rationale).slice(0, 110)}`);
			}

			// 6) Reviewer health, if the chain is in use.
			const reviews = done.filter((r) => r.who === "review" || r.rationale);
			if (reviews.length) {
				const risks = {};
				for (const r of reviews) if (r.risk) risks[r.risk] = (risks[r.risk] || 0) + 1;
				const riskLine = Object.entries(risks).sort().map(([k, n]) => `${k} ${n}`).join(", ") || "none reported";
				lines.push("", `Reviewer: ${reviews.length} decisions (risk: ${riskLine})`);
			}

			// Land the report where the agent or user can act on it.
			try {
				writeFileSync("/tmp/perm-report.txt", lines.join("\n") + "\n");
			} catch {}
			lines.push("", "(also written to /tmp/perm-report.txt)");

			if (!ctx.hasUI) return;
			await ctx.ui.custom(
				(tui, _theme, _keybindings, done) =>
					new LineViewer(lines, `perm-report`, tui, () => done(undefined), false),
				{
					overlay: true,
					overlayOptions: { width: "100%", maxHeight: "90%", anchor: "center" },
				},
			);
		},
	});
}
