function cb --description 'Allow piping to and from the system ClipBoard'
  # `echo "hi" | cb` copies "hi" to system clipboard
  # `cb` outputs clipboard contents
  if isatty stdin
    # Paste
    xclip -o -selection clipboard
  else
    # Copy
    xclip -selection clipboard
  end
end
