# shellcheck shell=bash
# Omarchy installs plugins under HOME/.config even when XDG_CONFIG_HOME differs.
plugin_sources=$HOME/.config/omarchy/plugins.conf
plugin_ignores=$HOME/.config/omarchy/.gitignore

plugin_id_valid() {
  [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $1 != *..* ]]
}

# Do not track machine-local or credential-bearing URLs.
plugin_url_valid() {
  [[ $1 =~ ^https://[[:alnum:]._-]+(:[0-9]+)?/[^@[:space:]?#]+$ ||
     $1 =~ ^git@[[:alnum:]._-]+:[^@[:space:]?#]+$ ||
     $1 =~ ^ssh://git@[[:alnum:]._-]+(:[0-9]+)?/[^@[:space:]?#]+$ ]]
}

plugin_append_line() {
  local file=$1 line=$2
  if [[ -s $file && $(tail -c 1 "$file" | wc -l) -eq 0 ]]; then
    printf '\n' >> "$file"
  fi
  printf '%s\n' "$line" >> "$file"
}

plugin_with_lock() {
  local fd
  mkdir -p "$HOME/.local/state/yadm"
  exec {fd}> "$HOME/.local/state/yadm/omarchy-plugins.lock"
  flock -x "$fd"
  "$@"
  exec {fd}>&-
}

plugin_drop_line() {
  local file=$1 id=$2 kind=$3 tmp
  tmp=$(mktemp "${file}.XXXXXX") || return 1
  if [[ $kind == source ]]; then
    awk -F '\t' -v id="$id" '$1 != id' "$file" > "$tmp"
  else
    awk -v line="plugins/$id/" '$0 != line' "$file" > "$tmp"
  fi
  chmod --reference="$file" "$tmp"
  mv -- "$tmp" "$file"
}

record_plugin_source() {
  local id=$1 url=$2 current=
  plugin_id_valid "$id" || return 1
  plugin_url_valid "$url" || return 1
  [[ -f $plugin_sources && -f $plugin_ignores ]] || return 1

  current=$(awk -F '\t' -v id="$id" '$1 == id { print $2; exit }' "$plugin_sources")
  if [[ -n $current && $current != "$url" ]]; then
    plugin_drop_line "$plugin_sources" "$id" source
  fi
  if [[ $current != "$url" ]]; then
    plugin_append_line "$plugin_sources" "$(printf '%s\t%s' "$id" "$url")"
  fi
  grep -Fxq -- "plugins/$id/" "$plugin_ignores" || plugin_append_line "$plugin_ignores" "plugins/$id/"
}

forget_plugin_source() {
  local id=$1
  plugin_id_valid "$id" || return 1
  [[ -f $plugin_sources && -f $plugin_ignores ]] || return 1
  if awk -F '\t' -v id="$id" '$1 == id { found=1 } END { exit !found }' "$plugin_sources"; then
    plugin_drop_line "$plugin_sources" "$id" source
  fi
  if grep -Fxq -- "plugins/$id/" "$plugin_ignores"; then
    plugin_drop_line "$plugin_ignores" "$id" ignore
  fi
}
