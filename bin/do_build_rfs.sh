#!/bin/bash

# if [ ! -f $DEBIAN_RFS_DIR ]
# then
# mkdir ${SOURCES_DIR}/debian_rfs
# fi

cp -p ${CONFIGS_DIR}/zynqmp-build-itb.its ${DEBIAN_RFS_DIR}
cp -p ${IMAGES_DIR}/system.dtb ${DEBIAN_RFS_DIR}
cp -p $IMAGES_DIR/Image.gz $DEBIAN_RFS_DIR/Image.gz
# cp -p $IMAGES_DIR/boot/BOOT.BIN ${DEBIAN_RFS_DIR}
# cp -p $IMAGES_DIR/boot/*.bit $DEBIAN_RFS_DIR/$BITSTREAM_NAME

if [ ! -f $CONFIGS_DIR/zynqmp-build-itb.its ]
then
    echo "$0: zynqmp-build-itb.its Missing, Fail"
    exit 1
fi

if [ ! -f $IMAGES_DIR/Image ]
then
    echo "$0: IMAGES_DIR/Image Missing, Fail"
    exit 1
else
    cp -p $IMAGES_DIR/Image $DEBIAN_RFS_DIR/Image
fi

if [ ! -f ${IMAGES_DIR}/system.dtb ]
then
    echo "$0: ${SOURCES_DIR}/device-tree/system.dtb Missing, Fail"
    exit 1
else
    cp -p ${IMAGES_DIR}/system.dtb $DEBIAN_RFS_DIR/system.dtb
fi

# if [ ! -f $IMAGES_DIR/boot/BOOT.BIN ]
# then
#     echo "$0: IMAGES_DIR/boot/BOOT.BIN Missing, Fail"
#     exit 1
# else
#     cp -p $IMAGES_DIR/boot/BOOT.BIN $DEBIAN_RFS_DIR/BOOT.BIN
# fi

# if [ ! -f $IMAGES_DIR/boot/*.bit ]
# then
#     echo "$0: IMAGES_DIR/boot/zynq.bit Missing, Fail"
#     exit 1
# else
#     cp -p $IMAGES_DIR/boot/*.bit $DEBIAN_RFS_DIR/$BITSTREAM_NAME
# fi

if [ ! -f ${IMAGES_DIR}/do_setup_debian.sh]
then
    echo "$0: ${SOURCES_DIR}/do_setup_debian.sh Missing, Fail"
    exit 1
else
    cp -p ${ROOT_DIR}/bin/do_setup_debian.sh $DEBIAN_RFS_DIR/
fi

pushd $DEBIAN_RFS_DIR


sudo  do_setup_debian.sh
if [ $? -ne 0 ]
then
    echo "$0: do_setup_debian FAILED, Fail"
    exit 1
fi



# cp -p zynq-base-os.tar.gz $IMAGES_DIR/zynq-base-os.tar.gz
# cp -p zynq.itb $IMAGES_DIR/boot/image.ub


popd
