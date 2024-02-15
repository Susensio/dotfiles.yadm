function cb --description 'Allow piping to and from the system ClipBoard'
  # `echo "hi" | cb` copies "hi" to system clipboard
  # `cb` outputs clipboard contents and can be piped
  # This depends on fish 3.6.0
  if isatty stdin
    # Paste
    # xclip -o -selection clipboard
    fish_clipboard_paste
  else
    # Copy
    # xclip -selection clipboard
    fish_clipboard_copy
  end
end
