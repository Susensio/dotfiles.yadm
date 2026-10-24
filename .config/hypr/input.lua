-- Overrides on Omarchy's default/hypr/input.lua
hl.config({
  input = {
    -- Caps Lock is keyd's both-Shifts toggle; xkb must not also make Caps Multi_key.
    kb_options = "",
    -- Spanish on AltGr (á é í ó ú ñ ü ¿ ¡). AltGr is keyd's rightalt = oneshot(altgr);
    -- us(altgr-intl) relies on Right Alt as level3, so removing that binding breaks this.
    kb_layout = "us",
    kb_variant = "altgr-intl",
    touchpad = {
      natural_scroll = true,
      -- Right-click in the lower-right corner, besides with two fingers
      clickfinger_behavior = false,
    },
  },
})

-- ZapFast and Spotifast each apply their own 1.8x to the 0.4x Omarchy leaves
-- every touchpad; 1 cancels that out, so they scroll at the pad's own deltas.
o.window("zapfast", { scroll_touchpad = 1 })
o.window("spotifast", { scroll_touchpad = 1 })

-- One entry per mouse; the name comes from `hyprctl devices`. MX Master 3
hl.device({ name = "logitech-mx-master-3-1", accel_profile = "flat", sensitivity = 0.8 })
