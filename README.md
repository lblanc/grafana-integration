## Docker Image with Telegraf, InfluxDB and Grafana with dashboard & REST script included for [DataCore SANsymphony](http://www.datacore.com)


[![](https://dockerbuildbadges.quelltext.eu/status.svg?organization=lblanc&repository=docker-influxdb-grafana-datacore)](https://hub.docker.com/r/lblanc/docker-influxdb-grafana-datacore/builds/)

[![License](http://img.shields.io/:license-mit-blue.svg)](http://octopress.mit-license.org)


Goal is to have grafana, influxdb and python script running to grab DataCore SANsymphony REST API performances


# Quick Start

To start the container the first time launch this by replacing -e variables:
* DCSSVR ->  DataCore Server (IP or hostname)
* DCSREST -> DataCore Rest API Server(IP or hostname)
* DCSUNAME -> DataCore User name
* DCSPWORD -> DataCore user password

```sh
docker run --ulimit nofile=66000:66000 \
  -d \
  --name grafana-datacore \
  -p 3000:3000 \
  -p 8888:8888 \
  -p 8086:8086 \
  -p 22022:22 \
  -p 8125:8125/udp \
  -e "DCSSVR=X.X.X.X" \
  -e "DCSREST=X.X.X.X" \
  -e "DCSUNAME=administrator" \
  -e "DCSPWORD=password" \
  lblanc/grafana-integration:lastest
```
If you have special characters in the password, do not forget the escapement '' before (ex: "password!" will be "password\\!")


If you want to monitor also vSphere you can add this variables:
* VSPHERE_USER -> vSphere user
* VSPHERE_PASS -> vSphere password
* VSPHERE_VCENTER -> vSphere vCenter (IP or hostname)
* VSPHERE_DOM -> vSphere domain

```sh
docker run --ulimit nofile=66000:66000 \
  -d \
  --name grafana-datacore \
  -p 3000:3000 \
  -p 8888:8888 \
  -p 8086:8086 \
  -p 22022:22 \
  -p 8125:8125/udp \
  -e "DCSSVR=X.X.X.X" \
  -e "DCSREST=X.X.X.X" \
  -e "DCSUNAME=administrator" \
  -e "DCSPWORD=password" \
  -e "VSPHERE_USER=administrator@vsphere.local" \
  -e "VSPHERE_PASS=password" \
  -e "VSPHERE_VCENTER=X.X.X.X" \
  lblanc/grafana-integration:lastest
```

To stop the container launch:
```sh
docker stop grafana-datacore
```


To start the container again launch:
```sh
docker start grafana-datacore
```

# Persistent data

You can optionaly add volume option to store Grafana configuration and influxdb files
Example:
```sh
docker run --ulimit nofile=66000:66000 \
  -d \
  --name grafana-datacore \
  -p 3000:3000 \
  -p 8888:8888 \
  -p 8086:8086 \
  -p 22022:22 \
  -p 8125:8125/udp \
  -v my-volume:/data \
  -e "DCSSVR=X.X.X.X" \
  -e "DCSREST=X.X.X.X" \
  -e "DCSUNAME=administrator" \
  -e "DCSPWORD=password" \
  -e "VSPHERE_USER=administrator@vsphere.local" \
  -e "VSPHERE_PASS=password" \
  -e "VSPHERE_VCENTER=X.X.X.X" \
  lblanc/grafana-integration:lastest
```


# Mapped Ports

```
Host		Container		Service

3000		3000			grafana
8888		8888			chronograf
8086		8086			influxdb
8125		8125			statsd
22022		22        sshd
```


# SSH

```sh
ssh root@localhost -p 22022
```
Password: root


# Grafana

Open <http://localhost:3000>

```
Username: grafana
Password: grafana
```