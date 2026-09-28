#!/usr/bin/env bash
# Render Omarchy's theme templates into the current theme, so the tracked
# templates in omarchy/themed/ and any stock template Omarchy updated are live
# without a manual omarchy-theme-refresh (docs/adr/0052). Rendering is otherwise
# triggered only by a theme set, which never happens on a fresh clone, and a
# config that requires a rendered file fails until it exists. Only rendered files
# change here; running apps still retint through Omarchy's theme-set hook.
set -euo pipefail

command -v omarchy-theme-set &>/dev/null || exit 0

STOCK_DIR=${OMARCHY_PATH:-/usr/share/omarchy}/default/themed
USER_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themed
THEME_STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current
THEME_DIR=$THEME_STATE_DIR/theme

# No theme rendered yet: omarchy-theme-set seeds the first one during install.
[[ -d $STOCK_DIR && -d $THEME_DIR ]] || exit 0
theme_name=$(cat "$THEME_STATE_DIR/theme.name" 2>/dev/null) || exit 0
[[ -n $theme_name ]] || exit 0

shopt -s nullglob
user_templates=("$USER_DIR"/*.tpl)
stock_templates=("$STOCK_DIR"/*.tpl)
shopt -u nullglob

stale=()
for template in "${user_templates[@]}"; do
  rendered=$THEME_DIR/$(basename "${template%.tpl}")
  [[ -f $rendered && ! $template -nt $rendered ]] || stale+=("$(basename "$template")")
done
for template in "${stock_templates[@]}"; do
  # A user template of the same name renders this one instead: theme-set-templates
  # generates user templates first and skips an output that already exists, so the
  # stock template's timestamp says nothing about that file.
  [[ -e $USER_DIR/$(basename "$template") ]] && continue
  rendered=$THEME_DIR/$(basename "${template%.tpl}")
  [[ -f $rendered && ! $template -nt $rendered ]] || stale+=("$(basename "$template")")
done

((${#stale[@]})) || exit 0

log info "Rendering Omarchy theme templates: ${stale[*]}"
OMARCHY_THEME_HEADLESS=1 OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "$theme_name"

# Headless mode skips Omarchy's post-theme reload, and a hypr config that failed
# to require its rendered module stays failed until something reloads it.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  omarchy-restart-hyprctl
fi
