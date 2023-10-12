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
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,lZYavnlSjN" "proxmox-backup,3yY8DfH9dw")
 elif [[ $machine_name = '192.168.10.3' ]] ; then
   # dns.sc - DNS Primary Server     
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,9mrcGFGuPy" "pihole-FTL,yI9pMYEXa1" "unbound,zOMfoMIzSg")
 elif [[ $machine_name = '192.168.10.4' ]] ; then
   # Secondary DNS Server dns-s.sc      
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,P2ZbmFb2bh" "pihole-FTL,61XLgyl9cn" "unbound,7Kg1i4GEbn" )
 elif [[ $machine_name = '192.168.10.5' ]] ; then
   # Nginx Reverse Proxy proxy.sc  
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,UkVl9kn22H")
 elif [[ $machine_name = '192.168.10.9' ]] ; then
   # Grafana/SysLog/Loki
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,2TQFDkMLCV" "loki,XGES7jK8Na" "grafana-server,tGUQZC7FQn" "promtail,ygzHCqCmpL")
 elif [[ $machine_name = '192.168.10.7' ]] ; then
   # Patch Server - Ansible
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,PBR4iKFCU9" "semaphore,9VbNQJ5Zf2" "mariadb,Czlh2EaR7l")
 elif [[ $machine_name = '192.168.40.4' ]] ; then
   # Node-Red 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,jpGdnyGGc6" "nodered,WaMnPbkAmx")
 elif [[ $machine_name = '192.168.40.5' ]] ; then
   # MQTT Server
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,EfpMPVREt4" "emqx,JIeg9ZKjQf")
 elif [[ $machine_name = '192.168.40.7' ]] ; then
   # Zigbee server
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,Hp82tHRSTw" "zigbee2mqtt,jetIFm0mCm")
 elif [[ $machine_name = '192.168.40.8' ]] ; then
   #ESP-Home    
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("rsyslog,lFonsrL2el" "esphomeDashboard,b4AFd8FkLP")
 elif [[ $machine_name = '192.168.40.9' ]] ; then
   # Z-Wave Server
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("zwave-js-ui,F19XypN0Sp" "rsyslog,WU0ebUAm2f")
 elif [[ $machine_name = '192.168.10.15' ]] ; then
   # Apache Server
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("apache2,6V2ZzA4nuc" "rsyslog,tPSlGYmlyA") 
# elif [[ $machine_name = '192.168.x.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.x.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
#
# elif [[ $machine_name = '192.168.10.x' ]] ; then
#    
#  echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
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

    # --no-progress-meter 
    result=$(curl --fail --insecure --retry 3 "${kuma_base_url}/api/push/$push_token?status=$srv_st" 2>&1)
    if [ $? -ne 0 ]; then
        echo "${current_date_time} : [Host: $(hostname -f)] Failed: $result" >&2
    else
        echo "${current_date_time} : [Host: $(hostname -f)] - Kuma push done for  service '$service_name' [Kuma Service ID: $push_token] - Process Completed"
    fi

done

#########################################################################
# below specific to Patch/Ansible Server
if [[ $machine_name = '192.168.10.7' ]] ; then
    ansible localhost -m ping -u root | grep 'SUCCESS' &> /dev/null
    if [ $? == 0 ]; then
           echo "${current_date_time} : [Host: $(hostname -f)] - Ansible localhost running"
       srv_st="up"
    else
       srv_st="down"
       echo  "${current_date_time} : [Host: $(hostname -f)] -  Ansible localhost not running"
    fi

    result=$(curl --fail --insecure --retry 3 "${kuma_base_url}/api/push/G8Qlw2EpoW?status=$srv_st" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Failed: $result" >&2
        echo "${current_date_time} : [Host: $(hostname -f)] - Failed: $result" >&2
    fi
fi
#########################################################################
