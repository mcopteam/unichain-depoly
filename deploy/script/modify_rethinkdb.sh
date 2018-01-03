#! /bin/bash

# The set -e option instructs bash to immediately exit
# if any command has a non-zero exit status
set -e

# (Re)create the RethinkDB configuration file conf/rethinkdb.conf
echo -e "[INFO]==========init rethinkdb conf=========="
python3 modify_rethinkdb_conf.py

# Rollout storage backend (RethinkDB) and start it
echo -e "[INFO]=========configure rethinkdb========="
# 修改旧节点rethinkdb配置文件
fab configure_rethinkdb
# 发送新增节点rethinkdb配置文件
fab -f fabfile_modify.py send_configure_rethinkdb

exit 0
