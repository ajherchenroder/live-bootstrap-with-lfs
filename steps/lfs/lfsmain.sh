#!/usr/bin/bash
set -e
# parse the flags
while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="-L";; #download from the local repositories
     esac
done
#start
/steps/lfs/lfs_setup.sh "$REMOTE"
su lfs -c /mnt/lfs/lfs_setup3.sh
/mnt/lfs/lfs_setup4.sh
chroot /mnt/lfs source /etc/profile