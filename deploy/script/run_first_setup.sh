#! /bin/bash

# The set -e option instructs bash to immediately exit
# if any command has a non-zero exit status
set -e

function printErr()
{
     echo "usage: ./first_setup.sh <number_of_files>"
     echo "No argument $1 supplied"
}
##get it from ../conf/blockchain_nodes 
#if [ -z "$1" ]; then
#    printErr "<number_of_files>"
#    exit 1
#fi

if [[ $# -eq 1 && $1 == "nostart" ]];then
    AUTO_START_FLAG=0
else
    AUTO_START_FLAG=1
fi
source ./blockchain_nodes_conf_util.sh
source ./common_lib.sh

##check blocknodes_conf format
echo -e "[INFO]==========check cluster nodes conf=========="
check_cluster_nodes_conf || {
    echo -e "[ERROR] $FUNCNAME execute fail!"
    exit 1
}

echo -e "[INFO]==========cluster nodes info=========="
cat $CLUSTER_CHAINNODES_CONF|grep -vE "^#|^$"
echo -e ""

echo -e "[WARNING]please confirm cluster nodes info: [y/n]"
read cluster_str
if [ "`echo "$cluster_str"|tr A-Z  a-z`" == "y" -o "`echo "$cluster_str"|tr A-Z  a-z`" == "yes" ];then
     echo -e "[INFO]=========begin first_setup=========="
else
    echo -e "[ERROR]input invalid or cluster nodes info invalid"
    echo -e "[ERROR]=========first_setup aborted==========="
    exit 1
fi

CLUSTER_BIGCHAIN_COUNT=`get_cluster_nodes_num`
[ $CLUSTER_BIGCHAIN_COUNT -eq 0 ] && {
    echo -e "[ERROR] blockchain_nodes num is 0"
    exit 1
}

#检查安装python3 fabric3
echo -e "[INFO]==========check master env=========="
./check_env_master.sh
echo -e "[INFO]==========Done=========="
echo -e "  "

## 在线安装python3 及 fabric3
#./run_init_env.sh

## 下载并打包sources
echo -e "[INFO]==========download and generate the unichain-archive.tar.gz=========="
./unichain_source_archive.sh

## 检查sources包及unichain_template文件是否存在
echo -e "[INFO]=========check control machine deploy files is ok!========="
./run_pre_check.sh

## 集群初始化
echo -e "[INFO]==========init all nodes env=========="
#fab init_all_nodes:shred=True,times=1,show=False,config_del=True

## 配置rethinkdb集群信息
echo -e "[INFO]==========configure  rethinkdb=========="
./configure_rethinkdb.sh

#unichain install&configure&init&shards&replicas
echo -e "[INFO]==========install unichain=========="
./install_unichain_archive.sh "local_tar_gz"

echo -e "[INFO]=========configure unichain========="
./configure_unichain.sh ${CLUSTER_BIGCHAIN_COUNT}

echo -e "[INFO]=========init unichain========="
fab init_unichain

echo -e "[INFO]==========set shards unichain=========="
fab set_shards:${CLUSTER_BIGCHAIN_COUNT}

echo -e "[INFO]==========set replicas unichain=========="
REPLICAS_NUM=`gen_replicas_num ${CLUSTER_BIGCHAIN_COUNT}`
fab set_replicas:${REPLICAS_NUM}

#bak conf
echo -e "[INFO]==========bak current conf=========="
./bak_conf.sh "new"
rm keypairs.py
if [[ -z $AUTO_START_FLAG || $AUTO_START_FLAG -eq 1 ]];then
    #start unichain nodes
    echo -e "[INFO]==========start unichain nodes=========="
    ./clustercontrol.sh start
    ./run_server_check.sh
else
    fab stop_rethinkdb
fi

exit 0
