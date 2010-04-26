#!/bin/sh
#
# Login and logout access
#
# Passive FTP (out), SSH and Telnet.
#

echo "fwrules.login"

# Logging
ipchains -A input -p TCP -i $IF_IP -y -d $IP ssh -l
ipchains -A input -p TCP -i $IF_IP -y -d $IP ftp -j REJECT -l
ipchains -A input -p TCP -i $IF_IP -y -d $IP telnet -j REJECT -l

# LOCAL input in
ipchains -A input -p TCP -i $IF_IP -s $HADES $HI -d $IP ssh -j ACCEPT
ipchains -A input -p TCP -i $IF_IP ! -y -s $HADES ssh -d $IP $HI -j ACCEPT

ipchains -A input -p TCP -i $IF_IP -s $TKARLSSON2 $HI -d $IP ssh -j ACCEPT
ipchains -A input -p TCP -i $IF_IP ! -y -s $TKARLSSON2 ssh -d $IP $HI -j ACCEPT

ipchains -A input -p TCP -i $IF_IP -s $ZEUS $HI -d $IP ssh -j ACCEPT
ipchains -A input -p TCP -i $IF_IP ! -y -s $ZEUS ssh -d $IP $HI -j ACCEPT

ipchains -A input -p TCP -i $IF_IP -s $NEMESIS $HI -d $IP ssh -j ACCEPT
ipchains -A input -p TCP -i $IF_IP ! -y -s $NEMESIS ssh -d $IP $HI -j ACCEPT

#ipchains -A input -p TCP -i $IF_IP -s $ROBUR $HI -d $IP ssh -j ACCEPT
#ipchains -A input -p TCP -i $IF_IP ! -y -s $ROBUR ssh -d $IP $HI -j ACCEPT

# Outgoing (returning packets) ftp, ssh and telnet
ipchains -A input -p TCP -i $IF_IP ! -y -s $NET_ALL ftp:telnet -d $IP $HI -j ACCEPT

# Data for ftp (using proxy)
ipchains -A input -p TCP -i $IF_IP -s $NET_ALL ftp-data -d $IP $HI -j ACCEPT

# LOCAL input out

# Logging
ipchains -A input -p TCP -i $IF_IP2 -y -s $NET_IP2 -d $NET_ALL ftp:telnet -l

# ssh and telnet
ipchains -A input -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $NET_B ssh:telnet -j ACCEPT

# ftp (using proxy)
ipchains -A input -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $IP2 ftp-data:ftp -j ACCEPT
ipchains -A input -p TCP -i $IF_IP2 -s $NET_IP2 $HI -d $IP2 $HI -j ACCEPT

# restrict the ftp-proxy out
#ipchains -A output -p TCP -i $IF_IP -d $RHEA ftp -j ACCEPT
ipchains -A output -p TCP -i $IF_IP -d $ZEUS ftp -j ACCEPT
ipchains -A output -p TCP -i $IF_IP -d $FATBUREN ftp -j ACCEPT
ipchains -A output -p TCP -i $IF_IP -d $NET_ALL ftp -j REJECT
