#!/bin/sh
# By Narunas Kapocius
# 2020 01 05
# Iperf3 client run with sar logging script
# Read arguments
interface=$1
server_ip=$2
if [ -z $interface ]
then
  echo "Please provide interface parameter"
  echo "Exiting.."
  exit
elif [ -z $server_ip ]
then
  echo "Please provide server_ip parameter"
  echo "Exiting.."
  exit
fi

# Variables
todaysdate=`date +%Y%m%d-%H%M%S`
host=`hostname -f`
sar_results_dir="/tmp/phys-tcp-throughput-test/sar-results"
sar_logs_dir="/tmp/phys-tcp-throughput-test/sar-logs"
iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
# Script
echo "Starting CNI/Network performance measurement run. Client side"
echo $todaysdate
echo $host
# Sar logging par
nohup sar -A 1 480 -o $sar_results_dir/$host-$todaysdate-iperf-client-sar.results > $sar_logs_dir/$host-$todaysdate-iperf-client-sar.out 2>&1 &
echo "sar results are stored in $sar_results_dir/$host-$todaysdate-iperf-client-sar.results"
echo "sar run log is stored in $sar_logs_dir/$host-$todaysdate-iperf-client-sar.out"

echo "going to sleep for 90 seconds"
sleep 5

# Iperf3 logging part
echo "Starting iperf3 client"
echo "iperf3 results are stored in $iperf_results_dir/$host-$todaysdate-iperf-client.results"
iperf3 -c $server_ip -B $interface --logfile $iperf_results_dir/$host-$todaysdate-iperf-client.results

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
echo "    sar results: $sar_results_dir/$host-$todaysdate-iperf-client-sar.results"
echo "    iperf3 results: $iperf_results_dir/$host-$todaysdate-iperf-client.results"
echo "Exiting.."

