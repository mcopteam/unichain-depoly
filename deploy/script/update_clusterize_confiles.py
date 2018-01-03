# -*- coding: utf-8 -*-
"""Given a directory full of default BigchainDB base_conf files,
transform them into base_conf files for a cluster with proper
keyrings, API endpoint values, etc. This script is meant to
be interpreted as a Python 2 script.

Note 1: This script assumes that there is a file named hostlist.py
containing public_dns_names = a list of the public DNS names of
all the hosts in the cluster.

Note 2: If the optional -k argument is included, then a keypairs.py
file must exist and must have enough keypairs in it to assign one
to each of the base_conf files in the directory of base_conf files.
You can create a keypairs.py file using write_keypairs_file.py

Usage:
    python clusterize_confiles.py [-h] [-k] dir number_of_files
"""

from __future__ import unicode_literals
import sys
import json
import os

from hostlist import public_hosts
from monitor_server import gMonitorServer
from multi_apps_conf import app_config

unichain_confiles = os.getcwd()

# 参数1:key文件路径,参数2:param文件路径,参数3:server文件路径,参数4:节点个数
key_dir = sys.argv[1]
param_dir = sys.argv[2]
server_dir = sys.argv[3]
use_keypairs = int(sys.argv[4])

# 检查文件个数与节点个数是否匹配
key_files = sorted(os.listdir(key_dir))
param_files = sorted(os.listdir(param_dir))
server_files = sorted(os.listdir(server_dir))

key_num_files = len(key_files)
param_key_num_files = len(param_files)
server_num_files = len(server_files)


if key_num_files != use_keypairs or param_key_num_files != use_keypairs or server_num_files != use_keypairs:
    raise ValueError('文件个数与节点个数是否不匹配!!!')

pubkeys = []
for filename in key_files:
    file_path = os.path.join(key_dir, filename)
    with open(file_path, 'r') as f:
        conf_dict = json.load(f)
        pubkey = conf_dict['keypair']['public']
        pubkeys.append(pubkey)


# 重写server配置文件
for i, filename in enumerate(server_files):
    file_path = os.path.join(server_dir, filename)
    with open(file_path, 'r') as f:
        conf_dict = json.load(f)
        conf_dict['server']['bind'] = '0.0.0.0:{}'.format(app_config['server_port'])
        conf_dict['api_endpoint'] = 'http://' + public_hosts[i] + \
                                    ':{}/uniledger/v1'.format(app_config['server_port'])
        conf_dict['statsd']['host'] = gMonitorServer
        conf_dict['restore_server']['bind'] = '0.0.0.0:{}'.format(app_config['restore_server_port'])
        conf_dict['restore_server']['compress'] = True
        conf_dict['restore_endpoint'] = 'http://' + public_hosts[i] +\
                                        ':{}/uniledger/v1/collect'.format(app_config['restore_server_port'])

        conf_dict['app']['service_name'] = '{}'.format(app_config['service_name'])
        conf_dict['app']['setup_name'] = '{}'.format(app_config['setup_name'])
    print('Rewriting {}'.format(file_path))
    with open(file_path, 'w') as f2:
        json.dump(conf_dict, f2)
