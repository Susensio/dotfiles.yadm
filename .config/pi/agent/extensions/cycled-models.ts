/**
 * Cycled Models Extension
 *
 * Shift+Left and Shift+Right step through a user-chosen list of models, so a
 * tier swap never lands on the full catalogue the way Ctrl+P did.
 * The list lives in cycled-models.json beside this extension and is edited with
 * /cycled-models, which toggles models in a searchable picker.
 */

import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir, getSettingsListTheme } from "@earendil-works/pi-coding-agent";
import { Container, Key, type SettingItem, SettingsList } from "@earendil-works/pi-tui";

// Alias tiers from model-alias.json, strongest first; the fallback chains they
// stand in for are what the fast cycle exists to switch between.
const DEFAULT_MODELS = ["alias/top", "alias/mid", "alias/cheap"];
const CONFIG_NAME = "cycled-models.json";
const CONFIG_COMMENT =
  "Models the fast cycle (Shift+Left/Shift+Right) steps through, in order; edited by /cycled-models. Each entry is provider/modelId.";

interface CycledModelsConfig {
  $comment?: string;
  models?: string[];
}

function configPath(): string {
  return join(getAgentDir(), CONFIG_NAME);
}

function readModels(): string[] {
  try {
    const parsed = JSON.parse(readFileSync(configPath(), "utf8")) as CycledModelsConfig;
    // An explicitly empty list is a choice and survives; only a missing or
    // malformed file falls back to the alias tiers.
    if (Array.isArray(parsed.models)) {
      return [...new Set(parsed.models.filter((ref): ref is string => typeof ref === "string" && ref.includes("/")))];
    }
  } catch {
    // Missing or malformed file: fall back to the alias tiers.
  }
  return [...DEFAULT_MODELS];
}

function writeModels(models: string[]): void {
  const config: CycledModelsConfig = { $comment: CONFIG_COMMENT, models };
  writeFileSync(configPath(), `${JSON.stringify(config, null, 2)}\n`);
}

function resolveModel(ref: string, ctx: ExtensionContext) {
  const slash = ref.indexOf("/");
  if (slash <= 0) return undefined;
  return ctx.modelRegistry.find(ref.slice(0, slash), ref.slice(slash + 1));
}

export default function (pi: ExtensionAPI) {
  async function cycle(direction: 1 | -1, ctx: ExtensionContext) {
    const models = readModels()
      .map((ref) => resolveModel(ref, ctx))
      .filter((model) => model !== undefined);
    if (models.length < 2) {
      ctx.ui.notify("The fast cycle needs at least two resolvable models; edit it with /cycled-models", "warning");
      return;
    }
    const current = ctx.model;
    const index = current
      ? models.findIndex((model) => model.provider === current.provider && model.id === current.id)
      : -1;
    // A concrete model sits outside the list: forward enters at the first entry,
    // backward at the last.
    const next =
      index >= 0
        ? models[(index + direction + models.length) % models.length]
        : models[direction === 1 ? 0 : models.length - 1];
    if (!(await pi.setModel(next))) {
      ctx.ui.notify(`Cannot switch to ${next.provider}/${next.id}`, "warning");
    }
  }

  pi.registerShortcut(Key.shift("right"), {
    description: "Next fast-cycle model",
    handler: (ctx) => cycle(1, ctx),
  });
  pi.registerShortcut(Key.shift("left"), {
    description: "Previous fast-cycle model",
    handler: (ctx) => cycle(-1, ctx),
  });

  pi.registerCommand("cycled-models", {
    description: "Choose the models the fast cycle steps through",
    handler: async (args, ctx) => {
      const arg = args.trim();
      if (arg === "reset") {
        writeModels([...DEFAULT_MODELS]);
        ctx.ui.notify(`Fast cycle reset to ${DEFAULT_MODELS.join(", ")}`, "info");
        return;
      }
      if (!arg && ctx.mode === "tui") {
        await editModels(ctx);
        return;
      }
      ctx.ui.notify(`Fast cycle: ${readModels().join(", ")}`, "info");
    },
  });

  async function editModels(ctx: ExtensionContext) {
    const order = readModels();
    const selected = new Set(order);
    const available = ctx.modelRegistry
      .getAvailable()
      .slice()
      .sort((a, b) => `${a.provider}/${a.id}`.localeCompare(`${b.provider}/${b.id}`));
    if (available.length === 0) {
      ctx.ui.notify("No models available", "warning");
      return;
    }

    await ctx.ui.custom((tui, theme, _kb, done) => {
      const items: SettingItem[] = available.map((model) => {
        const ref = `${model.provider}/${model.id}`;
        return {
          id: ref,
          label: ref,
          currentValue: selected.has(ref) ? "in cycle" : "off",
          values: ["in cycle", "off"],
        };
      });

      const container = new Container();
      container.addChild(
        new (class {
          render(_width: number) {
            return [theme.fg("accent", theme.bold("Fast cycle models")), ""];
          }
          invalidate() {}
        })(),
      );

      const list = new SettingsList(
        items,
        Math.min(items.length + 2, 15),
        getSettingsListTheme(),
        (id, value) => {
          if (value === "in cycle") {
            if (!order.includes(id)) order.push(id);
          } else {
            const at = order.indexOf(id);
            if (at >= 0) order.splice(at, 1);
          }
          writeModels(order);
        },
        () => done(undefined),
        { enableSearch: true },
      );

      container.addChild(list);

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          list.handleInput?.(data);
          tui.requestRender();
        },
      };
    });
  }
}
