#!/bin/sh
set -e
export MAKEFLAGS=-j$(nproc)
#
# 
echo "starting build at 8.51"
#
##python3
cd /sources
tar -xvf Python-3.11.4.tar.xz
cd Python-3.11.4
./configure --prefix=/usr --enable-shared  --with-system-expat  --with-system-ffi --enable-optimizations
make 
make install
cd /sources
rm -Rf Python-3.11.4
#
## flit-core
tar -xvf flit_core-3.9.0.tar.gz
cd flit_core-3.9.0
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist flit_core
cd /sources
rm -Rf flit_core-3.9.0
#
##wheel
tar -xvf wheel-0.41.1.tar.gz
cd wheel-0.41.1
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel
cd /sources
rm -Rf wheel-0.41.1
#
## ninja
tar -xvf ninja-1.11.1.tar.gz
cd ninja-1.11.1
export NINJAJOBS=2
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd /sources
rm -Rf ninja-1.11.1
#
##meson
tar -xvf meson-1.2.1.tar.gz
cd meson-1.2.1
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
cd /sources
rm -Rf meson-1.2.1
#
##coreutils
tar -xvf coreutils-9.3.tar.xz
cd coreutils-9.3
patch -Np1 -i ../coreutils-9.3-i18n-1.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --enable-no-install-program=kill,uptime
make
#make NON_ROOT_USERNAME=tester check-root
#groupadd -g 102 dummy -U tester
#chown -Rv tester . 
#su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
#groupdel dummy
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
cd /sources
rm -Rf coreutils-9.3
#
## check
tar -xvf check-0.15.2.tar.gz
cd check-0.15.2
./configure --prefix=/usr --disable-static
make
#make check
make docdir=/usr/share/doc/check-0.15.2 install
cd /sources
rm -Rf check-0.15.2
#
##diffutils
tar -xvf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf diffutils-3.10
#
## gawk
tar -xvf gawk-5.2.2.tar.xz
cd gawk-5.2.2
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
#chown -Rv tester .
#su tester -c "PATH=$PATH make check"
make LN='ln -f' install
cd /sources
rm -Rf gawk-5.2.2
#
## findutils
tar -xvf  findutils-4.9.0.tar.xz
cd findutils-4.9.0
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
#chown -Rv tester .
#su tester -c "PATH=$PATH make check"
make install
cd /sources
rm -Rf findutils-4.9.0
#
##grof
tar -xvf groff-1.23.0.tar.gz
cd groff-1.23.0
PAGE=letter ./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf groff-1.23.0
#
##grub
tar -xvf grub-2.06.tar.xz
cd grub-2.06
patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
cd /sources
rm -Rf grub-2.06
#
## gzip
tar -xvf gzip-1.12.tar.xz
cd gzip-1.12
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf gzip-1.12
#
##iprout
tar -xvf iproute2-6.4.0.tar.xz
cd iproute2-6.4.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
mkdir -pv             /usr/share/doc/iproute2-6.4.0
cp -v COPYING README* /usr/share/doc/iproute2-6.4.0
cd /sources
rm -Rf iproute2-6.4.0
#
## kbd
tar -xvf kbd-2.6.1.tar.xz
cd kbd-2.6.1
patch -Np1 -i ../kbd-2.6.1-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
#make check
make install
cd /sources
rm -Rf kbd-2.6.1
#
## libpipeline
tar -xvf libpipeline-1.5.7.tar.gz
cd libpipeline-1.5.7
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf libpipeline-1.5.7
#
## make
tar -xvf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr
make
#chown -Rv tester .
#su tester -c "PATH=$PATH make check"
make install
cd /sources
rm -Rf make-4.4.1
#
##patch
tar -xvf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make
#make check
make install
cd /sources
rm -Rf patch-2.7.6
#
## tar
tar -xvf tar-1.35.tar.xz
cd tar-1.35
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
make
#make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
cd /sources
rm -Rf tar-1.35
#
## texinfo 
tar -xvf texinfo-7.0.3.tar.xz
cd texinfo-7.0.3
./configure --prefix=/usr
make
#make check
make install
make TEXMF=/usr/share/texmf install-tex
cd /sources
rm -Rf texinfo-7.0.3
#
## vim
tar -xvf vim-9.0.1677.tar.gz
cd vim-9.0.1677
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.1677

#cat > /etc/vimrc << "EOF"
# Begin /etc/vimrc
# Ensure defaults are set before customizing settings, not after
#source $VIMRUNTIME/defaults.vim
#let skip_defaults_vim=1
#set nocompatible
#set backspace=2
#set mouse=
#syntax on
#if (&term == "xterm") || (&term == "putty")
#  set background=dark
#endif
# End /etc/vimrc
#EOF 

cd /sources
rm -Rf vim-9.0.1677
#
## markupsafe
tar -xvf MarkupSafe-2.1.3.tar.gz
cd MarkupSafe-2.1.3
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe
cd /sources
rm -Rf MarkupSafe-2.1.3
#
##Jinja
tar -xvf Jinja2-3.1.2.tar.gz
cd Jinja2-3.1.2
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2
cd /sources
rm -Rf Jinja2-3.1.2
#
##udev
tar -xvf systemd-254.tar.gz
cd systemd-254
sed -i -e 's/GROUP="render"/GROUP="video"/' -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
sed '/systemd-sysctl/s/^/#/' -i rules.d/99-systemd.rules.in
mkdir -p build
cd       build
meson setup --prefix=/usr --buildtype=release -Dmode=release -Ddev-kvm-mode=0660 -Dlink-udev-shared=false ..
ninja udevadm systemd-hwdb \
      $(grep -o -E "^build (src/libudev|src/udev|rules.d|hwdb.d)[^:]*" \
        build.ninja | awk '{ print $2 }')                              \
      $(realpath libudev.so --relative-to .)
rm rules.d/90-vconsole.rules
install -vm755 -d {/usr/lib,/etc}/udev/{hwdb,rules}.d
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                     /usr/bin/
install -vm755 systemd-hwdb                /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm              /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}         /usr/lib/
install -vm644 ../src/libudev/libudev.h    /usr/include/
install -vm644 src/libudev/*.pc            /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc               /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf       /etc/udev/
install -vm644 rules.d/* ../rules.d/{*.rules,README} /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README}   /usr/lib/udev/hwdb.d/
install -vm755 $(find src/udev -type f | grep -F -v ".") /usr/lib/udev
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install
tar -xf ../../systemd-man-pages-254.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd-'{hwdb,udevd.service}.8
sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8
sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8
rm  /usr/share/man/man8/systemd-*.8
udev-hwdb update
cd /sources
rm -Rf systemd-254
#
##ManDb
tar -xvf man-db-2.11.2.tar.xz
cd man-db-2.11.2
./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.11.2 --sysconfdir=/etc  --disable-setuid --enable-cache-owner=bin              \
  --with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind  --with-grap=/usr/bin/grap --with-systemdtmpfilesdir= --with-systemdsystemunitdir=
make
#make -k check
make install
cd /sources
rm -Rf man-db-2.11.2
echo " core build through 8.75 completed. run lfs_setup10.sh"
exec /lfs_setup10.sh