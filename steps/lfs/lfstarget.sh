#!/bin/sh
set -e
DISKTOUSE=$(</lfsdisktouse)
mount $DISKTOUSE'2' /mnt
git clone https://github.com/ajherchenroder/live-bootstrap-distro-build-scripts.git
mkdir target
cp /live-bootstrap-distro-build-scripts/target/* /target
mkdir /mnt/live-bootstrap/target/target
cp /live-bootstrap-distro-build-scripts/target/* /mnt/live-bootstrap/target/target/target
rm -Rf /live-bootstrap-distro-build-scripts
chmod +x,+x,+x /target/*
chmod +x,+x,+x /mnt/live-bootstrap/target/target/*
echo "cd into /target and run the desired build script"
echo "for Gentoo return to the live-bootstrap and then cd into /target"
umount /mnt