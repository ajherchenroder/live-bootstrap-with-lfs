#!/bin/sh
set -e
#
# 
export MAKEFLAGS=-j$(nproc)

echo "creating additional tools"
#
## gettext
cd /sources
tar -xvf gettext-0.22.tar.xz
cd gettext-0.22
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd /sources
rm -Rf gettext-0.22
#
##bison
tar -xvf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
cd /sources
rm -Rf bison-3.8.2
#
## perl
tar -xvf perl-5.38.0.tar.xz
cd perl-5.38.0
sh Configure -des -Dprefix=/usr -Dvendorprefix=/usr -Duseshrplib -Dprivlib=/usr/lib/perl5/5.38/core_perl -Darchlib=/usr/lib/perl5/5.38/core_perl \
 -Dsitelib=/usr/lib/perl5/5.38/site_perl -Dsitearch=/usr/lib/perl5/5.38/site_perl -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl
make
make install
cd /sources
rm -Rf perl-5.38.0
#
##python
tar -xvf Python-3.11.4.tar.xz
cd Python-3.11.4
./configure --prefix=/usr --enable-shared --without-ensurepip
make
make install
cd /sources
rm -Rf Python-3.11.4
#
## Texinfo
tar -xvf texinfo-7.0.3.tar.xz
cd texinfo-7.0.3
./configure --prefix=/usr
make
make install
cd /sources
rm -Rf texinfo-7.0.3
tar -xvf util-linux-2.39.1.tar.xz
cd util-linux-2.39.1
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   --libdir=/usr/lib --runstatedir=/run --docdir=/usr/share/doc/util-linux-2.39.1 --disable-chfn-chsh  \
 --disable-login --disable-nologin --disable-su --disable-setpriv --disable-runuser --disable-pylibmount --disable-static --without-python
make
make install
cd /sources
rm -Rf util-linux-2.39.1
#
## cleanup
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
echo "tools complete ready for the main event. Run lfs_setup7.sh"
exec /lfs_setup7.sh