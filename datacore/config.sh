#!/bin/bash

sed -i 's/datacore_server = dcs-ip/datacore_server = '${DCSSVR}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/rest_server = rest-ip/rest_server = '${DCSREST}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/user = user/user = '${DCSUNAME}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/passwd = pass/passwd = '${DCSPWORD}'/' /etc/datacore/datacore_get_perf.ini


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
  fi
fi

find /var/lib/mysql -type f -exec touch {} \; && /etc/init.d/mysql start && sleep 5
/etc/init.d/influxdb start && sleep 5
/etc/init.d/grafana-server start && sleep 5
grafana-cli plugins install grafana-piechart-panel
/etc/init.d/grafana-server restart && sleep 5


echo "Create Influxdb DataCore database"
curl  --silent --output /dev/null -POST 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode "q=CREATE DATABASE DataCoreRestDB WITH DURATION 6w REPLICATION 1"


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


echo "Create Grafana DataCore Dashboard"
python /etc/datacore/datacore-dashboard.py



exec "$@"