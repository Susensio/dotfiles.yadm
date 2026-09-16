#!/usr/bin/env bash
set -eu

SEP=$'\x1f'
LOOKUP_PATHS=($HOME/Projects ${XDG_CONFIG_HOME:-$HOME/.config})

declare -A ICONS=(
  [NEW]="󰄱 "
  [HERDR]=" "
  [DIR]=" "
  [PROJECT]="󰊢 "
  [CONFIG]=" "
  [CODE]=" "
)

to_row() {
  local kind=$1
  local id=$2
  local name=$3
  local path=$4
  local display=$5
  echo "${kind}${SEP}${id}${SEP}${name}${SEP}${path}${SEP}${display}"
}

path_to_row() {
  local path=$1
  local short_path="${path##*/}"
  local kind="DIR"

  case "$path" in
    $HOME/.config/*) kind="CONFIG" ;;
    "$HOME/bin" | $HOME/bin/*) kind="CODE" ;;
    $HOME/Projects/*) kind="PROJECT" ;;
  esac
  local icon=${ICONS[$kind]}
  to_row "$kind" "" "$short_path" "$path" "$icon ${path/#$HOME/\~}"
}

list_sources() {
  to_row "NEW" "" "" "$HOME" "${ICONS[NEW]} +New workspace"

  # 1. Existing Workspaces
  local workspaces_json
  workspaces_json=$(herdr workspace list 2>/dev/null || echo "{}")
  
  if echo "$workspaces_json" | jq -e '.result.workspaces' >/dev/null 2>&1; then
    echo "$workspaces_json" | jq -r '.result.workspaces[] | "\(.workspace_id)\t\(.label)\t\(.focused)"' | while IFS=$'\t' read -r w_id w_label w_focused; do
      # Prioritize focused workspace? No, let's just list them
      to_row "WORKSPACE" "$w_id" "$w_label" "" "${ICONS[HERDR]} $w_label"
    done
  fi

  {
    # 2. Zoxide MRU folders
    zoxide query --list 2>/dev/null | head -n 50 || true

    # 3. Defined lookup dirs
    find "${LOOKUP_PATHS[@]}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true

    # 4. Current directory
    echo "$PWD"
    find "$PWD" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true
  } | awk '!seen[$0]++' | while read -r path; do
    path_to_row "$path"
  done
}

if [[ "${1:-}" == "--list" ]]; then
  list_sources | tail -n +2
  exit
fi

preview_cmd="[[ {1} == 'NEW' ]] && exit || [[ {1} == 'WORKSPACE' ]] && echo -e '\033[1;34mWorkspace:\033[0m {3}' || eza --color=always --icons --tree --level=2 --git-ignore -- {4}"

selection=$(
  list_sources | awk -F"$SEP" '!seen[$3]++' | fzf \
    --delimiter="$SEP" \
    --with-nth=-1 \
    --no-sort \
    --scheme=path \
    --preview="$preview_cmd" \
    --bind="change:reload-sync($0 --list)+unbind(change)"
)

[[ -z "$selection" ]] && exit

IFS=$SEP read -r kind w_id w_name w_path fzf_display <<<"$selection"

case "$kind" in
  NEW)
    herdr workspace create --focus
    ;;
  WORKSPACE)
    herdr workspace focus "$w_id"
    ;;
  *)
    # directory selected
    herdr workspace create --cwd "$w_path" --label "$w_name" --focus
    zoxide add "$w_path" >/dev/null 2>&1 || true
    ;;
esac
