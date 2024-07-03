#!/usr/bin/bash
#set -e
echo "Config for LFS"
# make sure that the livebootstrap environment is configured for the kernel virtual files system
#update doas config for LFS
#echo "permit nopass setenv {PATH=/usr/local/bin:/usr/local/sbin: \
#/usr bin:/usr/sbin LFS=/mnt/lfs} :root" > /etc/doas.conf
#echo "permit nopass setenv {LFS=/mnt/lfs PATH=/mnt/lfs/tools/bin:/usr/#local/bin:/usr/local/sbin:/usr/bin:/usr/sbin LC_ALL=POSIX \
#LFS_TGT=$(uname -m)-lfs-linux-gnu \
#CONFIG_SITE=/mnt/lfs/usr/share/config.site MAKEFLAGS=-j$(nproc) }\
#:lfs" >> /etc/doas.conf
mount -vt devtmpfs devtmpfs /dev
mount -vt proc proc /proc
mount -vt sysfs sysfs /sys
mount -vt tmpfs tmpfs /run
mount -t tmpfs -o nosuid,nodev tmpfs /dev/shm
mount -vt devpts devpts -o mode=0625 /dev/pts
chmod -R 777 /etc
chmod -R 777 /steps
chmod -R 777 /tmp
chmod -R 777 /usr
chmod -c 0400 /etc/doas.conf
/usr/sbin/fdisk -l | grep /dev
read -p "Enter the partion to mount (sdxx) -> " USEPART
if ! test -d /mnt  
then 
    mkdir /mnt
fi
if ! test -d /mnt/lfs  
then 
    mkdir /mnt/lfs
fi
mount -v -t ext4 /dev/$USEPART /mnt/lfs
# set the LFS Var
export LFS=/mnt/lfs
# get the sources
if ! test -d $LFS/sources 
then 
    mkdir -v $LFS/sources
fi
echo $LFS
chmod -v a+wt $LFS/sources
cd $LFS/sources

# parse the flags
while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="local";; #download from the local repositories
     esac
done
echo $REMOTE
#local
if test "$REMOTE" = "local"; then 
   echo "local"
   curl http://192.168.2.102/LFS/lfs-packages-12.0.tar -O
   tar -xvf lfs-packages-12.0.tar
   cp $LFS/sources/12.0/* $LFS/sources/
   curl http://192.168.2.102/LFS/curl-8.6.0.tar.xz -O
   curl http://192.168.2.102/LFS/libunistring-1.1.tar.xz -O
   curl http://192.168.2.102/LFS/libidn2-2.3.7.tar.gz -O
   curl http://192.168.2.102/LFS/libpsl-0.21.5.tar.gz -O
   curl http://192.168.2.102/LFS/nano-7.2.tar.xz -O
   curl http://192.168.2.102/LFS/libtasn1-4.19.0.tar.gz -O
   curl http://192.168.2.102/LFS/p11-kit-0.25.0.tar.xz -O
   curl http://192.168.2.102/LFS/make-ca-1.13.tar.xz -O
   curl http://192.168.2.102/LFS/wget-1.21.4.tar.gz -O
   curl http://192.168.2.102/LFS/git-2.41.0.tar.xz -O
   curl http://192.168.2.102/LFS/nss-3.92.tar.gz -O
   curl http://192.168.2.102/LFS/nss-3.92-standalone-1.patch -O
   curl http://192.168.2.102/LFS/nspr-4.35.tar.gz -O
   curl http://192.168.2.102/LFS/sqlite-autoconf-3420000.tar.gz -O
   curl http://192.168.2.102/LFS/libarchive-3.7.1.tar.xz -O
   curl http://192.168.2.102/LFS/libxml2-2.10.4.tar.xz -O
   curl http://192.168.2.102/LFS/libuv-v1.46.0.tar.gz -O
   curl http://192.168.2.102/LFS/nghttp2-1.55.1.tar.xz -O
   curl http://192.168.2.102/LFS/cmake-3.27.2.tar.gz -O
   curl http://192.168.2.102/LFS/llvm-16.0.5.src.tar.xz -O
   curl http://192.168.2.102/LFS/llvm-cmake.src.tar.xz -O
   curl http://192.168.2.102/LFS/llvm-third-party.src.tar.xz -O
   curl http://192.168.2.102/LFS/clang-16.0.5.src.tar.xz -O
   curl http://192.168.2.102/LFS/clang-16.0.5-enable_default_ssp-1.patch -O
   curl http://192.168.2.102/LFS/compiler-rt-16.0.5.src.tar.xz -O
   curl http://192.168.2.102/LFS/which-2.21.tar.gz -O
   curl http://192.168.2.102/LFS/time-1.9.tar.gz -O
   curl http://192.168.2.102/LFS/p7zip-17.04.tar.gz -O -L
   curl http://192.168.2.102/LFS/lzip-1.24.1.tar.gz -O -L
else
   echo "remote"
   curl https://ftp.osu.org/pub/lfs/lfs-packages/lfs-packages-12.0.tar -O
   tar -xvf lfs-packages-12.0.tar
   cp $LFS/sources/12.0/* $LFS/sources/
   curl https://curl.se/download/curl-8.6.0.tar.xz -O
   curl https://ftp.gnu.org/gnu/libunistring/libunistring-1.1.tar.xz -O
   curl https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz -O
   curl https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz -O -L
   curl https://mirrors.ocf.berkeley.edu/gnu/nano/nano-7.2.tar.xz -O -L
   curl https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz -O
   curl https://github.com/p11-glue/p11-kit/releases/download/0.25.0/p11-kit-0.25.0.tar.xz -O -L
   curl https://github.com/lfs-book/make-ca/releases/download/v1.13/make-ca-1.13.tar.xz -O -L
   curl https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz -O
   curl https://www.kernel.org/pub/software/scm/git/git-2.41.0.tar.xz -O -L
   curl https://archive.mozilla.org/pub/security/nss/releases/NSS_3_92_RTM/src/nss-3.92.tar.gz -O -L
   curl https://www.linuxfromscratch.org/patches/blfs/12.0/nss-3.92-standalone-1.patch -O -L 
   curl https://archive.mozilla.org/pub/nspr/releases/v4.35/src/nspr-4.35.tar.gz -O -L
   curl https://sqlite.org/2023/sqlite-autoconf-3420000.tar.gz -O -L
   curl https://github.com/libarchive/libarchive/releases/download/v3.7.1/libarchive-3.7.1.tar.xz -O -L
   curl https://download.gnome.org/sources/libxml2/2.10/libxml2-2.10.4.tar.xz -O -L
   curl https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.5/llvm-16.0.5.src.tar.xz -O -L
   curl https://anduin.linuxfromscratch.org/BLFS/llvm/llvm-cmake.src.tar.xz -O -L
   curl https://anduin.linuxfromscratch.org/BLFS/llvm/llvm-third-party.src.tar.xz -O -L
   curl https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.5/clang-16.0.5.src.tar.xz -O -L
   curl https://www.linuxfromscratch.org/patches/blfs/12.0/clang-16.0.5-enable_default_ssp-1.patch -O -L
   curl https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.5/compiler-rt-16.0.5.src.tar.xz -O -L
   curl https://dist.libuv.org/dist/v1.46.0/libuv-v1.46.0.tar.gz -O -L 
   curl https://github.com/nghttp2/nghttp2/releases/download/v1.55.1/nghttp2-1.55.1.tar.xz -O -L
   curl https://cmake.org/files/v3.27/cmake-3.27.2.tar.gz -O -L
   curl https://ftp.gnu.org/gnu/which/which-2.21.tar.gz -O -L
   curl https://ftp.gnu.org/gnu/time/time-1.9.tar.gz -O -L
   curl https://github.com/p7zip-project/p7zip/archive/v17.04/p7zip-17.04.tar.gz -O -L
   curl http://download.savannah.gnu.org/releases/lzip/lzip-1.24.1.tar.gz -O -L
fi

#to do: add in any additional BLFS packages desired. 

# set up the initial directory layout
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools
#create the lfs user
if ! id -u "lfs" >/dev/null 2>&1; 
then
  /usr/sbin/groupadd lfs
  /usr/sbin/useradd -s /bin/bash -g lfs -G wheel -m -k /dev/null lfs
fi
echo "lfs:" | chpasswd
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

chown root:root $LFS/sources/*
#initial setup completed switch to the LFS user 
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
cp /steps/lfs/lfs* /mnt/lfs
cp /steps/target/* /mnt/lfs
echo "intial LFS setup complete. su into the lfs user and run lfs_setup2.sh"
su lfs -c /steps/lfs/lfs_setup2.sh
