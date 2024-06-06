#!/usr/bin/bash
set -e
#start
/steps/lfs/lfs_setup.sh
su lfs -c /mnt/lfs/lfs_setup3.sh
/mnt/lfs/lfs_setup4.sh
chroot /mnt/lfs source /etc/profile