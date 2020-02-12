#!/bin/sh
# By Narunas Kapocius
# 2020 01 05
# Iperf3 client run with sar logging script

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

sar_results_dir="/tmp/phys-tcp-throughput-test/sar-results"
sar_results_file_name=$host-$test_name-$todays_date-iperfserver-sar.results

sar_logs_dir="/tmp/phys-tcp-throughput-test/sar-logs"
sar_logs_file_name=$host-$test_name-$todays_date-iperfserver-sar.out

iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
iperf_results_file_name=$host-$test_name-$todays_date-iperfserver-iperf.results

idle_timer_before_measurement=5
performance_measurement_timer=180
idle_timer_after_measurement=60
sar_timer=$((idle_timer_before_measurement+performance_measurement_timer+idle_timer_after_measurement))

# Script
echo "Starting CNI/Network performance measurement run"
echo $todays_date
echo $host

# Sar logging part
nohup sar -A 1 $sar_timer -o $sar_results_dir/$sar_results_file_name > $sar_logs_dir/$sar_logs_file_name 2>&1 &
echo "sar results are stored in $sar_results_dir/$sar_results_file_name"
echo "sar run log is stored in $sar_logs_dir/$host-$todays_date-iperfserver-sar.out"

echo "going to sleep for $idle_timer_before_measurement seconds"
sleep $idle_timer_before_measurement

# Iperf3 logging part
echo "Starting iperf3 server"
echo "iperf3 results are stored in $iperf_results_dir/$iperf_results_file_name"
iperf3 -s -i $interface_ip -D --logfile $iperf_results_dir/$iperf_results_file_name -p $server_port

echo "going to sleep for $performance_measurement_timer seconds"
sleep $performance_measurement_timer

# Kill iper3 server
echo "killing iperf3 server which PID is: $(/usr/sbin/pidof iperf3)"
if [ -n $(/usr/sbin/pidof iperf3) ]
then
  kill -9 $(/usr/sbin/pidof iperf3)
else
  echo "there is no such a process as iperf3"
fi

echo "going to sleep for $idle_timer_after_measurement seconds"
sleep $idle_timer_after_measurement

# Kill sar 
echo "killing sar process which PID is: $(/usr/sbin/pidof sar)"
if [ -n $(/usr/sbin/pidof sar) ]
then
  kill -9 $(/usr/sbin/pidof sar)
else
  echo "there is no such a process as sar"
fi

sleep 5
# Finish script run
echo "This run results can be found:"
echo "    sar results: $sar_results_dir/$sar_results_file_name"
echo "    iperf3 results: $iperf_results_dir/$iperf_results_file_name"
echo "Exiting.."

