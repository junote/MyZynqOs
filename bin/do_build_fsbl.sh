#!/bin/bash

if [ ! -f $SOURCES_DIR/.dirhold ]
then
    echo "$0: SOURCES_DIR/.dirhold does not exist, error"
    exit 1
fi


#  Setup path to key tools in XSCT directory.
#
PATH=$PATH:$SOURCES_DIR/Scout/2019.1/gnu/aarch64/lin/aarch64-none/bin
PATH=$PATH:$SOURCES_DIR/Scout/2019.1/bin
PATH=$PATH:$SOURCES_DIR/Scout/2019.1/gnu/microblaze/lin/bin

# Destination Boot Images
#
mkdir -p $IMAGES_DIR/boot
mkdir -p $FSBL_BUILD_DIR
mkdir -p $PMUFW_BUILD_DIR


xsct -sdx -nodisp ${PMUFW_APP_TCL} \
      -ws ${PMUFW_BUILD_DIR} \
      -pname pmu-firmware \
      -rp ${PMUFW_DIR} \
      -processor psu_pmu_0 \
      -hdf ${HDF_PATH} \
      -arch 32 \
      -app "ZynqMP PMU Firmware" \
      -yamlconf ${PMUFW_YAML} 


 if [ $? -ne 0 ]
 then
     echo "$0: xsct on PMUFW failed"
     exit 1
 fi

 make  -C  ${PMUFW_BUILD_DIR}/pmu-firmware
 if [ $? -ne 0 ]
 then
     echo "$0: make on PMUFW failed"
     exit 1
 fi

cp -p ${PMUFW_BUILD_DIR}/pmu-firmware/executable.elf ${IMAGES_DIR}/boot/pmufw.elf

# hsi generate_app -hw $hwdsgn -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir $PMUFW_BUILD_DIR/elf

# cd $PMUFW_BUILD_DIR
# cp ${XSA_PATH} zynqmp.xsa
# cat > gen_pmuelf_from_xsa.tcl << EOF

# set hwdsgn [hsi open_hw_design zynqmp.xsa]

# hsi generate_app -hw $hwdsgn -proc psu_pmu_0 -app zynqmp_pmufw -compile  -dir $PMUFW_BUILD_DIR/elf

# EOF
# xsct -quiet gen_pmuelf_from_xsa.tcl


# Build the FSBL.

xsct -sdx -nodisp ${FSBL_APP_TCL} \
      -ws ${FSBL_BUILD_DIR} \
      -pname fsbl \
      -rp ${EMBEDDEDSW_DIR} \
      -processor psu_cortexa53_0 \
      -hdf ${HDF_PATH} \
      -arch 64 \
      -app "Zynq MP FSBL" \
      -yamlconf ${FSBL_YAML}
if [ $? -ne 0 ]
then
    echo "$0: xsct on FSBL failed"
    exit 1
fi

make CFLAGS="-DDEBUG -DFSBL_DEBUG_GENERAL -DFSBL_DEBUG_GENERAL"  -C ${FSBL_BUILD_DIR}/fsbl
if [ $? -ne 0 ]
then
    echo "$0: make on FSBL failed"
    exit 1
fi

# cd $FSBL_BUILD_DIR
# cp ${XSA_PATH} zynqmp.xsa
# cat > gen_fsblelf_from_xsa.tcl << EOF

# hsi open_hw_design zynqmp.xsa

# hsi generate_app -app zynqmp_fsbl  -proc psu_cortexa53_0 -dir $FSBL_BUILD_DIR -compile

# EOF

# xsct -quiet gen_fsblelf_from_xsa.tcl


cp -p ${FSBL_BUILD_DIR}/fsbl/executable.elf ${IMAGES_DIR}/boot/zynqmp_fsbl.elf



exit 0

