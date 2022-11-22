function myip -d "Return external IP from DNS"
	dig +short myip.opendns.com @resolver1.opendns.com
end

