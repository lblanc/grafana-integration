#!/bin/bash

sed -i 's/datacore_server = dcs-ip/datacore_server = '${DCSSVR}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/rest_server = rest-ip/rest_server = '${DCSREST}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/user = user/user = '${DCSUNAME}'/' /etc/datacore/datacore_get_perf.ini && \
sed -i 's/passwd = pass/passwd = '${DCSPWORD}'/' /etc/datacore/datacore_get_perf.ini


sed -i 's/{ "Username": "user", "Password": "pass", "Hostname": "vcenter" }/{ "Username": "'${VSPHERE_USER}'", "Password": "'${VSPHERE_PASS}'", "Hostname": "'${VSPHERE_VCENTER}'" }/' /etc/datacore/vsphere-influxdb-go.json && \
sed -i 's/"Domain": ".dom",/"Domain": ".'${VSPHERE_DOM}'",/' /etc/datacore/vsphere-influxdb-go.json && \
mv /etc/datacore/vsphere-influxdb-go.json /etc/vsphere-influxdb-go.json

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

echo "Create Influxdb vSphere database"
curl  --silent --output /dev/null -POST 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode "q=CREATE DATABASE vsphere WITH DURATION 6w REPLICATION 1"

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
  "name":"vSphere",
  "type":"influxdb",
  "url":"http://localhost:8086",
  "database":"vsphere",
  "access":"proxy"
}'

echo "Create Grafana DataCore Dashboard"
python /etc/datacore/datacore-dashboard.py

echo "Create Grafana vSphere Dashboards"
curl  --silent --output /dev/null  -X POST \
  http://127.0.0.1:3000/api/dashboards/db \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
  "dashboard": {
  "__inputs": [
    {
      "name": "vSphere",
      "label": "vSphere",
      "description": "",
      "type": "datasource",
      "pluginId": "influxdb",
      "pluginName": "InfluxDB"
    }
  ],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "5.2.4"
    },
    {
      "type": "panel",
      "id": "grafana-piechart-panel",
      "name": "Pie Chart",
      "version": "1.3.3"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph",
      "version": "5.0.0"
    },
    {
      "type": "datasource",
      "id": "influxdb",
      "name": "InfluxDB",
      "version": "5.0.0"
    },
    {
      "type": "panel",
      "id": "singlestat",
      "name": "Singlestat",
      "version": "5.0.0"
    },
    {
      "type": "panel",
      "id": "table",
      "name": "Table",
      "version": "5.0.0"
    }
  ],
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": 3556,
  "graphTooltip": 0,
  "id": null,
  "iteration": 1537129939331,
  "links": [
    {
      "asDropdown": true,
      "icon": "external link",
      "title": "All Dashboards",
      "type": "dashboards"
    }
  ],
  "panels": [
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 100,
      "panels": [],
      "repeat": null,
      "title": "Usage",
      "type": "row"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "rgba(245, 54, 54, 0.9)",
        "rgba(237, 129, 40, 0.89)",
        "rgba(50, 172, 45, 0.97)"
      ],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "format": "mbytes",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 1
      },
      "id": 91,
      "interval": "60s",
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": false,
        "lineColor": "rgb(31, 120, 193)",
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "hostsystem",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "mem_totalcapacity_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              },
              {
                "params": [
                  "* 1.07374"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "name",
              "operator": "=~",
              "value": "/^$esx$/"
            }
          ]
        }
      ],
      "thresholds": "",
      "title": "Total RAM available in GB",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "rgba(245, 54, 54, 0.9)",
        "rgba(237, 129, 40, 0.89)",
        "rgba(50, 172, 45, 0.97)"
      ],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "format": "kbytes",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 1
      },
      "id": 84,
      "interval": "60s",
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": true,
        "lineColor": "rgb(31, 120, 193)",
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "1m"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "query": "SELECT sum(\"mem_capacity_provisioned_average\") FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND $timeFilter GROUP BY time($interval)  fill(null)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "mem_capacity_provisioned_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            }
          ]
        }
      ],
      "thresholds": "",
      "title": "Total allocated vRAM",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "rgba(245, 54, 54, 0.9)",
        "rgba(237, 129, 40, 0.89)",
        "rgba(50, 172, 45, 0.97)"
      ],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "format": "hertz",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "id": 85,
      "interval": "60s",
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": true,
        "lineColor": "rgb(31, 120, 193)",
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT sum(\"cpu_usagemhz_average\")  * 1000000 FROM \"hostsystem\" WHERE \"host\" =~ /$host$/ AND $timeFilter GROUP BY time($interval)  fill(null)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": "",
      "title": "Total Used CPU in GHz",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "rgba(245, 54, 54, 0.9)",
        "rgba(237, 129, 40, 0.89)",
        "rgba(50, 172, 45, 0.97)"
      ],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "format": "kbytes",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "id": 86,
      "interval": "60s",
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": true,
        "lineColor": "rgb(31, 120, 193)",
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT sum(\"mem_consumed_average\") FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND $timeFilter GROUP BY time($interval)  fill(null)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": "",
      "title": "Total Used Memory in GB",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 103,
      "panels": [],
      "repeat": null,
      "title": "ESX by CPU/Ram",
      "type": "row"
    },
    {
      "columns": [
        {
          "text": "Avg",
          "value": "avg"
        },
        {
          "text": "Total",
          "value": "total"
        }
      ],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 16
      },
      "id": 4,
      "interval": "60s",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 3,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "percent",
          "thresholds": [
            "80",
            "90"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "MHz",
          "thresholds": [],
          "type": "number",
          "unit": "hertz"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "ready ",
          "thresholds": [
            "5",
            "10"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/.*/",
          "thresholds": [],
          "type": "number",
          "unit": "short"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "hostsystem",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT mean(\"cpu_usage_average\")  / 100 as percent,  (mean(\"cpu_ready_summation\")  / (60 * 1000)) * 100 as \"ready \", mean(\"cpu_usagemhz_average\")  * 1000000 as MHz FROM \"hostsystem\" WHERE \"host\" =~ /$host$/ AND $timeFilter GROUP BY \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "cpu_usagemhz_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " * 1000000"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/$host$/"
            }
          ]
        }
      ],
      "title": "CPU",
      "transform": "table",
      "type": "table"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 16
      },
      "id": 6,
      "interval": "60s",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 2,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "percent",
          "thresholds": [
            "80",
            "90"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "memory",
          "thresholds": [],
          "type": "number",
          "unit": "kbytes"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "hide": true,
          "measurement": "virtualmachine",
          "policy": "default",
          "refId": "B",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "mem_capacity_provisioned_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            }
          ]
        },
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "measurement": "hostsystem",
          "policy": "default",
          "query": "SELECT mean(\"mem_usage_average\") / 100 as percent, mean(\"mem_consumed_average\") as memory FROM \"hostsystem\" WHERE \"host\" =~ /$host$/ AND $timeFilter GROUP BY  \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "mem_consumed_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/$host$/"
            }
          ]
        }
      ],
      "title": "ESX by memory usage",
      "transform": "table",
      "type": "table"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 23
      },
      "id": 101,
      "panels": [],
      "repeat": null,
      "title": "VMs by IOPS",
      "type": "row"
    },
    {
      "aliasColors": {},
      "breakPoint": "50%",
      "cacheTimeout": null,
      "combine": {
        "label": "Others",
        "threshold": 0
      },
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fontSize": "80%",
      "format": "short",
      "gridPos": {
        "h": 9,
        "w": 8,
        "x": 0,
        "y": 24
      },
      "id": 2,
      "interval": "60s",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": false,
        "total": false,
        "values": false
      },
      "legendType": "rightSide",
      "links": [],
      "maxDataPoints": 3,
      "nullPointMode": "connected",
      "nullText": null,
      "pieType": "pie",
      "strokeWidth": 1,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "hostsystem",
          "policy": "default",
          "query": "SELECT mean(\"datastore_numberwriteaveraged_average\") + mean(\"datastore_numberreadaveraged_average\") FROM \"virtualmachine\" WHERE \"host\" =~ /$host$/  AND $timeFilter GROUP BY \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Pie",
      "transparent": true,
      "type": "grafana-piechart-panel",
      "valueName": "current"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 9,
        "w": 8,
        "x": 8,
        "y": 24
      },
      "id": 1,
      "interval": "",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 3,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "/avg/",
          "thresholds": [
            "150",
            "500"
          ],
          "type": "number",
          "unit": "short"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/max/",
          "thresholds": [
            "150",
            "500"
          ],
          "type": "number",
          "unit": "short"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "measurement": "hostsystem",
          "policy": "default",
          "query": "SELECT mean(\"datastore_numberwriteaveraged_average\") + mean(\"datastore_numberreadaveraged_average\") as \"IOPS avg\", max(\"datastore_numberwriteaveraged_average\") + max(\"datastore_numberreadaveraged_average\") as \"IOPS max\" FROM \"virtualmachine\" WHERE \"host\" =~ /$host$/ AND \"datastore\" =~ /$datastore$/ AND $timeFilter GROUP BY  \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Table",
      "transform": "table",
      "transparent": false,
      "type": "table"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 9,
        "w": 8,
        "x": 16,
        "y": 24
      },
      "id": 82,
      "interval": "",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 2,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "row",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "/.*/",
          "thresholds": [
            "10",
            "15"
          ],
          "type": "number",
          "unit": "ms"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "query": "SELECT mean(\"datastore_totalreadlatency_average\") as \"read\" , mean(\"datastore_totalwritelatency_average\") as \"write\" FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND $timeFilter AND \"datastore_totalreadlatency_average\" > 0 AND \"datastore_totalwritelatency_average\" > 0 GROUP BY  \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "datastore_totalreadlatency_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            }
          ]
        }
      ],
      "title": "Latency",
      "transform": "table",
      "transparent": false,
      "type": "table"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 33
      },
      "id": 102,
      "panels": [],
      "repeat": null,
      "title": "VMs by CPU/RAM usage",
      "type": "row"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 34
      },
      "id": 46,
      "interval": "",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 4,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "decimals": 2,
          "pattern": "usage",
          "thresholds": [],
          "type": "number",
          "unit": "hertz"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/ready .*/",
          "thresholds": [
            "3",
            "5"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "percent",
          "thresholds": [
            "80",
            "90"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "vcpu",
          "thresholds": [
            "7",
            "8"
          ],
          "type": "number",
          "unit": "short"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "ready ",
          "thresholds": [
            "5",
            "10"
          ],
          "type": "number",
          "unit": "percent"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "measurement": "virtualmachine",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT mean(\"cpu_usage_average\")  / 100 as percent, mean(\"cpu_usagemhz_average\")  * 1000000  as usage,  (mean(\"cpu_ready_summation\")  / (60 * 1000)) * 100 as \"ready avg\", (max(\"cpu_ready_summation\")  / (60 * 1000)) * 100 as \"ready max\", mean(\"cpu_corecount_provisioned_average\") as vcpu FROM \"virtualmachine\" WHERE \"host\" =~ /$host$/ AND $timeFilter GROUP BY \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "cpu_usagemhz_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " * 1000000"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/$host$/"
            }
          ]
        }
      ],
      "title": "CPU",
      "transform": "table",
      "type": "table"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 41
      },
      "id": 48,
      "interval": "60s",
      "links": [],
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 2,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "decimals": 2,
          "pattern": "usage",
          "thresholds": [],
          "type": "number",
          "unit": "kbytes"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "percent",
          "thresholds": [
            "80",
            "90"
          ],
          "type": "number",
          "unit": "percent"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "provisioned",
          "thresholds": [
            "24"
          ],
          "type": "number",
          "unit": "kbytes"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "query": "SELECT mean(\"mem_consumed_average\") /mean(\"mem_capacity_provisioned_average\")  * 100 as percent, mean(\"mem_consumed_average\") as usage,  mean(\"mem_capacity_provisioned_average\") as provisioned FROM \"virtualmachine\" WHERE \"host\" =~ /$host$/ AND $timeFilter GROUP BY \"name\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "mem_usage_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/$host$/"
            }
          ]
        }
      ],
      "title": "Memory",
      "transform": "table",
      "type": "table"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 48
      },
      "id": 104,
      "panels": [],
      "repeat": null,
      "title": "Datastores",
      "type": "row"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 49
      },
      "id": 83,
      "links": [],
      "minSpan": 24,
      "pageSize": null,
      "repeat": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 4,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "/IOPS/",
          "thresholds": [
            "150",
            "500"
          ],
          "type": "number",
          "unit": "short"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/latency/",
          "thresholds": [
            "10",
            "15"
          ],
          "type": "number",
          "unit": "ms"
        },
        {
          "colorMode": null,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/write|read/",
          "thresholds": [],
          "type": "number",
          "unit": "Bps"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT mean(\"datastore_numberwriteaveraged_average\") + mean(\"datastore_numberreadaveraged_average\") as \"IOPS a\", max(\"datastore_numberwriteaveraged_average\") + max(\"datastore_numberreadaveraged_average\") as \"IOPS m\", mean(\"datastore_read_average\") * 1000 as \"read a\", mean(\"datastore_write_average\") * 1000 as \"write a\"  ,  max(\"datastore_read_average\") * 1000 as \"read m\", max(\"datastore_write_average\") * 1000 as \"write m\" , mean(\"datastore_totalreadlatency_average\") + mean(\"datastore_totalwritelatency_average\") as \"latency a\", max(\"datastore_totalreadlatency_average\") + max(\"datastore_totalwritelatency_average\") as \"latency m\" FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND \"esx\" =~ /^$esx$/ AND \"datastore\" =~ /^$datastore$/ AND $timeFilter GROUP BY  \"name\", \"datastore\"",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "VMs by datastore - $datastore",
      "transform": "table",
      "type": "table"
    },
    {
      "columns": [],
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "filterNull": false,
      "fontSize": "100%",
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 56
      },
      "id": 88,
      "interval": "60s",
      "links": [],
      "minSpan": 24,
      "pageSize": null,
      "scroll": true,
      "showHeader": true,
      "sort": {
        "col": 3,
        "desc": true
      },
      "styles": [
        {
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "pattern": "Time",
          "type": "date"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "decimals": 2,
          "pattern": "/IOPS/",
          "thresholds": [
            "150",
            "500"
          ],
          "type": "number",
          "unit": "short"
        },
        {
          "colorMode": "cell",
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "pattern": "/latency/",
          "thresholds": [
            "10",
            "15"
          ],
          "type": "number",
          "unit": "ms"
        }
      ],
      "targets": [
        {
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT (sum(\"datastore_numberwriteaveraged_average\") + sum(\"datastore_numberreadaveraged_average\")) / 60 as \"IOPS avg\", max(\"datastore_numberwriteaveraged_average\") + max(\"datastore_numberreadaveraged_average\") as \"IOPS max\", mean(\"datastore_totalreadlatency_average\") + mean(\"datastore_totalwritelatency_average\") as \"latency avg\", max(\"datastore_totalreadlatency_average\") + max(\"datastore_totalwritelatency_average\") as \"latency max\" FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND \"datastore\" =~ /$datastore$/ AND  $timeFilter GROUP BY \"datastore\", time($interval)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "table",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Datastores - $datastore",
      "transform": "table",
      "type": "table"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 63
      },
      "id": 90,
      "interval": ">60s",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "read ops $tag_datastore",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "datastore"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "datastore_numberreadaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "esx",
              "operator": "=~",
              "value": "/^$esx$/"
            },
            {
              "condition": "AND",
              "key": "datastore",
              "operator": "=~",
              "value": "/^$datastore$/"
            }
          ]
        },
        {
          "alias": "write ops $tag_datastore",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "datastore"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "datastore_numberwriteaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "esx",
              "operator": "=~",
              "value": "/^$esx$/"
            },
            {
              "condition": "AND",
              "key": "datastore",
              "operator": "=~",
              "value": "/^$datastore$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Datastore $datastore total mean",
      "tooltip": {
        "msResolution": false,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 63
      },
      "id": 89,
      "interval": ">60s",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "read ops $tag_datastore",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "datastore"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "datastore_numberreadaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "max"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "esx",
              "operator": "=~",
              "value": "/^$esx$/"
            },
            {
              "condition": "AND",
              "key": "datastore",
              "operator": "=~",
              "value": "/^$datastore$/"
            }
          ]
        },
        {
          "alias": "write ops $tag_datastore",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "datastore"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "policy": "default",
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "datastore_numberwriteaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "max"
              },
              {
                "params": [
                  "* -1"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "esx",
              "operator": "=~",
              "value": "/^$esx$/"
            },
            {
              "condition": "AND",
              "key": "datastore",
              "operator": "=~",
              "value": "/^$datastore$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Datastore $datastore total max",
      "tooltip": {
        "msResolution": false,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 70
      },
      "id": 106,
      "panels": [],
      "repeat": null,
      "title": "Network",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 71
      },
      "id": 43,
      "interval": "60s",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "min",
        "sortDesc": false,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "received $tag_name:$tag_instance",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "instance"
              ],
              "type": "tag"
            }
          ],
          "measurement": "net",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "net_received_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  "*8"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "name",
              "operator": "=~",
              "value": "/^$esx$/"
            }
          ]
        },
        {
          "alias": "transmitted $tag_name:$tag_instance",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "instance"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "net",
          "policy": "default",
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "net_transmitted_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  "* -8"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "host",
              "operator": "=~",
              "value": "/^$host$/"
            },
            {
              "condition": "AND",
              "key": "name",
              "operator": "=~",
              "value": "/^$esx$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Network KBps",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "Kbits",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 78
      },
      "id": 98,
      "panels": [],
      "repeat": null,
      "title": "Provisioning",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 79
      },
      "id": 92,
      "interval": "60s",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 3,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "available vcpu",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT sum(\"cpu_corecount_total\") * 3 / 2 FROM \"hostsystem\" WHERE \"host\" =~ /^$host$/ AND \"name\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "provisioned vcpu",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT sum(\"cpu_corecount_provisioned_average\") FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/  AND \"esx\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "n-1 available vcpu",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT ((sum(\"cpu_corecount_total\") - max(\"cpu_corecount_total\")) * 3 / 2 ) FROM \"hostsystem\" WHERE \"host\" =~ /^$host$/ AND \"name\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)",
          "rawQuery": true,
          "refId": "C",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "gt"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "vCPU available / provisioned",
      "tooltip": {
        "msResolution": false,
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": "vcpu",
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 79
      },
      "id": 94,
      "interval": "60s",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "RAM available",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT sum(\"mem_totalcapacity_average\") * 1.07374 FROM \"hostsystem\" WHERE \"host\" =~ /^$host$/ AND \"name\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval) fill(null)",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "RAM provisioned",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT sum(\"mem_capacity_provisioned_average\") * 0.000976563 FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND \"esx\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)  fill(null)",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "RAM available N-1",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT (sum(\"mem_totalcapacity_average\") - max(\"mem_totalcapacity_average\") )* 1.07374 FROM \"hostsystem\" WHERE \"host\" =~ /^$host$/ AND \"name\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval) fill(null)",
          "rawQuery": true,
          "refId": "D",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "RAM used",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "policy": "default",
          "query": "SELECT sum(\"mem_consumed_average\") * 0.000976563 FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/ AND \"esx\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)  fill(null)",
          "rawQuery": true,
          "refId": "C",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "RAM provisioned / available / used",
      "tooltip": {
        "msResolution": false,
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "mbytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "fill": 1,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 86
      },
      "id": 96,
      "interval": "60s",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "minSpan": 4,
      "nullPointMode": "null",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "repeat": "esx",
      "repeatDirection": "h",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "vcpu_provisioned",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT sum(\"cpu_corecount_provisioned_average\") FROM \"virtualmachine\" WHERE \"host\" =~ /^$host$/  AND \"esx\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval), esx",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "vcpu_available",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT sum(\"cpu_corecount_total\") * 3 / 2 FROM \"hostsystem\" WHERE \"host\" =~ /^$host$/ AND \"name\" =~ /^$esx$/ AND $timeFilter GROUP BY time($interval)",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "vCPU Provisioned per ESX $esx",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": "1m",
  "schemaVersion": 16,
  "style": "dark",
  "tags": [
    "vmware"
  ],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": false,
        "label": null,
        "multi": false,
        "name": "host",
        "options": [],
        "query": "show tag values with key = \"host\"\t",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": true,
        "label": null,
        "multi": true,
        "name": "esx",
        "options": [],
        "query": "show tag values from hostsystem with key = \"name\" where host =~ /$host/\t",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": true,
        "label": null,
        "multi": true,
        "name": "datastore",
        "options": [],
        "query": "SHOW TAG VALUES WITH KEY =\"datastore\" WHERE \"host\" =~ /$host/\t",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-30m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "browser",
  "title": "VMware Overview",
  "uid": "X6HOUBTmz",
  "version": 3
},
  "folderId": 0,
  "overwrite": true
}'

curl  --silent --output /dev/null  -X POST \
  http://127.0.0.1:3000/api/dashboards/db \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
  "dashboard": {
  "__inputs": [
    {
      "name": "vSphere",
      "label": "vSphere",
      "description": "",
      "type": "datasource",
      "pluginId": "influxdb",
      "pluginName": "InfluxDB"
    }
  ],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "5.2.4"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph",
      "version": "5.0.0"
    },
    {
      "type": "datasource",
      "id": "influxdb",
      "name": "InfluxDB",
      "version": "5.0.0"
    }
  ],
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "View CPU, Memory, Network, Disk Metrics for multiple VMs in multiple vCenters",
  "editable": true,
  "gnetId": null,
  "graphTooltip": 1,
  "id": null,
  "iteration": 1537130888449,
  "links": [
    {
      "asDropdown": true,
      "icon": "external link",
      "title": "All Dashboards",
      "type": "dashboards"
    }
  ],
  "panels": [
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 20,
      "panels": [],
      "repeat": null,
      "title": "General ESX Performance",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 1
      },
      "id": 18,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "hostsystem",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT mean(\"cpu_usage_average\")  / 100 FROM \"virtualmachine\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "cpu_usage_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " / 100"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$esx$/"
            }
          ]
        }
      ],
      "thresholds": [
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(216, 200, 27, 0.27)",
          "op": "gt",
          "value": 75
        },
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(234, 112, 112, 0.22)",
          "op": "gt",
          "value": 90
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "ESX CPU Usage %",
      "tooltip": {
        "msResolution": true,
        "shared": false,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": 100,
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 22,
      "interval": "",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sideWidth": null,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "hostsystem",
          "orderByTime": "ASC",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "mem_usage_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " / 100"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$esx$/"
            }
          ]
        }
      ],
      "thresholds": [
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(216, 200, 27, 0.27)",
          "op": "gt",
          "value": 75
        },
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(234, 112, 112, 0.22)",
          "op": "gt",
          "value": 90
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "ESX Memory Usage %",
      "tooltip": {
        "msResolution": true,
        "shared": false,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": 100,
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 14,
      "panels": [],
      "repeat": null,
      "title": "General VM Performance",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 16
      },
      "id": 1,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT mean(\"cpu_usage_average\")  / 100 FROM \"virtualmachine\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "cpu_usage_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " / 100"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(216, 200, 27, 0.27)",
          "op": "gt",
          "value": 75
        },
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(234, 112, 112, 0.22)",
          "op": "gt",
          "value": 90
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "VM CPU Usage %",
      "tooltip": {
        "msResolution": true,
        "shared": false,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": 100,
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 23
      },
      "id": 2,
      "interval": "",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sideWidth": null,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "orderByTime": "ASC",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "mem_usage_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " / 100"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(216, 200, 27, 0.27)",
          "op": "gt",
          "value": 75
        },
        {
          "colorMode": "custom",
          "fill": true,
          "fillColor": "rgba(234, 112, 112, 0.22)",
          "op": "gt",
          "value": 90
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "VM Memory Usage %",
      "tooltip": {
        "msResolution": true,
        "shared": false,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": 100,
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "decimals": 2,
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 30
      },
      "id": 3,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualmachine",
          "orderByTime": "ASC",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "cpu_ready_summation"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              },
              {
                "params": [
                  " / 100"
                ],
                "type": "math"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "CPU Ready %",
      "tooltip": {
        "msResolution": true,
        "shared": false,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 37
      },
      "id": 15,
      "panels": [],
      "repeat": null,
      "title": "DISK",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 38
      },
      "id": 4,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "orderByTime": "ASC",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_totalreadlatency_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Read Latency (ms)",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "ms",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 38
      },
      "id": 5,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": "max",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_totalwritelatency_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Write Latency (ms)",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "ms",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 45
      },
      "id": 6,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_numberreadaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Read IO",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "rps",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 45
      },
      "id": 7,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": null,
        "sortDesc": null,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "query": "SELECT SUM(\"virtualdisk_numberwriteaveraged_average\")  FROM \"virtualdisk\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_numberwriteaveraged_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Write IO",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "wps",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 52
      },
      "id": 10,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": null,
        "sortDesc": null,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "query": "SELECT SUM(\"virtualdisk_numberwriteaveraged_average\") FROM \"virtualdisk\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_readoio_latest"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Read OIO",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "wps",
          "label": "Outstanding Read IOs",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 52
      },
      "id": 11,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": null,
        "sortDesc": null,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "query": "SELECT SUM(\"virtualdisk_numberwriteaveraged_average\") FROM \"virtualdisk\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_writeoio_latest"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Write OIO",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "wps",
          "label": "Outstanding Write IOs",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 59
      },
      "id": 12,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_read_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Read Throughput",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "deckbytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "vSphere",
      "editable": true,
      "error": false,
      "fill": 1,
      "grid": {},
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 59
      },
      "id": 13,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "sort": null,
        "sortDesc": null,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 2,
      "links": [],
      "nullPointMode": "connected",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "alias": "$tag_name",
          "dsType": "influxdb",
          "groupBy": [
            {
              "params": [
                "$interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "name"
              ],
              "type": "tag"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "virtualdisk",
          "policy": "default",
          "query": "SELECT SUM(\"virtualdisk_numberwriteaveraged_average\")  FROM \"virtualdisk\" WHERE \"name\" =~ /^$vmname$/ AND $timeFilter GROUP BY time($interval), \"name\" fill(null)",
          "rawQuery": false,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "virtualdisk_write_average"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "sum"
              }
            ]
          ],
          "tags": [
            {
              "key": "name",
              "operator": "=~",
              "value": "/^$vmname$/"
            }
          ]
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": null,
      "title": "Disk Write Throughput",
      "tooltip": {
        "msResolution": true,
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "deckbytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": true,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 66
      },
      "id": 16,
      "panels": [
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "vSphere",
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {},
          "gridPos": {
            "h": 7,
            "w": 12,
            "x": 0,
            "y": 24
          },
          "id": 8,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": false,
            "max": true,
            "min": true,
            "rightSide": true,
            "show": true,
            "sort": "max",
            "sortDesc": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "alias": "$tag_name",
              "dsType": "influxdb",
              "groupBy": [
                {
                  "params": [
                    "$interval"
                  ],
                  "type": "time"
                },
                {
                  "params": [
                    "name"
                  ],
                  "type": "tag"
                },
                {
                  "params": [
                    "null"
                  ],
                  "type": "fill"
                }
              ],
              "measurement": "virtualmachine",
              "policy": "default",
              "refId": "A",
              "resultFormat": "time_series",
              "select": [
                [
                  {
                    "params": [
                      "net_received_average"
                    ],
                    "type": "field"
                  },
                  {
                    "params": [],
                    "type": "mean"
                  }
                ]
              ],
              "tags": [
                {
                  "key": "name",
                  "operator": "=~",
                  "value": "/^$vmname$/"
                }
              ]
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeShift": null,
          "title": "Network Recieve kb/s",
          "tooltip": {
            "msResolution": true,
            "shared": true,
            "sort": 0,
            "value_type": "cumulative"
          },
          "transparent": true,
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "KBs",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "vSphere",
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {},
          "gridPos": {
            "h": 7,
            "w": 12,
            "x": 12,
            "y": 24
          },
          "id": 9,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": false,
            "max": true,
            "min": true,
            "rightSide": true,
            "show": true,
            "sort": "max",
            "sortDesc": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "alias": "$tag_name",
              "dsType": "influxdb",
              "groupBy": [
                {
                  "params": [
                    "$interval"
                  ],
                  "type": "time"
                },
                {
                  "params": [
                    "name"
                  ],
                  "type": "tag"
                },
                {
                  "params": [
                    "null"
                  ],
                  "type": "fill"
                }
              ],
              "measurement": "virtualmachine",
              "policy": "default",
              "refId": "A",
              "resultFormat": "time_series",
              "select": [
                [
                  {
                    "params": [
                      "net_transmitted_average"
                    ],
                    "type": "field"
                  },
                  {
                    "params": [],
                    "type": "mean"
                  }
                ]
              ],
              "tags": [
                {
                  "key": "name",
                  "operator": "=~",
                  "value": "/^$vmname$/"
                }
              ]
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeShift": null,
          "title": "Network Transmit kb/s",
          "tooltip": {
            "msResolution": true,
            "shared": true,
            "sort": 0,
            "value_type": "cumulative"
          },
          "transparent": true,
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "KBs",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        }
      ],
      "repeat": null,
      "title": "NETWORK",
      "type": "row"
    }
  ],
  "refresh": "10s",
  "schemaVersion": 16,
  "style": "dark",
  "tags": [
    "vmware"
  ],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": false,
        "label": null,
        "multi": true,
        "name": "vCenter",
        "options": [],
        "query": "SHOW TAG VALUES FROM \"virtualmachine\" with key = \"host\"",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": true,
        "label": "Virtual Machine",
        "multi": true,
        "name": "vmname",
        "options": [],
        "query": "SHOW TAG VALUES FROM \"virtualmachine\" WITH KEY = \"name\" where \"host\" =~ /^$vCenter$/",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "vSphere",
        "hide": 0,
        "includeAll": true,
        "label": "ESX",
        "multi": true,
        "name": "esx",
        "options": [],
        "query": "SHOW TAG VALUES FROM \"hostsystem\" WITH KEY = \"name\" where \"host\" =~ /^$vCenter$/",
        "refresh": 1,
        "regex": "",
        "sort": 0,
        "tagValuesQuery": null,
        "tags": [],
        "tagsQuery": null,
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-3h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "browser",
  "title": "VMware Performance: Multiple VMs",
  "uid": null,
  "version": 25
},
  "folderId": 0,
  "overwrite": true
}'



echo "Set DataCore Dashboard as Home"
curl  --silent --output /dev/null  -X PUT \
  http://docker:3000/api/user/preferences \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic Z3JhZmFuYTpncmFmYW5h' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
    "theme": "",
    "homeDashboardId": 1,
    "timezone": ""
}'

exec "$@"