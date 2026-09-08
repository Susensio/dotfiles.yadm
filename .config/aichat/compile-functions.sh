#!/usr/bin/env bash
set -euo pipefail

aichat_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$aichat_dir/functions-src"
output_dir="$aichat_dir/functions"
upstream_dir="${XDG_LIB_HOME:-$HOME/.local/lib}/llm-functions"
upstream_url=https://github.com/sigoden/llm-functions.git

if [[ -d "$upstream_dir/.git" ]]; then
	git -C "$upstream_dir" pull --ff-only
else
	mkdir -p -- "$(dirname -- "$upstream_dir")"
	git clone --depth 1 "$upstream_url" "$upstream_dir"
fi

mkdir -p -- "$output_dir"
rm -rf -- "$aichat_dir"/functions/bin "$aichat_dir"/functions/cache "$aichat_dir"/functions/functions.json

rsync --archive --delete \
	--exclude=.git/ \
	--exclude=.env \
	--exclude=bin/ \
	--exclude=cache/ \
	--exclude=functions.json \
	"$upstream_dir/" "$output_dir/"

rsync --archive "$source_dir/" "$output_dir/"

cd -- "$output_dir"
argc build
