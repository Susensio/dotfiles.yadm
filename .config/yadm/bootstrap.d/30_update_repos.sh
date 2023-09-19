#!/usr/bin/env bash
mkdir -p ~/.local/bin
mkdir -p "${XDG_DATA_HOME}/man/man1"

PATH=~/bin:$PATH update-repos
