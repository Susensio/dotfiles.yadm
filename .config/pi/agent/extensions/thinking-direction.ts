import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";

const levels = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

export default function (pi: ExtensionAPI) {
  function move(
    direction: number,
    model: { reasoning: boolean; thinkingLevelMap?: Partial<Record<(typeof levels)[number], unknown>> } | undefined,
  ) {
    if (!model?.reasoning) return;

    const available = levels.filter((level) => {
      const mapped = model.thinkingLevelMap?.[level];
      if (mapped === null) return false;
      return (level !== "xhigh" && level !== "max") || mapped !== undefined;
    });
    const current = available.indexOf(pi.getThinkingLevel());
    if (current < 0) return;
    pi.setThinkingLevel(available[(current + direction + available.length) % available.length]);
  }

  pi.registerShortcut(Key.shift("up"), {
    description: "Increase thinking level",
    handler: async (ctx) => move(1, ctx.model),
  });
  pi.registerShortcut(Key.shift("down"), {
    description: "Decrease thinking level",
    handler: async (ctx) => move(-1, ctx.model),
  });
}
