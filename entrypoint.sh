#!/bin/sh

set -xe

# enable debug settings
echo 0 > /proc/sys/kernel/kptr_restrict
mount -t debugfs debugfs /sys/kernel/debug

# a trick to workaround an overlay fs issue in container
mkdir -p "$HOME/bin"
mount -t tmpfs -o size=5m tmpfs "$HOME/bin"
cp `which bpftrace` "$HOME/bin/"
export PATH="$HOME/bin:$PATH"

exec "$@"

