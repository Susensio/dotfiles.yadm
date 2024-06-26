function myip -d "Return public and local IPs"
  set -l options l/local p/public
  argparse $options -- $argv
  or return

  if set -q _flag_local
    _local_ip
    return 0
  end

  if set -q _flag_public
    _public_ip
    return 0
  end

  # Default

  # printf because of \t
  printfn "Public IP:\t$(_public_ip)"
  printfn "Local IP:\t$(_local_ip)"

end

function _local_ip
  echo (ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
end

function _public_ip
  dig +short myip.opendns.com @resolver1.opendns.com
end
