#!/usr/bin/env bash
# Do not checkout README.md
~/.local/bin/yadm gitconfig core.sparseCheckout true
( cd \
  && ~/.local/bin/yadm sparse-checkout set  '/*' '!/README.md' '!/.github' \
  && ~/.local/bin/yadm sparse-checkout reapply \
)
