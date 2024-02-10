#!/bin/sh

echo "hello world-3"

rm -f qnap_hdd_details.*

wget "https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/linux/qnap_hdd_details.py" -O "qnap_hdd_details.py"
/share/CACHEDEV1_DATA/.system/Python python "qnap_hdd_details.py"
