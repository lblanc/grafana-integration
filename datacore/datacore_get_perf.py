#!/usr/bin/env python3


"""
Get system and product information, and server properties for servers
in the server group. Then, add them to the Grafana InfluxDB server.
"""


import json
import time
import logging
import configparser
from concurrent.futures import ProcessPoolExecutor

import requests


def get_resource(args):
    """
    Get the resource at url. The mandatory arguments are url, resource and
    headers (a dict with two keys: 'ServerHost' and 'Authorization').
    See the Datacore doc for more information on the arguments needed for
    each resource.

    The arguments are passed as a dict so we can use this funtion with a
    futures.

    Return a Python dict.
    """
    logging.info('Querying {} {}'.format(args['resource'], args.get('id', '')))
    if len(args) > 3:  # We have something else than the mandatory stuff
        k, v = [(k, v) for k, v in args.items()
                if k not in ['url', 'resource', 'headers']][0]
        s = '{}/{}/{}'.format(args['url'], args['resource'], v)
    else:
        s = '{}/{}'.format(args['url'], args['resource'])

    r = requests.get(s, headers=args['headers'])
    if r.status_code == 200:
        logging.info('Done querying {} {}'.format(args['resource'], args.get('id', '')))
    else:
        logging.error('A problem occurs... Response code was {}'.format(r.status_code))


    return r.json()


def get_all(url, resources, headers):
    """
    Asynchronously get all the wanted resources, taking care of the
    priorities (hosts before ports for example).

    Return the results as json.
    """
    # First, we get the resources that are not performance
    res_not_perf = [{'url': url, 'headers': headers, 'resource': r}
                    for r in resources if 'perf' not in r]
    # Special case
    if 'virtualdisks' in res_not_perf:
        i = res_not_perf.index('virtualdisks')
        res_not_perf[i]['type'] = '2'

    temp = {}
    with ProcessPoolExecutor() as executor:
        for r, res in zip((i['resource'] for i in res_not_perf),
                          executor.map(get_resource, res_not_perf)):
            temp[r] = res

    # Second, we get the performance resources, using the Ids
    # fetched just above
    res_perf = {}
    for r in resources:
        if 'perf' not in r:
            continue
        k = r.split('_')[0]
        for v in temp[k]:
            i = '{}_{}'.format(r, v['Id'])
            res_perf[i] = {'url': url, 'headers': headers, 'resource': 'performance',
                           'id': v['Id']}

    result = {}
    with ProcessPoolExecutor() as executor:
        for r, res in zip(res_perf.keys(),
                          executor.map(get_resource, res_perf.values())):
            result[r] = res

    # Finally, we clean up the results and return them
    
    for k, v in temp.items():
        for i in v:
            result['{}_{}'.format(k, i['Id'])] = i
    return result



def make_influxdb_line(data):
    """
    Return a str suitable to be send to the InfluxDB server.

    .. Note:: We assume we have **no** shared physical disks.
    """
    result = []
    for k, v in data.items():
        fd = k.split('_') # The Id
        i = '_'.join(fd[2:])  # The Id
        # What do we have?
        if 'servers_perf' in k:
            table = 'DataCore_Servers'
            objectname = 'DataCore\ Servers'
            instance = data['servers_{}'.format(i)]['ExtendedCaption'].replace(' ', '\\ ')
            host = data['servers_{}'.format(i)]['Caption'].replace(' ', '\\ ')
        elif 'pools_perf' in k:
            table = 'DataCore_Disk_pools'
            objectname = 'DataCore\ Disk\ pools'
            pool = data['pools_{}'.format(i)]
            instance = pool['ExtendedCaption'].replace(' ', '\\ ')
            host = data['servers_{}'.format(pool['ServerId'])]['Caption'].replace(' ', '\\ ')
        elif 'virtualdisks_perf' in k:
            table = 'DataCore_Virtual_Disks'
            objectname = 'DataCore\ Virtual\ disks'
            vdsk = data['virtualdisks_{}'.format(i)]
            instance = vdsk['ExtendedCaption'].replace(' ', '\\ ')
            host = 'NA'
        elif 'physicaldisks_perf' in k:
            table = 'DataCore_Physical_disk'
            objectname = 'DataCore\ Physical\ disk'
            pdsk = data['physicaldisks_{}'.format(i)]
            instance = pdsk['ExtendedCaption'].replace(' ', '\\ ')
            if data.get('servers_{}'.format(pdsk['HostId'])):
                host = data['servers_{}'.format(pdsk['HostId'])]['Caption'].replace(' ', '\\ ')
            else:
                host = data['hosts_{}'.format(pdsk['HostId'])]['Caption'].replace(' ', '\\ ')
        elif 'ports_perf' in k:
            table = 'DataCore_SCSI_ports'
            objectname = 'DataCore\ SCSI\ ports'
            instance = data['ports_{}'.format(i)]['ExtendedCaption'].replace(' ', '\\ ')
            host = data['ports_{}'.format(i)]['HostId']
            if host is None:
               continue
            else:
               host = host.replace(' ', '\\ ')
        elif 'monitors' in k:  # Special case
            line = 'DataCore_Monitors,instance={},objectname={} State={} {}'
            result.append(line.format(
                data[k]['ExtendedCaption'].replace(' ', '\\ '),
                data[k]['Caption'].replace(' ', '\\ '),
                data[k]['State'],
                int(data[k]['TimeStamp'][6:-7])*1000000
            ))
            continue
        elif 'hosts' in k:  # Special case
            continue
        elif 'servers' in k:
            line = 'DataCore_State,objectname=DataCore\ Servers,host={} State={}'
            result.append(line.format(
                data[k]['Caption'].replace(' ', '\\ '),
                data[k]['State'],
            ))
            continue
        elif 'virtualdisks' in k:
            line = 'DataCore_State,objectname=DataCore\ Virtual\ disks,instance={} State={}'
            result.append(line.format(
                data[k]['Caption'].replace(' ', '\\ '),
                data[k]['DiskStatus'],
            ))
            continue
        else:
            continue

        perf = v[0]  # We assume we have NO shared physical disks

        line = '{},instance={},objectname={},host={} {} {}'
        for p in perf:
            if p == 'CollectionTime' or p == '__type':
                continue
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                '='.join([p, str(perf[p])]),
                int(perf['CollectionTime'][6:-2])*1000000
            ))

    return '\n'.join(result)


def main():
    config = configparser.ConfigParser()
    config.read('/etc/datacore/datacore_get_perf.ini')

    if config['LOGGING'].getboolean('log'):
        logging.basicConfig(filename=config['LOGGING']['logfile'],
                            format='%(asctime)s - %(message)s',
                            level=logging.INFO)
    else:
        logging.basicConfig(format='%(asctime)s - %(message)s')

    url = "http://{}/RestService/rest.svc/1.0/".format(config['SERVERS']['rest_server'])
    headers = {'ServerHost': config['SERVERS']['datacore_server'],
               'Authorization': 'Basic {} {}'.format(config['CREDENTIALS']['user'],
                                                     config['CREDENTIALS']['passwd'])}

    resources = [r for r in config['RESOURCES'] if config['RESOURCES'].getboolean(r)]

    logging.info('Begin to query the REST server at {}'.format(config['SERVERS']['rest_server']))
    metrics = get_all(url, resources, headers)
    logging.info('Done for REST queries')

    logging.info('Writing down the metrics to the InfluxDB server at {}'
                 .format(config['SERVERS']['influxdb_server']))
    influxdb_line = make_influxdb_line(metrics)
    url ='http://{}:{}/write?db=DataCoreRestDB'.format(config['SERVERS']['influxdb_server'],
                                                       config['SERVERS']['influxdb_port'])

    #logging.info (influxdb_line)
    req = requests.post(url, data=influxdb_line.encode('utf-8'))
    if req.status_code >= 200 and req.status_code < 300:
        logging.info('Done!')
    else:
        logging.error('A problem occurs... Response code was {}'.format(req.status_code))
        logging.error(req.text)

    logging.info('Bye!')


if __name__ == '__main__':
    main()
    exit(0)

