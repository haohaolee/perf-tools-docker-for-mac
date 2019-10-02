#!/bin/sh

set -x
set -e

mount -t debugfs debugfs /sys/kernel/debug
echo 0 > /proc/sys/kernel/kptr_restrict

exec "$@"

