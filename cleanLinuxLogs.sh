#!/usr/bin/env bash

name=$(hostname)

echo "[Info]$ Cleaning $name$ \n"
cache=$(find /var/cache/ -type f)
if [[ -z "$cache" ]]; then
  echo "It appears there are no cached files on your system. \n"
  sleep 1
else
  echo "cache \n"
  echo "Cache in $name$"
  #read -p "Would you like to remove the selected cache listed above? [y/N] " -n 1 -r
  echo
  #if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing cache"
    find /var/cache -type f -delete
    echo "Successfully Removed cache"
    sleep 1
  #fi
fi

echo "[Info] Cleaning $name$ \n"
logs=$(find /var/log/ -type f)
if [[ -z "$logs" ]]; then
  echo  "It appears there are no logs on your system. \n"
  sleep 1
else
  echo "logs \n"
  echo "Logs in $name$"
  #read -p "Would you like to remove the selected logs listed above? [y/N] " -n 1 -r
  echo
  #if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing logs"
    find /var/log -type f -delete
    echo "Successfully Removed logs"
    sleep 1
  #fi
fi

echo  "[Info]$ Cleaning $name$ \n"
echo  "Populating apt lists \n"
