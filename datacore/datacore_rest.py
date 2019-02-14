#coding:utf-8
"""
Module for using DataCore REST API
"""
import sys

def msg_error_import(module_name):
    print("Need '{}' module, you have to install it".format(module_name))
    print("Run 'pip install {}'".format(module_name))
    sys.exit(1)

try:
    import logging
except:
    msg_error_import("logging")
try:
    import configparser
except:
    msg_error_import("configparser")
try:
    import requests
except:
    msg_error_import("requests")
try:
    import json
except:
    msg_error_import("json")
try:
    from concurrent.futures import ThreadPoolExecutor
except:
    msg_error_import("futures")
try:
    from concurrent.futures import ProcessPoolExecutor
except:
    msg_error_import("concurrent")



# Read config file
config = configparser.ConfigParser()
try:
    config.read('datacore_get_perf.ini')
except:
    print("Config file (datacore_get_perf.ini) not found")
    sys.exit(1)

# Enable logging
if config['LOGGING'].getboolean('log'):
    logging.basicConfig(filename=config['LOGGING']['logfile'],
                        format='%(asctime)s - %(message)s',
                        level=logging.INFO)
else:
    logging.basicConfig(format='%(asctime)s - %(message)s')

# Construct rest url and headers
url = "http://{}/RestService/rest.svc/1.0".format(config['SERVERS']['rest_server'])
headers = {'ServerHost': config['SERVERS']['datacore_server'],
           'Authorization': 'Basic {} {}'.format(config['CREDENTIALS']['user'],
                                                 config['CREDENTIALS']['passwd'])}


# lambdas

dcs_b2g = lambda value:value/1024/1024/1024 # Convert Bytes to GigaBytes

#dcs_request_perf = lambda value:requests.get('{}/performance/{}'.format(url,value), headers=headers) # request perf from dcs_object Id


# fuctions

def print_cool(msg):
    msg = "  " + msg + "  "
    print("".center(80,"#"))
    print(msg.center(80,"#"))
    print("".center(80,"#"))
    print("\n")

def dcs_monitorid_to_str(i):
    """
    Helper that convert a monitor state int to a str.
    """
    if i == 1:
        return "Undefined"
    elif i == 2:
        return "Healthy"
    elif i == 4:
        return "Attention"
    elif i == 8:
        return "Warning"
    elif i == 16:
        return "Critical"
    else:
        return "Undefined"


def dcs_get_object(dcs_object):
    """
    Get DataCore Object (ex: servers, virtualdisks...)
    """
    logging.info('Begin to query the REST server at {}'.format(config['SERVERS']['rest_server']))
    
    try:
        r = requests.get('{}/{}'.format(url,dcs_object), headers=headers)
    except:
        logging.error("Something wrong during connection")
        sys.exit(1)
    else:
        logging.info("Querying {}".format(dcs_object))
        tmp = r.json()
        result = []
        for item in tmp:
            item["dcs_resource"] = dcs_object
            result.append(item)
        return result


def dcs_request_perf(dcs_object):
    res = requests.get('{}/performance/{}'.format(url,dcs_object["Id"]), headers=headers)
    logging.info("Querying perf for {}".format(dcs_object["Caption"]))
    dcs_object["Performances"] = res.json()[0]
    return dcs_object

def dcs_get_perf(dcs_objects):
    """
    Get DataCore Objects performances (ex: servers, virtualdisks...)
    """

    logging.info('Begin to query the REST server for perf at {}'.format(config['SERVERS']['rest_server']))

    result = []
    with ProcessPoolExecutor() as executor:
        for  dcs_perf in zip(dcs_objects, executor.map(dcs_request_perf, dcs_objects)):
            result.append(dcs_perf[1])
    return result


def dcs_caption_from_id(dcs_id,dcs_json_data):
    """
    Find Caption from an DataCore Id
    """ 
    for item in dcs_json_data:
        if item["Id"] == dcs_id:
            return item["Caption"]





if __name__ == "__main__":

    """
    # dcs_get_object example to get servers
    print_cool("dcs_get_object example to get servers")

    dcs_servers = dcs_get_object("servers")

    for dcs_server in dcs_servers:
        print("Server: {}\nOS Version: {}\nDataCore Version: {}".format(dcs_server["HostName"],dcs_server["OsVersion"],dcs_server["ProductVersion"]))
        print("Id: {}\nCache State: {}".format(dcs_server["Id"],dcs_monitorid_to_str(dcs_server["CacheState"])))
        print("Cache Size: {}GB\n".format(dcs_b2g(dcs_server["CacheSize"]["Value"])))

    # dcs_get_object example to get virtual disks
    print_cool("dcs_get_object example to get virtual disks")

    dcs_vdisks = dcs_get_object("virtualdisks")

    for dcs_vdisk in dcs_vdisks:
        if dcs_vdisk["Type"] == 2:
            print("vDisk: {}".format(dcs_vdisk["Caption"]))
            print("Id: {}".format(dcs_vdisk["Id"]))
            print("Size: {}GB".format(dcs_b2g(dcs_vdisk["Size"]["Value"])))
            print("First Host: {}".format(dcs_caption_from_id(dcs_vdisk["FirstHostId"],dcs_servers)))
            print("Second Host: {}\n".format(dcs_caption_from_id(dcs_vdisk["SecondHostId"],dcs_servers)))
    """

    # dcs_get_perf example
    print_cool("dcs_get_perf example")

    dcs_objects = dcs_get_object("servers")
    dcs_objects += dcs_get_object("virtualdisks")
    dcs_objects += dcs_get_object("pools")
    dcs_objects += dcs_get_object("hosts")
    dcs_objects += dcs_get_object("ports")
    dcs_objects += dcs_get_object("physicaldisks")
    #dcs_objects += dcs_get_object("fc")
    dcs_objects += dcs_get_object("targetdevices")
    
    dcs_perfs = dcs_get_perf(dcs_objects)

    for dcs_perf in dcs_perfs:
        print("Caption: {}".format(dcs_perf["Caption"]))
        for k,v in dcs_perf["Performances"].items():
            print("{}: {}".format(k,v))
        print("\n")

    
    logging.info('Bye!')