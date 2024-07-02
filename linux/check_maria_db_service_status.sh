service_name="mariadb"

if ! systemctl is-active --quiet $service_name; then
  echo "$service_name is not running, restarting..."
  sudo systemctl restart $service_name
else
  echo "$service_name is already running - skip"
fi
