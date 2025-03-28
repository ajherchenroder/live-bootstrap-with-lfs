#!/usr/bin/bash
#set -e
echo "Config for chroot"

. /steps/bootstrap.cfg
. /steps/env


mount -vt devtmpfs devtmpfs /dev
mount -vt devpts devpts /dev/pts
mount -vt proc proc /proc
mount -vt sysfs sysfs /sys
mount -vt tmpfs tmpfs /run
mount -t tmpfs -o nosuid,nodev tmpfs /dev/shm
env - PATH=${PREFIX}/bin PS1="\w # " setsid openvt -fec1 -- bash -i

