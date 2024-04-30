#!/bin/bash


## Ensure to install the mysql client using the below apt install default-mysql-client
declare -a MYSQL_HOST="db.sc"
declare -a MYSQL_USERNAME="admin"
declare -a MYSQL_PASSWORD="Tuhina@0404"

## Ensure MQTT client is installed on this Linux machine
## sudo apt-get install mosquitto-clients
# declare -a MQTT_HOST="ha.sc"
# declare -a MQTT_PORT=1883
# declare -a MQTT_UID="mqtt_user"
# declare -a MQTT_PWD="Tuhina@0404"
# declare -a MQTT_TOPIC="linux/$(hostname).sc"

declare -a KERNAL_NAME=$(cat /etc/*-release | egrep "PRETTY_NAME|VERSION_ID" | cut -d = -f 2 | tr -d '"' |  xargs)

# declare -a LAST_SEEN="$(date +"%Y-%m-%dT%H:%M:%S%z")"

declare -a HOST_NAME=$(hostname).sc
declare -a HOST_IP=$(hostname -I | awk '{print $1}')

declare -a RAM_TOTAL=0
declare -a RAM_USED=0
declare -a RAM_FREE=0

declare -a HDD_TOTAL=0
declare -a HDD_USED=0
declare -a HDD_FREE=0

declare -a PVE_BACKUP_HDD_TOTAL=0
declare -a PVE_BACKUP_HDD_USED=0
declare -a PVE_BACKUP_HDD_FREE=0

declare -a SYSTEM_UPTIME=""

declare -a RECENT_APT_UPDATE_TIMESTAMP=""

declare -a JSON_LINE=""
declare -a JSON_ARRAY=""
declare -a temp=""
declare -a replace=""

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
     unset  JSON_ARRAY

    if [ "$HOSTNAME" = "backup" ]; then
       //COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /mnt/datastore/NAS-VM-Backups | head -n 2 | tail -1)
       COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /dev/mapper/pbs-root | head -n 2 | tail -1)
       
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

     if [ "$HOSTNAME" = "backup" ]; then
           # get storage for backup server storage
           COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /mnt/datastore/NAS-VM-Backups | head -n 2 | tail -1)
           IFS=' ' read -a arr <<< "$COMMAND_OP"
            //PBS_BACKUP_STORAGE_USAGE
            PVE_BACKUP_HDD_TOTAL="${arr[0]}"
            PVE_BACKUP_HDD_USED="${arr[1]}"
            PVE_BACKUP_HDD_FREE="${arr[2]}"
     elif [[ "$HOSTNAME" == "vm" ]]; then
           # get additional storage for VM

          JSON_ARRAY=""

	  while IFS= read -a oL ; do {  # reads single/one line
	    BBB=($oL)
	    temp="${BBB[3]}"
            replace=""

            temp="${temp/\/mnt\/pve\//$replace}"

            JSON_LINE="{'totalsize': ${BBB[0]}, 'used': ${BBB[1]}, 'name': '${temp}', 'free': ${BBB[2]}}"

            if [ -z "${JSON_ARRAY}" ]; then
              JSON_ARRAY="[${JSON_LINE}"
            else
              JSON_ARRAY+=",${JSON_LINE}"
            fi

	  };

	  done < <(df --output=size,used,avail,target --total  --human-readable --block-size=1G  /mnt/pve/* | tail -n +2);
	  unset oL;

	   if [ -n "${JSON_ARRAY}" ]; then
               JSON_ARRAY+="]"
           fi

           # replace all single quotes with double quotes
           # JSON_ARRAY="${JSON_ARRAY//\'/\"}"

	   # echo  "${JSON_ARRAY}"

     fi 
    
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
  RECENT_APT_UPDATE_TIMESTAMP=$(date -d @"${RECENT_APT_UPDATE_TIMESTAMP}")
  RECENT_APT_UPDATE_TIMESTAMP=$(date -d"${RECENT_APT_UPDATE_TIMESTAMP}" +"%Y-%m-%d %H:%M:%S")
} # End function

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

declare -a sql="UPDATE server_status SET SERVER_MULTIPLE_DRIVE= \"${JSON_ARRAY}\", PBS_BACKUP_STORAGE_TOTAL_MB= \"${PVE_BACKUP_HDD_TOTAL}\", PBS_BACKUP_STORAGE_USED_MB= \"${PVE_BACKUP_HDD_USED}\", KERNAL_NAME= \"${KERNAL_NAME}\" , RECENT_APT_UPDATE=\"${RECENT_APT_UPDATE_TIMESTAMP}\" , SYSTEM_UPTIME= \"${SYSTEM_UPTIME}\" , LAST_MODIFIED_DATE_TIME= CURRENT_TIMESTAMP, RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\", SERVER_DNS=\"${HOST_NAME}\", HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE SERVER_IP = \"${HOST_IP}\""

echo "Update SQL: ${sql}"

mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"

# End
