#!/bin/bash
#set -e
echo "starting to build"
##
##set up the lfs user's environment
export LFS=/mnt/lfs
MAKEFLAGS=-j$(nproc)
##clear out any existing entries from prior attempts
if test -f ~/.bash_profile
then
   rm ~/.bash_profile
fi
if test -f ~/.bashrc
then
   rm ~/.bashrc
fi
##.bash_profile
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
## .bashrc
#read -p "Number of Cores to use? -> " CORES

cat > ~/.bashrc << "EOF"
set +h
umask 022
CORES=$(nproc)
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$CORES
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS
EOF

echo "profile setup, move to next script"
echo "cd into /mnt/lfs and run lfs_setup3.sh"

#source ~/.bash_profile
#echo $CORES
#su - lfs -c /mnt/lfs/lfs_setup3.sh
