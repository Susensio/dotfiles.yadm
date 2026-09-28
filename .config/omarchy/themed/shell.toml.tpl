# User template: pins only the bar surface, darker than the theme's general
# background. Omarchy's stock shell.toml.tpl renders every other surface; keys
# left out here fall back in Color.qml/Style.qml to the same value the stock
# template renders, so re-check those fallbacks when Omarchy's shell surfaces
# change. A machine-level omarchy/shell.toml key would win over this file.

[bar]
background = "{{ darker_background }}"
