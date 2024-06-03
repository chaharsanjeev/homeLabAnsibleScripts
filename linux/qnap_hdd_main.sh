#!/bin/sh

# below added to QNAP crontab at location "/etc/config/crontab"
# */30 * * * * curl -sL https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/qnap_hdd_main.sh  | sudo bash >> /dev/null 2>&1 #below added by sanjeev to send HDD details to node-red, run every 30 mins
# Commond to restart cronjobs for QMAP:  crontab /etc/config/crontab && /etc/init.d/crond.sh restart


rm -f qnap_hdd_details.*

wget "https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/qnap_hdd_details.py" -O "qnap_hdd_details.py"

chmod 777 "qnap_hdd_details.py"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin python "qnap_hdd_details.py"

rm -f qnap_hdd_details.*
