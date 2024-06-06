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
curl https://ftp.osuosl.org/pub/lfs/lfs-packages/lfs-packages-12.0.tar -O
#local
#curl http://192.168.2.102/LFS/lfs-packages-12.0.tar -O
tar -xvf lfs-packages-12.0.tar
cp $LFS/sources/12.0/* .
rm lfs-packages-12.0.tar
curl https://curl.se/download/curl-8.6.0.tar.xz -O
#local
#curl http://192.168.2.102/LFS/curl-8.6.0.tar.xz -O
curl https://ftp.gnu.org/gnu/libunistring/libunistring-1.1.tar.xz -O
#local
#curl http://192.168.2.102/LFS/libunistring-1.1.tar.xz -O
curl https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz -O
#local
#curl http://192.168.2.102/LFS/libidn2-2.3.7.tar.gz -O
curl https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz -O
#local
#curl http://192.168.2.102/LFS/libpsl-0.21.5.tar.gz -O
curl https://www.nano-editor.org/dist/v7/nano-7.2.tar.xz -O
#local
#curl http://192.168.2.102/LFS/nano-7.2.tar.xz -O
curl https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz -O
#local
#curl http://192.168.2.102/LFS/libtasn1-4.19.0.tar.gz -O
curl https://github.com/p11-glue/p11-kit/releases/download/0.25.0/p11-kit-0.25.0.tar.xz -O
#local 
#curl http://192.168.2.102/LFS/p11-kit-0.25.0.tar.xz -O
curl https://github.com/lfs-book/make-ca/releases/download/v1.12/make-ca-1.12.tar.xz -O
#local
#curl http://192.168.2.102/LFS/make-ca-1.12.tar.xz -O
curl https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz -O
#local
#curl http://192.168.2.102/LFS/wget-1.21.4.tar.gz -O

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
