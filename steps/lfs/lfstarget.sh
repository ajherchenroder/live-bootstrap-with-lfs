#!/bin/sh
set -e
git clone https://github.com/ajherchenroder/live-bootstrap-distro-build-scripts.git
mkdir target
cp /live-bootstrap-distro-build-scripts/target/* /target
rm -Rf /live-bootstrap-distro-build-scripts

echo "cd into /target and run the desired build script"
 