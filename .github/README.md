# Dotfiles

Personal [yadm](https://yadm.io/) dotfiles, rooted at `$HOME`.

## New machine

Installs curl and git, clones this repository and runs `yadm bootstrap`. Needs curl or wget to start.
Run it with `source`, so `yadm` stays available in your shell afterwards.

```bash
source <(curl -fsSL https://raw.githubusercontent.com/Susensio/dotfiles.yadm/master/.config/yadm/new-machine)
```

```bash
source <(wget -qO- https://raw.githubusercontent.com/Susensio/dotfiles.yadm/master/.config/yadm/new-machine)
```

It replaces any file on the machine that the repository also tracks. Rerun it with `new_machine`.
