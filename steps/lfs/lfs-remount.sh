#!/usr/bin/bash
set -e

echo "remounting LFS file systems"
mount -vt devtmpfs devtmpfs /dev
mount -vt devpts devpts /dev/pts
mount -vt proc proc /proc
#mount -vt sysfs sysfs /sys
mount -vt tmpfs tmpfs /run

