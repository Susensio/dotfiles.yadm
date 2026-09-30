-- Cross-layer scheme: docs/keybinds.md; Omarchy defaults off in hypr/hyprland.lua.
require("default.hypr.bindings.media")
require("default.hypr.bindings.clipboard")

-- Focus (crosses monitors)
o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Workspaces; keycodes survive keyboard-layout changes.
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
-- Cycling reaches floating windows that directional focus skips.
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

-- Window actions
o.bind("SUPER + CTRL + H", "Shrink width", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + CTRL + J", "Grow height", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
o.bind("SUPER + CTRL + K", "Shrink height", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
o.bind("SUPER + CTRL + L", "Grow width", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + SHIFT + H", "Swap left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + ALT + H", "Window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + ALT + J", "Window to lower monitor", hl.dsp.window.move({ monitor = "d" }))
o.bind("SUPER + ALT + K", "Window to upper monitor", hl.dsp.window.move({ monitor = "u" }))
o.bind("SUPER + ALT + L", "Window to right monitor", hl.dsp.window.move({ monitor = "r" }))

-- Apps
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
-- tm creates/attaches `main`, or opens sessionizer when called from $HOME
o.bind("SUPER + SHIFT + RETURN", "Tmux", { launch = "omarchy-launch-terminal tm" })
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + W", "Slim browser", { webapp = "https://www.google.com/" })
o.bind("SUPER + SHIFT + W", "Browser", { omarchy = "browser" })
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + A", "Agent", "omarchy-agent --pick")
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")

-- System
-- omarchy-sleep-lock.service secures the session before suspend (ADR-0069).
o.bind("XF86PowerOff", "Suspend", "systemctl suspend-then-hibernate", { locked = true })
o.bind("CTRL + XF86PowerOff", "Lock system", "omarchy-system-lock", { locked = true })
o.bind("SUPER + XF86PowerOff", "System menu", "omarchy-menu toggle system", { locked = true })
o.bind("ALT + XF86PowerOff", "Screensaver", "omarchy-launch-screensaver force", { locked = true })
o.bind("SUPER + ESCAPE", "Activity", { tui = "btop", focus = true })
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })
o.bind("SUPER + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + SHIFT + comma", "Dismiss all notifications", "omarchy-shell notifications dismissAll")
o.bind("SUPER + CTRL + comma", "Notification history", "omarchy-shell notifications showHistory")
o.bind_toggle("SUPER + ALT + comma", "Toggle silencing notifications", "notification-silencing")

-- Bar panels
o.bind("SUPER + CTRL + W", "Wi-Fi panel", "omarchy-shell shell toggle omarchy.network")
o.bind("SUPER + CTRL + B", "Bluetooth panel", "omarchy-shell shell toggle omarchy.bluetooth")
o.bind("SUPER + CTRL + A", "Audio panel", "omarchy-shell shell toggle omarchy.audio")
o.bind("SUPER + CTRL + D", "Display panel", "omarchy-shell shell toggle omarchy.monitor")
o.bind("SUPER + CTRL + P", "Power panel", "omarchy-shell shell toggle omarchy.power")

-- Dictation; voxtype ignores start while recording, so Insert ends a latch.
o.bind("Insert", "Start dictation", "voxtype record start")
o.bind("Insert", "Stop dictation", "voxtype record stop", { release = true })
o.bind("SHIFT + Insert", "Dictate hands-free", "voxtype record toggle")

-- Power profile
o.bind("SUPER + ALT + P", "Cycle power profile", "omarchy-powerprofiles-cycle")

-- Radio toggles
o.bind("SUPER + ALT + W", "Toggle wifi", "bash -lc '[[ $(nmcli -t -f WIFI radio) == enabled ]] && nmcli radio wifi off || nmcli radio wifi on'")
o.bind("SUPER + ALT + B", "Toggle bluetooth", "omarchy-bluetooth-power toggle")

-- Square window
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

-- Capture
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + PRINT", "Capture menu", "omarchy-menu toggle capture")
o.bind("SHIFT + PRINT", "Extract text (OCR)", "omarchy-capture-text")
o.bind("CTRL + PRINT", "Scan QR code", "omarchy-capture-qr")
o.bind("ALT + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")

-- Region picker keys; slurp opens one selection layer per monitor.
local selection_layers = 0
local selection_binds = {}

hl.on("layer.opened", function(layer)
  if layer.namespace == "selection" then
    selection_layers = selection_layers + 1
    if selection_layers == 1 then
      selection_binds = {
        hl.bind("RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-window"),
          { description = "Capture highlighted window" }),
        hl.bind("SHIFT + RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-fullscreen"),
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
      -- Unbind handles, not keys, to preserve any same-key user binding.
      for _, keybind in ipairs(selection_binds) do
        keybind:unbind()
      end
      selection_binds = {}
    end
  end
end)
