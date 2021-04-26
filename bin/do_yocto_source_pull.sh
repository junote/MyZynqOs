#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi



BRANCH="master"
URL=https://github.com/Xilinx/

REPO_LIST="meta-xilinx meta-xilinx-tools meta-petalinux poky meta-mingw meta-openamp meta-browser meta-openembedded meta-qt5 meta-linaro meta-virtualization"

pushd sources
for repo in $REPO_LIST
do
    if [ ! -e $repo ]
    then
        PULL_STRING="-b $BRANCH $URL/$repo".git
        git clone $PULL_STRING
    else
	echo "$0: $repo already pulled, skiping"
    fi
done

mv poky core
touch poky

. $ROOT_DIR/bin/setupyoctosdk

popd
