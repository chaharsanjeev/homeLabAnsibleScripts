#!/bin/sh

echo "hello world-5"

rm -f qnap_hdd_details.*

wget "https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/qnap_hdd_details.py" -O "qnap_hdd_details.py"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin python "qnap_hdd_details.py"
