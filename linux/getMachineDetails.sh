#!/bin/bash

## Below syntex to run this script from Crontab
##  # send service Linux details to Database - every 25 mins
## */25 * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c "$(wget -qLO - https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/getMachineDetails.sh)" >>/var/log/haSensor.log 2>/dev/null

## Ensure to install the mysql client using the below 
## apt install default-mysql-client


declare -a MYSQL_HOST="db.sc"
declare -a MYSQL_USERNAME="admin"
declare -a MYSQL_PASSWORD="Tuhina@0404"

declare -a KERNAL_NAME=$(cat /etc/*-release | egrep "PRETTY_NAME|VERSION_ID" | cut -d = -f 2 | tr -d '"' |  xargs)

# declare -a LAST_SEEN="$(date +"%Y-%m-%dT%H:%M:%S%z")"

declare -a HOST_NAME=$(hostname).sc
declare -a HOST_IP=$(hostname -I | awk '{print $1}')

if [ "$HOST_IP" = "192.168.10.11" ]; then
   HOST_NAME=$(hostname)
fi


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

declare -a sql=""

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
       ## COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /mnt/datastore/NAS-VM-Backups | head -n 2 | tail -1)
       COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /dev/mapper/pbs-root | head -n 2 | tail -1)
       
       IFS=' ' read -a arr <<< "$COMMAND_OP" 
    else
       COMMAND_OP=$(df --output=size,used,avail --total  --human-readable --block-size=1M | head -n 2 | tail -1)
       IFS=' ' read -a arr <<< "$COMMAND_OP"
    fi

    HDD_TOTAL="${arr[0]}"
    HDD_USED="${arr[1]}"
    HDD_FREE="${arr[2]}"

     if [ "$HOSTNAME" = "backup" ]; then
           # get storage for backup server storage
           COMMAND_OP=$(df --output=size,used,avail,target --total  --human-readable --block-size=1M -t ext4 /mnt/datastore/NAS-VM-Backups | head -n 2 | tail -1)
           IFS=' ' read -a arr <<< "$COMMAND_OP"
            ## PBS_BACKUP_STORAGE_USAGE
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
		  }; # End while loop

		done < <(df --output=size,used,avail,target --total  --human-readable --block-size=1G  /mnt/pve/* | tail -n +2 | head -n -1);
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

# fire common SQL first
# declare -a sql="UPDATE server_status SET SERVER_MULTIPLE_DRIVE= \"${JSON_ARRAY}\", PBS_BACKUP_STORAGE_TOTAL_MB= \"${PVE_BACKUP_HDD_TOTAL}\", PBS_BACKUP_STORAGE_USED_MB= \"${PVE_BACKUP_HDD_USED}\", KERNAL_NAME= \"${KERNAL_NAME}\" , RECENT_APT_UPDATE=\"${RECENT_APT_UPDATE_TIMESTAMP}\" , SYSTEM_UPTIME= \"${SYSTEM_UPTIME}\" , LAST_MODIFIED_DATE_TIME= CURRENT_TIMESTAMP, RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\", SERVER_DNS=\"${HOST_NAME}\", HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE SERVER_IP = \"${HOST_IP}\""
sql="UPDATE server_status SET KERNAL_NAME= \"${KERNAL_NAME}\" , RECENT_APT_UPDATE=\"${RECENT_APT_UPDATE_TIMESTAMP}\" , SYSTEM_UPTIME= \"${SYSTEM_UPTIME}\" , LAST_MODIFIED_DATE_TIME= CURRENT_TIMESTAMP, RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\", SERVER_DNS=\"${HOST_NAME}\", HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE SERVER_IP = \"${HOST_IP}\""
echo "Common Update SQL: ${sql}"
mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"

if [ "$HOSTNAME" = "backup" ]; then
	sql="UPDATE server_status SET PBS_BACKUP_STORAGE_TOTAL_MB= \"${PVE_BACKUP_HDD_TOTAL}\", PBS_BACKUP_STORAGE_USED_MB= \"${PVE_BACKUP_HDD_USED}\", PBS_BACKUP_STORAGE_LAST_UPDATED=CURRENT_TIMESTAMP WHERE SERVER_IP = \"${HOST_IP}\""
	echo "Backup Server Update SQL: ${sql}"
	mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"

elif [[ "$HOSTNAME" == "vm" ]]; then
	sql="UPDATE server_status SET SERVER_MULTIPLE_DRIVE= \"${JSON_ARRAY}\", SERVER_MULTIPLE_DRIVE_LAST_UPDATED= CURRENT_TIMESTAMP WHERE SERVER_IP = \"${HOST_IP}\""
	echo "Proxmox Server Update SQL: ${sql}"
	mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"
fi

# End
