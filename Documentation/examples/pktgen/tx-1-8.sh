#!/bin/bash
#
# Contributed by: radim.roska@gmail.com
#
# 1 interfaces, 8 cores
#
# for setting CPU affinity either use https://github.com/jelaas/eth-affinity/tree/22f0707e980a4d74f34ab9775bc07fadd0dda9d7
# or script supplied by intel with its ixgbe driver...

grep -q pktgen /proc/modules | modprobe pktgen

#ctrl+c stops generation but still shows result
trap bashtrap INT

USAGE="$0 -c <#cpus> -e <ethX> -s <#bytes> -d <ns> -n <#> -r <pps>"

CPUS=8
DEVICE=eth3
MIN=0
MAX=0
N=100000000
SIZE=1512
myDELAY=0

#only in case you want to run oprofile during test...must be configured and running
PROFILE=0

OPROFILE_REPORT=/root/setups/opreport_`date +"%H:%M:%S-%d-%m"`.log

while getopts "c:e:d:s:n:hpr:" opts ; do
    case $opts in
	p) PROFILE=1;;
	c) CPUS=$OPTARG;;
        e) DEVICE=eth$OPTARG;;
        s) SIZE=$OPTARG;;
	r) PPKS=$OPTARG;;
	d) myDELAY=$OPTARG;;
	n) N=$OPTARG;;
        h) echo -e $USAGE;exit 1;;
        ?) echo -e $USAGE;
        exit 1;;
    esac
done


#================================================================================================


function print_config() {
	echo "--------------------------------------------------------"
	echo `date`
	echo "N=$N, CPUS=$CPUS, DEV=$DEVICE, pkt_size=$SIZE"
	echo "--------------------------------------------------------"
}

function pgset() {
	local result
	echo $1 > $PGDEV
}

function bashtrap() {

	echo "CTRL+C Detected !...stop generation"
	pgset "stop"

}
function print_result() {

	echo "--------------"
	echo "Results for $1"
	grep -h pps /proc/net/pktgen/${1}*

	SUM=0
	for a in `grep -h pps /proc/net/pktgen/${1}* | cut -d"p" -f1 `;do 
		SUM=$((SUM+a))
	done

	echo "pps = " $SUM
	SUM=0
	for a in `grep -h pkts-sofar /proc/net/pktgen/${1}* | awk '{print $2}'`;do 
		SUM=$((SUM+a))
	done
	echo "packets sent = " $SUM

	echo `cat /proc/net/pktgen/eth* | grep Mb  | awk '{s+=$2} END {print s}'` Mbps
	
}

#================================================================================================


PKTS=$((N / CPUS))
RATEP=$((PPS / CPUS))
CLONE_SKB=" clone_skb 1000000"
PKT_SIZE=" pkt_size $SIZE "
COUNT=" count $PKTS"

# delay 0 means maximum speed.
if [[ -z $PPKS ]]; then
        DELAY="delay $myDELAY"
else
        DELAY="ratep $PPKS"
fi

print_config

for pgdev in /proc/net/pktgen/kpktgend_*
do
	PGDEV=$pgdev
	# echo "Removing all devices"
	pgset "rem_device_all"
done

for (( processor=0; processor <= $CPUS -1; processor++ ))
do
	PGDEV=/proc/net/pktgen/kpktgend_$processor

	echo "Adding $DEVICE"
	pgset "add_device $DEVICE@$processor "
	PGDEV=/proc/net/pktgen/$DEVICE@$processor


	echo " Configuring $PGDEV"
	pgset "$COUNT"
	pgset "flag QUEUE_MAP_CPU"
	pgset "$CLONE_SKB"
	pgset "$PKT_SIZE"
	pgset "$DELAY"

#	pgset "ratep $RATEP"
#	pgset "dst 10.11.11.11"
#	pgset "dst_mac $MAC"

#----------------------------------
#single flow
#----------------------------------
	pgset "dst 10.0.0.99" 
	#pgset "dst 10.0.0.5" 


#----------------------------------
#multiple src flow - IP
#----------------------------------
	pgset "flag IPSRC_RND"
	pgset "src_min 10.0.0.1"            #Set the minimum (or only) source IP.
	pgset "src_max 10.0.0.254"          #Set the maximum source IP.


#----------------------------------
#multiple dest flow - IP
#----------------------------------
	#pgset " flag IPDST_RND"
	# pgset "dst_min 10.0.5.1"            #Same as dst
	# pgset "dst_max 10.0.5.254"          #Set the maximum destination IP.
	


#----------------------------------
#dest ports
#----------------------------------
	pgset "flag UDPDST_RND"
	#pgset "config 1"
	PORT=$((10000 + processor + RANDOM%10000))
	pgset "udp_dst_min $PORT"
	pgset "udp_dst_max $PORT"


	#my eth3 mac
	#pgset "src_mac 00:25:90:0e:59:39" 
	#test
	pgset "dst_mac  00:00:00:00:00:00"
	#pgset "dst_mac  00:25:90:0e:59:57"

done
# Time to run
PGDEV=/proc/net/pktgen/pgctrl
echo "Running . . . ctrl^C to stop "

#PROFILE? -> make sure oprofiler is setup correctly
if [[ "$PROFILE" -eq 1 ]];then
	opcontrol --reset
	opcontrol --start
fi

pgset "start"
echo "Done"


#PROFILE? -> make sure oprofiler is setup correctly
if [[ "$PROFILE" -eq 1 ]];then
	opcontrol --stop
	print_config > $OPROFILE_REPORT
	opreport  -l -p=/lib/modules/2.6.38.5/kernel/net/core/,/lib/modules/2.6.38.5/kernel/drivers/net/ixgbe/ >> $OPROFILE_REPORT
	echo "======================GEN RESULTS=========================" >> $OPROFILE_REPORT
	print_result ${DEVICE} >> $OPROFILE_REPORT
fi

print_result ${DEVICE}

