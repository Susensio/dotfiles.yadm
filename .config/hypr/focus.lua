-- Focus mode: the window floats at 4:3 in the middle of the monitor while the
-- tag rule in hypr/looknfeel.lua dims everything behind it. The tag is per
-- window, so several can hold it at once; it survives a reload while the size
-- does not, and toggling off returns the window to the layout.

local function tagged_focus(window)
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "focus" then
      return true
    end
  end
  return false
end

-- 4:3 of the monitor's height, narrowed when that would leave no side margin.
local function focus_size(monitor)
  local width = math.floor(monitor.width / monitor.scale * 0.95)
  local height = math.floor(monitor.height / monitor.scale * 0.85)
  if math.floor(height * 4 / 3) <= width then
    return math.floor(height * 4 / 3), height
  end
  return width, math.floor(width * 3 / 4)
end

o.bind("SUPER + CTRL + BACKSPACE", "Focus window", function()
  local window = hl.get_active_window()
  if not window then
    return
  end

  if tagged_focus(window) then
    hl.dispatch(hl.dsp.window.tag({ tag = "-focus" }))
    hl.dispatch(hl.dsp.window.float({ action = "unset" }))
    return
  end

  local monitor = hl.get_active_monitor()
  if not monitor then
    return
  end

  local width, height = focus_size(monitor)
  hl.dispatch(hl.dsp.window.tag({ tag = "+focus" }))
  hl.dispatch(hl.dsp.window.float({ action = "set" }))
  hl.dispatch(hl.dsp.window.resize({ x = width, y = height }))
  hl.dispatch(hl.dsp.window.center())
end)
