# Dotfiles

Personal [yadm](https://yadm.io/) dotfiles, rooted at `$HOME`.

## New machine

In Bash, keep the same shell open:

```bash
source <(curl -fsSL https://bootstrap.yadm.io) && yadm clone --no-bootstrap -b master https://github.com/Susensio/dotfiles.yadm.git
```

On Omarchy, review any pre-existing files reported by the clone, then check out the tracked versions:

```bash
yadm checkout -- ~/.config
```

Finally:

```bash
yadm bootstrap
```
