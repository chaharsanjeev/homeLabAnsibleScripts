#!/bin/bash
exec &>>  /var/log/kuma_service_status_push.log

machine_name="$(hostname -i)" # Get Machine IP address
echo "Machine IP: ${machine_name}"

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
kuma_base_url='http://192.168.10.14:3001'

function fail {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
} # End Function

###############  Update Below Section ###################################

declare -a AllServices=() # declare empty array for services

if [[ $machine_name = '192.168.10.8' ]]
then
    # backup.sc.home - Proxmox Backup Server
    AllServices=("rsyslog,lZYavnlSjN" "proxmox-backup,3yY8DfH9dw")
else
  fail "ERROR: ${current_date_time} : Machine IP ${machine_name} not Configured in the bash script!"
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
