#!/bin/sh
# By Narunas Kapocius
# 2020 02 25
# Iperf3 server run without sar logging script

# Read arguments
interface_ip=$1
server_port=$2
test_name=$3
if [ -z $interface_ip ] || [ -z $server_port ] || [ -z $test_name ]
then
  echo "Please provide inteface and port parameters. Example:"
  echo "./iperf-server-run.sh enp3s0f0 50002 first_test"
  echo "Exiting.."
  exit
fi

# Variables
todays_date=`date +%Y%m%d-%H%M%S`
host=`hostname -f`

iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
iperf_results_file_name=$host-$test_name-$todays_date-iperfserver-iperf.results

idle_timer_before_measurement=60
performance_measurement_timer=185
idle_timer_after_measurement=60

# Script
echo "Starting CNI/Network performance measurement run"
echo $todays_date
echo $host

echo "going to sleep for $idle_timer_before_measurement seconds"
sleep $idle_timer_before_measurement

# Iperf3 logging part
echo "Starting iperf3 server"
echo "iperf3 results are stored in $iperf_results_dir/$iperf_results_file_name"
iperf3 -s -i $interface_ip -D --logfile $iperf_results_dir/$iperf_results_file_name -p $server_port

echo "going to sleep for $performance_measurement_timer seconds"
sleep $performance_measurement_timer

echo "going to sleep for $idle_timer_after_measurement seconds"
sleep $idle_timer_after_measurement

sleep 5
# Finish script run
echo "This run results can be found:"
echo "    sar results: $sar_results_dir/$sar_results_file_name"
echo "    iperf3 results: $iperf_results_dir/$iperf_results_file_name"
echo "Exiting.."
