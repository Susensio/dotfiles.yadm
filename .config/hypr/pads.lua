-- Named special workspaces ("pads"), declared once: key, label, window class,
-- and seed together. A pad with `move` also gets Shift on its key.

-- Every special workspace shares one shape: the desktop gap scaled up, flush at
-- the top. A window rule's size would freeze at map time; gaps follow the monitor.
local gap = hl.get_config("general.gaps_out")
hl.workspace_rule({
  workspace = "s[true]",
  gaps_out = { top = 0, right = 10 * gap.right, bottom = 5 * gap.bottom, left = 10 * gap.left },
})

-- Omarchy names an --app window after the URL's host and path, and the class
-- match is a substring, so no escaping is needed to make it literal.
local function webapp_class(url)
  local helper = io.popen("omarchy-webapp-window-class " .. url)
  local class = helper:read("*l")
  helper:close()
  return class
end

local PADS = {
  -- Replaces Omarchy's agent console on Super+grave: a plain terminal.
  { name = "term", key = "grave", label = "Terminal pad", move = true,
    seed = "foot" },

  { name = "whatsapp", key = "m", label = "WhatsApp pad",
    class = "zapfast", seed = "zapfast" },

  { name = "spotify", key = "XF86AudioPlay", label = "Spotify pad",
    class = webapp_class("https://open.spotify.com/"),
    seed = "omarchy-launch-webapp https://open.spotify.com/" },

  -- No class: an agent opened from the menu stays where it was opened, and only
  -- this seed lands here, because the toggle has already focused the pad.
  { name = "agent", key = "a", label = "Agent pad",
    seed = "sh -c 'cd ~/.config && exec omarchy-agent --pick'" },
}

for _, pad in ipairs(PADS) do
  local workspace = "special:" .. pad.name

  o.bind("SUPER + " .. pad.key, pad.label, hl.dsp.workspace.toggle_special(pad.name))

  if pad.move then
    o.bind("SUPER + SHIFT + " .. pad.key, "Send window to " .. pad.label,
      hl.dsp.window.move({ workspace = workspace, follow = false }))
  end

  hl.workspace_rule({
    workspace = workspace,
    on_created_empty = pad.seed and ("[workspace " .. workspace .. " silent] " .. pad.seed),
  })

  if pad.class then
    o.window({ class = pad.class }, { workspace = workspace })
  end
end
