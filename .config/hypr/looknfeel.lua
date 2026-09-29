-- Overrides on Omarchy's default/hypr/looknfeel.lua
local palette = require("omarchy.current.theme.hypr-palette")

hl.config({
  -- Omarchy's 1 hands the zoom to the next window that takes focus.
  misc = { on_focus_under_fullscreen = 2 },

  -- Window-level damage leaves the dim overlay over the gaps after unzoom.
  debug = { damage_tracking = 1 },

  -- Fullscreen video scans out directly, cutting ~1-2 frames of compositor latency.
  render = { direct_scanout = true },

  decoration = {
    rounding = 5,
    dim_inactive = true,
    dim_strength = 0.15,
    -- Hyprland's 0.2 dims too little for the covered workspace to read as behind.
    dim_special = 0.5,
  },
})

-- SUPER + Z is otherwise invisible.
o.window(
  { fullscreen_state_internal = 1 },
  { border_color = palette.maximize_border, dim_around = true }
)

-- The bar's workspace strip keeps showing the workspace under a special as
-- focused, and Hyprland reports it as active too, so the overlay has to say so
-- itself: a border twice the weight of a tiled window's, in the active colour
-- the scratchpad chip in the bar also uses.
o.window(
  { workspace = "special:scratchpad" },
  { border_size = 4 }
)
