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
	mount -n -w -o remount,ro /
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
[ $(allcaps) = yes ] && mount -n -w -o remount /

# Install default versions if needed:
for f in hosts passwd shadow group fstab hosts.allow syslog.conf resolv.conf ntp.conf TZ dhcpcd.conf; do
    [ -f /etc/$f ] || cp -p /etc/config.preconf/$f.default /etc/$f
done
for f in root; do
    [ -f /etc/cron.user/$f ] || cp -p /etc/config.preconf/cron-$f.default /etc/cron.user/$f
done
for f in PANIC; do
    [ -f /etc/config.data/$f ] || cp -p /etc/config.preconf/$f.default /etc/config.data/$f
done
for f in cron ifstat2 sshd swedish-keyboard ipv4-forward ipv6-forward fw6rules fwrules ignore-icmp-bc ipmi short-defrag-time disable-route-cache; do
    [ -f /etc/config.flags/$f ] || echo yes > /etc/config.flags/$f
done
for f in usb-suspend rwsystem fsck dhcpd inetd ntp dnsmasq ramlog slow-keyboard ifrename conntrack local-port-range eth0.nic dummy0.nic; do
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
[ -f /etc/mtab ] || touch /etc/mtab
mount -n --bind /proc/1/mounts /etc/mtab

# Create pseudo file systems
export TMPSIZE=`cat /etc/config.data/tmpsize`
mount -t tmpfs -o size=$TMPSIZE tmpfs /tmp
mount /sys

# Detect hardware and modprobe appropriate kernel modules
# module may be disable in /etc/config.flags/MODULENAME.mod
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

# if /var is _not_ the default ram disk, we need to mount it now
grep -q /var /etc/fstab && mount /var

# if /var is on kept between runs, we need to clean up old pids
[ -d /var/run ] && rm -f /var/run/*.pid

# Create directories as needed
echo "Adding files and directories to /var (usually /var -> /tmp)"
for d in adm spool spool/cron spool/locks tmp log lock run empty db; do
    [ -d /var/$d ] || mkdir -p /var/$d
done

# Mount file systems in fstab (and create an entry for /)
# but not NFS.
echo "Mounting any additional filesystems"
mount -avt nonfs

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
	echo -1 > /sys/module/usbcore/parameters/autosuspend
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
