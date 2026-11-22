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
      -- Omarchy damps touchpads to 0.4; 1.0 scrolls at the pad's own deltas.
      scroll_factor = 1.0,
    },
  },
})

-- Chromium and its webapps scroll too fast at the raw base; 0.6 is the middle ground.
o.window("(chromium|chrome-.*)", { scroll_touchpad = 0.6 })

-- One entry per mouse; the name comes from `hyprctl devices`. MX Master 3
hl.device({ name = "logitech-mx-master-3-1", accel_profile = "flat", sensitivity = 0.8 })
