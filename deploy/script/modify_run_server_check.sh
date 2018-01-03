#!/bin/bash

set -e
source ./blockchain_nodes_conf_util.sh
source ./common_lib.sh

CLUSTER_BIGCHAIN_COUNT=`get_cluster_nodes_num`
[ $CLUSTER_BIGCHAIN_COUNT -eq 0 ] && {
    echo -e "[ERROR] blockchain_nodes num is 0"
    exit 1
}
MODIFY_CLUSTER_BIGCHAIN_COUNT=`get_modify_nodes_num`
[ ${MODIFY_CLUSTER_BIGCHAIN_COUNT} -eq 0 ] && {
    echo -e "[ERROR] modify blockchain nodes num is 0"
    exit 1
}

((ALL_NODE_NUMBER=${CLUSTER_BIGCHAIN_COUNT}+${CLUSTER_BIGCHAIN_COUNT}))

#detect rethinkdb
echo -e "[INFO]===========检测rethinkdb进程及分片及副本数==========="
for((i=0; i<${MODIFY_CLUSTER_BIGCHAIN_COUNT}; i++));do
    fab -f fabfile_modify.py set_host:${i} detect_rethinkdb:${i},${ALL_NODE_NUMBER}
done
for((i=0; i<${CLUSTER_BIGCHAIN_COUNT}; i++));do
    fab set_host:${i} detect_rethinkdb:${i},${ALL_NODE_NUMBER}
done

echo -e "[INFO]===========检测localdb==========="
fab detect_localdb
fab -f fabfile_modify.py detect_localdb

#detect unichain-pro
# get bigchain port & check port & check process
echo -e "[INFO]===========检测unichain集群个数及进程数=========="
fab detect_unichain:${ALL_NODE_NUMBER}
fab -f fabfile_modify.py detect_unichain:${ALL_NODE_NUMBER}

#detect unichain-api
# get api port & check port & check api
echo -e "[INFO]===========检测unichain集群个数及api进程数==========="
fab detect_unichain_api:${ALL_NODE_NUMBER}
fab -f fabfile_modify.py detect_unichain_api:${ALL_NODE_NUMBER}

echo -e "[INFO]===========检测unichain的公约环==========="
fab set_host:0 detect_unichain_config

exit 0
