
#!/usr/bin/env bash

# Copyright (c) 2021-2023 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

BL=$(echo "\033[36m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
name=$(hostname)

echo "${BL}[Info]${GN} Cleaning $name${CL} \n"
cache=$(find /var/cache/ -type f)
if [[ -z "$cache" ]]; then
  echo "It appears there are no cached files on your system. \n"
  sleep 1
else
  echo "$cache \n"
  echo "${GN}Cache in $name${CL}"
  #read -p "Would you like to remove the selected cache listed above? [y/N] " -n 1 -r
  echo
  #if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing cache"
    find /var/cache -type f -delete
    echo "Successfully Removed cache"
    sleep 1
  #fi
fi

echo "${BL}[Info]${GN} Cleaning $name${CL} \n"
logs=$(find /var/log/ -type f)
if [[ -z "$logs" ]]; then
  echo  "It appears there are no logs on your system. \n"
  sleep 1
else
  echo "$logs \n"
  echo "${GN}Logs in $name${CL}"
  #read -p "Would you like to remove the selected logs listed above? [y/N] " -n 1 -r
  echo
  #if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing logs"
    find /var/log -type f -delete
    echo "Successfully Removed logs"
    sleep 1
  #fi
fi

echo  "${BL}[Info]${GN} Cleaning $name${CL} \n"
echo  "${GN}Populating apt lists${CL} \n"
