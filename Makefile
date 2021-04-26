export ROOT_DIR := $(shell pwd)
export SOURCES_DIR := ${ROOT_DIR}/sources
export IMAGES_DIR := ${ROOT_DIR}/images
export CONFIGS_DIR := ${ROOT_DIR}/configs
export DTSI_PATH := ${ROOT_DIR}/configs/system-user.dtsi
export XSA_DIR := ${ROOT_DIR}/hdf
export DEBIAN_RFS_DIR := ${SOURCES_DIR}/debian_rfs

#  FSBL Specific.
# 
export FSBL_BUILD_DIR := ${SOURCES_DIR}/fsbl_build
export EMBEDDEDSW_DIR := ${SOURCES_DIR}/embeddedsw
export FSBL_APP_TCL := ${CONFIGS_DIR}/fsbl_app.tcl
export FSBL_YAML := ${CONFIGS_DIR}/fsbl.yaml

export PMUFW_BUILD_DIR := ${SOURCES_DIR}/pmufw_build
export PMUFW_DIR := ${SOURCES_DIR}/pmu-firmware
export PMUFW_YAML := ${CONFIGS_DIR}/pmu-firmware.yaml
export PMUFW_APP_TCL := ${CONFIGS_DIR}/pmufw_app.tcl

#  Primary Configuration options on XSA.
#  
export XSA_NAME := zynqmp.xsa
export BITSTREAM_NAME := zynqmp.bit
export XSA_PATH := ${XSA_DIR}/${XSA_NAME}

export NUM_CPUS := $(shell nproc)

//change dir and arch if needed
export YOCTO_SDK := /opt/petalinux/2019.1/environment-setup-aarch64-xilinx-linux
export ARCH := arm64

.PHONY: os
os: pull_os_source bootsystem kernel rfs

.PHONY: bootsystem
bootsystem: build_dts u-boot build_fsbl build_boot

.PHONY: kernel
kernel: linux_defconfig linux linux_modules_install

.PHONY: sdk
sdk: pull_yocto_source build_yocto

.PHONY: pull_yocto_source
pull_yocto_source:
	@ bin/do_yocto_source_pull.sh

.PHONY: build_yocto
build_yocto:
	@ bin/do_build_yocto.sh

.PHONY: pull_os_source
pull_os_source:
	@ bin/do_os_source_pull.sh


.PHONY: linux_defconfig
linux_defconfig:
	@ cp -p  ${CONFIGS_DIR}/zynqmp_defconfig ${SOURCES_DIR}/linux-xlnx/arch/arm64/configs/
	make -C ${SOURCES_DIR}/linux-xlnx zynqmp_defconfig

.PHONY: linux_save_defconfig
linux_save_defconfig:
	make -C ${SOURCES_DIR}/linux-xlnx savedefconfig
	@ cp -p ${SOURCES_DIR}/linux-xlnx/defconfig ${CONFIGS_DIR}/zynqmp_defconfig


.PHONY: linux_xconfig
linux_xconfig:
	make -C ${SOURCES_DIR}/linux-xlnx xconfig

.PHONY: linux_menuconfig
linux_menuconfig:
	make -C ${SOURCES_DIR}/linux-xlnx menuconfig

.PHONY: linux
linux:
	@ if [ -f ${YOCTO_SDK} ]; \
	then \
	    . ${YOCTO_SDK}; make -j ${NUM_CPUS} -C ${SOURCES_DIR}/linux-xlnx; \
	    cp -p ${SOURCES_DIR}/linux-xlnx/arch/arm64/boot/Image ${IMAGES_DIR}/ ;\
	    cp -p ${SOURCES_DIR}/linux-xlnx/arch/arm64/boot/Image.gz ${IMAGES_DIR}/ ;\
	else \
	    echo "YOCTO_SDK missing";\
	fi;

.PHONY: linux_modules_install
linux_modules_install:
	@ if [ -f ${YOCTO_SDK} ]; \
	then \
	    . ${YOCTO_SDK}; make -C ${SOURCES_DIR}/linux-xlnx INSTALL_MOD_PATH=${SOURCES_DIR} modules_install; \
		# rm modules/4.19.0/source \
		# rm modules/4.19.0/build \
	else \
	    echo "YOCTO_SDK missing";\
	fi;

.PHONY: linux_all
linux_all: linux_defconfig linux linux_modules_install

.PHONY: linux_mrproper
linux_mrproper:
	make -C ${SOURCES_DIR}/linux-xlnx mrproper


.PHONY: u-boot
u-boot:
	@ if [ -f ${YOCTO_SDK} ]; \
	then \
	    cp -p ${IMAGES_DIR}/system.dts ${SOURCES_DIR}/u-boot-xlnx/arch/arm/dts/zynqmp.dts; \
	    . ${YOCTO_SDK}; make -C ${SOURCES_DIR}/u-boot-xlnx zynqmp_defconfig; \
	    . ${YOCTO_SDK}; make -C ${SOURCES_DIR}/u-boot-xlnx ; \
	    cp -p ${SOURCES_DIR}/u-boot-xlnx/u-boot.elf ${IMAGES_DIR}/ ; \
	    cp -p ${SOURCES_DIR}/u-boot-xlnx/u-boot.elf ${IMAGES_DIR}/boot/ ; \
	else \
	    echo "YOCTO_SDK missing";\
	fi;

.PHONY: u-boot_defconfig
u-boot_defconfig:
	make -C ${SOURCES_DIR}/u-boot-xlnx zynqmp_defconfig

.PHONY: u-boot_save_defconfig
u-boot_save_defconfig:
	make -C ${SOURCES_DIR}/u-boot-xlnx savedefconfig
	@ cp -p ${SOURCES_DIR}/u-boot-xlnx/defconfig ${SOURCES_DIR}/u-boot-xlnx/configs/zynqmp_defconfig

.PHONY: u-boot_menuconfig
u-boot_menuconfig:
	make -C ${SOURCES_DIR}/u-boot-xlnx menuconfig

.PHONY: clean_u-boot
clean_u-boot:
	make -C ${SOURCES_DIR}/u-boot-xlnx distclean

.PHONY: buildroot
buildroot:
	cp -p ${CONFIGS_DIR}/buidroot.busybox.defconfig ${SOURCES_DIR}/buildroot/; \
	cp -p ${CONFIGS_DIR}/buidroot.defconfig ${SOURCES_DIR}/buildroot/.config; \
	make -C ${SOURCES_DIR}/buildroot; \
	cp -p ${SOURCES_DIR}//buildroot/output/images/rootfs.cpio.gz ${IMAGES_DIR}/buildroot.cpio.gz ; \


.PHONY: buildroot_save_defconfig
buildroot_save_defconfig:
	make -C ${SOURCES_DIR}/buildroot savedefconfig
	@ cp -p ${SOURCES_DIR}/buildroot/defconfig ${CONFIGS_DIR}/configs/buidroot.defconfig

.PHONY: buildroot_menuconfig
u-boot_menuconfig:
	make -C ${SOURCES_DIR}/buildroot menuconfig

.PHONY: clean_buildroot
clean_buildroot:
	make -C ${SOURCES_DIR}/buildroot distclean
	
.PHONY: buildroot_switch_squashfs
buildroot_switch_squashfs:
	cp -p ${CONFIGS_DIR}/init_sqfs.sh ${SOURCES_DIR}/buildroot/fs/cpio/init; \
	make -C ${SOURCES_DIR}/buildroot; \
	cp -p ${SOURCES_DIR}//buildroot/output/images/rootfs.cpio.gz ${IMAGES_DIR}/swsqfs.cpio.gz ; \

.PHONY: buildroot_switch_ext4
buildroot_switch_ext4:
	cp -p ${CONFIGS_DIR}/init_ext4.sh ${SOURCES_DIR}/buildroot/fs/cpio/init; \
	make -C ${SOURCES_DIR}/buildroot; \
	cp -p ${SOURCES_DIR}//buildroot/output/images/rootfs.cpio.gz ${IMAGES_DIR}/swext4.cpio.gz ; \


.PHONY: rfs
rfs:
	@ bin/do_build_rfs.sh

.PHONY: uscript
uscript:
	@ bin/do_build_uscript.sh


.PHONY: build_fsbl
build_fsbl:
	@ if [ ! -f .fsbl_built ]; \
	then \
	   bin/do_build_fsbl.sh ; \
	else \
	   echo "FSBL Built"; \
	fi;

.PHONY: clean_fsbl
clean_fsbl:
	@ rm -rf ${FSBL_BUILD_DIR}
	@ rm -rf ${PMUFW_BUILD_DIR}
	@ rm -f .fsbl_built

.PHONY: build_dts
build_dts:
	@ bin/do_build_dts.sh

.PHONY: clean_dts
clean_dts:
	@ rm -rf ${IMAGES_DIR}/device-tree

.PHONY: build_boot
build_boot:
	@ bin/do_build_boot_bin.sh

.PHONY: clean_boot
clean_boot: clean_fsbl
	@ rm -rf ${IMAGES_DIR}/boot/pmufw.elf
	@ rm -rf ${IMAGES_DIR}/boot/zynqmp_fsbl.elf
	# @ rm -rf ${IMAGES_DIR}/boot_images
	@ rm -rf ${SOURCES_DIR}/xsa_obj
	@ rm -rf ${FSBL_BUILD_DIR}
	@ rm -rf ${PMUFW_BUILD_DIR}

#	@ rm -rf ${SOURCES_DIR}/arm-trusted-firmware

.PHONY: rm_rootfs
rm_rootfs:
	@ bin/do_rm_rootfs.sh

.PHONY: clean_sources
clean_sources: rm_rootfs
	@ rm -rf ${SOURCES_DIR}/*

.PHONY: clean_images
clean_images:
	@ rm -rf ${IMAGES_DIR}/*
	@ rm -f $$(git ls-files xsa -o)
	@ rm -f .fsbl_built

.PHONY: clean_all
clean_all: clean_sources clean_images

.PHONY: help
help:
	@ less README.Makefile
