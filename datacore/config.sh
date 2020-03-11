#!/bin/bash

sed -i 's/datacore_server = dcs-ip/datacore_server = '${DCSSVR}'/' /etc/datacore/datacore_get_perf.ini 
sed -i 's/rest_server = rest-ip/rest_server = '${DCSREST}'/' /etc/datacore/datacore_get_perf.ini 
sed -i 's/user = user/user = '${DCSUNAME}'/' /etc/datacore/datacore_get_perf.ini 
sed -i 's/passwd = pass/passwd = '${DCSPWORD}'/' /etc/datacore/datacore_get_perf.ini 

if [ ! -z "$VSPHERE_VCENTER" ]
then
      sed -i 's/ip-vcenter/'${VSPHERE_VCENTER}'/' /etc/telegraf/telegraf.conf 
      sed -i 's/username = "user"/username = "'${VSPHERE_USER}'"/' /etc/telegraf/telegraf.conf 
      sed -i 's/password = "pass"/password = "'${VSPHERE_PASS}'"/' /etc/telegraf/telegraf.conf
fi




if [ -d "/data" ]; then
  if [ ! -d "/data/mysql" ]; then
  rm /var/lib/influxdb
  rm /var/lib/mysql 
  mv /data-docker/influxdb /data/
  mv /data-docker/mysql /data/
  ln -s /data/mysql /var/lib/mysql
  ln -s /data/influxdb /var/lib/influxdb
  else
  rm /var/lib/influxdb
  rm /var/lib/mysql 
  ln -s /data/mysql /var/lib/mysql
  ln -s /data/influxdb /var/lib/influxdb
  chown -R influxdb:influxdb /data/influxdb
  chown -R mysql:mysql /data/mysql
  fi
fi

find /var/lib/mysql -type f -exec touch {} \; && /etc/init.d/mysql start && sleep 5
/etc/init.d/influxdb start && sleep 5
/etc/init.d/grafana-server start && sleep 5
grafana-cli plugins install grafana-piechart-panel
/etc/init.d/grafana-server restart && sleep 5


echo "Create Influxdb DataCore database"
curl  --silent --output /dev/null -POST 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode "q=CREATE DATABASE DataCoreRestDB WITH DURATION 6w REPLICATION 1"

echo "Change telegraf database retention policy"
curl  --silent --output /dev/null -POST 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode "q=ALTER RETENTION POLICY autogen ON telegraf DURATION 6w REPLICATION 1"


echo "Create Grafana Data Sources"
curl --silent --output /dev/null  -X POST \
  http://127.0.0.1:3000/api/datasources \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
  "name":"DataCoreRestDB",
  "type":"influxdb",
  "url":"http://localhost:8086",
  "database":"DataCoreRestDB",
  "access":"proxy",
  "isdefault":true
}'

curl --silent --output /dev/null  -X POST \
  http://127.0.0.1:3000/api/datasources \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
  "name":"telegraf",
  "type":"influxdb",
  "url":"http://localhost:8086",
  "database":"telegraf",
  "access":"proxy"
}'

echo "Create Grafana DataCore Dashboard"
python /etc/datacore/datacore-overview.py
python /etc/datacore/datacore-dashboard.py
python /etc/datacore/datacore-hosts.py


echo "Set DataCore Dashboard as home"
curl --silent --output /dev/null  -X PUT \
  http://127.0.0.1:3000/api/user/preferences \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{"theme":"","homeDashboardId":1,"timezone":""}'

echo "Create Grafana vSphere Dashboards"
if [ ! -z "$VSPHERE_VCENTER" ]
then
      python /etc/datacore/vsphere-datastore.py
      python /etc/datacore/vsphere-overview.py
      python /etc/datacore/vsphere-vms.py
      python /etc/datacore/vsphere-host.py
fi



exec "$@"
