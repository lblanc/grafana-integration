FROM debian:10
MAINTAINER Luc Blanc <email@luc-blanc.com>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8

# Database Defaults
ENV INFLUXDB_GRAFANA_DB datasource
ENV INFLUXDB_GRAFANA_USER datasource
ENV INFLUXDB_GRAFANA_PW datasource

ENV MYSQL_GRAFANA_USER grafana
ENV MYSQL_GRAFANA_PW grafana


# Copy files for DataCore
COPY datacore/* /etc/datacore/


# Base dependencies
RUN mkdir /data-docker && mkdir /data-docker/mysql && mkdir /data-docker/influxdb && \
 ln -s /data-docker/mysql /var/lib/mysql && ln -s /data-docker/influxdb /var/lib/influxdb && \
 chmod 777  /data-docker/influxdb && \
 chmod 777  /var/lib/influxdb && \
 rm /var/lib/apt/lists/* -vf && \
 apt-get -y update && \
 apt-get -y dist-upgrade && \
 apt-get -y --force-yes install \
  apt-utils \
  ca-certificates \
  curl \
  git \
  htop \
  libfontconfig \
  mysql-client \
  mysql-server \
  nano \
  gnupg2 \
  gnupg1 \
  gnupg \
  net-tools \
  openssh-server \
  vim \
  supervisor \
  apt-transport-https \
  python-configparser \
  python-concurrent.futures \
  python-requests \
  cron \
  influxdb \
  wget && \
 #curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
 #apt-get install -y nodejs &&\
  echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list &&\
  wget https://packages.grafana.com/gpg.key &&\
  apt-key add gpg.key &&\
  apt-get update &&\
  apt-get install grafana && \
  wget https://repos.influxdata.com/influxdb.key && \
  apt-key add influxdb.key && \
  echo "deb https://repos.influxdata.com/debian buster stable" |  tee /etc/apt/sources.list.d/influxdb.list && \
  apt-get update && \
  apt-get install telegraf chronograf
 

# Configure Supervisord, SSH, base env, cron and MySql
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /root

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd && \
    cat /etc/datacore/datacore-cron >> /etc/crontab && \
    /etc/datacore/setup_mysql.sh && \
    chmod +x /etc/datacore/config.sh


# Install InfluxDB / Telegraf / chronograf 
#RUN wget https://dl.influxdata.com/chronograf/releases/chronograf_1.6.2_amd64.deb && \
#    dpkg -i chronograf_1.6.2_amd64.deb && rm chronograf_1.6.2_amd64.deb


# Configure InfluxDB
COPY influxdb/init.sh /etc/init.d/influxdb

# Configure Telegraf
COPY telegraf/telegraf.conf /etc/telegraf/telegraf.conf
COPY telegraf/init.sh /etc/init.d/telegraf

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini

# Cleanup
RUN apt-get clean && \
 rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME [ "/data" ]

ENTRYPOINT [ "/etc/datacore/config.sh" ]

CMD [ "/usr/bin/supervisord" ]
