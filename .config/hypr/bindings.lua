-- Keybinds follow the cross-layer scheme in docs/keybinds.md; ADR-0055 has the
-- decision. Omarchy's default bindings are off in hypr/hyprland.lua; its
-- self-contained files are loaded below, and the few lines kept from its
-- utilities.lua are copied here.

-- Volume, brightness, keyboard backlight and media keys
require("default.hypr.bindings.media")
-- Super + C/V/X copy, paste and cut in terminals too; Super + Ctrl + V history
require("default.hypr.bindings.clipboard")
hl.unbind("SUPER + A") -- clipboard.lua's select-all; Super + A opens agents

-- Focus; crosses monitors too
o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Workspaces. Keycodes keep the digits independent of the keyboard layout.
o.bind("SUPER + I", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + O", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))
for workspace = 1, 9 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + " .. key, "Workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- Scratchpad
o.bind("SUPER + grave", "Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + grave", "Move window to scratchpad",
  hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
-- Cycling reaches floating windows, which directional focus skips from a tiled one
o.bind("SUPER + TAB", "Next window", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
o.bind("SUPER + SHIFT + TAB", "Previous window", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
o.bind("SUPER + Z", "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + SHIFT + Z", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + T", "Float or tile", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + backslash", "Switch split direction", hl.dsp.layout("togglesplit"))
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
o.bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Window mode: stays active until Escape or Return so held keys keep resizing
o.bind("SUPER + P", "Window mode", hl.dsp.submap("window"))
hl.define_submap("window", function()
  o.bind("H", "Shrink width", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
  o.bind("J", "Grow height", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
  o.bind("K", "Shrink height", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
  o.bind("L", "Grow width", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
  o.bind("SHIFT + H", "Swap left", hl.dsp.window.swap({ direction = "l" }))
  o.bind("SHIFT + J", "Swap down", hl.dsp.window.swap({ direction = "d" }))
  o.bind("SHIFT + K", "Swap up", hl.dsp.window.swap({ direction = "u" }))
  o.bind("SHIFT + L", "Swap right", hl.dsp.window.swap({ direction = "r" }))
  o.bind("CTRL + H", "Workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
  o.bind("CTRL + J", "Workspace to lower monitor", hl.dsp.workspace.move({ monitor = "d" }))
  o.bind("CTRL + K", "Workspace to upper monitor", hl.dsp.workspace.move({ monitor = "u" }))
  o.bind("CTRL + L", "Workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
  o.bind("ESCAPE", "Leave window mode", hl.dsp.submap("reset"))
  o.bind("RETURN", "Leave window mode", hl.dsp.submap("reset"))
end)

-- Apps; anything else is a search away in the Omarchy menu
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
-- tm creates/attaches `main`, or opens sessionizer when called from $HOME
o.bind("SUPER + SHIFT + RETURN", "Tmux", { launch = "omarchy-launch-terminal tm" })
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
-- An app window: no tabs or address bar
o.bind("SUPER + W", "Slim browser", { webapp = "https://www.google.com/" })
o.bind("SUPER + SHIFT + W", "Browser", { omarchy = "browser" })
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + A", "Agent", "omarchy-agent --pick")
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")

-- System
o.bind("SUPER + ESCAPE", "Lock system", "omarchy-system-lock")
o.bind("XF86PowerOff", "System menu", "omarchy-menu toggle system", { locked = true })
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })
o.bind("SUPER + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + SHIFT + comma", "Dismiss all notifications", "omarchy-shell notifications dismissAll")

-- Screenshot; the region-picker keys below are the utilities.lua copy
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")

local selection_layers = 0
local selection_binds = {}

hl.on("layer.opened", function(layer)
  if layer.namespace == "selection" then
    selection_layers = selection_layers + 1
    if selection_layers == 1 then
      selection_binds = {
        hl.bind("RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-window"),
          { description = "Capture highlighted window" }),
        hl.bind("CTRL + RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-fullscreen"),
          { description = "Capture entire screen" }),
        hl.bind("TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window next"),
          { description = "Select next window to capture" }),
        hl.bind("CTRL + TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window prev"),
          { description = "Select previous window to capture" }),
      }
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        table.insert(
          selection_binds,
          hl.bind(direction:upper(), hl.dsp.exec_cmd("omarchy-capture-region --select-window " .. direction),
            { description = "Select window to capture" })
        )
      end
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == "selection" and selection_layers > 0 then
    selection_layers = selection_layers - 1
    if selection_layers == 0 then
      for _, keybind in ipairs(selection_binds) do
        keybind:unbind()
      end
      selection_binds = {}
    end
  end
end)
