# Proxmox VE LXC Updater
# This script has been created to simplify and speed up the process of updating all LXC containers across various Linux distributions, such as Ubuntu, Debian, Devuan, Alpine Linux, CentOS-Rocky-Alma, Fedora, and ArchLinux. It's designed to automatically skip templates and specific containers during the update, enhancing its convenience and usability.
# Run the command below in the Proxmox VE Shell.
# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"

#!/usr/bin/env bash

# Below for  URL encoding - sanjeev
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
} # end function

sendtelegram () {
  local data="Proxmox Server __NEWLINE____NEWLINE__Below Proxmox Containers need restart since their Kernal was updated__NEWLINE____NEWLINE__ ${1} __NEWLINE__"
  # echo "${data}"
  curl -k -X POST --connect-timeout 5 https://post.telegram.sc.home?msg=$( rawurlencode "$data" )
} # end function




# Copyright (c) 2021-2023 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE


set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

echo "Loading..."
whiptail --title "Proxmox VE Helper Scripts - Proxmox VE LXC Updater" --infobox "This Will Update LXC Containers." 8 78


NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
# excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from updates:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

function needs_reboot() {
    local container=$1
    local os=$(pct config "$container" | awk '/^ostype/ {print $2}')
    local reboot_required_file="/var/run/reboot-required.pkgs"
    if [ -f "$reboot_required_file" ]; then
        if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
            if pct exec "$container" -- [ -s "$reboot_required_file" ]; then
                return 0
            fi
        fi
    fi
    return 1
} # end function

function update_container() {
  container=$1

  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"

    usedspace=${disk_info_array[0]}
    maxallowed=70

    if [ "$usedspace" -gt "$maxallowed" ]; then
       echo "Send telegram - continer running out of space"
       msg="Proxmox Server__NEWLINE____NEWLINE__Below Proxmox Containers running out of HDD space __NEWLINE____NEWLINE__Id: ${container} __NEWLINE__Name: ${name}.sc __NEWLINE__Total HDD Capicity: ${disk_info_array[2]}b __NEWLINE__Used Space: ${disk_info_array[1]}b [${disk_info_array[0]}% used] __NEWLINE__Free Space: ${disk_info_array[3]}b __NEWLINE__Alert Threshold Percentage: ${maxallowed}% __NEWLINE____NEWLINE__"
       echo "$msg"
       curl -k -X POST --connect-timeout 5 https://post.telegram.sc.home?msg=$( rawurlencode "$msg" )
       sleep 5
    fi



  else
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  case "$os" in
  alpine) pct exec "$container" -- ash -c "apk update && apk upgrade" ;;
  archlinux) pct exec "$container" -- bash -c "pacman -Syyu --noconfirm" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "dnf -y update && dnf -y upgrade" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "apt-get update 2>/dev/null | grep 'packages.*upgraded'; apt list --upgradable && apt-get -y dist-upgrade" ;;
  esac
}

containers_needing_reboot=()

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then

    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    status=$(pct status $container)
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      update_container $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      update_container $container
    fi
    if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
        # Get the container's hostname and add it to the list
        container_hostname=$(pct exec "$container" hostname)
        containers_needing_reboot+=("$container ($container_hostname)")
    fi
  fi
done
wait

echo -e "${GN}The process is complete, and the selected containers have been updated.${CL}\n"
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
    cntname=""
    counter=1

    echo -e "${RD}The following containers require a reboot:${CL}"
    for container_name in "${containers_needing_reboot[@]}"; do
        echo "$counter - $container_name"
        cntname+="$counter - $container_name __NEWLINE__"

        ((counter++))

    done

    sendtelegram "$cntname"

fi

echo "Process Completed"

exit 0

