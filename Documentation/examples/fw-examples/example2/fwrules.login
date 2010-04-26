#!/bin/sh
#
# Login access
#
# Passive FTP (out), Normal FTP (in), SSH and Telnet.
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
ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON2 $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $TKARLSSON2 ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $TKARLSSON ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $ROBUR $HI -d $IP ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $ROBUR ssh -d $IP $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP3 -s $ZEUS $HI -d $IP3 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP3 ! -y -s $ZEUS ssh -d $IP3 $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP3 -s $NEMESIS $HI -d $IP3 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP3 ! -y -s $NEMESIS ssh -d $IP3 $HI -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP2 -s $SESAM $HI -d $IP2 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP2 ! -y -s $SESAM ssh -d $IP2 $HI -j ACCEPT

# Open for the ftp proxy
#ipchains $ACTION login -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $IP2 $HI -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP2 -s $NET_IP3 $HI -d $IP3 $HI -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $IP2 ftp-data:ftp -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP2 ! -y -s $NET_IP2 ftp-data:ftp -d $IP2 $HI -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP3 -s $NET_IP3 $HI -d $IP3 ftp-data:ftp -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP3 ! -y -s $NET_IP3 ftp-data:ftp -d $IP3 $HI -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL ftp-data -d $IP $HI -j ACCEPT
#ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $NET_ALL ftp -d $IP $HI -j ACCEPT

# Logging (check fwrules.log for other logs)
ipchains $ACTION login -p TCP -i $IF_IP -y -d $NET_IP2 ftp-data:telnet -l

# FORWARD input in

# Login to servers
#ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL $HI -d $RHEA ftp-data:ssh -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL $HI -d $ARES ftp-data:telnet -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $ARES ftp-data:telnet -j ACCEPT

ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL $HI -d $ZEUS ftp-data:ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $ZEUS ftp-data:ssh -j ACCEPT

# Login to internal host from Tkarlsson2 and modem pool
ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON2 $HI -d $NMR400 ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON2 $HI -d $SESAM ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP -s $TKARLSSON2 $HI -d $NEMESIS ssh -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP -s $NET_118 $HI -d $NEMESIS ssh -j ACCEPT

# Outgoing (returning packets) passive ftp, ssh and telnet
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $NET_ALL ftp:telnet -d $NET_IP2 $HI -j ACCEPT

# Data for passive ftp (and some other protocols as well)
ipchains $ACTION login -p TCP -i $IF_IP ! -y -s $NET_ALL $HI -d $NET_IP2 $HI -j ACCEPT

# Normal ftp to Skogis and Betula (doesn't support passive ftp) from Olofgren
ipchains $ACTION login -p TCP -i $IF_IP -s $SKOGIS ftp-data -d $OLOFGREN $HI -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP -s $BETULA ftp-data -d $OLOFGREN $HI -j ACCEPT

# Normal ftp out from Sesam and Nemesis (proxy doesn't support passive ftp)
# Sesam is restricted to use ftp to Fatburen only, externaly
ipchains $ACTION login -p TCP -i $IF_IP -s $FATBUREN ftp-data -d $SESAM $HI -j ACCEPT
ipchains $ACTION login -p TCP -i $IF_IP -s $NET_ALL ftp-data -d $NEMESIS $HI -j ACCEPT
