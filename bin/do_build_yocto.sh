#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi

pushd $SOURCES_DIR

. $ROOT_DIR/bin/setupyoctosdk

MACHINE=zcu102-zynqmp bitbake petalinux-image-minimal
if [ $? -ne 0 ]
then
    exit 1
fi

MACHINE=zcu102-zynqmp bitbake petalinux-image-minimal -c populate_sdk
if [ $? -ne 0 ]
then
    exit 1
fi

pwd
cp -p tmp/deploy/sdk/petalinux-glibc-x86_64-petalinux-image-minimal-aarch64-toolchain-2019.1.host.manifest ${IMAGES_DIR}/
cp -p tmp/deploy/sdk/petalinux-glibc-x86_64-petalinux-image-minimal-aarch64-toolchain-2019.1.target.manifest ${IMAGES_DIR}/
cp -p tmp/deploy/sdk/petalinux-glibc-x86_64-petalinux-image-minimal-aarch64-toolchain-2019.1.sh ${IMAGES_DIR}/

popd
