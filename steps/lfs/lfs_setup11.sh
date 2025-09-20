#!/bin/sh
set -e
#
## make sure the profile is initiated and the certs are updated
#reset the root password
passwd -d root
/usr/sbin/make-ca -g
echo "this completes the basic LFS environment build. Please note that it has not been stripped."
echo "The system is not bootable and is intended as a chrootable x86-64 build environment."
echo "To make the system into a full LFS install, run chapter 9 and 10 by hand"
echo "please note that this environment has both curl and wget for file transfer"
echo "please exit back to the livebootstrap environment"
echo "the folowing BLFS packages are installed in this build : Curl, libpsl, libidn2, libunistring, nano, libtasn1, p11-kit"
echo "make-ca, git, NSPR, NSS, sqlite, libarchive, libuv, nghttp2, cmake, clang/llvm, gnu-which, time, p7zip, lzip, popt,"
echo "rsync, the linux kernel, dosfstools, unzip, cpio, sgml-common, LZO, Nettle, libarchive, docbook-xml, git, sudo and wget"
#echo "run source /etc/profile to set up your environment."


source /etc/profile