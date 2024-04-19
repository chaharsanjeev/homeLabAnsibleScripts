#!/bin/bash

## Ensure MQTT client is install on this Linux machine
## sudo apt-get install mosquitto-clients

declare -a MYSQL_HOST="db.sc"
declare -a MYSQL_USERNAME="admin"
declare -a MYSQL_PASSWORD="Tuhina@0404"

# declare -a MQTT_HOST="ha.sc"
# declare -a MQTT_PORT=1883
# declare -a MQTT_UID="mqtt_user"
# declare -a MQTT_PWD="Tuhina@0404"
# declare -a MQTT_TOPIC="linux/$(hostname).sc"

declare -a KERNAL_NAME=$(cat /etc/*-release | egrep "PRETTY_NAME|VERSION_ID" | cut -d = -f 2 | tr -d '"' |  xargs)

declare -a LAST_SEEN="$(date +"%Y-%m-%dT%H:%M:%S%z")"

declare -a HOST_NAME=$(hostname).sc
declare -a HOST_IP=$(hostname -I | awk '{print $1}')

declare -a RAM_TOTAL=0
declare -a RAM_USED=0
declare -a RAM_FREE=0

declare -a HDD_TOTAL=0
declare -a HDD_USED=0
declare -a HDD_FREE=0

declare -a SYSTEM_UPTIME=""

declare -a RECENT_APT_UPDATE_TIMESTAMP=""

############## GET RAM USAGE  #######################
function getMachineRAM(){
      # COMMAND_OP=$(free --mega -h | head -n 2 | tail -1)
       COMMAND_OP=$(free --mega | head -n 2 | tail -1)

      IFS=' ' read -a arr <<< "$COMMAND_OP"

      RAM_TOTAL="${arr[1]/M}"
      RAM_USED="${arr[2]/M}"
      RAM_FREE="${arr[3]/M}"
} # End function - getRAMDetails


################# GET HDD USAGE
function getMachineHDD
{
    if [ "$HOSTNAME" = "backup" ]; then
       COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /mnt/datastore/NAS-VM-Backups | head -n 2 | tail -1)
       IFS=' ' read -a arr <<< "$COMMAND_OP" 
    else
       COMMAND_OP=$(df --output=size,used,avail --total  --human-readable --block-size=1M | head -n 2 | tail -1)
       IFS=' ' read -a arr <<< "$COMMAND_OP"
    fi

    # COMMAND_OP=$(df --output=size,used,avail --total  --human-readable --block-size=1M | head -n 2 | tail -1)
    # IFS=' ' read -a arr <<< "$COMMAND_OP"

    HDD_TOTAL="${arr[0]}"
    HDD_USED="${arr[1]}"
    HDD_FREE="${arr[2]}"
} # End Function

##################### Get Recent Boot date & time
function getUptime()
{

  # COMMAND_OP=$(uptime -s | date -u +"%Y-%m-%dT%H:%M:%S.000Z") ## return datetime in ISO format
  # COMMAND_OP=$(uptime -s | date -u ) ## return datetime in ISO format
  COMMAND_OP=$(uptime -p ) ## return as "up 2 weeks, 6 days, 17 hours, 19 minutes"

  SYSTEM_UPTIME="$COMMAND_OP"

} # End function


############### Recent APT Update Timestamp
function getAPTUpdateTimestamp
{
  RECENT_APT_UPDATE_TIMESTAMP=$(stat -c %Y /var/cache/apt/)
} # End fucntion

getMachineRAM
getMachineHDD
getUptime
getAPTUpdateTimestamp

# json=$(cat <<-END
#    {
#        "host_name": "${HOST_NAME}",
#        "host_ip": "${HOST_IP}",
#        "RAM_TOTAL_MB": ${RAM_TOTAL},
#        "RAM_USED_MB": ${RAM_USED},
#        "RAM_FREE_MB": ${RAM_FREE},
#        "HDD_TOTAL_MB": ${HDD_TOTAL},
#        "HDD_USED_MB": ${HDD_USED},
#        "HDD_FREE_MB": ${HDD_FREE},
#        "SYSTEM_UPTIME": "${SYSTEM_UPTIME}",
#        "RECENT_APT_UPDATE_TIMESTAMP": "${RECENT_APT_UPDATE_TIMESTAMP}",
#        "KERNAL": "${KERNAL_NAME}",
#        "LAST_SEEN": "${LAST_SEEN}"
#    }
#END
#)

# mosquitto_pub -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_UID}" -P "${MQTT_PWD}" --insecure -i "Linux_machine" -r -t "${MQTT_TOPIC}" -m "${json}"

# mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e "UPDATE server_status SET RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\", server_name=\"${HOST_NAME}\", HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE server_ip = \"${HOST_IP}\""

declare -a sql="UPDATE server_status SET RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\", server_name=\"${HOST_NAME}\", HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE server_ip = \"${HOST_IP}\""
echo "Update SQL : ${sql}"

mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"
