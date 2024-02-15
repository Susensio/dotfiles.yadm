function fzf --wraps fzf --description 'FZF with adaptative min-height'
  # It keeps `MIN_MARGIN` shell lines visible
  set -l MIN_MARGIN 1
  set -l MIN_HEIGHT 20
  set -l threshold $(math $MIN_HEIGHT + $MIN_MARGIN)
  set -l screen_height $(tput lines)

  if test $screen_height -gt $threshold
    set -a argv "--min-height=$MIN_HEIGHT"
  else
    set -l min_height_corrected $(math $screen_height - $MIN_MARGIN)
    set -a argv "--min-height=$min_height_corrected"
  end

  command fzf $argv
  # if command -vq tmux && set -q TMUX
  #   command fzf-tmux-auto -- $argv
  # else
  #   command fzf $argv
  # end
  commandline -f repaint
end
