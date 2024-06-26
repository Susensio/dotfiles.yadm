function cb --description 'Allow piping to and from the system ClipBoard'
  # `echo "hi" | cb` copies "hi" to system clipboard
  # `cb` outputs clipboard contents and can be piped
  # This depends on fish 3.6.0
  if isatty stdin
    # Paste
    # xclip -o -selection clipboard
    clipboard paste
  else
    # Copy
    clipboard copy
    # xclip -selection clipboard
  end
end
