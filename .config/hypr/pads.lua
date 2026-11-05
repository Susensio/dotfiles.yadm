-- Named special workspaces ("pads"), one Super chord each.
-- Kept out of hypr/bindings.lua because the geometry here must be written after
-- looknfeel's s[true] rule: Hyprland takes the last matching workspace rule.

-- Shape from Omarchy's qconsole: a window rule's size freezes at map time, so the
-- pad is the work area minus gaps, recomputed from the monitor it opens on.
-- `share` is the fraction of the work area's height, `box` how much wider than
-- that height the panel may get.
local function fit(pad, monitor)
  local active = monitor or hl.get_active_monitor()
  if not active then return end

  local reserved = active.reserved
  local width = active.width / active.scale - reserved.left - reserved.right
  local height = active.height / active.scale - reserved.top - reserved.bottom

  local tall = math.floor(height * pad.share)
  local side = math.floor((width - math.min(width, tall * pad.box)) / 2)

  hl.workspace_rule({
    workspace = "special:" .. pad.name,
    gaps_in = 0,
    gaps_out = { top = 0, right = side, bottom = height - tall, left = side },
  })
end

local PADS = {
  { name = "whatsapp", key = "m", label = "WhatsApp pad",
    class = "zapfast", seed = "zapfast" },

  -- Chromium names an --app window after the URL's host and path.
  { name = "spotify", key = "XF86AudioPlay", label = "Spotify pad",
    class = "^chrome%-open%.spotify%.com__%-Default$",
    seed = "omarchy-launch-webapp https://open.spotify.com/" },

  -- No class: an agent opened from the menu stays where it was opened, and only
  -- this seed lands here, because the toggle has already focused the pad.
  { name = "agent", key = "a", label = "Agent pad",
    seed = "sh -c 'cd ~/.config && exec omarchy-agent --pick'" },
}

for _, pad in ipairs(PADS) do
  local workspace = "special:" .. pad.name
  pad.share = pad.share or 0.5
  pad.box = pad.box or 2

  o.bind("SUPER + " .. pad.key, pad.label, hl.dsp.workspace.toggle_special(pad.name))

  hl.workspace_rule({
    workspace = workspace,
    on_created_empty = pad.seed and ("[workspace " .. workspace .. " silent] " .. pad.seed),
  })

  if pad.class then
    o.window({ class = pad.class }, { workspace = workspace })
  end

  fit(pad)
end

-- A bar height or resolution change moves the work area without a config reload.
hl.on("monitor.layout_changed", function()
  for _, pad in ipairs(PADS) do
    fit(pad)
  end
end)
