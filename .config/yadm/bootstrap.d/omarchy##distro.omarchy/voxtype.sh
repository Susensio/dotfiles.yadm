#!/usr/bin/env bash
# Provisions dictation in place of omarchy-voxtype-install, which prompts, overwrites the
# tracked voxtype/config.toml with its template and runs `gpu --enable` unprivileged
# behind `|| true` (omarchy#11110). The packages are in mise/conf.d/omarchy.toml.
set -euo pipefail

command -v voxtype &>/dev/null || exit 0

changed=false

# Derive the model from the tracked config so the two cannot drift.
config=${XDG_CONFIG_HOME:-$HOME/.config}/voxtype/config.toml
model=$(sed -n 's/^model = "\([^"/]*\)"$/\1/p' "$config" | head -1)
model=${model:-small}
model_file=${XDG_DATA_HOME:-$HOME/.local/share}/voxtype/models/ggml-$model.bin
if [[ ! -f $model_file ]]; then
  voxtype setup --download --model "$model" --no-post-install
  changed=true
fi

# The Alt + Insert key (hypr/bindings.lua) records with multilingual small for Spanish.
if [[ ! -f ${model_file%/*}/ggml-small.bin ]]; then
  voxtype setup --download --model small --no-post-install
  changed=true
fi

# Only where the hardware offers it; elsewhere the CPU build is the right one.
if omarchy-hw-vulkan 2>/dev/null && [[ $(readlink -f /usr/bin/voxtype) != */voxtype-vulkan ]]; then
  sudo voxtype setup gpu --enable
  changed=true
fi

# Omarchy's first-run hook offers the installer once; accepting it would overwrite the config.
omarchy-done check voxtype-install-invitation || omarchy-done mark voxtype-install-invitation

# The package ships the unit; headless runs (omarchy update over SSH) have no user manager.
if systemctl --user show-environment &>/dev/null && ! systemctl --user is-enabled --quiet voxtype.service; then
  systemctl --user enable voxtype.service
  changed=true
fi

if $changed && systemctl --user is-active --quiet graphical-session.target; then
  systemctl --user restart voxtype.service
fi
