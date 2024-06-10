#!/bin/sh
set -e
#
## make sure the profile is initiated and the certs are updated
source /etc/profile
/usr/sbin/make-ca -g