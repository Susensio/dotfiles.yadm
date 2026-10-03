# Syntax
"keyword" = "red_bright"
"keyword.control" = { fg = "red_bright", modifiers = ["italic"] }
"function" = "green_bright"
"function.builtin" = "cyan"
"function.macro" = "orange"
"type" = "yellow_bright"
"type.builtin" = "yellow"
"type.enum.variant" = "cyan"
"constructor" = "green_bright"
"constant" = "magenta_bright"
"constant.builtin" = "magenta_bright"
"constant.numeric" = "magenta_bright"
"constant.character" = "cyan"
"constant.character.escape" = "orange"
"string" = "green_bright"
"string.regexp" = "orange"
"string.special" = "cyan"
"comment" = { fg = "muted", modifiers = ["italic"] }
"variable" = "foreground"
"variable.parameter" = { fg = "blue_bright", modifiers = ["italic"] }
"variable.builtin" = "orange"
"variable.other.member" = "cyan"
"label" = "cyan"
"punctuation" = "muted"
"punctuation.special" = "orange"
"operator" = "magenta_bright"
"tag" = "cyan"
"namespace" = { fg = "blue", modifiers = ["italic"] }
"special" = "orange"
"attribute" = "cyan"

# Markup
"markup.heading.1" = "red_bright"
"markup.heading.2" = "orange"
"markup.heading.3" = "yellow_bright"
"markup.heading.4" = "green_bright"
"markup.heading.5" = "cyan"
"markup.heading.6" = "magenta_bright"
"markup.list" = "cyan"
"markup.list.unchecked" = "muted"
"markup.list.checked" = "green_bright"
"markup.bold" = { modifiers = ["bold"] }
"markup.italic" = { modifiers = ["italic"] }
"markup.strikethrough" = { modifiers = ["crossed_out"] }
"markup.link.url" = { fg = "blue_bright", modifiers = ["italic", "underlined"] }
"markup.link.text" = "magenta"
"markup.link.label" = "cyan"
"markup.raw" = "green_bright"
"markup.quote" = "magenta"

# Diff
"diff.plus" = "green_bright"
"diff.minus" = "red_bright"
"diff.delta" = "yellow_bright"

# Leave the editor background transparent so the terminal background shows through
"ui.background" = { }

"ui.linenr" = { fg = "muted" }
"ui.linenr.selected" = { fg = "accent" }

# Statusline uses an inverted band (background-color text on foreground-color
# background) to guarantee contrast across both light and dark Omarchy themes.
"ui.statusline" = { fg = "background", bg = "foreground" }
"ui.statusline.inactive" = { fg = "background", bg = "muted" }
"ui.statusline.normal" = { fg = "background", bg = "blue", modifiers = ["bold"] }
"ui.statusline.insert" = { fg = "background", bg = "green", modifiers = ["bold"] }
"ui.statusline.select" = { fg = "background", bg = "magenta", modifiers = ["bold"] }

"ui.popup" = { fg = "foreground", bg = "background" }
"ui.window" = { fg = "muted" }
"ui.help" = { fg = "foreground", bg = "background" }

"ui.bufferline" = { fg = "muted", bg = "background" }
"ui.bufferline.active" = { fg = "foreground", bg = "background", underline = { color = "magenta", style = "line" } }

"ui.text" = "foreground"
"ui.text.focus" = { fg = "foreground", bg = "lighter_background", modifiers = ["bold"] }
"ui.text.inactive" = { fg = "muted" }
"ui.text.directory" = { fg = "blue_bright" }

"ui.virtual" = "muted"
"ui.virtual.ruler" = { bg = "lighter_background" }
"ui.virtual.indent-guide" = "muted"
"ui.virtual.inlay-hint" = { fg = "muted" }
"ui.virtual.jump-label" = { fg = "red_bright", modifiers = ["bold"] }
"ui.virtual.whitespace" = "muted"

"ui.selection" = { bg = "selection_background", fg = "selection_foreground" }

"ui.cursor" = { fg = "background", bg = "bright_foreground" }
"ui.cursor.primary" = { fg = "background", bg = "bright_foreground" }
"ui.cursor.match" = { fg = "yellow", modifiers = ["bold"] }
"ui.cursor.primary.normal" = { fg = "background", bg = "bright_foreground" }
"ui.cursor.primary.insert" = { fg = "background", bg = "green" }
"ui.cursor.primary.select" = { fg = "background", bg = "magenta" }

"ui.cursorline.primary" = { bg = "lighter_background" }

"ui.highlight" = { bg = "lighter_background", modifiers = ["bold"] }

"ui.menu" = { fg = "foreground", bg = "background" }
"ui.menu.selected" = { fg = "background", bg = "foreground", modifiers = ["bold"] }

"diagnostic.error" = { underline = { color = "red", style = "curl" } }
"diagnostic.warning" = { underline = { color = "yellow", style = "curl" } }
"diagnostic.info" = { underline = { color = "blue", style = "curl" } }
"diagnostic.hint" = { underline = { color = "cyan", style = "curl" } }
"diagnostic.unnecessary" = { modifiers = ["dim"] }
"diagnostic.deprecated" = { modifiers = ["crossed_out"] }

error = "red"
warning = "yellow"
info = "blue"
hint = "cyan"


# Helix asks for a bare markup.heading in query sets without levels (git commit subjects).
"markup.heading" = "red_bright"
"string.special.symbol" = "red"

[palette]
background = "{{ background }}"
foreground = "{{ foreground }}"
lighter_background = "{{ lighter_background }}"
bright_foreground = "{{ bright_foreground }}"
muted = "{{ muted }}"
accent = "{{ accent }}"
selection_background = "{{ selection_background }}"
selection_foreground = "{{ selection_foreground }}"
red = "{{ red }}"
green = "{{ green }}"
yellow = "{{ yellow }}"
orange = "{{ orange }}"
blue = "{{ blue }}"
magenta = "{{ magenta }}"
cyan = "{{ cyan }}"
red_bright = "{{ bright_red }}"
green_bright = "{{ bright_green }}"
yellow_bright = "{{ bright_yellow }}"
blue_bright = "{{ bright_blue }}"
magenta_bright = "{{ bright_magenta }}"
