-- Overrides on Omarchy's default/hypr/input.lua
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
      -- Right-click in the lower-right corner, besides with two fingers
      clickfinger_behavior = false,
    },
  },
})

-- One entry per mouse; the name comes from `hyprctl devices`. MX Master 3
hl.device({ name = "logitech-mx-master-3-1", accel_profile = "flat", sensitivity = 0.8 })
