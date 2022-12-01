#!/bin/sh
# Five arguments are passed to the file, (1) current file name, (2) width, (3) height, (4) horizontal position, and (5) vertical position of preview pane respectively.

image() {
  chafa "$1" -s "$2"x"$3"
}

text() {
  file="$1"
  # save bat args to $@
  set -- "--paging=never" "--style=auto" "-f"
  if command -v batcat >/dev/null 2>&1; then
    batcat "$@" "$file"
  elif command -v bat >/dev/null 2>&1; then
    bat "$@" "$file"
  else
    cat "$file"
  fi
}

case "$1" in
  *.tar*) tar tf "$1";;
  *.zip) unzip -l "$1";;
  *.rar) unrar l "$1";;
  *.7z) 7z l "$1";;
  *.pdf) pdftotext "$1" -;;
  *.jpg) image "$@" ;;
  *.jpeg) image "$@" ;;
  *.png) image "$@" ;;
  *.gif) image "$@" ;;
  *.bmp) image "$@" ;;
  *) text "$@";;
esac
