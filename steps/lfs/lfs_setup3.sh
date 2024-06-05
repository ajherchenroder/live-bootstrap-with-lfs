#!/usr/bin/bash
set -e
source ~/.bashrc
cd $LFS/sources
# Start building the cross toolchain
#
##binutils pass 1
tar -xvf binutils-2.41.tar.xz
cd binutils-2.41
mkdir -v build
cd       build
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror
make
make install
cd $LFS/sources
rm -Rf binutils-2.41
#
##GCC pass 1
tar -xvf gcc-13.2.0.tar.xz
cd gcc-13.2.0
tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
mkdir -v build
cd       build
../configure  --target=$LFS_TGT --prefix=$LFS/tools  --with-glibc-version=2.38 --with-sysroot=$LFS --with-newlib --without-headers --enable-default-pie      \
 --enable-default-ssp --disable-nls --disable-shared --disable-multilib --disable-threads --disable-libatomic --disable-libgomp --disable-libquadmath     \
 --disable-libssp --disable-libvtv --disable-libstdcxx  --enable-languages=c,c++
make -j2
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
cd $LFS/sources
rm -Rf gcc-13.2.0
#
## linux headers
tar -xvf linux-6.4.12.tar.xz
cd linux-6.4.12
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
cd $LFS/sources
rm -Rf linux-6.4.12
#
##glibc
tar -xvf glibc-2.38.tar.xz
cd glibc-2.38
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
patch -Np1 -i ../glibc-2.38-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.14               \
      --with-headers=$LFS/usr/include    \
      libc_cv_slibdir=/usr/lib
make
make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
cd $LFS/sources
rm -Rf glibc-2.38
tar -xvf gcc-13.2.0.tar.xz
cd gcc-13.2.0
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la
cd $LFS/sources
rm -Rf gcc-13.2.0
#
## M4
tar -xvf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf m4-1.4.19
#
## Ncurses
tar -xvf ncurses-6.4.tar.gz
cd ncurses-6.4
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            --enable-widec
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
cd $LFS/sources
rm -Rf ncurses-6.4
#
##bash
tar -xvf bash-5.2.15.tar.gz
cd bash-5.2.15
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd $LFS/sources
rm -Rf bash-5.2.15
#
##coreutils
tar -xvf coreutils-9.3.tar.xz
cd coreutils-9.3
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            gl_cv_macro_MB_CUR_MAX_good=y
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
cd $LFS/sources
rm -Rf coreutils-9.3
#
##diffutils
tar -xvf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf diffutils-3.10
#
## file
tar -xvf file-5.45.tar.gz
cd file-5.45
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd $LFS/sources
rm -Rf file-5.45
#
## findutils
tar -xvf findutils-4.9.0.tar.xz
cd findutils-4.9.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf findutils-4.9.0
#
## GAWK
tar -xvf gawk-5.2.2.tar.xz
cd gawk-5.2.2
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf gawk-5.2.2
#
##grep
tar -xvf grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf grep-3.11
#
## gzip
tar -xvf gzip-1.12.tar.xz
cd gzip-1.12
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf gzip-1.12
#
##make
tar -xvf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf make-4.4.1
#
##patch
tar -xvf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf patch-2.7.6
#
##SED
tar -xvf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf sed-4.9
#
##TAR
tar -xvf tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources
rm -Rf tar-1.35
#
##xz
tar -xvf xz-5.4.4.tar.xz
cd xz-5.4.4
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.4.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd $LFS/sources
rm -Rf xz-5.4.4
#
##binutils pass 2
tar -xvf binutils-2.41.tar.xz
cd binutils-2.41
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd
make -j2
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd $LFS/sources
rm -Rf binutils-2.41
#
## GCC pass 2
tar -xvf gcc-13.2.0.tar.xz
cd gcc-13.2.0
tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -v build
cd       build
../configure  --build=$(../config.guess) --host=$LFS_TGT --target=$LFS_TGT LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc --prefix=/usr                                  \
 --with-build-sysroot=$LFS --enable-default-pie --enable-default-ssp --disable-nls --disable-multilib  --disable-libatomic --disable-libgomp --disable-libquadmath                          \
 --disable-libsanitizer  --disable-libssp --disable-libvtv --enable-languages=c,c++
make -j2
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
cd $LFS/sources
rm -Rf gcc-13.2.0
echo "Pre-chroot tools build complete exit back to root and run lfs_setup4.sh"
#exec su -c /mnt/lfs/lfs_setup4.sh -m root
