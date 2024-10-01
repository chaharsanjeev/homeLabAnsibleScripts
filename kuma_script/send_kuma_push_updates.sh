#!/bin/bash

# Input arguments
# 1 - Option source machine IP Address
#
#
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
kuma_base_url='http://192.168.10.17:3001'

# check if input argument IP of the source machine is passed
if [ "$#" -eq 1 ] ; then
  echo "${current_date_time} : Input IP Argument Passed: $1"
  machine_name="$1" # Get input argument IP
else
  # machine_name="$(hostname -i)" # Get Machine IP address
  machine_name="$(hostname --fqdn)" # Get Machine dns name from PVE dns name
fi

echo "${current_date_time} : Machine IP: ${machine_name}"
echo "${current_date_time} : Uptime Kuma Push API BaseURL = ${kuma_base_url}"

function fail {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
} # End Function

###############  Update Below Section ###################################

declare -a AllServices=() # declare empty array for services

if [[ $machine_name = 'backup.sc.home' ]] ; then
   # backup.sc.home - Proxmox Backup Server - NEW UPDATE
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("proxmox-backup,3yY8DfH9dw")
 elif [[ $machine_name = 'dns.sc' ]] ; then
   # dns.sc - DNS Primary Server  - NEW UPDATE    
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("pihole-FTL,yI9pMYEXa1" "unbound,zOMfoMIzSg")
 elif [[ $machine_name = 'homepage.sc' ]] ; then
   # homepage.sc - Homepage Server  - NEW UPDATE    
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   #AllServices=()
  elif [[ $machine_name = 'dns-s.sc' ]] ; then
   #  Secondary DNS Server dns-s.sc - NEW UPDATE    
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("pihole-FTL,LKR6yvNNB5" "unbound,puyI6NEH1v" )
 elif [[ $machine_name = 'proxy.sc' ]] ; then
   # Nginx Reverse Proxy proxy.sc  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   # AllServices=("rsyslog,UkVl9kn22H")
 elif [[ $machine_name = 'db.sc' ]] ; then
   # Maria-DB  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("mariadb,D2ymdp5lUn")
 elif [[ $machine_name = 'ansible.sc' ]] ; then
   # Patch Server - Ansible - NEW UPDATE - xxxxxxxxxxxxxxxxxxxxxxxx
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("semaphore,9VbNQJ5Zf2")
 # elif [[ $machine_name = 'nodered.sc' ]] ; then
 #  # Node-Red  - NEW UPDATE 
 #  echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
 #  AllServices=("nodered,WaMnPbkAmx")
 elif [[ $machine_name = 'nodered-1.sc' ]] ; then
   # Node-Red-1  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("nodered,WaMnPbkAmx")
 elif [[ $machine_name = 'nodered-2.sc' ]] ; then
   # Node-Red-2  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("nodered,s6bJ2REZ6y")
 # elif [[ $machine_name = 'mqtt.sc' ]] ; then
   # MQTT Server
   # echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   # AllServices=("rsyslog,EfpMPVREt4" "emqx,JIeg9ZKjQf")
 elif [[ $machine_name = 'zigbee.sc' ]] ; then
   # Zigbee server - NEW UPDATE
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("zigbee2mqtt,jetIFm0mCm")
 elif [[ $machine_name = 'esp.sc' ]] ; then
   #ESP-Home     - NEW UPDATE
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("esphomeDashboard,b4AFd8FkLP")
 elif [[ $machine_name = 'zwave.sc' ]] ; then
   # Z-Wave Server- NEW UPDATE
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("zwave-js-ui,F19XypN0Sp")
 elif [[ $machine_name = 'apache.sc' ]] ; then
   # Apache Server  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("apache2,6V2ZzA4nuc") 
 elif [[ $machine_name = 'homebridge.sc' ]] ; then
  # Home Bridge Server  - NEW UPDATE 
   echo "${current_date_time} : [Host: $(hostname -f)/${machine_name} ] - Start Push For Services"
   AllServices=("homebridge,YROk7uncfP") 
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
  fail "**********  ERROR ********** : ${current_date_time} : Machine ${machine_name} not Configured in the bash script!"
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
if [[ $machine_name = 'ansible.sc' ]] ; then
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
