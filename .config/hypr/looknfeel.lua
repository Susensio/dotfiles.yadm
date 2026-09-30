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

-- SUPER + CTRL + BACKSPACE: the tagged window dims everything behind it in the
-- same colour maximize uses, so one window can be singled out without leaving
-- the workspace. Tags are per window, so several can be in this mode at once.
o.window(
  { tag = "focus" },
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
