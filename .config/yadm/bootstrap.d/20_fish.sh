#!/usr/bin/env bash
set -euo pipefail

# Add repo if not present
if command -v apt-get &> /dev/null && ! grep -rq "fish-shell" /etc/apt/sources.list*; then
  log info "Adding fish shell repository..."
  sudo add-apt-repository -y ppa:fish-shell/release-4
fi

if ! command -v fish &> /dev/null; then
  log info "Installing fish shell..."
  pkg-install fish
  log info "Fish shell installed"
fi

# set default interactive shell
BASHRC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/bash/bashrc"
RELAY=$(cat << 'EOF'
# >>> fish relay, kept by yadm/bootstrap.d/20_fish.sh >>>
if [[ $- == *i* ]] &&                                     # 1. Is it an interactive session?
   [[ -z ${BASH_EXECUTION_STRING:-} ]] &&                 # 2. Is there no command to run? (`bash -ilc` stays in bash)
   command -v fish >/dev/null 2>&1 &&                     # 3. Is fish actually installed?
   [[ $(ps -p $PPID -o comm= 2>/dev/null) != *fish* ]] && # 4. Is the parent process NOT fish? (Prevents the bash trap)
   [[ ${SHLVL} =~ ^[12]$ ]]; then                         # 5. Are we at the top shell level? (Prevents breaking subshells)

    # Pass through the login state to fish
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
fi
# <<< fish relay <<<
EOF
)
current=$(cat -- "$BASHRC_FILE" 2>/dev/null || true)
rest=$(sed '/^# >>> fish relay/,/^# <<< fish relay/d' <<<"$current" | sed '/./,$!d')
# Prepended, so bash hands over before running the rest of its startup
wanted=$(printf '%s\n\n%s' "$RELAY" "$rest")
if [[ $wanted != "$current" ]]; then
  log info "Writing the fish relay into $BASHRC_FILE..."
  mkdir --parents -- "$(dirname -- "$BASHRC_FILE")"
  printf '%s\n' "$wanted" >"$BASHRC_FILE"
fi

# if [ "$SHELL" != "$(which fish)" ]; then
#   log info "Setting fish as default shell for current user..."
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
