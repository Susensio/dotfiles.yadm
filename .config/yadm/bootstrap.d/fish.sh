#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

# Add repo if not present
if ! grep -rq "fish-shell" /etc/apt/sources.list*; then
  log_info "Adding fish shell repository..."
  sudo add-apt-repository -y ppa:fish-shell/release-3
fi

if ! command -v fish &> /dev/null; then
  log_info "Installing fish shell..."
  sudo apt update
  sudo apt install fish
  log_info "Fish shell installed"
fi

# set default interactive shell
BASHRC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/bash/bashrc"
if ! grep --quiet "fish" "$BASHRC_FILE"; then
  log_info "Setting fish as default interactive shell for current user..."
  sudo tee --append "$BASHRC_FILE" << EOF
# Drop into fish cleanly
if [[ $- == *i* ]] &&                                     # 1. Is it an interactive session?
   command -v fish >/dev/null 2>&1 &&                     # 2. Is fish actually installed?
   [[ $(ps -p $PPID -o comm= 2>/dev/null) != *fish* ]] && # 3. Is the parent process NOT fish? (Prevents the bash trap)
   [[ ${SHLVL} =~ ^[12]$ ]]; then                         # 4. Are we at the top shell level? (Prevents breaking subshells)

    # Pass through the login state to fish
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
fi
EOF
fi
# if [ "$SHELL" != "$(which fish)" ]; then
#   log_info "Setting fish as default shell for current user..."
#   sudo chsh -s "$(which fish)" "$USER"
# fi

# # update plugins from fish_plugins if changed
# if [[ -n $(comm -3 \
#     <(fish -c 'fisher list' | tr '[:upper:]' '[:lower:]' | sort) \
#     <(cat ~/.config/fish/fish_plugins |tr '[:upper:]' '[:lower:]' | sort) \
#     &> /dev/null) ]]; then
#   fish -c 'fisher update' &
#   # have to wait bc fisher is async
#   wait
# fi
