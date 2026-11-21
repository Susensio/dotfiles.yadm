# Import systemd user environment variables into Fish
# Interactive: every pane, popup and nested shell is a fresh terminal session
# that must not inherit a stale parent env (ADR-0003's amended trigger).
# Login: kept for non-interactive `fish -lc` script entries, e.g. the SSH
# `clipboard` path on the nuc (ADR-0113).
if status is-interactive; or status is-login; and type -q systemctl
    _env_pull
end

# COLORTERM states the outer terminal's 24-bit capability, and no transport
# carries it to a remote shell: Tailscale SSH forwards no env at all, and
# OpenSSH needs per-host SendEnv plumbing (docs/adr/0109). Every terminal we
# actually sit at (foot, alacritty, Termux) is truecolor, so re-assert the
# claim where the transport lost it — except on the kernel console
# (TERM=linux, 8 colors), and inside tmux, which sets COLORTERM itself from
# its own client-capability match (tmux/conf.d/10_main.conf) and whose
# refusal must stand. herdr panes always carry COLORTERM, so the first
# check already defers to them.
if status is-interactive; and not set -q COLORTERM; and not set -q TMUX; and test "$TERM" != linux
    set -gx COLORTERM truecolor
end
