#!/bin/sh
# Read arguments
interface=$1
if [ -z $interface ]
then
  echo "Please provide inteface parameter"
  echo "Exiting.."
  exit
fi

#
# Variables
todaysdate=`date +%Y%m%d-%H%M%S`
host=`hostname -f`
sar_results_dir="/tmp/phys-tcp-throughput-test/sar-results"
sar_logs_dir="/tmp/phys-tcp-throughput-test/sar-logs"
iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
# Script
echo "Starting CNI/Network performance measurement run"
echo $todaysdate
echo $host
# Sar logging par
nohup sar -A 1 480 -o $sar_results_dir/$host-$todaysdate-iperfserver-sar.results > $sar_logs_dir/$host-$todaysdate-iperfserver-sar.out 2>&1 &
echo "sar results are stored in $sar_results_dir/$host-$todaysdate-iperfserver-sar.results"
echo "sar run log is stored in $sar_logs_dir/$host-$todaysdate-iperfserver-sar.out"

echo "going to sleep for 90 seconds"
sleep 5

# Iperf3 logging part
echo "Starting iperf3 server"
echo "iperf3 results are stored in $iperf_results_dir/$host-$todaysdate-iperfserver-iperf.results"
iperf3 -s -i $interface -D --logfile $iperf_results_dir/$host-$todaysdate-iperfserver-iperf.results

echo "going to sleep for 300 seconds"
sleep 5

# kill iper3 server
echo "killing iperf3 server which PID is: $(pidof iperf3)"
if [ -n $(pidof iperf3) ]
then
  kill -9 $(pidof iperf3)
else
  echo "there is no such a process as iperf3"
fi

echo "going to sleep for 90 seconds"
sleep 5

# kill sar 
echo "killing sar process which PID is: $(pidof sar)"
if [ -n $(pidof sar) ]
then
  kill -9 $(pidof sar)
else
  echo "there is no such a process as sar"
fi

sleep 5
# Finish script run
echo "This run results can be found:"
echo "    sar results: $sar_results_dir/$host-$todaysdate-iperfserver-sar.results"
echo "    iperf3 results: $iperf_results_dir/$host-$todaysdate-iperfserver-iperf.results"
echo "Exiting.."

