-- Overrides on Omarchy's default/hypr/looknfeel.lua
local palette = require("omarchy.current.theme.hypr-palette")

hl.config({
  -- Omarchy's 1 hands the zoom to the next window that takes focus.
  misc = { on_focus_under_fullscreen = 2 },

  -- Window-level damage leaves the dim overlay over the gaps after unzoom.
  debug = { damage_tracking = 1 },

  decoration = {
    rounding = 5,
    dim_inactive = true,
    dim_strength = 0.15,
    -- Hyprland's 0.2 dims too little for the covered workspace to read as behind.
    dim_special = 0.5,
    dim_around = 0.3
  },
})

-- SUPER + Z is otherwise invisible.
o.window(
  { fullscreen_state_internal = 1 },
  { border_color = palette.maximize_border, dim_around = true }
)

-- f[1] matches a workspace with a maximized window: wider side gaps give it the zen ratio.
local zen_ratio = 4 / 3
local gap = hl.get_config("general.gaps_out")
local monitor = hl.get_active_monitor()
local side = gap.left
if monitor then
  local height = monitor.height / monitor.scale - monitor.reserved.top - monitor.reserved.bottom - gap.top - gap.bottom
  side = math.max(gap.left, math.floor((monitor.width / monitor.scale - height * zen_ratio) / 2))
end
hl.workspace_rule({ workspace = "f[1]", gaps_out = { top = gap.top, right = side, bottom = gap.bottom, left = side } })

-- The bar's workspace strip keeps showing the workspace under a special as
-- focused, and Hyprland reports it as active too, so the overlay has to say so
-- itself: a border twice the weight of a tiled window's, in the active colour
-- the scratchpad chip in the bar also uses.
o.window(
  { workspace = "special:scratchpad" },
  { border_size = 4 }
)
