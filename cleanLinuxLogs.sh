#!/usr/bin/env bash

# Copyright (c) 2021-2023 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

name=$(hostname)
header_info
echo -e "Cleaning $name$\n"
cache=$(find /var/cache/ -type f)
if [[ -z "$cache" ]]; then
  echo -e "It appears there are no cached files on your system. \n"
  sleep 2
else
  echo -e "$cache \n"
  echo -e "${GN}Cache in $name${CL}"
  read -p "Would you like to remove the selected cache listed above? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing cache"
    find /var/cache -type f -delete
    echo "Successfully Removed cache"
    sleep 2
  fi
fi

echo -e "${BL}[Info]${GN} Cleaning $name${CL} \n"
logs=$(find /var/log/ -type f)
if [[ -z "$logs" ]]; then
  echo -e "It appears there are no logs on your system. \n"
  sleep 2
else
  echo -e "$logs \n"
  echo -e "${GN}Logs in $name${CL}"
  read -p "Would you like to remove the selected logs listed above? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing logs"
    find /var/log -type f -delete
    echo "Successfully Removed logs"
    sleep 2
  fi
fi
