#!/bin/bash

# Script for installing the framework to a destination directory.
# This includes: copying files, creating links, creating directory structure.
# Everything should be put inplace so that the distribution binaries may be
# unpacked on-top of the structure to create a complete system.

dst=/tmp/bifrost-6.1-beta2

mkdir -p $dst

for d in bin bin32 bin64 boot contrib dev dev/pts dev/bus dev/bus/usb dev.real dev.real/pts dev.real/bus dev.real/bus/usb  Documentation etc etc/config.data etc/config.flags etc/config.default etc/crontabs etc/device-detect.d etc/eth-detect.d etc/fs etc/iproute2 etc/rc.d etc/ssh filter lib mnt opt proc sbin sys tmp usr usr/bin usr/lib usr/libexec usr/log.persistent usr/sbin usr/lib/file usr/lib/tc usr/lib/terminfo usr/lib/terminfo/v usr/lib/terminfo/x usr/lib/zoneinfo .ssh; do
    mkdir -p $dst/$d
done

ln -sf tmp $dst/var
ln -sf /tmp/know_hosts_root  $dst/.ssh/know_hosts
ln -sf /tmp/know_hosts2_root $dst/.ssh/know_hosts2

ln -sf /dev.real $dst/tmp/dev

ln -sf lib       $dst/usr/share
ln -sf /tmp      $dst/usr/tmp
ln -sf /var/adm  $dst/usr/adm
ln -snf /var/log  $dst/usr/log

ln -sf /tmp/initrunlvl             $dst/etc/initrunlvl
ln -sf /usr/lib/zoneinfo/localtime $dst/etc/localtime
ln -sf /proc/mounts                $dst/etc/mtab
ln -sf rc.0                        $dst/etc/rc.d/rc.6
ln -sf /sbin/e2fsck                $dst/etc/fs/fsck.ext2

for dev in dev dev.real; do
    ln -sf /proc/kcore   $dst/$dev/core
    ln -snf /proc/self/fd $dst/$dev/fd
    ln -sf fd/0          $dst/$dev/stdin
    ln -sf fd/1          $dst/$dev/stdout
    ln -sf fd/2          $dst/$dev/stderr
    ln -snf ramdisk       $dst/$dev/ram0
    ln -snf ram1          $dst/$dev/ram1
done

ln -sf bash $dst/bin/sh

install -p -m 0400 input.rc     $dst/.input.rc
install -p -m 0400 bash_logout  $dst/.bash_logout
install -p -m 0400 bash_profile $dst/.bash_profile
