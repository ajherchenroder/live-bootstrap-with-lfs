#!/bin/sh
set -e
#
## make sure the profile is initiated and the certs are updated

/usr/sbin/make-ca -g
source /etc/profile