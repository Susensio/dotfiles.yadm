-- Hyprland's Lua config cannot read colors.toml, so this bakes the palette in.
return {
  maximize_border = "rgb({{ light_foreground_strip }})",
}
