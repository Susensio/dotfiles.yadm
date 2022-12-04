function myip -d "Return public and local IPs"
  set -l options l/local p/public
  argparse $options -- $argv
  or return

  if set -q _flag_local
    __local_ip
    return 0
  end
  
  if set -q _flag_public
    __public_ip
    return 0
  end

  # Default

  printfn "Public IP:\t$(__public_ip)"
  printfn "Local IP:\t$(__local_ip)"

end

function __local_ip
  echo (ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
end

function __public_ip
  dig +short myip.opendns.com @resolver1.opendns.com
end
