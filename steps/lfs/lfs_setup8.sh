#!/bin/sh
set -e
export MAKEFLAGS=-j$(nproc)
#
# 
echo "starting build at 8.26"
#
## shadow
cd /sources
tar -xvf shadow-4.13.tar.xz
cd shadow-4.13
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
touch /usr/bin/passwd
./configure --sysconfdir=/etc --disable-static --with-{b,yes}crypt --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
cd /sources
rm -Rf shadow-4.13
#
## GCC 
tar -xvf gcc-13.2.0.tar.xz
cd gcc-13.2.0
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
../configure --prefix=/usr LD=ld --enable-languages=c,c++ --enable-default-pie --enable-default-ssp --disable-multilib       \
 --disable-bootstrap --disable-fixincludes --with-system-zlib
make -j2
#ulimit -s 32768
#chown -Rv tester .
#su tester -c "PATH=$PATH make -k check"
#../contrib/test_summary
make install
#chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources
rm -Rf gcc-13.2.0
#
## pkgconf
tar -xvf pkgconf-2.0.1.tar.xz
cd pkgconf-2.0.1
./configure --prefix=/usr --disable-static  --docdir=/usr/share/doc/pkgconf-2.0.1
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
cd /sources
rm -Rf pkgconf-2.0.1
#
## ncurses
tar -xvf ncurses-6.4.tar.gz
cd ncurses-6.4
./configure --prefix=/usr --mandir=/usr/share/man --with-shared --without-debug --without-normal --with-cxx-shared       \
  --enable-pc-files --enable-widec --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.4
cp -av dest/* /
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.4
cd /sources
rm -Rf ncurses-6.4
#
## sed
tar -xvf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr
make
make html
#chown -Rv tester .
#su tester -c "PATH=$PATH make check"
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
cd /sources
rm -Rf sed-4.9
#
## psmisc
tar -xvf psmisc-23.6.tar.xz
cd psmisc-23.6
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf psmisc-23.6
#
##gettext
tar -xvf gettext-0.22.tar.xz
cd gettext-0.22
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/gettext-0.22
make
#make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources
rm -Rf gettext-0.22
#
## bison
tar -xvf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
#make check
make install
cd /sources
rm -Rf bison-3.8.2
#
## grep
tar -xvf grep-3.11.tar.xz
cd grep-3.11
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf grep-3.11
#
##bash
tar -xvf bash-5.2.15.tar.gz
cd bash-5.2.15
./configure --prefix=/usr --without-bash-malloc --with-installed-readline --docdir=/usr/share/doc/bash-5.2.15
make
#chown -Rv tester . 
#su -s /usr/bin/expect tester << EOF
#set timeout -1
#spawn make tests
#expect eof
#lassign [wait] _ _ _ value
#exit $value
#EOF
make install
#exec /usr/bin/bash --login
cd /sources
rm -Rf bash-5.2.15
#
##libtool
tar -xvf libtool-2.4.7.tar.xz
cd libtool-2.4.7
./configure --prefix=/usr
make
#make -k check
make install
rm -fv /usr/lib/libltdl.a
cd /sources
rm -Rf libtool-2.4.7
#
##GDBM
tar -xvf gdbm-1.23.tar.gz
cd gdbm-1.23
./configure --prefix=/usr --disable-static --enable-libgdbm-compat
make
#make check
make install
cd /sources
rm -Rf gdbm-1.23
#
##gperf
tar -xvf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
#make -j1 check
make install
cd /sources
rm -Rf gperf-3.1
#
##expat
tar -xvf expat-2.5.0.tar.xz
cd expat-2.5.0
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat-2.5.0
make
#make check
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.5.0
cd /sources
rm -Rf expat-2.5.0
#
##inetutils
tar -xvf inetutils-2.4.tar.xz
cd inetutils-2.4
./configure --prefix=/usr --bindir=/usr/bin  --localstatedir=/var --disable-logger --disable-whois  --disable-rcp        \
  --disable-rexec --disable-rlogin --disable-rsh --disable-servers
make
#make check
make install
mv -v /usr/{,s}bin/ifconfig
cd /sources
rm -Rf inetutils-2.4
#
## less
tar -xvf less-643.tar.gz
cd less-643
./configure --prefix=/usr --sysconfdir=/etc
make
#make check
make install
cd /sources
rm -Rf less-643
#
##perl
tar -xvf perl-5.38.0.tar.xz
cd perl-5.38.0
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr -Dvendorprefix=/usr -Dprivlib=/usr/lib/perl5/5.38/core_perl -Darchlib=/usr/lib/perl5/5.38/core_perl      \
  -Dsitelib=/usr/lib/perl5/5.38/site_perl -Dsitearch=/usr/lib/perl5/5.38/site_perl -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
  -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl -Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 -Dpager="/usr/bin/less -isR"                 \
  -Duseshrplib -Dusethreads
make
#make test
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -Rf perl-5.38.0
#
## XML Parser
tar -xvf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46
perl Makefile.PL
make
#make test
make install
cd /sources
rm -Rf XML-Parser-2.46
#
## Intltool 
tar -xvf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
#make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd /sources
rm -Rf intltool-0.51.0
#
##autoconf
tar -xvf autoconf-2.71.tar.xz
cd autoconf-2.71
sed -e 's/SECONDS|/&SHLVL|/'               \
    -e '/BASH_ARGV=/a\        /^SHLVL=/ d' \
    -i.orig tests/local.at
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf autoconf-2.71
#
## automake
tar -xvf automake-1.16.5.tar.xz
cd automake-1.16.5
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make
#make -j2 check
make install
cd /sources
rm -Rf automake-1.16.5
#
##openssl
tar -xvf openssl-3.1.2.tar.gz
cd openssl-3.1.2
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib  shared  zlib-dynamic
make
#make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.1.2
cp -vfr doc/* /usr/share/doc/openssl-3.1.2
cd /sources
rm -Rf openssl-3.1.2
#
## kmod
tar -xvf kmod-30.tar.xz
cd kmod-30
./configure --prefix=/usr --sysconfdir=/etc --with-openssl --with-xz --with-zstd --with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod
cd /sources
rm -Rf kmod-30
#
## libelf
tar -xvf elfutils-0.189.tar.bz2
cd elfutils-0.189
./configure --prefix=/usr --disable-debuginfod --enable-libdebuginfod=dummy
make
#make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd /sources
rm -Rf elfutils-0.189
#
## libffi
tar -xvf libffi-3.4.4.tar.gz
cd libffi-3.4.4
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make
#make check
make install
cd /sources
rm -Rf libffi-3.4.4
echo " core build through 8.50 completed. run lfs_setup9.sh"
# moved from the bash install
#exec /usr/bin/bash --login .lfs 
exec su -l root /lfs_setup9.sh


