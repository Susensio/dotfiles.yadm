/**
 * Always-ask authorizer link
 *
 * Bash asks whose command matches always-ask.json are put to you in this pane
 * and your answer is final, so no later link in authorizerChain can approve
 * them for you; an earlier one decides before this runs. Everything else is
 * deferred to the next link.
 * Enabled by naming "always-ask" in pi-permission-system's authorizerChain.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

const LINK_NAME = "always-ask";

type Verdict = { kind: "allow" } | { kind: "deny"; reason?: string } | { kind: "defer" };
interface AskDetails {
  command?: string;
}
interface PermissionsService {
  registerAuthorizer(name: string, authorize: (details: AskDetails) => Promise<Verdict>): () => void;
}

/** A missing or malformed list matches nothing; auto-review's policy still denies pkexec. */
function readAlwaysAsk(): RegExp[] {
  try {
    const parsed = JSON.parse(readFileSync(join(getAgentDir(), "always-ask.json"), "utf8")) as { commands?: unknown };
    if (!Array.isArray(parsed.commands)) return [];
    return parsed.commands
      .filter((glob): glob is string => typeof glob === "string")
      .map((glob) => new RegExp(`^${glob.split("*").map((part) => part.replace(/[.+?^${}()|[\]\\]/g, "\\$&")).join(".*")}$`, "s"));
  } catch {
    return [];
  }
}

// The same process-global map getPermissionsService reads; the package itself is
// not resolvable from a local extension.
function permissionsService(sessionId: string): PermissionsService | undefined {
  const services = (globalThis as Record<symbol, unknown>)[Symbol.for("@gotgenes/pi-permission-system:session-services")];
  return (services as Map<string, PermissionsService> | undefined)?.get(sessionId);
}

export default function (pi: ExtensionAPI) {
  let ctx: ExtensionContext | undefined;
  let dispose: (() => void) | undefined;

  async function authorize(details: AskDetails): Promise<Verdict> {
    const command = details.command;
    if (command === undefined || !readAlwaysAsk().some((pattern) => pattern.test(command))) return { kind: "defer" };
    // Without a UI the terminal link is the one that decides.
    if (!ctx?.hasUI) return { kind: "defer" };
    pi.events.emit("herdr:blocked", { active: true, label: `always-ask: ${command}` });
    try {
      const approved = await ctx.ui.confirm("Always-ask command", command);
      return approved ? { kind: "allow" } : { kind: "deny", reason: "The user declined this command." };
    } finally {
      pi.events.emit("herdr:blocked", { active: false });
    }
  }

  pi.on("session_start", (_event, startCtx) => {
    ctx = startCtx;
  });

  pi.events.on("permissions:ready", (data) => {
    const { sessionId } = data as { sessionId: string | null };
    if (dispose || !sessionId) return;
    dispose = permissionsService(sessionId)?.registerAuthorizer(LINK_NAME, authorize);
  });

  pi.on("session_shutdown", () => {
    dispose?.();
    dispose = undefined;
    ctx = undefined;
  });
}
