#!/usr/bin/env bash
cat KEYBINDS.md | perl -pe 's/[\[]{2} (.*?) ]]/<kbd>\1<\/kbd>/g'
