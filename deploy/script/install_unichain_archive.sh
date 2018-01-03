#! /bin/bash

# The set -e option instructs bash to immediately exit
# if any command has a non-zero exit status
set -e

CUR_INSTALL_PATH=$(cd "$(dirname "$0")"; pwd)
rm -f ${CUR_INSTALL_PATH}/unichain-archive.tar.gz 2>/dev/null

[ $# -lt 1 ] && echo -e "[ERROR]install_unichain_archive.sh need param!!!" && exit 1

install_orig=$1

if [ $install_orig == "git" ];then
install_tag=$2
    [ $# -lt 2 ] && echo -e "[ERROR]install_unichain_archive.sh need 2 param!!!" && exit 1
    cd ../../
    git archive ${install_tag} --format=tar --output=unichain-archive.tar
    gzip unichain-archive.tar
    mv unichain-archive.tar.gz deploy/script/
    cd -
elif [ $install_orig == "local" ];then
    cd ../../
    tar -cf unichain-archive.tar *
    gzip unichain-archive.tar
    mv unichain-archive.tar.gz deploy/script/
    cd -
elif [ $install_orig == "local_tar_gz" ];then
    cp ../sources/unichain-archive.tar.gz ../script/
fi

fab install_unichain_from_archive

rm -f ${CUR_INSTALL_PATH}/unichain-archive.tar.gz 2>/dev/null
