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

import argparse
import json
import os

from hostlist import public_hosts
from monitor_server import gMonitorServer
from multi_apps_conf import app_config

unichain_confiles = os.getcwd()

keypairs_path = os.chdir('../script')
if os.path.isfile('keypairs.py'):
    from keypairs import keypairs_list

os.chdir(unichain_confiles)

# Parse the command-line arguments
desc = 'Transform a directory of default {} base_conf files '.format(app_config['setup_name'])
desc += 'into base_conf files for a cluster'
parser = argparse.ArgumentParser(description=desc)
parser.add_argument('dir',
                    help='Directory containing the base_conf files')
parser.add_argument('number_of_files',
                    help='Number of base_conf files expected in dir',
                    type=int)
parser.add_argument('-k', '--use-keypairs',
                    action='store_true',
                    default=False,
                    help='Use public and private keys from keypairs.py')
args = parser.parse_args()

conf_dir = args.dir

num_files_expected = int(args.number_of_files)
use_keypairs = args.use_keypairs

# Check if the number of files in conf_dir is what was expected
conf_files = sorted(os.listdir(conf_dir))
num_files = len(conf_files)
if num_files != num_files_expected:
    raise ValueError('There are {} files in {} but {} were expected'.
                     format(num_files, conf_dir, num_files_expected))

# If the -k option was included, check to make sure there are enough keypairs
# in keypairs_list
num_keypairs = len(keypairs_list)

if use_keypairs:
    if num_keypairs < num_files:
        raise ValueError('There are {} base_conf files in {} but '
                         'there are only {} keypairs in keypairs.py'.
                         format(num_files, conf_dir, num_keypairs))
    print('Using keypairs from keypairs.py')
    pubkeys = [keypair[1] for keypair in keypairs_list[:num_files]]
else:
    # read the pubkeys from the base_conf files in conf_dir
    pubkeys = []
    for filename in conf_files:
        file_path = os.path.join(conf_dir, filename)
        with open(file_path, 'r') as f:
            conf_dict = json.load(f)
            pubkey = conf_dict['keypair']['public']
            pubkeys.append(pubkey)

# Rewrite each base_conf file, one at a time
for i, filename in enumerate(conf_files):
    file_path = os.path.join(conf_dir, filename)
    with open(file_path, 'r') as f:
        conf_dict = json.load(f)
        # If the -k option was included
        # then replace the private and public keys
        # with those from keypairs_list
        if use_keypairs:
            keypair = keypairs_list[i]
            conf_dict['keypair']['private'] = keypair[0]
            conf_dict['keypair']['public'] = keypair[1]
        # The keyring is the list of *all* public keys
        # minus the base_conf file's own public key
        keyring = list(pubkeys)
        keyring.remove(conf_dict['keypair']['public'])
        conf_dict['keyring'] = keyring
        # Allow incoming server traffic from any IP address
        # to port 9984
        conf_dict['server']['bind'] = '0.0.0.0:{}'.format(app_config['server_port'])
        # Set the api_endpoint
        conf_dict['api_endpoint'] = 'http://' + public_hosts[i] + \
                                    ':{}/uniledger/v1'.format(app_config['server_port'])
        # Set Statsd host
        conf_dict['statsd']['host'] = gMonitorServer

        # localdb restore app
        conf_dict['restore_server']['bind'] = '0.0.0.0:{}'.format(app_config['restore_server_port'])
        conf_dict['restore_server']['compress'] = True
        conf_dict['restore_endpoint'] = 'http://' + public_hosts[i] +\
                                        ':{}/uniledger/v1/collect'.format(app_config['restore_server_port'])

        # multi apps configure
        conf_dict['app']['service_name'] = '{}'.format(app_config['service_name'])
        conf_dict['app']['setup_name'] = '{}'.format(app_config['setup_name'])
    # Delete the base_conf file
    # os.remove(file_path)

    # Write new base_conf file with the same filename
    print('Rewriting {}'.format(file_path))
    with open(file_path, 'w') as f2:
        json.dump(conf_dict, f2)
