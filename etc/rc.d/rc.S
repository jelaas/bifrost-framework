#!/bin/sh
#
# /etc/rc.d/rc.S:  System initialization script.

echo "?"

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/etc

# mount /proc early to allow handling of LABEL.
mount -n -t proc proc /proc &> /dev/null

# Create and populate /dev if devtmpfs is not used
if ! grep -q devtmpfs /proc/mounts; then
    [ $(allcaps) = yes ] && mount -n -t tmpfs tmpfs /dev

    # Copy devices to tmpfs-dev
    [ $(allcaps) = yes ] && cp -ra /dev.real/* /dev

    # Start daemon to automatically populate block-devices in /dev
    [ $(allcaps) = yes ] && /sbin/blockdev-populate -d
fi

# Create mountpoint for devpts if needed
[ -e /dev/pts ] || mkdir -p /dev/pts

# Check the integrity of all filesystems (add your own extras here)
if [ $(allcaps) = yes ]; then
    FLAG=no
    if [ -f /etc/config.flags/fsck ]; then
	read FLAG < /etc/config.flags/fsck
    fi
    if [ "$FLAG" = yes ]; then
	remount r
	e2fsck -n LABEL=bifrost
	
# If there was a failure, drop into single-user mode.
	rc=$?
	if [ $rc -gt 1 ] ; then
	    echo
	    echo
	    echo "*****************************************"
	    echo "fsck returned exit code $rc"
	    echo "Common exit codes are: "
	    echo "1 - File system errors corrected"
	    echo "2 - File system errors corrected, system should be rebooted"
	    echo "4 - File system errors left uncorrected"
	    echo "*****************************************"
	    echo
	    echo
	    echo "*****************************************"
	    echo "Launching a minimal single user shell."
	    echo "If you do not login normal boot will continue in 60 seconds."
	    echo "Or you may press CONTROL-D to continue normal boot."
	    echo "*****************************************"
	    echo
	    echo
	    login
	fi
    fi
fi

# Remount the root filesystem in read-write mode
echo "Remounting root device with read-write enabled."
[ $(allcaps) = yes ] && remount w

# Install default versions if needed:
for f in hosts passwd shadow group fstab hosts.allow syslog.conf ntp.conf TZ dhcpcd.conf\
 opt/sources.list ssh/ssh_config ssh/sshd_config rc.d/rc.inet.local inputrc profile; do
    [ -f /etc/$f ] || cp -p /etc/config.preconf/$f.default /etc/$f
done
for f in root; do
    [ -f /etc/cron.user/$f ] || cp -p /etc/config.preconf/cron-$f.default /etc/cron.user/$f
done
for f in PANIC resolv.conf dhcrelay4.conf dhcrelay6.conf; do
    [ -f /etc/config.data/$f ] || cp -p /etc/config.preconf/$f.default /etc/config.data/$f
done
for f in cron ifstat2 sshd swedish-keyboard ipv4-forward ipv6-forward fw6rules fwrules ignore-icmp-bc ipmi short-defrag-time; do
    [ -f /etc/config.flags/$f ] || echo yes > /etc/config.flags/$f
done
for f in usb-suspend rwsystem fsck dhcpd dhcrelay4 dhcrelay6 inetd ntp dnsmasq ramlog slow-keyboard ifrename conntrack local-port-range eth0.nic dummy0.nic pmem; do
    [ -f /etc/config.flags/$f ] || echo no > /etc/config.flags/$f
done
[ -f /etc/config.data/tmpsize ] || echo 256m > /etc/config.data/tmpsize
[ -f /etc/HOSTNAME ] || echo Bifrost > /etc/HOSTNAME

# Generate ssh keys if needed
[ -f /.ssh/identity ] || ssh-keygen -t rsa1 -P "" -N "" -f /.ssh/identity
[ -f /.ssh/id_rsa ] || ssh-keygen -t rsa -P "" -N "" -f /.ssh/id_rsa
[ -f /.ssh/id_dsa ] || ssh-keygen -t dsa -P "" -N "" -f /.ssh/id_dsa
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -t rsa -b 2048 -P "" -N "" -f /etc/ssh/ssh_host_rsa_key
[ -f /etc/ssh/ssh_host_dsa_key ] || ssh-keygen -t dsa -P "" -N "" -f /etc/ssh/ssh_host_dsa_key

# Create /tmp, /proc and /sys
rm -rf /tmp
[ $(allcaps) = yes ] && rm -rf /sys
mkdir -p /tmp /sys
chgrp tmp /tmp
chmod 1777 /tmp

# Bind mount /proc/1/mounts /etc/mtab
# This works better than link
[ -L /etc/mtab ] && rm -f /etc/mtab
[ -f /etc/mtab ] || touch /etc/mtab
mount -n --bind /proc/1/mounts /etc/mtab

# Create pseudo file systems
export TMPSIZE=`cat /etc/config.data/tmpsize`
mount -n -t tmpfs -o size=$TMPSIZE tmpfs /tmp
mount -n /sys

# Create directory for System files
mkdir /tmp/System

# Bind mount /etc/resolv.conf
touch /tmp/System/resolv.conf
chmod 0644 /tmp/System/resolv.conf
[ -f /etc/resolv.conf ] || touch /etc/resolv.conf
[ -f /etc/config.data/resolv.conf ] && cp /etc/config.data/resolv.conf /tmp/System/resolv.conf
mount -n --bind /tmp/System/resolv.conf /etc/resolv.conf

# Detect hardware and modprobe appropriate kernel modules
# module may be disable in /etc/config.flags/MODULENAME.mod
[ -f /etc/config.hooks/mount.pre ] && . /etc/config.hooks/mount.pre
if [ $(allcaps) = yes ]; then
    for d in $(/usr/bin/device-detect) NONE; do
	if [ -f /etc/config.flags/$d.mod ]; then
	        if [ `cat /etc/config.flags/$d.mod` = no ]; then
		    echo "/etc/config.flags/$d.mod disabled"
		    continue
		fi
	fi
	[ "$d" = NONE ] || modprobe $d
    done
fi

# Mount suitable /var. Ramdisk, pmem or specified in /etc/fstab
FLAG=no; [ -f /etc/config.flags/pmem ] && read FLAG < /etc/config.flags/pmem
if [ "$FLAG" = yes ]; then
    modprobe pmem
    if [ -e /dev/pmem0 ]; then
        if ! file -s /dev/pmem0 | grep -q ext4; then
            mkfs.ext4 -F /dev/pmem0
        fi
    fi
fi
if mount -fn /var &>/dev/null; then
    [ -L /var ] && rm -f /var
    mkdir -p /var
    fsck -y /var
    mount -n /var || mount -n --bind /tmp /var
else
    if [ "$FLAG" = yes ]; then
	mount -n /dev/pmem0 /var || mount -n --bind /tmp /var
    else
	mount -n --bind /tmp /var
    fi
fi

# if /var is on kept between runs, we need to clean up old pids
[ -d /var/run ] && rm -f /var/run/*.pid

# Create directories as needed
echo "Adding files and directories to /var (usually /var -> /tmp)"
for d in adm spool spool/cron spool/locks tmp log lock run empty db lib/misc; do
    [ -d /var/$d ] || mkdir -p /var/$d
done

# Mount file systems in fstab except NFS.
sleep 5
echo "Mounting any additional filesystems"
mount -n -avt nonfs
[ -f /etc/config.hooks/mount.post ] && . /etc/config.hooks/mount.post

#Setup RAM logging
export RAM_LOG=`cat /etc/config.flags/ramlog`
if [ $RAM_LOG = "yes" ]; then
        cp -rp /usr/log.persistent/* /var/log/
fi

# Configure USB suspend
# This can be dangerous: some devices never wake up from suspend!
read FLAG < /etc/config.flags/usb-suspend
if [ "$FLAG" != yes ]; then
    if [ -f /sys/module/usbcore/parameters/autosuspend -a $(allcaps) = yes ]; then
	/bin/echo -1 > /sys/module/usbcore/parameters/autosuspend
    fi
fi

umask 077
touch /var/known_hosts_root /var/known_hosts2_root /var/log/lastlog /var/log/wtmp
umask 022
chgrp tmp /tmp
chmod 1777 /var/run

# SSH privsep.
chown root:sys /var/empty
chmod 0700 /var/empty

# Looks like we have to create this.
cat /dev/null > /var/run/utmp

# Prepare kernel module path
touch /etc/config.data/kernel
cp /dev/null /etc/config.data/kernel
echo "export KERNEL=`uname -r`" >> /etc/config.data/kernel

# Setup keyboard for slow typists
export CONFIG_SLOWKEYBOARD=`cat /etc/config.flags/slow-keyboard`
if [ $CONFIG_SLOWKEYBOARD = "yes" ]; then
    [ $(allcaps) = yes ] && kbdrate -r 10.0 -d 700
fi

# Setup Swedish keyboard layout
echo "Setting Swedish keyboard layout..."
export CONFIG_SWKEYBOARD=`cat /etc/config.flags/swedish-keyboard`
if [ $CONFIG_SWKEYBOARD = "yes" ]; then
    [ $(allcaps) = yes ] && loadkeys /etc/swedish.keyboard.map
fi

echo "# rc.S completed"
