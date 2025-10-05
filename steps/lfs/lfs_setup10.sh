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
tar -xvf make-ca-1.16.1.tar.gz
cd make-ca-1.16.1
make install
install -vdm755 /etc/ssl/local
#/usr/sbin/make-ca -g
cd /sources
rm -Rf make-ca-1.16.1
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
#
## libxml2
tar -xvf libxml2-2.10.4.tar.xz
cd libxml2-2.10.4
./configure --prefix=/usr --sysconfdir=/etc --disable-static  --with-history PYTHON=/usr/bin/python3 \
--docdir=/usr/share/doc/libxml2-2.10.4
make
make install
cd /sources
rm -Rf libxml2-2.10.4
#
## libarchive
tar -xvf libarchive-3.7.1.tar.xz
cd libarchive-3.7.1
./configure --prefix=/usr --disable-static
make
make install
cd /sources
rm -Rf libarchive-3.7.1
#
## libuv
tar -xvf libuv-v1.46.0.tar.gz 
cd libuv-v1.46.0
sh autogen.sh 
./configure --prefix=/usr --disable-static
make 
make install
cd /sources
rm -Rf libuv-v1.46.0
#
##nghttp2
tar -xvf nghttp2-1.55.1.tar.xz
cd nghttp2-1.55.1
./configure --prefix=/usr --disable-static --enable-lib-only --docdir=/usr/share/doc/nghttp2-1.55.1
make
make install
cd /sources
rm -Rf nghttp2-1.55.1
#
##cmake
tar -xvf cmake-3.27.2.tar.gz
cd cmake-3.27.2
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
./bootstrap --prefix=/usr --system-libs --mandir=/share/man --no-system-jsoncpp --no-system-cppdap --no-system-librhash \
  --docdir=/share/doc/cmake-3.27.2
make
make install
cd /sources
rm -Rf cmake-3.27.2
#
## clang/llvm
tar -xvf llvm-16.0.5.src.tar.xz
cd llvm-16.0.5.src
tar -xf ../llvm-cmake.src.tar.xz                                   
tar -xf ../llvm-third-party.src.tar.xz                             
sed '/LLVM_COMMON_CMAKE_UTILS/s@../cmake@llvm-cmake.src@'          \
    -i CMakeLists.txt                                              
sed '/LLVM_THIRD_PARTY_DIR/s@../third-party@llvm-third-party.src@' \
    -i cmake/modules/HandleLLVMOptions.cmake
tar -xf ../clang-16.0.5.src.tar.xz -C tools &&
mv tools/clang-16.0.5.src tools/clang
tar -xf ../compiler-rt-16.0.5.src.tar.xz -C projects &&
mv projects/compiler-rt-16.0.5.src projects/compiler-rt
grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/'
patch -Np2 -d tools/clang <../clang-16.0.5-enable_default_ssp-1.patch
sed 's/clang_dfsan/& -fno-stack-protector/' \
    -i projects/compiler-rt/test/dfsan/origin_unaligned_memtrans.c
mkdir -v build
cd       build
CC=gcc CXX=g++                                  \
cmake -DCMAKE_INSTALL_PREFIX=/usr               \
      -DLLVM_ENABLE_FFI=ON                      \
      -DCMAKE_BUILD_TYPE=Release                \
      -DLLVM_BUILD_LLVM_DYLIB=ON                \
      -DLLVM_LINK_LLVM_DYLIB=ON                 \
      -DLLVM_ENABLE_RTTI=ON                     \
      -DLLVM_TARGETS_TO_BUILD="host;AMDGPU;BPF" \
      -DLLVM_BINUTILS_INCDIR=/usr/include       \
      -DLLVM_INCLUDE_BENCHMARKS=OFF             \
      -DCLANG_DEFAULT_PIE_ON_LINUX=ON           \
      -Wno-dev -G Ninja ..                      
ninja
ninja install &&
cp bin/FileCheck /usr/bin
cd /sources
rm -Rf llvm-16.0.5
#
##which
tar -xvf which-2.21.tar.gz
cd which-2.21
./configure --prefix=/usr
make
make install
cd /sources
rm -Rf which-2.21
tar -xvf time-1.9.tar.gz
cd time-1.9
./configure --prefix=/usr
make
make install
cd /sources
rm -Rf time-1.9
#
#p7zip
tar -xvf p7zip-17.04.tar.gz
cd p7zip-17.04
sed '/^gzip/d' -i install.sh
sed -i '160a if(_buffer == nullptr || _size == _pos) return E_FAIL;' CPP/7zip/Common/StreamObjects.cpp
make all3
make DEST_HOME=/usr DEST_MAN=/usr/share/man DEST_SHARE_DOC=/usr/share/doc/p7zip-17.04 install
cd /sources
rm -Rf p7zip-17.04
#
##lzip 
tar -xvf lzip-1.24.1.tar.gz
cd lzip-1.24
./configure --prefix=/usr
make
make install
cd /sources
rm -Rf lzip-1.24
#
##popt
tar -xvf popt-1.19.tar.gz
cd popt-1.19
./configure --prefix=/usr --disable-static
make
make install
cd /sources 
rm -Rf popt-1.19
#
## rsync
tar -xvf rsync-3.2.7.tar.gz
cd rsync-3.2.7
./configure --prefix=/usr --disable-lz4 --disable-xxhash --without-included-zlib &&
make
make install
cd /sources
rm -Rf rsync-3.2.7
#
## linux kernel
tar -xvf linux-6.4.12.tar.xz
cd linux-6.4.12
make mrproper
make defconfig
make
make modules_install
cd /sources
rm -Rf linux-6.4.12
#
## dosfstools
tar -xvf dosfstools-4.2.tar.gz
cd dosfstools-4.2
./configure --prefix=/usr --enable-compat-symlinks --mandir=/usr/share/man --docdir=/usr/share/doc/dosfstools-4.2
make
make install
cd /sources
rm -Rf dosfstools-4.2
#
## unzip
tar -xvf unzip60.tar.gz
cd unzip60
patch -Np1 -i ../unzip-6.0-consolidated_fixes-1.patch
make -f unix/Makefile generic
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install
cd /sources
#
##cpio
rm -Rf unzip60
tar -xvf cpio-2.14.tar.bz2
cd cpio-2.14
./configure --prefix=/usr --enable-mt --with-rmt=/usr/libexec/rmt
make
make install
cd /sources
rm -Rf cpio-2.14
#
## sgml-common
tar -xvf sgml-common-0.6.3.tgz
cd sgml-common-0.6.3
patch -Np1 -i ../sgml-common-0.6.3-manpage-1.patch && autoreconf -f -i
./configure --prefix=/usr --sysconfdir=/etc && make
make docdir=/usr/share/doc install && 
install-catalog --add /etc/sgml/sgml-ent.cat \ /usr/share/sgml/sgml-iso-entities-8879.1986/catalog
install-catalog --add /etc/sgml/sgml-docbook.cat \ /etc/sgml/sgml-ent.cat
cd /sources
rm -Rf sgml-common-0.6.3
#
## lzo
tar -xvf lzo-2.10.tar.gz
cd lzo-2.10
./configure --prefix=/usr                    \
            --enable-shared                  \
            --disable-static                 \
            --docdir=/usr/share/doc/lzo-2.10 &&
make
make install
cd /sources
rm -Rf lzo-2.10
#
## Nettle
tar -xvf nettle-3.9.1.tar.gz
cd nettle-3.9.1
./configure --prefix=/usr --disable-static
make
make install
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so
install -v -m755 -d /usr/share/doc/nettle-3.9.1
install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-3.9.1
cd /sources
rm -Rf nettle-3.9.1
#
##libarchive
tar -xvf libarchive-3.7.1.tar.xz
cd libarchive-3.7.1
./configure --prefix=/usr --disable-static
make
make install
cd /sources
rm -Rf libarchive-3.7.1
#
## docbook-xml
mkdir docbook
cd docbook
unzip ../docbook-5.0.zip
cd docbook-5.0
install -vdm755 /usr/share/xml/docbook/schema/{dtd,rng,sch,xsd}/5.0 
install -vm644  dtd/* /usr/share/xml/docbook/schema/dtd/5.0         
install -vm644  rng/* /usr/share/xml/docbook/schema/rng/5.0         
install -vm644  sch/* /usr/share/xml/docbook/schema/sch/5.0         
install -vm644  xsd/* /usr/share/xml/docbook/schema/xsd/5.0
if [ ! -e /etc/xml/docbook-5.0 ]; then
    xmlcatalog --noout --create /etc/xml/docbook-5.0
fi &&

xmlcatalog --noout --create /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml

xmlcatalog --noout --add "public"     \
  "-//OASIS//DTD DocBook XML 5.0//EN" \
  "docbook.dtd" /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml &&

xmlcatalog --noout --add "system"                             \
  "http://www.oasis-open.org/docbook/xml/5.0/dtd/docbook.dtd" \
  "docbook.dtd" /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml &&

xmlcatalog --noout --create /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                 \
  "http://docbook.org/xml/5.0/rng/docbook.rng" \
  "docbook.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                \
  "http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rng" \
  "docbook.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                   \
  "http://docbook.org/xml/5.0/rng/docbookxi.rng" \
  "docbookxi.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                  \
  "http://www.oasis-open.org/docbook/xml/5.0/rng/docbookxi.rng" \
  "docbookxi.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                 \
  "http://docbook.org/xml/5.0/rng/docbook.rnc" \
  "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                \
  "http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rnc" \
  "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                   \
  "http://docbook.org/xml/5.0/rng/docbookxi.rnc" \
  "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                  \
  "http://www.oasis-open.org/docbook/xml/5.0/rng/docbookxi.rnc" \
  "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml &&

xmlcatalog --noout --create /usr/share/xml/docbook/schema/sch/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                 \
  "http://docbook.org/xml/5.0/sch/docbook.sch" \
  "docbook.sch" /usr/share/xml/docbook/schema/sch/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                \
  "http://www.oasis-open.org/docbook/xml/5.0/sch/docbook.sch" \
  "docbook.sch" /usr/share/xml/docbook/schema/sch/5.0/catalog.xml &&

xmlcatalog --noout --create /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                 \
  "http://docbook.org/xml/5.0/xsd/docbook.xsd" \
  "docbook.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                \
  "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbook.xsd" \
  "docbook.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                   \
  "http://docbook.org/xml/5.0/xsd/docbookxi.xsd" \
  "docbookxi.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                                  \
  "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbookxi.xsd" \
  "docbookxi.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"               \
  "http://docbook.org/xml/5.0/xsd/xlink.xsd" \
  "xlink.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                               \
   "http://www.oasis-open.org/docbook/xml/5.0/xsd/xlink.xsd" \
   "xlink.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"              \
   "http://docbook.org/xml/5.0/xsd/xml.xsd" \
   "xml.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml &&

xmlcatalog --noout --add "uri"                             \
   "http://www.oasis-open.org/docbook/xml/5.0/xsd/xml.xsd" \
   "xml.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml

if [ ! -e /etc/xml/catalog ]; then
    install -v -d -m755 /etc/xml &&
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "delegatePublic"                    \
  "-//OASIS//DTD DocBook XML 5.0//EN                       " \
  "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" \
  /etc/xml/catalog &&

xmlcatalog --noout --add "delegateSystem"                    \
  "http://docbook.org/xml/5.0/dtd/"                          \
  "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" \
  /etc/xml/catalog &&

xmlcatalog --noout --add "delegateURI"                       \
  "http://docbook.org/xml/5.0/dtd/"                          \
  "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" \
  /etc/xml/catalog &&

xmlcatalog --noout --add "delegateURI"                       \
  "http://docbook.org/xml/5.0/rng/"                          \
  "file:///usr/share/xml/docbook/schema/rng/5.0/catalog.xml" \
  /etc/xml/catalog &&

xmlcatalog --noout --add "delegateURI"                       \
  "http://docbook.org/xml/5.0/sch/"                          \
  "file:///usr/share/xml/docbook/schema/sch/5.0/catalog.xml" \
  /etc/xml/catalog &&

xmlcatalog --noout --add "delegateURI"                       \
  "http://docbook.org/xml/5.0/xsd/"                          \
  "file:///usr/share/xml/docbook/schema/xsd/5.0/catalog.xml" \
  /etc/xml/catalog



cd /sources
rm -Rf docbook
#
## git
tar -xvf git-2.41.0.tar.xz
cd git-2.41.0
./configure --prefix=/usr --with-gitconfig=/etc/gitconfig --with-python=python3
make
make perllibdir=/usr/lib/perl5/5.38/site_perl install
cd /sources
rm -Rf git-2.41.0
#
## sudo
tar -xvf sudo-1.9.14p3.tar.gz
cd sudo-1.9.14p3
./configure --prefix=/usr              \
            --libexecdir=/usr/lib      \
            --with-secure-path         \
            --with-all-insults         \
            --with-env-editor          \
            --docdir=/usr/share/doc/sudo-1.9.14p3 \
            --with-passprompt="[sudo] password for %p: "
make
make install
ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0
cat > /etc/sudoers.d/00-sudo << "EOF"
Defaults secure_path="/usr/sbin:/usr/bin"
%wheel ALL=(ALL) ALL
EOF
cd /sources
rm -Rf sudo-1.9.14p3
#
##libxslt
tar -xvf libxslt-1.1.38.tar.xz
cd libxslt-1.1.38
./configure --prefix=/usr                          \
            --disable-static                       \
            --docdir=/usr/share/doc/libxslt-1.1.38 \
            PYTHON=/usr/bin/python3
make
make install 
cd /sources
rm -Rf libxslt-1.1.38
#
## docbook-xml-dtd
mkdir docbookdtd
cd docbookdtd
unzip ../docbook-4.5.zip
sed -i -e '/ISO 8879/d' \
       -e '/gml/d' docbook.cat
install -v -d /usr/share/sgml/docbook/sgml-dtd-4.5 &&
chown -R root:root . &&

install -v docbook.cat /usr/share/sgml/docbook/sgml-dtd-4.5/catalog &&
cp -v -af *.dtd *.mod *.dcl /usr/share/sgml/docbook/sgml-dtd-4.5 &&

install-catalog --add /etc/sgml/sgml-docbook-dtd-4.5.cat \
    /usr/share/sgml/docbook/sgml-dtd-4.5/catalog &&

install-catalog --add /etc/sgml/sgml-docbook-dtd-4.5.cat \
    /etc/sgml/sgml-docbook.cat
cd /sources
rm -Rf docbookdtd


#
#end program builds
#
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

