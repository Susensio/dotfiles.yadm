#!/usr/bin/env bash
if command -v mise &> /dev/null; then
  [[ -n "${DEBUG-}" ]] && echo "mise is already installed" >&2
  exit 0
else
  echo "Installing mise..." >&2

  sudo apt update -y && sudo apt install -y curl
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update -y
  sudo apt install -y mise

  echo "mise installed" >&2
fi


# Integrate with fish
# vendor_conf_path="/usr/share/fish/vendor_conf.d"
# mkdir -p "$vendor_conf_path" && echo 'mise activate fish | source' | sudo tee "$vendor_conf_path/mise.fish" 1> /dev/null
vendor_completions_path="/usr/share/fish/vendor_completions.d"
mkdir -p "$vendor_completions_path" && mise completion fish | sudo tee "$vendor_completions_path/mise.fish" 1> /dev/null

