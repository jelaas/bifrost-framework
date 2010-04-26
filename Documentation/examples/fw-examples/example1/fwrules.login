#!/bin/sh
#
# Login access
#

source /filter/fw.conf
echo "$0"

ARG=$1
if [ ${1:-none} = "none" ]; then
    ARG="refresh"
    ipchains -F login
else
    if [ $ARG != "refresh" -a $ARG != "purge" -a $ARG != "delete" ]; then
	echo
	echo "Usage:   $0 <refresh|purge|delete>"
	echo "Example: $0 refresh    (default)"
	echo
	exit
    fi
fi
case $ARG in ( refresh ) ACTION="-A"; ipchains -F login;;
	     ( purge )   ACTION="-D";;
	     ( delete )  ACTION="-D"; ipchains -F login; exit;;
esac

###------- Edit Rules Below -------###

# LOCAL input
ipchains $ACTION login -p TCP -i $IF_IP2 -s $TKARLSSON2 $HI -d $IP2 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP2 ! -y -s $TKARLSSON2 ssh -d $IP2 $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP3 -s $TKARLSSON2 $HI -d $IP3 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP3 ! -y -s $TKARLSSON2 ssh -d $IP3 $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP4 -s $TKARLSSON2 $HI -d $IP4 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP4 ! -y -s $TKARLSSON2 ssh -d $IP4 $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP5 -s $TKARLSSON2 $HI -d $IP5 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP5 ! -y -s $TKARLSSON2 ssh -d $IP5 $HI -j ACCEPT


ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $TKARLSSON ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $HADES $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $HADES ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $ROBUR $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $ROBUR ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $RHEA $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $RHEA ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $ZEUS $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $ZEUS ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $OWELIN $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $OWELIN ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $TLOHAMMAR3 $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $TLOHAMMAR3 ssh -d $IP $HI -j ACCEPT

# Logging
ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL $HI_SSH -y -d $TKARLSSON2 ftp-data:telnet -l

# FORWARD input in
ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL $HI_SSH -d $TKARLSSON2 ftp:telnet -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $NET_ALL ftp:telnet -d $TKARLSSON2 $HI_SSH -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $NET_ALL $HI -d $TKARLSSON2 $HI -j ACCEPT
