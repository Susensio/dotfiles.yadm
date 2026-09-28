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
  },
})

-- SUPER + Z is otherwise invisible.
o.window(
  { fullscreen_state_internal = 1 },
  { border_color = palette.maximize_border, dim_around = true }
)
