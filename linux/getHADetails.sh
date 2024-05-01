#!/bin/bash

## Below syntex to run this script from Crontab
##  # send service Linux details to Database - every 25 mins
## */25 * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c "$(wget -qLO - https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/getMachineDetails.sh)" >>/var/log/haSensor.log 2>/dev/null
/etc/crontabs

## Ensure to install the mysql client using the below
## apk add mysql-client

declare -a MYSQL_HOST="db.sc"
declare -a MYSQL_USERNAME="admin"
declare -a MYSQL_PASSWORD="Tuhina@0404"

declare -a KERNAL_NAME=$(cat /etc/*-release | egrep "PRETTY_NAME|VERSION_ID" | cut -d = -f 2 | tr -d '"' |  xargs)

declare -a HOST_IP="$1" ## HA machine IP passsed as input

declare -a RAM_TOTAL=0
declare -a RAM_USED=0
declare -a RAM_FREE=0
declare -a HDD_TOTAL=0
declare -a HDD_USED=0
declare -a HDD_FREE=0

declare -a SYSTEM_UPTIME=""
############## GET RAM USAGE  #######################
function getMachineRAM(){
      COMMAND_OP=$(free -m | head -n 2 | tail -1)

      IFS=' ' read -a arr <<< "$COMMAND_OP"

      RAM_TOTAL="${arr[1]/M}"
      RAM_USED="${arr[2]/M}"
      RAM_FREE="${arr[3]/M}"

} # End function - getRAMDetails

################# GET HDD USAGE
function getMachineHDD
{
  COMMAND_OP=$(df -m | head -n 2 | tail -1)
  IFS=' ' read -a arr <<< "$COMMAND_OP"

  HDD_TOTAL="${arr[1]}"
  HDD_USED="${arr[2]}"
  HDD_FREE="${arr[3]}"
}

##################### Get Recent Boot date & time
function getUptime()
{

  # COMMAND_OP=$(uptime | date -u +"%Y-%m-%dT%H:%M:%S.000Z") ## return datetime in ISO format
  # COMMAND_OP=$(uptime | date -u ) ## return datetime in ISO format
  # COMMAND_OP=$(uptime ) ## return as "up 2 weeks, 6 days, 17 hours, 19 minutes"
  # SYSTEM_UPTIME="$COMMAND_OP"
  SYSTEM_UPTIME=$( uptime | sed 's/^.*up/up/'  | cut -f1 -d",")

} # End function

getMachineRAM
getMachineHDD
getUptime

sql="UPDATE server_status SET KERNAL_NAME= \"${KERNAL_NAME}\",SYSTEM_UPTIME= \"${SYSTEM_UPTIME}\" , LAST_MODIFIED_DATE_TIME= CURRENT_TIMESTAMP, RAM_USED_MB=\"${RAM_USED}\" , RAM_TOTAL_MB=\"${RAM_TOTAL}\",HDD_TOTAL_MB=\"${HDD_TOTAL}\", HDD_USED_MB=\"${HDD_USED}\" WHERE SERVER_IP = \"${HOST_IP}\""
echo "Common Update SQL: ${sql}"

mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"
