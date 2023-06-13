function git-sim
  set --local tempdir "/tmp/git-sim"(git rev-parse --show-toplevel)
  command git-sim --media-dir=$tempdir $argv
end
