function purge --description 'Purge previously only removed packages'
  dpkg -l | grep '^rc' | awk '{print $2}' | sudo xargs --no-run-if-empty dpkg --purge
end
