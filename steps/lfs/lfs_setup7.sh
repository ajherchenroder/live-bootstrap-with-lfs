#!/bin/sh
set -e
#
# 
export MAKEFLAGS=-j$(nproc)
echo "Starting the main event building chapter 8"
#
## man-pages
cd /sources
tar -xvf man-pages-6.05.01.tar.xz
cd man-pages-6.05.01
rm -v man3/crypt*
make prefix=/usr install
cd /sources
rm -Rf man-pages-6.05.01
#
##ina-etc
tar -xvf iana-etc-20230810.tar.gz
cd iana-etc-20230810
cp services protocols /etc
cd /sources
rm -Rf iana-etc-20230810
#
## Glibc
tar -xvf glibc-2.38.tar.xz
cd glibc-2.38
patch -Np1 -i ../glibc-2.38-fhs-1.patch
patch -Np1 -i ../glibc-2.38-memalign_fix-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr --disable-werror --enable-kernel=4.14 --enable-stack-protector=strong --with-headers=/usr/include libc_cv_slibdir=/usr/lib
make -j2
#make check
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -xf ../../tzdata2023c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
## setting the eastern time zone to America/New_York
ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

cd /sources
rm -Rf glibc-2.38
#
## zlib
tar -xvf zlib-1.2.13.tar.xz
cd zlib-1.2.13
./configure --prefix=/usr
make
#make check
make install
rm -fv /usr/lib/libz.a
cd /sources
rm -Rf zlib-1.2.13
#
## bzip2
tar -xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
ln -sfv bzip2 /usr/bin/bzcat
ln -sfv bzip2 /usr/bin/bunzip2
rm -fv /usr/lib/libbz2.a
cd /sources
rm -Rf bzip2-1.0.8
#
## XZ 
tar -xvf xz-5.4.4.tar.xz
cd xz-5.4.4
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz-5.4.4
make
#make check
make install
cd /sources
rm -Rf xz-5.4.4
#
## zstd
tar -xvf zstd-1.5.5.tar.gz
cd zstd-1.5.5
make prefix=/usr
#make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a
cd /sources
rm -Rf zstd-1.5.5
#
## file
tar -xvf file-5.45.tar.gz
cd file-5.45
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf file-5.45
#
## readline
tar -xvf readline-8.2.tar.gz
cd readline-8.2
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
patch -Np1 -i ../readline-8.2-upstream_fix-1.patch
./configure --prefix=/usr --disable-static --with-curses  --docdir=/usr/share/doc/readline-8.2
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2
cd /sources
rm -Rf readline-8.2
#
## M4
tar -xvf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf m4-1.4.19
#
##BC
tar -xvf bc-6.6.0.tar.xz
cd bc-6.6.0
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
#make test
make install
cd /sources
rm -Rf bc-6.6.0
#
##flex
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4 --disable-static
make
#make check
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
cd /sources
rm -Rf flex-2.6.4
#
## tcl
tar -xvf tcl8.6.13-src.tar.gz
cd tcl8.6.13
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr --mandir=/usr/share/man
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR
#make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd /sources
rm -Rf tcl8.6.13
#
##expect
tar -xvf expect5.45.4.tar.gz
cd expect5.45.4
./configure --prefix=/usr  --with-tcl=/usr/lib --enable-shared  --mandir=/usr/share/man --with-tclinclude=/usr/include
make
#make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
cd /sources
rm -Rf expect5.45.4
#
## dejaGNU
tar -xvf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
#make check
cd /sources
rm -Rf dejagnu-1.6.3
#
##binutils
tar -xvf binutils-2.41.tar.xz
cd binutils-2.41
mkdir -v build
cd       build
../configure --prefix=/usr --sysconfdir=/etc --enable-gold --enable-ld=default --enable-plugins --enable-shared     \
 --disable-werror --enable-64-bit-bfd --with-system-zlib
make tooldir=/usr
#make -k check
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
cd /sources
rm -Rf binutils-2.41
#
## gmp
tar -xvf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --prefix=/usr --enable-cxx --disable-static --docdir=/usr/share/doc/gmp-6.3.0 --host=none-linux-gnu
make
make html
#make check 2>&1 | tee gmp-check-log
#awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html
cd /sources
rm -Rf gmp-6.3.0
#
## mpfr 
tar -xvf mpfr-4.2.0.tar.xz
cd mpfr-4.2.0
sed -e 's/+01,234,567/+1,234,567 /' \
    -e 's/13.10Pd/13Pd/'            \
    -i tests/tsprintf.c
./configure --prefix=/usr --disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr-4.2.0
make
make html
#make check
make install
make install-html
cd /sources
rm -Rf mpfr-4.2.0
#
## mpc
tar -xvf mpc-1.3.1.tar.gz
cd mpc-1.3.1
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc-1.3.1
make
make html
#make check
make install
make install-html
cd /sources
rm -Rf mpc-1.3.1
#
## attr
tar -xvf attr-2.5.1.tar.gz
cd attr-2.5.1
./configure --prefix=/usr --disable-static  --sysconfdir=/etc --docdir=/usr/share/doc/attr-2.5.1
make
#make check
make install
cd /sources
rm -Rf attr-2.5.1
#
## acl
tar -xvf acl-2.3.1.tar.xz
cd acl-2.3.1
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/acl-2.3.1
make
make install
cd /sources
rm -Rf acl-2.3.1
#
##libcap
tar -xvf libcap-2.69.tar.xz
cd libcap-2.69
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
#make test
make prefix=/usr lib=lib install
cd /sources
rm -Rf libcap-2.69
#
## libxcrypt
tar -xvf libxcrypt-4.4.36.tar.xz
cd libxcrypt-4.4.36
./configure --prefix=/usr --enable-hashes=strong,glibc --enable-obsolete-api=glibc  --disable-static --disable-failure-tokens
make
#make check
make install
cd /sources
rm -Rf libxcrypt-4.4.36
echo "This completes the build through 8.25. Run lfs_setup8.sh to continue"
exec /lfs_setup8.sh

