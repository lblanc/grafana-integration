#coding:utf-8
"""
Module for using DataCore REST API
"""
from __future__ import unicode_literals
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
    config.read('/etc/datacore/datacore_get_perf.ini')
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




url_influxdb ='http://{}:{}/write?db=DataCoreRestDB'.format(config['SERVERS']['influxdb_server'],
                                                       config['SERVERS']['influxdb_port'])



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





def put_in_influxdb(datas):

    result = []

    for data in datas:
        if "servers" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_Servers"
            objectname = "DataCore\ Servers"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            host = data["Caption"].replace(" ", "\\ ")
            # Add specific info
            add_info = ",id=" + data["Id"]
            add_info += ",OsVersion=" + data["OsVersion"].replace(" ", "\\ ")
            add_info += ",ProductBuild=" + data["ProductBuild"].replace(" ", "\\ ")
            add_info += ",ProductVersion=" + data["ProductVersion"].replace(" ", "\\ ")
            add_info += ",ProductName=" + data["ProductName"].replace(" ", "\\ ")
            add_info += ",ProductType=" + data["ProductType"].replace(" ", "\\ ")
            add_info += ",Caption=" + data["Caption"].replace(" ", "\\ ")
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["State", str(data["State"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["CacheState", str(data["CacheState"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["PowerState", str(data["PowerState"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
        elif "pools" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_Disk_pools"
            objectname = "DataCore\ Disk\ pools"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            host = dcs_caption_from_id(data["ServerId"],dcs_servers)
            host = host.replace(" ", "\\ ")
            # Add specific info
            add_info = ",id=" + data["Id"]
            add_info += ",InSharedMode=" + str(data["InSharedMode"])
            add_info += ",AutoTieringEnabled=" + str(data["AutoTieringEnabled"])
            add_info += ",Caption=" + data["Caption"].replace(" ", "\\ ")
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["PoolStatus", str(data["PoolStatus"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["TierReservedPct", str(data["TierReservedPct"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["ChunkSize", str(data["ChunkSize"]["Value"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
            result.append(line.format(
                table,
                instance,
                objectname,
                host,
                add_info,
                "=".join(["MaxTierNumber", str(data["MaxTierNumber"])]),
                int(data["Performances"]["CollectionTime"][6:-2])*1000000
            ))
        elif "virtualdisks" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_Virtual_Disks"
            objectname = "DataCore\ Virtual\ disks"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            host = 'NA'
            # Add specific info
            add_info = ",id=" + data["Id"]
            add_info += ",ScsiDeviceIdString=" + data["ScsiDeviceIdString"]
            add_info += ",Type=" + str(data["Type"])
            if data["FirstHostId"] != None:
                add_info += ",FirstHost=" + dcs_caption_from_id(data["FirstHostId"],dcs_servers)
            if data["SecondHostId"] != None:
                add_info += ",SecondHost=" + dcs_caption_from_id(data["SecondHostId"],dcs_servers)
            add_info += ",Caption=" + data["Caption"].replace(" ", "\\ ")
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
            result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join(["DiskStatus", str(data["DiskStatus"])]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
            result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join(["Size", str(data["Size"]["Value"])]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
        elif "physicaldisks" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_Physical_disk"
            objectname = "DataCore\ Physical\ disk"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            host = dcs_caption_from_id(data["HostId"],dcs_servers_hosts)
            host = host.replace(" ", "\\ ")
            # Add specific info
            add_info = ",id=" + data["Id"]
            if data["InquiryData"]["Serial"] != None:
                add_info += ",Serial=" + data["InquiryData"]["Serial"]
            else:
                add_info += ",Serial=UNKNOWN"
            add_info += ",Type=" + str(data["Type"])
            add_info += ",Caption=" + data["Caption"].replace(" ", "\\ ")
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
            result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join(["DiskStatus", str(data["DiskStatus"])]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
        elif "ports" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_SCSI_ports"
            objectname = "DataCore\ SCSI\ ports"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            if data["HostId"] != None:
                host = dcs_caption_from_id(data["HostId"],dcs_servers_hosts)
                host = host.replace(" ", "\\ ")
            else:
                host = 'NA'
            # Add specific info
            add_info = ",id=" + data["Id"]
            try:
                if data["__type"] != None:
                    add_info += ",__type=" + data["__type"]
                    add_info += ",Role=" + str(data["ServerPortProperties"]["Role"])
            except:
                logging.info("No __type")
                
            add_info += ",PortType=" + str(data["PortType"])
            
            try:
                add_info += ",PortRole=" + str(data["ServerPortProperties"]["Role"])
            except:
                add_info += ",PortRole=" + "N/A"

            add_info += ",Caption=" + data["Caption"].replace(" ", "\\ ")
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
        elif "hosts" in data["dcs_resource"]:
            line = "{},instance={},objectname={},host={}{} {} {}"
            table = "DataCore_Hosts"
            objectname = "DataCore\ Hosts"
            instance = data["ExtendedCaption"].replace(" ", "\\ ")
            host = data["Caption"].replace(" ", "\\ ")
            # Add specific info
            add_info = ",id=" + data["Id"]
            add_info += ",MpioCapable=" + str(data["MpioCapable"])
            add_info += ",AluaSupport=" + str(data["AluaSupport"])
            for k,v in data["Performances"].items():
                if "CollectionTime" in k:
                    continue
                result.append(line.format(
                    table,
                    instance,
                    objectname,
                    host,
                    add_info,
                    "=".join([str(k), str(v)]),
                    int(data["Performances"]["CollectionTime"][6:-2])*1000000
                ))
        else:
            logging.error("This resource ({}) is not yet implemented".format(resource))
    
    # Post in influxdb
    logging.info("Post data in influxdb")         
    data = "\n".join(result)
    req = requests.post(url_influxdb, data.encode('utf-8'))
    if req.status_code >= 200 and req.status_code < 300:
        logging.info("Done!")
    else:
        logging.error("A problem occurs... Response code was {}".format(req.status_code))
        logging.error(req.text)




if __name__ == "__main__":
    
    dcs_servers = {}

    dcs_servers = dcs_get_object("servers")
    dcs_servers_hosts = dcs_servers + dcs_get_object("hosts")
    resources = [r for r in config['RESOURCES'] if config['RESOURCES'].getboolean(r)]
    
    dcs_objects = []
    for resource in resources:
        dcs_objects += dcs_get_object(resource)
    
    dcs_perfs = dcs_get_perf(dcs_objects)

    put_in_influxdb(dcs_perfs)
  
