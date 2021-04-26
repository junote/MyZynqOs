#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi


pushd $IMAGES_DIR

# mkdir -p boot
pushd boot

#  Setup path to key tools in XSCT directory.
#
# PATH=$PATH:$SOURCES_DIR/Vitis/2020.1/gnu/aarch64/lin/aarch64-none/bin
# PATH=$PATH:$SOURCES_DIR/Vitis/2020.1/bin
# PATH=$PATH:$SOURCES_DIR/Vitis/2020.1/gnu/microblaze/lin/bin

PATH=$PATH:${HOME}/Xilinx/SDK/2019.1/bin/
. ${YOCTO_SDK}


# Unpack HDF data.
#
# pushd $SOURCES_DIR
# mkdir -p hdf_obj
# cd hdf_obj
# unzip -u $HDF_PATH
# cp -p $BITSTREAM_NAME $IMAGES_DIR/boot/
# popd


pushd $SOURCES_DIR
if [ ! -d arm-trusted-firmware ]
then
    cd arm-trusted-firmware/
    git checkout tags/xilinx-v2019.1
else
    echo "$0: arm-trusted-firmware exists, not pulling"
fi
popd

# Yocto shows this on make line: ZYNQMP_CONSOLE=cadence
pushd $SOURCES_DIR/arm-trusted-firmware
make CFLAGS= LDFLAGS= PLAT=zynqmp RESET_TO_BL31=1 bl31
cp -p build/zynqmp/release/bl31/bl31.elf $IMAGES_DIR/boot/
popd


cat > bootgen.bif << EOF

the_ROM_image:

{
        [fsbl_config] a53_x64
        [bootloader, destination_cpu=a53-0] fsbl.elf
        [pmufw_image] pmufw.elf
        [destination_device=pl] fpga.bit
        [destination_cpu=a53-0, exception_level=el-3, trustzone] bl31.elf
        [destination_cpu=a53-0, exception_level=el-2] u-boot.elf
}

EOF

# ./bootgen -arch zynqmp -image bootgen.bif -o BOOT.bin -w on
bootgen -arch zynqmp -image bootgen.bif -o BOOT.bin -w on

popd
popd
