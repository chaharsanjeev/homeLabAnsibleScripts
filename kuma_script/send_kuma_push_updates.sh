#!/bin/bash

# Input arguments
# 1 - Option source machine IP Address
#
#

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
kuma_base_url='http://192.168.10.14:3001'

# check if input argument IP of the source machine is passed
if [ "$#" -eq 1 ] ; then
  echo "${current_date_time} : Input IP Argument Passed: $1"
  machine_name="$1" # Get input argument IP
else
  machine_name="$(hostname -i)" # Get Machine IP address
fi

echo "${current_date_time} : Machine IP: ${machine_name}"
echo "${current_date_time} : Uptime Kuma Push API BaseURL = ${kuma_base_url}"

function fail {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
} # End Function

###############  Update Below Section ###################################

declare -a AllServices=() # declare empty array for services

if [[ $machine_name = '192.168.10.8' ]] ; then
    # backup.sc.home - Proxmox Backup Server
    echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
    AllServices=("rsyslog,lZYavnlSjN" "proxmox-backup,3yY8DfH9dw")
 elif [[ $machine_name = '192.168.10.3' ]] ; then
   # dns.sc - DNS Primary Server     
   echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
   AllServices=("rsyslog,9mrcGFGuPy" "pihole-FTL,yI9pMYEXa1" "unbound,zOMfoMIzSg")
 elif [[ $machine_name = '192.168.10.4' ]] ; then
  # Secondary DNS Server dns-s.sc      
  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
  AllServices=("rsyslog,P2ZbmFb2bh" "pihole-FTL,61XLgyl9cn" "unbound,7Kg1i4GEbn" )
# elif [[ $machine_name = '192.168.10.5' ]] ; then
  # Nginx Reverse Proxy proxy.sc  
  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#    
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#
#  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/$(hostname -i) ] - Start Push For Services"
#
else
  fail "**********  ERROR ********** : ${current_date_time} : Machine IP ${machine_name} not Configured in the bash script!"
fi

#########################################################################


#########################################################################

for serviceDetail in "${AllServices[@]}"; do
    service_name=$(echo "$serviceDetail" | awk -F',' '{ print $1 }')
    push_token=$(echo "$serviceDetail" | awk -F',' '{ print $2 }')

    if systemctl is-active --quiet "$service_name.service" ; then
        echo "${current_date_time} : [Host: $(hostname -f)] - '$service_name' is Running"
        srv_st="up"
    else
        srv_st="down"
        echo  "${current_date_time} : [Host: $(hostname -f)] -  '$service_name' is Not Running"
    fi

    result=$(curl --fail --no-progress-meter --insecure --retry 3 "${kuma_base_url}/api/push/$push_token?status=$srv_st" 2>&1)
    if [ $? -ne 0 ]; then
        echo "${current_date_time} : [Host: $(hostname -f)] Failed: $result" >&2
    else
        echo "${current_date_time} : [Host: $(hostname -f)] - Kuma push done for  service '$service_name' [Kuma Service ID: $push_token] - Process Completed"
    fi

done

#########################################################################
