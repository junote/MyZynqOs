#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi



URL=https://github.com/Xilinx/


# project:repository:branch
REPO_LIST="linux-xlnx \
           u-boot-xlnx \
           embeddedsw \
           arm-trusted-firmware \
           device-tree-xlnx \
            "

# set needed
$BRANCH = matser


pushd sources
for repo in $REPO_LIST
do
    # PROJ=`echo $repo | awk -F : '{print $1}'`
    # REPO=`echo $repo | awk -F : '{print $2}'`
    # BRANCH=`echo $repo | awk -F : '{print $3}'`
    if [ ! -e $REPO ]
    then
        # PULL_STRING="$URL/$PROJ/$REPO".git
        PULL_STRING="$URL/$REPO.git
        git clone $PULL_STRING
	if [ $? -ne 0 ]
	then
	    echo "$0: Could not fetch $repo"
	    exit 1
	fi

	pushd $REPO

	git checkout $BRANCH
	if [ $? -ne 0 ]
	then
	    echo "$0: Could not checkout $repo"
	    exit 1
	fi

	popd
    else
	echo "$0: $repo already pulled, skiping"
    fi
done



# URL=http://sv-debosmirror/mirror/petalinux.xilinx.com/sswreleases/rel-v2019.1/downloads/xsct/
URL=http://petalinux.xilinx.com/sswreleases/rel-v2019.1/downloads/xsct/
XSCT_FNAME=xsct_2019.1.tar.xz

pushd $SOURCES_DIR

if [ ! -f $XSCT_FNAME ]
then
    wget $URL/$XSCT_FNAME
    if [ $? -ne 0 ]
    then
       echo "$0: wget of XSCT failed, error"
       exit 1
    fi
else
    echo "$0: $XSCT_FNAME exists, not pulling"
fi

if [ ! -d Scout ]
then
    tar xf $XSCT_FNAME
    if [ $? -ne 0 ]
    then
       echo "$0: tar xf of XSCT failed, error"
       exit 1
    fi
else
    echo "$0: Scout directory exists, not unpacking."
fi

popd

# pull buildroot
pushd $SOURCES_DIR

if [ ! -f buildroot ]
then
    git clone https://github.com/buildroot/buildroot.git
    if [ $? -ne 0 ]
    then
       echo "$0: git of buildroot failed, error"
       exit 1
    fi
else
    echo "$0: buildroot exists, not pulling"
fi
popd

#  We need to symlink embeddedsw to pmu-firmware to make xsct work;
#  Yocto pulls embeddedsw into pmu-firmware for the build, it appears
#  to be key to making it work.

pushd $SOURCES_DIR
if [ ! -e pmu-firmware ]
then
    ln -s embeddedsw pmu-firmware
fi
popd


