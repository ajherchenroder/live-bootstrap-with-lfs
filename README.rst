.. SPDX-FileCopyrightText: 2021 Andrius Štikonas <andrius@stikonas.eu>
.. SPDX-FileCopyrightText: 2021 Paul Dersey <pdersey@gmail.com>
.. SPDX-FileCopyrightText: 2021 fosslinux <fosslinux@aussies.space>
.. SPDX-FileCopyrightText: 2024 Tony Herchenroder 

.. SPDX-License-Identifier: CC-BY-SA-4.0

This fork is an extension of the live-bootstrap project to provide a fully bootstrapped software build environment based on live-bootstrap extended by a LFS (Linux From Scratch) 12 build. The LFS subsystem is not intended to be a full distribution. It has no init system scripts or bootloader. The intent is to provide a dynamically linked build environment that is capable of building packages for other applications. I created this fork as an interim step in my project to bootstrap a Gentoo stage three tarball from source. I thought someone else might find it useful.

The environment is based on some old bash scripts I had made for installing LFS. The scripts were updated to LFS V12 and tweaked to work in the live-bootstrap environment. LFS revision 12 was chosen because it is the last revision of LFS that will work with the Linux kernel used in the live-bootstrap.

Requirements

In addition the the requirements of the live-bootstrap, you will need an additional partition to 
build the lfs environment in. 32 GB is sufficient for the task.

recommendations and notes

I would recommend the use of a separate swap partition rather than using the swap system in the
live-bootstrap. 8 GB is sufficient for the task. The repo is set up to use the chroot method by 
default. The defaults should work with the qemu mode and bare metal as is. If using the bubble
wrap method, delete the contents of the /steps/after directory prior to running the live-
bootstrap. It is also recommended that you download the live-bootstrap and lfs source files
locally. I store them on a web server on my local NAS. To use a local repository search for 
"#local" in the lfs_setup.sh script located in /steps/lfs. modify the links to point to the local
repository. I also recommend creating an additional partition. The extra partition would be used to build any of the follow on distributions that are being worked on.

How to use:

1. set up the necessary partitions
2. git clone https://github.com/ajherchenroder/live-bootstrap-with-lfs
3. git submodule update --init --recursive
4. run rootfs.py with the desired options

NOTE: The live-bootstrap will automatically terminate in the interactive mode except when using bubble wrap. In that case please use the interactive option.

5. swapon the external swap partition (if desired)
6. cd into /steps/lfs
7. run ./lfsmain.sh (or ./lfsmain.sh -L if using a local repository) and follow the prompts.
The scripts will end with you chrooted into the lfs partition.

Original live-bootstrap readme follows:


live-bootstrap
==============

An attempt to provide a reproducible, automatic, complete end-to-end
bootstrap from a minimal number of binary seeds to a supported fully
functioning operating system.

How do I use this?
------------------

Quick start:

Choose a mirror from https://github.com/fosslinux/live-bootstrap/wiki/Mirrors,
or create a private/public mirror yourself (see further below). You should
provide the mirror as ``--mirror`` to ``rootfs.py``.

See ``./rootfs.py --help`` and follow the instructions given there.
This uses a variety of userland tools to prepare the bootstrap.

(*Currently, there is no way to perform the bootstrap without external
preparations! This is a currently unsolved problem.*)

Without using Python:

0. Choose a mirror as detailed above. (You will input this later, instead of
   passing it to ``rootfs.py```).
1. ``git clone https://github.com/fosslinux/live-bootstrap``
2. ``git submodule update --init --recursive``
3. Consider whether you are going to run this in a chroot, in QEMU, or on bare
   metal. (All of this *can* be automated, but not in a trustable way. See
   further below.)

   a. **chroot:** Create a directory where the chroot will reside, run
      ``./download-distfiles.sh``, and copy:

      * The entire contents of ``seed/stage0-posix`` into that directory.
      * All other files in ``seed`` into that directory.
      * ``steps/`` and ``distfiles/`` into that directory.

        * At least all files listed in ``steps/pre-network-sources`` must be
          copied in. All other files will be obtained from the network.
      * Run ``/bootstrap-seeds/POSIX/x86/kaem-optional-seed`` in the chroot.
        (Eg, ``chroot rootfs /bootstrap-seeds/POSIX/x86/kaem-optional-seed``).
   b. **QEMU:** Create two blank disk images.

      * Generate ``builder-hex0-x86-stage1.img`` from hex0 source:

        ``sed 's/[;#].*$//g' builder-hex0/builder-hex0-x86-stage1-hex0 | xxd -r -p``
      * On the first image, write ``builder-hex0-x86-stage1.img`` to it, followed
        by ``kernel-bootstrap/builder-hex0-x86-stage2.hex0``, followed by zeros
        padding the disk to the next sector.
      * distfiles can be obtained using ``./download-distfiles.sh``.
      * See the list in part a. For every file within that list, write a line to
        the disk ``src <size-of-file> <path-to-file>``, followed by the contents
        of the file.

        * *Only* copy distfiles listed in ``sources`` files for ``build:`` steps
          manifested before ``improve: get_network`` into this disk.
      * Optionally (if you don't do this, distfiles will be network downloaded):

        * On the second image, create an MSDOS partition table and one ext3
          partition.
        * Copy ``distfiles/`` into this disk.
      * Run QEMU, with 4+G RAM, optionally SMP (multicore), both drives (in the
        order introduced above), a NIC with model E1000
        (``-nic user,model=e1000``), and ``-machine kernel-irqchip=split``.
   c. **Bare metal:** Follow the same steps as QEMU, but the disks need to be
      two different *physical* disks, and boot from the first disk.

Mirrors
-------

It has been decided that repackaging distfiles for live-bootstrap is generally
permissible, particularly from git repositories. We do this primarily because

a. currently live-bootstrap only supports tarballs/raw files as input, not git
   repositories
b. to reduce load on servers

You may choose to use an existing mirror from 
https://github.com/fosslinux/live-bootstrap/wiki/Mirrors, however you may be
(to some varied extent) trusting the operator of the mirror.

Alternatively, you can create your own local mirror - one such implementation
is in ``./mirror.sh``. You can invoke it with
``./mirror.sh path/to/mirror/dir path/to/mirror/state``.
You would then pass ``--mirror path/to/mirror/dir`` to rootfs.py.
(If not using rootfs.py, you need to copy files around manually into distfiles.)

Most helpfully to the project, you could create your own public mirror, by
running ``./mirror.sh`` or writing your own script that does something similar
on a timer (systemd timer or cron job, for example), where the mirror directory
is publicly accessible on the Internet (ideally, via HTTP and HTTPS).

Background
----------

Problem statement
=================

live-bootstrap's overarching problem statement is;

> How can a usable Linux system be created with only human-auditable, and
wherever possible, human-written, source code?

Clarifications:

* "usable" means a modern toolchain, with appropriate utilities, that can be
  used to expand the amount of software on the system, interactively, or
  non-interactively.
* "human-auditable" is discretionary, but is usually fairly strict. See
  "Specific things to be bootstrapped" below.

Why is this difficult?
======================

The core of a modern Linux system is primarily written in C and C++. C and C++
are **self-hosting**, ie, nearly every single C compiler is written in C.

Every single version of GCC was written in C. To avoid using an existing
toolchain, we need some way to be able to compile a GCC version without C. We
can use a less well-featured compiler, TCC, to do this. And so forth, until we
get to a fairly primitive C compiler written in assembly, ``cc_x86``.

Going up through this process requires a bunch of other utilities as well; the
autotools suite, guile and autogen, etc. These also have to be matched
appropriately to the toolchain available.

Why should I care?
------------------

That is outside of the scope of this README. Here’s a few things you can
look at:

-  https://bootstrappable.org
-  Trusting Trust Attack (as described by Ken Thompson)
-  https://guix.gnu.org/manual/en/html_node/Bootstrapping.html
-  Collapse of the Internet (eg CollapseOS)

Specific things to be bootstrapped
----------------------------------

GNU Guix is currently the furthest along project to automate
bootstrapping. However, there are a number of non-auditable files used
in many of their packages. Here is a list of file types that we deem
unsuitable for bootstrapping.

1. Binaries (apart from seed hex0, kaem, builder-hex0).
2. Any pre-generated configure scripts, or Makefile.in’s from autotools.
3. Pre-generated bison/flex parsers (identifiable through a ``.y``
   file).
4. Any source code/binaries downloaded within a software’s build system
   that is outside of our control to verify before use in the build
   system.
5. Any non-free software. (Must be FSF-approved license).

How does this work?
-------------------

**For a more in-depth discussion, see parts.rst.**

Firstly, ``builder-hex0`` is launched. ``builder-hex0`` is a minimal kernel that is
written in ``hex0``, existing in 3 self-bootstrapping stages.

This is capable of executing the entirety of ``stage0-posix``, (see
``seed/stage0-posix``), which produces a variety of useful utilities and a basic
C language, ``M2-Planet``.

``stage0-posix`` runs a file called ``after.kaem``. This is a shell script that
builds and runs a small program called ``script-generator``. This program reads
``steps/manifest`` and converts it into a series of shell scripts that can be
executed in sequence to complete the bootstrap.

From this point forward, ``steps/manifest`` is effectively self documenting.
Each package built exists in ``steps/<pkg>``, and the build scripts can be seen
there.
