#!/bin/bash

## Ensure to install the mysql client using the below
## apt install default-mysql-client


declare -a MYSQL_HOST="db.sc"
declare -a MYSQL_USERNAME="admin"
declare -a MYSQL_PASSWORD="Tuhina@0404"
declare -a DT="$(date +"%Y-%m-%d %H:%M:%S")"
declare -a HOST_IP=$(hostname -I | awk '{print $1}')

# one input argument is passed which is proxmox id
declare -a sql="UPDATE server_status SET BACKUP_DATE_TIME=\"${DT}\" , LAST_MODIFIED_DATE_TIME= CURRENT_TIMESTAMP WHERE PROXMOX_ID = \"$1\""
echo "Update SQL: ${sql}"

mysql --host="${MYSQL_HOST}" --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" -D "personal" -e  "${sql}"
