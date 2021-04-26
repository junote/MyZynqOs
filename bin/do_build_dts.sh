#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi


pushd $SOURCES_DIR

mkdir -p device-tree
pushd device-tree

if [ ! -d device-tree-xlnx ]
then
    git clone https://github.com/Xilinx/device-tree-xlnx.git
    if [ $? -ne 0 ]
    then
        echo "$0: Can't clone Device Tree, FAIL"
	exit 1
    fi

    pushd device-tree-xlnx
    git checkout tags/xilinx-v2019.1
    if [ $? -ne 0 ]
    then
        echo "$0: Can't Checkout Device Tree Branch , FAIL"
	exit 1
    fi
    popd
else
    echo "$0: device-tree-xlnx exists, not pulling"
fi


#  Setup path to key tools in XSCT directory.
#

PATH=$PATH:$SOURCES_DIR/Scout/2019.1/gnu/aarch64/lin/aarch64-none/bin
PATH=$PATH:$SOURCES_DIR/Scout/2019.1/bin
PATH=$PATH:$SOURCES_DIR/Scout/2019.1/gnu/microblaze/lin/bin

cat > gen_dts_from_hdf.tcl << EOF

hsi open_hw_design ${XSA_PATH}

hsi set_repo_path .
hsi create_sw_design device-tree -os device_tree -proc psu_cortexa53_0
hsi generate_target -dir system_dts
exit

EOF

xsct -quiet gen_dts_from_hdf.tcl

grep -v system-conf.dtsi ${DTSI_PATH} > system_dts/system-user.dtsi

echo '#include "system-user.dtsi"' >> system_dts/system-top.dts

gcc -I system_dts \
  -I device-tree-xlnx/device_tree/data/kernel_dtsi/2019.1/include \
  -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp \
  -o system_dts/system-top.dts.tmp system_dts/system-top.dts

dtc -I dts -O dtb -o system.dtb system_dts/system-top.dts.tmp
dtc -I dtb -O dts -o system.dts system.dtb

cp -p system.dts $IMAGES_DIR/
cp -p system.dtb $IMAGES_DIR/


popd
popd

exit 0
