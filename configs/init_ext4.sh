#!/bin/sh
# devtmpfs does not get automounted for initramfs
PATH="/bin:/sbin:usr/bin:usr/sbin"

echo "waiting for mount sda1"
while test ! -e /dev/sda1
do
    sleep 0.1
    printf "#"
done

echo ""



/bin/mount -t proc proc /proc
/bin/mount -t sysfs sys /sys
/bin/mkdir -p /dev/pts /dev/shm
/bin/mount -t devtmpfs devtmpfs /dev

#echo "/sbin/mdev" >/proc/sys/kernel/hotplug
#/sbin/mdev -s
#echo "waiting mdev to find mount dev"
# /bin/mknod /dev/sda1 b 8 1
# sleep 1


/bin/mkdir /mnt/sda
/bin/mount -t ext4 /dev/sda1 /mnt/sda
/bin/mkdir /newroot
/bin/mount -t ext4 /mnt/sda/rootfs.ext4 /newroot

/bin/mkdir -p /newroot/mnt/sda
/bin/mount --move /mnt/sda /newroot/mnt/sda

exec /sbin/switch_root  /newroot /lib/systemd/systemd

# use the /dev/console device node from devtmpfs if possible to not
# confuse glibc's ttyname_r().
# This may fail (E.G. booted with console=), and errors from exec will
# terminate the shell, so use a subshell for the test
# if (exec 0</dev/console) 2>/dev/null; then
#     exec 0</dev/console
#     exec 1>/dev/console
#     exec 2>/dev/console
# fi

# exec /sbin/init "$@"
