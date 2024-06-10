#!/bin/sh
set -e
#
export MAKEFLAGS=-j$(nproc)
# 
echo "starting bauild at 8.76"
#
##Procps-ng
tar -xvf procps-ng-4.0.3.tar.xz
cd procps-ng-4.0.3
./configure --prefix=/usr --docdir=/usr/share/doc/procps-ng-4.0.3 --disable-static  --disable-kill
make
#make check
make install
cd /sources
rm -Rf procps-ng-4.0.3
#
##Util-linux
tar -xvf util-linux-2.39.1.tar.xz
cd util-linux-2.39.1
sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime --bindir=/usr/bin --libdir=/usr/lib --runstatedir=/run --sbindir=/usr/sbin  \
  --disable-chfn-chsh --disable-login --disable-nologin --disable-su --disable-setpriv --disable-runuser --disable-pylibmount \
  --disable-static --without-python --without-systemd --without-systemdsystemunitdir --docdir=/usr/share/doc/util-linux-2.39.1
make
#chown -Rv tester .
#su tester -c "make -k check"
make install
cd /sources
rm -Rf util-linux-2.39.1
#
##e2fsprogs
tar -xvf e2fsprogs-1.47.0.tar.gz
cd e2fsprogs-1.47.0
mkdir -v build
cd       build
../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs  --disable-libblkid  --disable-libuuid --disable-uuidd --disable-fsck
make
#make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
cd /sources
rm -Rf e2fsprogs-1.47.0
#
##Sysklogd
tar -xvf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd /sources
rm -Rf sysklogd-1.5.1
#
##sysvinit
tar -xvf sysvinit-3.07.tar.xz
cd sysvinit-3.07
patch -Np1 -i ../sysvinit-3.07-consolidated-1.patch
make
make install
cd /sources
rm -Rf sysvinit-3.07
#
##libunistring
tar -xvf libunistring-1.1.tar.xz
cd libunistring-1.1
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/libunistring-1.1 &&
make
make install
cd /sources
rm -Rf libunistring-1.1
#
##libidn2
tar -xvf libidn2-2.3.7.tar.gz
cd libidn2-2.3.7
./configure --prefix=/usr --disable-static &&
make
make install
cd /sources
rm -Rf libidn2-2.3.7
#
##libpsl
tar -xvf libpsl-0.21.5.tar.gz
cd libpsl-0.21.5
mkdir build 
cd    build 
meson setup --prefix=/usr --buildtype=release
ninja
ninja install
cd /sources
rm -Rf libpsl-0.21.5
#
##libtasn1
tar -xvf libtasn1-4.19.0.tar.gz
cd libtasn1-4.19.0
./configure --prefix=/usr --disable-static 
make
make install
cd /sources
rm -Rf libtasn1-4.19.0
#
## p11-kit
tar -xvf p11-kit-0.25.0.tar.xz
cd p11-kit-0.25.0
sed 's/if (gi/& \&\& gi != C_GetInterface/' -i p11-kit/modules.c
sed '20,$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications
# Update trust stores
/usr/sbin/make-ca -r
EOF
mkdir p11-build 
cd p11-build
meson setup ..  --prefix=/usr --buildtype=release -Dtrust_paths=/etc/pki/anchors
ninja
ninja install
ln -sfv /usr/libexec/p11-kit/trust-extract-compat /usr/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
cd /sources
rm -Rf p11-kit-0.25.0
#
##nspr
tar -xvf nspr-4.35.tar.gz
cd nspr-4.35
cd nspr 
sed -ri '/^RELEASE/s/^/#/' pr/src/misc/Makefile.in
sed -i 's#$(LIBRARY) ##'   config/rules.mk      
./configure --prefix=/usr --with-mozilla --with-pthreads $([ $(uname -m) = x86_64 ] && echo --enable-64bit)
make
make install
cd /sources
rm -Rf nspr-4.35
#
##nss
tar -xvf nss-3.92.tar.gz
cd nss-3.92
patch -Np1 -i ../nss-3.92-standalone-1.patch
cd nss
make BUILD_OPT=1  NSPR_INCLUDE_DIR=/usr/include/nspr USE_SYSTEM_ZLIB=1 ZLIB_LIBS=-lz NSS_ENABLE_WERROR=0 \
$([ $(uname -m) = x86_64 ] && echo USE_64=1) $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)
cd ../dist   
install -v -m755 Linux*/lib/*.so              /usr/lib 
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib 
install -v -m755 -d                           /usr/include/nss 
cp -v -RL {public,private}/nss/*              /usr/include/nss
install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin 
install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
cd /sources
rm -Rf nss-3.92
#
##sqlite
tar -xvf sqlite-autoconf-3420000.tar.gz
cd sqlite-autoconf-3420000
./configure --prefix=/usr --disable-static --enable-fts{4,5} CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1 \
 -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 -DSQLITE_ENABLE_DBSTAT_VTAB=1 -DSQLITE_SECURE_DELETE=1          \
 -DSQLITE_ENABLE_FTS3_TOKENIZER=1" 
make
make install
cd /sources
rm -Rf sqlite-autoconf-3420000
#
## make-ca
tar -xvf make-ca-1.13.tar.xz
cd make-ca-1.13
make install
install -vdm755 /etc/ssl/local
#/usr/sbin/make-ca -g
cd /sources
rm -Rf make-ca-1.13
#
## wget
tar -xvf wget-1.21.4.tar.gz
cd wget-1.21.4
./configure --prefix=/usr --sysconfdir=/etc --with-ssl=openssl 
make
make install
cd /sources
rm -Rf wget-1.21.4
#
## curl
tar -xvf curl-8.6.0.tar.xz
cd curl-8.6.0 
./configure --prefix=/usr --disable-static  --with-openssl  --enable-threaded-resolver  --with-ca-path=/etc/ssl/certs &&
make
make install 
rm -rf docs/examples/.deps
find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete
cp -v -R docs -T /usr/share/doc/curl-8.6.0
cd /sources
rm -Rf curl-8.6.0
#
## nano
if test -f nano-7.2.tar.xz; then
  tar -xvf nano-7.2.tar.xz
else
tar -xvf nano-7.2.tar.gz
fi
cd nano-7.2
./configure --prefix=/usr --sysconfdir=/etc --enable-utf8 --docdir=/usr/share/doc/nano-7.2
make
make install
install -v -m644 doc/{nano.html,sample.nanorc} /usr/share/doc/nano-7.2
cat > /etc/nanorc << "EOF"
set autoindent
set constantshow
set fill 72
set historylog
set multibuffer
set positionlog
set quickblank
set regexp
EOF
cd /sources
rm -Rf nano-7.2
#
##git
tar -xvf git-2.41.0.tar.xz
cd git-2.41.0
./configure --prefix=/usr --with-gitconfig=/etc/gitconfig --with-python=python3 &&
make
make perllibdir=/usr/lib/perl5/5.38/site_perl install
cd /sources
rm -Rf git-2.41.0
cd /sources
rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
userdel -r tester
#set up bash config files 
cat > /etc/profile << "EOF"
# Begin /etc/profile
# Append our default paths
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:$PATH"
export TERM=$TERM PS1='\u:\w\$ '
# add terminal type
export TERM="xterm"
EOF
# inputrc
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
#shells
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

echo "this completes the basic LFS environment build. Please note that it has not been stripped."
echo "The system is not bootable and is intended as a chrootable x86-64 build environment."
echo "To make the system into a full LFS install, run chapter 9 and 10 by hand"
echo "please note that this environment has both curl and wget for file transfer"
echo "please exit back to the livebootstrap environment"
echo "the folowing BLFS packages are installed in this build : Curl, libpsl, libidn2, libunistring, nano, libtasn1, p11-kit, make-ca, git, NSPR, NSS, sqlite and wget "
echo "run source /etc/profile to set up your environment."

