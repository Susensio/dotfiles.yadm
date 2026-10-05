-- Overrides on Omarchy's default/hypr/input.lua
hl.config({
  input = {
    -- Caps Lock is keyd's both-Shifts toggle; xkb must not also make Caps Multi_key.
    kb_options = "",
    touchpad = {
      natural_scroll = true,
      -- Right-click in the lower-right corner, besides with two fingers
      clickfinger_behavior = false,
    },
  },
})

-- One entry per mouse; the name comes from `hyprctl devices`. MX Master 3
hl.device({ name = "logitech-mx-master-3-1", accel_profile = "flat", sensitivity = 0.8 })
