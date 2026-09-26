-- Overrides on Omarchy's default/hypr/input.lua; hl.config merges, so only the
-- settings that differ are listed.
hl.config({
  input = {
    touchpad = {
      -- Content follows the fingers, as on a phone
      natural_scroll = true,
      -- Right-click with the pad's lower-right corner, not a two-finger click
      clickfinger_behavior = false,
    },
  },
})
