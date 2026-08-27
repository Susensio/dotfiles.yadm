#!/bin/sh
# Claude Code statusline. Reads status JSON on stdin, prints one line.
# Left: folder, branch, diff lines. Right: model, context bar, 5h limit bar.
# Every segment degrades to empty (never "null") if its field is absent.

# Locale with comma decimals makes awk read "0.1234" as 0.
LC_ALL=C
export LC_ALL

input=$(cat)

j() {
  printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

# tput cols cannot see the terminal here; Claude Code exports COLUMNS instead.
width=${COLUMNS:-80}
# Interface indents the row 2 columns and reserves 1 at the right edge; padding
# past width-3 gets clipped to an ellipsis. One more keeps the tail off the edge.
RIGHT_MARGIN=4
BAR_W=16
# Fraction of the model's real window the ctx bar reads against, so the bar goes
# red while there is still room to act. Answer quality decays continuously with
# fill rather than falling off a cliff, so the useful signal is distance from a
# self-imposed budget, not from the hard wall -- Claude Code's own auto-compact
# does not fire until window minus 33k (167k of 200k), long past the point where
# a session is worth clearing. No published number backs any particular fraction.
# Half puts the bar red around 40% real fill: 100k on Opus 5, 500k on Sonnet 5.
SOFT_CTX_FRAC=0.50

RESET='\033[0m'
DIM='\033[2m'
DIR_C='\033[36m'
GIT_C='\033[33m'
DIRTY_C='\033[31m'
ADD_C='\033[32m'
DEL_C='\033[31m'
MODEL_C='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

left=""; left_w=0
right=""; right_w=0

# add <group> <colored> <visible-width>. dash counts ${#} in bytes, so bar
# glyphs must report their width explicitly rather than be measured.
add() {
  group=$1; colored=$2; w=$3
  [ "$w" -le 0 ] && return
  eval "cur=\$$group; cur_w=\${${group}_w}"
  if [ "$cur_w" -eq 0 ]; then
    eval "$group=\$colored; ${group}_w=\$w"
  else
    eval "$group=\"\$cur ${DIM}|${RESET} \$colored\"; ${group}_w=\$((cur_w + 3 + w))"
  fi
}

# Green under 50%, yellow under 80%, red above.
color_for() {
  awk -v p="$1" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" \
    'BEGIN { printf "%s", (p < 50) ? g : (p < 80) ? y : r }'
}

# Filled cells colored by threshold, empty cells dim.
bar() {
  awk -v p="$1" -v n="$BAR_W" -v c="$(color_for "$1")" -v d="$DIM" -v e="$RESET" '
    BEGIN {
      f = int(p / 100 * n + 0.5)
      if (f < 0) f = 0
      if (f > n) f = n
      printf "%s", c
      for (i = 0; i < f; i++) printf "▓"
      printf "%s", d
      for (i = f; i < n; i++) printf "░"
      printf "%s", e
    }'
}

# --- cwd ---
cwd=$(j '.cwd')
[ -z "$cwd" ] && cwd=$(j '.workspace.current_dir')
if [ -n "$cwd" ]; then
  if [ "$cwd" = "$HOME" ]; then
    dir_disp="~"
  else
    dir_disp=$(basename "$cwd")
  fi
  add left "${DIR_C}${dir_disp}${RESET}" "${#dir_disp}"
fi

# --- git branch + dirty ---
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  if git --no-optional-locks -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
      dirty=""
      [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)" ] && dirty="*"
      add left "${GIT_C}${branch}${RESET}${DIRTY_C}${dirty}${RESET}" "$((${#branch} + ${#dirty}))"
    fi
  fi
fi

# --- diff lines ---
added=$(j '.cost.total_lines_added')
removed=$(j '.cost.total_lines_removed')
if [ -n "$added" ] || [ -n "$removed" ]; then
  [ -z "$added" ] && added=0
  [ -z "$removed" ] && removed=0
  add left "${ADD_C}+${added}${RESET}/${DEL_C}-${removed}${RESET}" "$((${#added} + ${#removed} + 3))"
fi

# --- model ---
model=$(j '.model.display_name')
[ -n "$model" ] && add right "${MODEL_C}${model}${RESET}" "${#model}"

# --- context window ---
# Percentage of the soft budget, so it passes 100 while the real window still
# has room. The bar pins full there; the number keeps climbing to show how far
# over. Absent window size just leaves the cap governing.
ctx_tokens=$(j '.context_window.total_input_tokens')
ctx_size=$(j '.context_window.context_window_size')
# Payloads have carried the window size since the field existed; 200k is only a
# floor so a future rename degrades to the old reading rather than to nothing.
[ -z "$ctx_size" ] && ctx_size=200000
if [ -n "$ctx_tokens" ]; then
  ctx=$(awk -v t="$ctx_tokens" -v f="$SOFT_CTX_FRAC" -v w="$ctx_size" \
    'BEGIN { printf "%d", t / (w * f) * 100 + 0.5 }')
  seg="${DIM}ctx${RESET} $(bar "$ctx") ${ctx}%"
  add right "$seg" "$((4 + BAR_W + 2 + ${#ctx}))"
fi

# --- 5h rate limit + time to reset ---
rl=$(j '.rate_limits.five_hour.used_percentage')
if [ -n "$rl" ]; then
  countdown=""
  resets=$(j '.rate_limits.five_hour.resets_at')
  pct=$(awk -v p="$rl" 'BEGIN { printf "%d", p + 0.5 }')
  if [ -n "$resets" ]; then
    if [ "$pct" -ge 100 ]; then
      # At cap, "time left" is meaningless -- show the clock time it lifts instead.
      countdown=$(date -d "@$resets" +%H:%M 2>/dev/null)
    else
      secs=$((resets - $(date +%s)))
      if [ "$secs" -gt 0 ]; then
        h=$((secs / 3600))
        m=$(((secs % 3600) / 60))
        if [ "$h" -gt 0 ]; then
          countdown="${h}h${m}m"
        elif [ "$m" -gt 0 ]; then
          countdown="${m}m"
        else
          countdown="<1m"
        fi
      fi
    fi
  fi
  seg="${DIM}limit${RESET} $(bar "$rl") ${pct}%"
  w=$((6 + BAR_W + 1 + ${#pct} + 1))
  if [ -n "$countdown" ]; then
    seg="${seg} ${DIM}${countdown}${RESET}"
    w=$((w + 1 + ${#countdown}))
  fi
  add right "$seg" "$w"
fi

if [ "$right_w" -eq 0 ]; then
  printf '%b\n' "$left"
  exit 0
fi
if [ "$left_w" -eq 0 ]; then
  printf '%b\n' "$right"
  exit 0
fi

gap=$((width - left_w - right_w - RIGHT_MARGIN))
# Too narrow to right-align: fall back to a single separated line.
if [ "$gap" -lt 2 ]; then
  printf '%b\n' "$left ${DIM}|${RESET} $right"
  exit 0
fi

pad=$(awk -v n="$gap" 'BEGIN { while (n-- > 0) printf " " }')
printf '%b\n' "${left}${pad}${right}"
