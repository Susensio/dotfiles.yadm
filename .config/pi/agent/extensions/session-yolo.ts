/**
 * Session yolo authorizer link
 *
 * /yolo (or launching with --yolo) approves every ask that reaches this link,
 * for this session only: the switch lives in memory and nothing is written to
 * pi-permission-system's config, so other running sessions are unaffected.
 * Off, it defers everything. Like every link, it decides only the asks that no
 * earlier link in authorizerChain decided.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const LINK_NAME = "session-yolo";

type Verdict = { kind: "allow" } | { kind: "deny"; reason?: string } | { kind: "defer" };
interface PermissionsService {
  registerAuthorizer(name: string, authorize: () => Promise<Verdict>): () => void;
}

// The same process-global map getPermissionsService reads; the package itself is
// not resolvable from a local extension.
function permissionsService(sessionId: string): PermissionsService | undefined {
  const services = (globalThis as Record<symbol, unknown>)[Symbol.for("@gotgenes/pi-permission-system:session-services")];
  return (services as Map<string, PermissionsService> | undefined)?.get(sessionId);
}

export default function (pi: ExtensionAPI) {
  let enabled = false;
  let dispose: (() => void) | undefined;

  function show(ctx: ExtensionContext) {
    ctx.ui.setStatus(LINK_NAME, enabled ? ctx.ui.theme.fg("warning", "yolo") : undefined);
  }

  async function authorize(): Promise<Verdict> {
    return enabled ? { kind: "allow" } : { kind: "defer" };
  }

  pi.registerFlag("yolo", { description: "Approve every permission ask for this session", type: "boolean" });

  pi.registerCommand("yolo", {
    description: "Toggle approving every permission ask for this session",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      show(ctx);
      ctx.ui.notify(enabled ? "yolo on for this session" : "yolo off", enabled ? "warning" : "info");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    enabled = pi.getFlag("yolo") === true;
    show(ctx);
  });

  pi.events.on("permissions:ready", (data) => {
    const { sessionId } = data as { sessionId: string | null };
    if (dispose || !sessionId) return;
    dispose = permissionsService(sessionId)?.registerAuthorizer(LINK_NAME, authorize);
  });

  pi.on("session_shutdown", () => {
    dispose?.();
    dispose = undefined;
  });
}
