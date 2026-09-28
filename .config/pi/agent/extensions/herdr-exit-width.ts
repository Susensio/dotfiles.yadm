import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function paneScrollbarsEnabled(): boolean {
  const configPath =
    process.env.HERDR_CONFIG_PATH ??
    join(
      process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"),
      "herdr/config.toml",
    );
  try {
    let inUi = false;
    for (const line of readFileSync(configPath, "utf8").split(/\r?\n/)) {
      const section = line.match(/^\s*\[([^\]]+)\]\s*(?:#.*)?$/);
      if (section) inUi = section[1] === "ui";
      if (!inUi) continue;
      const setting = line.match(
        /^\s*pane_scrollbars\s*=\s*(true|false)\s*(?:#.*)?$/,
      );
      if (setting) return setting[1] === "true";
    }
  } catch {
    // Herdr enables pane scrollbars by default.
  }
  return true;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (
      ctx.mode !== "tui" ||
      process.env.HERDR_ENV !== "1" ||
      !paneScrollbarsEnabled()
    )
      return;
    ctx.ui.setWidget("herdr-exit-width", (tui) => {
      const terminal = tui.terminal;
      const ownColumns = Object.getOwnPropertyDescriptor(terminal, "columns");
      const getColumns = Object.getOwnPropertyDescriptor(
        Object.getPrototypeOf(terminal),
        "columns",
      )?.get;
      if (ownColumns || !getColumns)
        return { render: () => [], invalidate: () => {} };

      let previousMode = tui.mode;
      let waitingForResize = false;
      let fullscreenWidth = 0;
      const onResize = () => {
        waitingForResize = false;
      };
      process.stdout.on("resize", onResize);

      // Pi renders the exit transcript before Herdr reclaims its scrollbar column.
      Object.defineProperty(terminal, "columns", {
        configurable: true,
        get() {
          const width = getColumns.call(terminal) as number;
          const mode = tui.mode;
          if (mode !== previousMode) {
            waitingForResize =
              previousMode === "fullscreen" && mode === "regular";
            fullscreenWidth = width;
            previousMode = mode;
          }
          if (waitingForResize && width < fullscreenWidth)
            waitingForResize = false;
          return waitingForResize ? Math.max(1, width - 1) : width;
        },
      });

      return {
        render: () => [],
        invalidate: () => {},
        dispose: () => {
          process.stdout.off("resize", onResize);
          delete (terminal as { columns?: number }).columns;
        },
      };
    });
  });
}
