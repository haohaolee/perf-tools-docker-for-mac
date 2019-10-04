#!/bin/sh

set -xe

# enable debug settings
echo 0 > /proc/sys/kernel/kptr_restrict
mount -t debugfs debugfs /sys/kernel/debug

# a trick to workaround an overlay fs issue in container
mkdir -p ~/bin
mount -t tmpfs -o size=5m tmpfs ~/bin
cp `which bpftrace` ~/bin/
export PATH=~/bin:$PATH

exec "$@"

