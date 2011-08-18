#!/bin/bash

# Script for installing the framework to a destination directory.
# This includes: copying files, creating links, creating directory structure.
# Everything should be put inplace so that the distribution binaries may be
# unpacked on-top of the structure to create a complete system.

while [ "$1" ]; do
    [ "$1" = "-d" ] && dst=$2 && shift
    shift
done

if [ -z "$dst" ] ; then
    dst=/tmp/bifrost-$(cat version)
    echo "Install framework into $dst?"
    echo -n "[y/n]:"
    read REPLY
    [ "$REPLY" = y ] || exit 1
fi

function devcreate {
    local dst L dt n major minor mode
    dst=$1
    while read L; do
	dt=x
	if echo $L|grep -q "block special"; then
	    dt=b
	fi
	if echo $L|grep -q "character special"; then
	    dt=c
	fi
	if [ "$dt" != x ]; then
	    mode=$(echo $L|cut -d, -f 1)
	    major=$(echo $L|cut -d, -f 2)
	    minor=$(echo $L|cut -d, -f 3)
	    n=$(echo $L|cut -d, -f 5)
	    n=$(basename $n)
	    mknod $dst/$n $dt 0x$major 0x$minor && chmod $mode $dst/$n
	fi
    done
}

mkdir -p $dst

for d in bin bin32 bin64 contrib dev dev/pts dev/bus dev/bus/usb dev.real dev.real/pts dev.real/bus dev.real/bus/usb  Documentation etc etc/config.data etc/config.flags etc/config.preconf etc/crontabs etc/device-detect.d etc/eth-detect.d etc/fs etc/iproute2 etc/rc.d etc/ssh filter lib mnt opt proc sbin sys tmp usr usr/bin usr/lib usr/libexec usr/log.persistent usr/sbin usr/lib/file usr/lib/tc usr/lib/terminfo usr/lib/terminfo/v usr/lib/terminfo/x usr/lib/zoneinfo .ssh; do
    mkdir -p $dst/$d
done

ln -sf tmp $dst/var
ln -sf /tmp/know_hosts_root  $dst/.ssh/know_hosts
ln -sf /tmp/know_hosts2_root $dst/.ssh/know_hosts2

ln -sf /dev.real $dst/tmp/dev

ln -snf lib       $dst/usr/share
ln -snf /tmp      $dst/usr/tmp
ln -snf /var/adm  $dst/usr/adm
ln -snf /var/log  $dst/usr/log

ln -sf /tmp/initrunlvl             $dst/etc/initrunlvl
ln -sf /usr/lib/zoneinfo/localtime $dst/etc/localtime
ln -sf rc.0                        $dst/etc/rc.d/rc.6
ln -sf /sbin/e2fsck                $dst/etc/fs/fsck.ext2

for dev in dev dev.real; do
    ln -sf /proc/kcore    $dst/$dev/core
    ln -snf /proc/self/fd $dst/$dev/fd
    ln -sf fd/0           $dst/$dev/stdin
    ln -sf fd/1           $dst/$dev/stdout
    ln -sf fd/2           $dst/$dev/stderr
    ln -snf ram0          $dst/$dev/ramdisk
    ln -snf ram1          $dst/$dev/ram
    devcreate $dst/$dev < devices
done

ln -sf bash $dst/bin/sh

install -p -m 0400 input.rc     $dst/.inputrc
install -p -m 0400 bash_logout  $dst/.bash_logout
install -p -m 0400 bash_profile $dst/.bash_profile

for f in CHANGELOG CONFIG.txt README.txt README-bifrost-6.0 README-bifrost-6.1 README-bifrost-7.0; do
    cp -Pp $f $dst/$f
done 

cp -a Documentation $dst
cp -a etc           $dst
mkdir -p $dst/etc/cron.d
mkdir -p $dst/etc/cron.user
cp -a filter        $dst
cp -a opt           $dst
cp -a sbin          $dst
cp -a usr           $dst
cp -a boot          $dst
