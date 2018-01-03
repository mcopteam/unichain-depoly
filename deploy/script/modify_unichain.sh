#! /bin/bash

# The set -e option instructs bash to immediately exit
# if any command has a non-zero exit status
set -e

function printErr()
{
    echo "usage: ./configure_unichain.sh <number_of_files>"
    echo "No argument $1 supplied"
}

if [ -z "$1" ]; then
    printErr "<number_of_files>"
    exit 1
fi
NUMFILES=$1

CONFDIR=../conf/unichain_confiles
KEY_DIR=../conf/unichain_confiles/key
PARAM_DIR=../conf/unichain_confiles/param
SERVER_DIR=../conf/unichain_confiles/server

# If $CONFDIR exists, remove it
if [ -d "${CONFDIR}" ]; then
    rm -rf ${CONFDIR}
fi

# 创建配置文件夹
mkdir -p ${CONFDIR}
mkdir -p ${KEY_DIR}
mkdir -p ${PARAM_DIR}
mkdir -p ${SERVER_DIR}

UNICHAIN_TEMPLATE_FILE=../conf/template/unichain.conf.template

UNICHAIN_KEY_FILE=../conf/template/unichain.key.template
UNICHAIN_PARAM_FILE=../conf/template/unichain.param.template
UNICHAIN_SERVER_FILE=../conf/template/unichain.server.template

if [ ! -f "$UNICHAIN_KEY_FILE" ] || [ ! -f "$UNICHAIN_PARAM_FILE" ] || [ ! -f "$UNICHAIN_SERVER_FILE" ]; then
    echo "缺少必要的配置文件模板!!!"
    exit 1
fi

## 创建各个节点模板配置文件
for (( i=0; i<$NUMFILES; i++ )); do
    COPY_KEY_DIR=${KEY_DIR}"/bcdb_conf"$i
    COPY_PARAM_DIR=${PARAM_DIR}"/bcdb_conf"$i
    COPY_SERVER_DIR=${SERVER_DIR}"/bcdb_conf"$i
    echo "Writing "${KEY_DIR}
    echo "Writing "${PARAM_DIR}
    echo "Writing "${SERVER_DIR}
    cp ${UNICHAIN_KEY_FILE} ${COPY_KEY_DIR}
    cp ${UNICHAIN_PARAM_FILE} ${COPY_PARAM_DIR}
    cp ${UNICHAIN_SERVER_FILE} ${COPY_SERVER_DIR}
done

num_pairs=$1
NUM_NODES=$1

## 生成keypair文件
python3 write_keypairs_file.py $num_pairs
UNICHAIN_NODE_KEYRING=../conf

## 备份最近部署公钥环
mkdir -p $UNICHAIN_NODE_KEYRING/keyring_bak
if [ -f "$UNICHAIN_NODE_KEYRING/keyring" ]; then
    datestr=`date +%Y-%m-%d-%H-%M`
    cp $UNICHAIN_NODE_KEYRING/keyring $UNICHAIN_NODE_KEYRING/keyring_bak/keyring_$datestr
fi

## 追加本次新增加节点公约
python3 unichain_keyrings_bak.py

## 生成公私钥配置文件
## 参数1:key文件路径,参数2:param文件路径,参数3:server文件路径,参数4:节点个数
python3 modify_clusterize_confiles.py ${KEY_DIR} ${PARAM_DIR} ${SERVER_DIR} ${NUM_NODES}

# Send one of the config files to each instance
for (( HOST=0 ; HOST<$NUM_NODES ; HOST++ )); do
    CONFILE="bcdb_conf"$HOST
    echo "Sending "$CONFILE
    fab set_host:$HOST send_confile:$CONFILE
    fab -f fabfile_modify.py modify_node_confile
done


exit 0
