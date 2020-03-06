#!/bin/sh
# By Narunas Kapocius
# 2020 03 06
#  sar logging script

# Read arguments
test_name=$1
if [ -z $test_name ]
then
  echo "Please provide server_name, server_port, test_name, tcp_segment_size, client_port and serveri service yaml file path as a parameters. Example"
  echo "./iperf-client-run.sh iperf_server_1 50002 first_test 88 50003 server-service-1.yaml"
  echo "Exiting.."
  exit
fi

# Variables
todays_date=`date +%Y%m%d-%H%M%S`
host=`hostname -f`
sar_results_dir="/tmp/phys-tcp-throughput-test/sar-results"
sar_results_file_name=$host-$test_name-$todays_date-iperf-client-sar.results

sar_logs_dir="/tmp/phys-tcp-throughput-test/sar-logs"
sar_logs_file_name=$host-$test_name-$todays_date-iperf-client-sar.out

idle_timer_before_measurement=5
performance_measurement_timer=15
idle_timer_after_measurement=10
sar_timer=$((idle_timer_before_measurement+performance_measurement_timer+idle_timer_after_measurement))
iperf_loop_counter=0
max_iperf_client_retries=15

# Script
echo "Starting CNI/Network performance measurement run. K8s master side"
echo $todays_date
echo $host

# Sar logging part
nohup sar -A 1 $sar_timer -o $sar_results_dir/$sar_results_file_name > $sar_logs_dir/$sar_logs_file_name 2>&1 &
echo "sar results are stored in $sar_results_dir/$sar_results_file_name"
echo "sar run log is stored in $sar_logs_dir/$sar_logs_file_name"

echo "going to sleep for $idle_timer_before_measurement seconds"
sleep $idle_timer_before_measurement

sleep $idle_timer_after_measurement

# Kill sar 
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
echo "    sar results: $sar_results_dir/$sar_results_file_name"
echo "Exiting.."
