import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";

// Tier ladder from model-alias.json, strongest first. An alias cannot target
// another alias, so each name is a concrete model; keep this list in step with
// that file's tiers.
const TIERS = ["top", "mid", "cheap"] as const;

export default function (pi: ExtensionAPI) {
  async function cycle(direction: 1 | -1, ctx: ExtensionContext) {
    const current = ctx.model;
    const index = current?.provider === "alias" ? TIERS.indexOf(current.id as (typeof TIERS)[number]) : -1;
    // A concrete model sits outside the ladder: forward enters at the top,
    // backward at the cheap end.
    const next =
      index >= 0
        ? TIERS[(index + direction + TIERS.length) % TIERS.length]
        : TIERS[direction === 1 ? 0 : TIERS.length - 1];
    const model = ctx.modelRegistry.find("alias", next);
    if (!model) {
      ctx.ui.notify(`Alias alias/${next} is not registered`, "warning");
      return;
    }
    if (!(await pi.setModel(model))) {
      ctx.ui.notify(`Cannot switch to alias/${next}`, "warning");
    }
  }

  pi.registerShortcut(Key.shift("right"), {
    description: "Next alias tier (top, mid, cheap)",
    handler: (ctx) => cycle(1, ctx),
  });
  pi.registerShortcut(Key.shift("left"), {
    description: "Previous alias tier (cheap, mid, top)",
    handler: (ctx) => cycle(-1, ctx),
  });
}
