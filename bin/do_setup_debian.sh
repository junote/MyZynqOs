#!/bin/bash

#set -x

# Key variables for proper opration.
#
ROOTDIR=`pwd`
ROOTFS_NAME=rootfs
ROOTFS=${ROOTDIR}/${ROOTFS_NAME}


DEBIAN_RELEASE_NAME=buster
ARCH=arm64
DEB_MIRROR_PATH=https://mirrors.tuna.tsinghua.edu.cn/debian/

function do_force_unmount()
{
    umount $ROOTFS/dev/pts 2>&1
    umount $ROOTFS/proc 2>&1
    umount $ROOTFS/sys 2>&1
    return 0
}

#  Mounted needed functions for apt operations.
#
function do_mount()
{
    mount --bind /dev/pts $ROOTFS/dev/pts
    if [ $? -ne 0 ]
    then
        echo "$0: mount of $ROOTFS/dev/pts failed"
        return 1
    fi

    mount --bind /proc $ROOTFS/proc
    if [ $? -ne 0 ]
    then
        echo "$0: mount of $ROOTFS/proc failed"
        umount $ROOTFS/dev/pts
        return 1
   fi

    return 0
}

# Attempt to do a clean unmount, and check status.
#
function do_unmount()
{
    umount $ROOTFS/dev/pts
    if [ $? -ne 0 ]
    then
        echo "$0: umount of $ROOTFS/dev/pts failed"
        umount $ROOTFS/proc
        return 1
    fi

    umount $ROOTFS/proc
    if [ $? -ne 0 ]
    then
        echo "$0: umount of $ROOTFS/proc failed"
        return 2
    fi

    return 0
}

function ctl_c_handler()
{
    echo echo "$0: ctl_c_handler: Forcing Unmount"
    do_force_unmount
    echo "$0: Exiting"
    exit 0
}



if [[ -e minbase-buster-rootfs ]]
then
    cp -a minbase-buster-rootfs ${ROOTFS}
else
    qemu-debootstrap --arch=${ARCH} --variant=minbase \
	    ${DEBIAN_RELEASE_NAME} ${ROOTFS} ${DEB_MIRROR_PATH}
    if [ $? -ne 0 ]
    then
        echo "$0: qemu-debootstrap failed"
        do_force_unmount
       exit 1
    else
        do_force_unmount
    fi
fi

cat > ${ROOTFS}/etc/apt/sources.list << EOF
deb [ trusted=yes ] ${DEB_MIRROR_PATH} ${DEBIAN_RELEASE_NAME} main
deb [ trusted=yes ] ${DEB_MIRROR_PATH} ${DEBIAN_RELEASE_NAME} non-free
EOF

PACKAGES=apt-utils
PACKAGES+=,busybox
PACKAGES+=,bridge-utils
PACKAGES+=,curl
PACKAGES+=,dbus
PACKAGES+=,dosfstools
# PACKAGES+=,docker-compose
PACKAGES+=,dpkg-dev
PACKAGES+=,dpkg-sig
PACKAGES+=,edac-utils
# PACKAGES+=,gdb-minimal
PACKAGES+=,ftp
PACKAGES+=,gdbserver
PACKAGES+=,inetutils-ftpd
PACKAGES+=,iproute2
PACKAGES+=,iptables
PACKAGES+=,iputils-ping
PACKAGES+=,isc-dhcp-client
PACKAGES+=,isc-dhcp-server
PACKAGES+=,kmod
PACKAGES+=,logrotate
PACKAGES+=,libltdl7
# PACKAGES+=,libboost-thread1.67.0
PACKAGES+=,lsof
PACKAGES+=,mtd-utils
# PACKAGES+=,nano-tiny
PACKAGES+=,net-tools
PACKAGES+=,networkd-dispatcher
PACKAGES+=,ntp
PACKAGES+=,ntpstat
PACKAGES+=,openssh-client
PACKAGES+=,openssh-server
PACKAGES+=,openssh-sftp-server
PACKAGES+=,parted
PACKAGES+=,pciutils
PACKAGES+=,procps
PACKAGES+=,psmisc
PACKAGES+=,rng-tools5
PACKAGES+=,rsh-client
PACKAGES+=,rsh-server
PACKAGES+=,syslog-ng
PACKAGES+=,systemd
PACKAGES+=,systemd-sysv
PACKAGES+=,tcpdump
PACKAGES+=,telnet
PACKAGES+=,telnetd
PACKAGES+=,udev
PACKAGES+=,usbutils
PACKAGES+=,watchdog
PACKAGES+=,wget
PACKAGES+=,vlan
PACKAGES+=,memtool
# ThanOS additions
# PACKAGES+=,libboost-dev
# PACKAGES+=,libboost-date-time-dev
# PACKAGES+=,libboost-filesystem-dev

echo "$0: Mounting for Package Install"
do_mount
if [ $? -ne 0 ]
then
    echo "$0: do_mount FAILED"
    exit 1
fi

chroot ${ROOTFS} sh -c "\
    export DEBIAN_FRONTEND=noninteractive; \
    export LC_ALL=C.UTF-8; \
    apt-get update ;\
    apt-get install -y --no-install-recommends $( echo ${PACKAGES} | tr "," " " ); "

echo "$0: Unmounting after Package Install"
do_unmount
if [ $? -ne 0 ]
then
    echo "$0: do_unmount FAILED"
    exit 1
fi

echo "zynqmp" > ${ROOTFS}/etc/hostname

chroot ${ROOTFS} sh -c "\
    echo root:root | chpasswd"

    
#
# Kernel mounts initramfs as / and expects to find /init
#
ln -sf /sbin/init ${ROOTFS}/init

#
# Add ttyPS0 and pseudo terminal slave pts/0 ... pts/31 to /etc/securetty
#
echo ttyPS0 >> ${ROOTFS}/etc/securetty
for i in {0..31}
do
    echo pts/$i >> ${ROOTFS}/etc/securetty
done

cat >> ${ROOTFS}/etc/inetd.conf << EOF
ftp     stream  tcp     nowait  root    /usr/sbin/tcpd  /usr/sbin/ftpd
EOF

# mkdir -p ${ROOTFS}/var/local/services
# cp -v docker-services/docker-compose.yml ${ROOTFS}/root
# cp -v docker-services/.env ${ROOTFS}/root

# chroot ${ROOTFS} sh -c "\
#     cp -v root/docker-compose.yml /var/local/services/ ; \
#     cp -v root/.env /var/local/services/ ;\
#     rm root/docker-compose.yml ;\
#     rm root/.env "

sed -i '/^ExecStart=.*/ s/$/ -r \/dev\/urandom /' ${ROOTFS}/lib/systemd/system/rngd.service


chroot ${ROOTFS} sh -c "\
    rm /etc/alternatives/iptables-restore ; \
    rm /etc/alternatives/iptables-save ; \
    rm /etc/alternatives/iptables ; \
    ln -s /usr/sbin/iptables-legacy-restore /etc/alternatives/iptables-restore ; \
    ln -s /usr/sbin/iptables-legacy-save /etc/alternatives/iptables-save ; \
    ln -s /usr/sbin/iptables-legacy /etc/alternatives/iptables ;\
    ln -sf /usr/bin/busybox /bin/vi"

grep -v -e "^BindsTo=" ${ROOTFS}/lib/systemd/system/serial-getty\@.service \
    > serial-getty\@.service
# diff ${ROOTFS}/serial-getty\@.service serial-getty\@.service
mv serial-getty\@.service ${ROOTFS}/lib/systemd/system/serial-getty\@.service

mkdir -p ${ROOTFS}/usr/local/bin



function createCpio()
{
    cd ${ROOTFS}
    find . | cpio -H newc -o | gzip -9 -c > ../${ROOTFS_NAME}.cpio.gz
    cd ..
}
function createKernelRfs
{
    sudo mkimage -f zynqmp-build-itb.its zynqmp.itb
}
createCpio
createKernelRfs

