#!/bin/bash
#
# rc.M		This file is executed by init(8) when the system is being
#		initialized for one of the "multi user" run levels (i.e.
#		levels 1 through 6).  It usually does mounting of file
#		systems et al.

. /etc/config.data/kernel

# Tell the viewers what's going to happen...
echo "Going multiuser..."

# Check kernel module dependencies
[ $(allcaps) = yes ] && depmod

# Detect hardware and modprobe appropriate kernel modules
# module may be disable in /etc/config.flags/MODULENAME.mod
if [ $(allcaps) = yes ]; then
    for d in $(/usr/bin/eth-detect) NONE; do
	if [ -f /etc/config.flags/$d.mod ]; then
	    if [ `cat /etc/config.flags/$d.mod` = no ]; then
		echo "/etc/config.flags/$d.mod disabled"
		continue
	    fi
	fi
	[ "$d" = NONE ] || modprobe $d
    done
fi

# Check if system has been configured
if [ ! -f /etc/.configured ]; then
    configure
    echo "System should now be rebooted (if you have configured it, that is)"
    echo ""
    echo -n "Do you want to reboot ? ([y]/n): "
    read
    if [ ${REPLY:-y} = "y" ]; then
	echo "Remounting the disk read-only and reboot..."
	[ $(allcaps) = yes ] && remount r
        [ $(allcaps) = yes ] && reboot
    fi
    echo ""
    echo "Your system will now continue to boot..."
    echo ""
fi

# Set the hostname.
[ -f /etc/HOSTNAME ] && hostname `cat /etc/HOSTNAME`

# Set reboot time for panic to 1 minute
[ $(allcaps) = yes ] && (/bin/echo 60 > /proc/sys/kernel/panic)

# - - - - - - - - - - - - - - - - - - - - - -
# Initialize the NET subsystem.
[ -f /etc/config.hooks/net.pre ] && . /etc/config.hooks/net.pre
if [ -f /etc/rc.d/rc.inet ]; then
    /etc/rc.d/rc.inet 2> /dev/null
fi
[ -f /etc/config.hooks/net.post ] && . /etc/config.hooks/net.post

# Turn off flow control on all interfaces
flowctl off

# Sleep 4 seconds and then remount the flash disk read-only
read FLAG < /etc/config.flags/rwsystem
if [ "$FLAG" != yes ]; then
    sleep 4
    [ $(allcaps) = yes ] && remount r
fi

# Start syslog
if [ -f /etc/rc.d/rc.syslog ]; then
    echo -n " syslog "
    /etc/rc.d/rc.syslog start && echo ok || echo failed
fi

# Start ipmi
read FLAG < /etc/config.flags/ipmi
if [ "$FLAG" = yes ]; then
    echo -n " ipmi "
    /etc/rc.d/rc.ipmi start && echo ok || echo failed
fi

# Start the dnsmasq server
read FLAG < /etc/config.flags/dnsmasq
if [ "$FLAG" = yes ]; then
    echo -n " dnsmasq "
    /etc/rc.d/rc.dnsmasq start && echo ok || echo failed
fi

# Start dhcp relay service
read FLAG < /etc/config.flags/dhcrelay4
if [ "$FLAG" = yes ]; then
    echo -n " dhcrelay IPv4 "
    /etc/rc.d/rc.dhcrelay4 start && echo ok || echo failed
fi
read FLAG < /etc/config.flags/dhcrelay6
if [ "$FLAG" = yes ]; then
    echo -n " dhcrelay IPv6 "
    /etc/rc.d/rc.dhcrelay6 start && echo ok || echo failed
fi

# Inetd daemon
read FLAG < /etc/config.flags/inetd
if [ "$FLAG" = yes ]; then
    echo -n " inetd "
    /etc/rc.d/rc.inetd start && echo ok || echo failed
fi

# SSH daemon, needs full path to exec
read FLAG < /etc/config.flags/sshd
if [ "$FLAG" = yes ]; then
    echo -n " sshd "
    /etc/rc.d/rc.sshd start && echo ok || echo failed
fi

# Vixie Cron
read FLAG < /etc/config.flags/cron
if [ "$FLAG" = yes ]; then
    echo -n " cron "
    /etc/rc.d/rc.cron start && echo ok || echo failed
fi

# Start the interface statistics daemon ifstat2
read FLAG < /etc/config.flags/ifstat2
if [ "$FLAG" = yes ]; then
    echo -n " ifstat2 "
    /etc/rc.d/rc.ifstat2 start && echo ok || echo failed
fi

# Start the DHCP server
read FLAG < /etc/config.flags/dhcpd
if [ "$FLAG" = yes -a -f /etc/rc.d/rc.dhcp ]; then
    echo -n " dhcp "
    /etc/rc.d/rc.dhcp start && echo ok || echo failed
fi

# Start the NTP server/client
read FLAG < /etc/config.flags/ntp
if [ "$FLAG" = yes ]; then
    if [ -f /etc/rc.d/rc.ntp ]; then
	/etc/rc.d/rc.ntp start &
    fi
fi

[ -f /etc/config.hooks/opt.pre ] && . /etc/config.hooks/opt.pre

#-- loop through all rc-scripts provided by extra optional packages
#-- for each of them check for matching config.flag -eq "yes" and
#-- if so run the rc-script with argument "start".
#-- Loop supports multiple service-flags in one pkg.
#--   Note that the rc-script should be fully self sustained with
#-- regards to paths and stuff.                 (emilp, 2003-10-01)

for file in $(ls /opt/*/etc/config.flags/* 2>/dev/null); do
    dir=${file%%/etc/*}
    pkg=${file##*/}
    if [ $(cat $file) = "yes" ]; then
        if [ -f "$dir/rc.d/rc.$pkg" ]; then
	    echo -n " ${dir##*/}/$pkg"
            $dir/rc.d/rc.$pkg start && echo ok || echo failed
        fi
    fi
done

[ -f /etc/config.hooks/opt.post ] && . /etc/config.hooks/opt.post
[ -x /etc/rc.local ] && /etc/rc.local

read GREET < /etc/.version
echo ${GREET^} ready.
