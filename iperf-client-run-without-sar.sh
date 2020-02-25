#!/bin/sh
# By Narunas Kapocius
# 2020 02 25
# Iperf3 client run without sar logging

# Read arguments
interface_ip=$1
server_ip=$2
iperf_server_port=$3
test_name=$4
mss=$5
iperf_client_port=$6
if [ -z $interface_ip ] || [ -z $server_ip ] || [ -z $iperf_server_port ] || [ -z $test_name ] || [ -z $mss ] || [ -z $iperf_client_port ]
then
  echo "Please provide interface_ip, server_ip, server_port, test_name, tcp_segment_size, client_port parameters. Example"
  echo "./iperf-client-run.sh 192.168.2.2 192.168.2.1 50002 first_test 88 50003"
  echo "Exiting.."
  exit
fi

# Variables
todays_date=`date +%Y%m%d-%H%M%S`
host=`hostname -f`

iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
iperf_results_file_name=$host-$test_name-$todays_date-iperf-client.results

idle_timer_before_measurement=60
performance_measurement_timer=180
idle_timer_after_measurement=60
iperf_loop_counter=0
max_iperf_client_retries=15

# Script
echo "Starting CNI/Network performance measurement run. Client side"
echo $todays_date
echo $host

echo "going to sleep for $idle_timer_before_measurement seconds"
sleep $idle_timer_before_measurement

# Iperf3 logging part
echo "Starting iperf3 client"
echo "iperf3 results are stored in $iperf_results_dir/$iperf_results_file_name"
until nc -v -z $server_ip $iperf_server_port
do
  echo "waiting for iperf server to come up"
  sleep 1
  if [ $iperf_loop_counter -eq $max_iperf_client_retries ]
  then
    echo "Could not connect to iperf sever even after $iperf_loop_counter retries. Aborting.."
    exit
  fi
  iperf_loop_counter=$((iperf_loop_counter+1))
  echo $iperf_loop_counter
done

#start iperf client
iperf3 -c $server_ip -B $interface_ip --logfile $iperf_results_dir/$iperf_results_file_name -t $performance_measurement_timer -p $iperf_server_port --set-mss $mss --cport $iperf_client_port
echo "going to sleep for $performance_measurement_timer seconds"
#sleep $performance_measurement_timer

# Kill iper3 client
echo "killing iperf3 client which PID is: $(/usr/sbin/pidof iperf3)"
if [ -n $(/usr/sbin/pidof iperf3) ]
then
  kill -9 $(/usr/sbin/pidof iperf3)
else
  echo "there is no such a process as iperf3"
fi

echo "going to sleep for $idle_timer_after_measurement seconds"
sleep $idle_timer_after_measurement

sleep 5
# Finish script run
echo "This run results can be found:"
echo "    sar results: $sar_results_dir/$sar_results_file_name"
echo "    iperf3 results: $iperf_results_dir/$iperf_results_file_name"
echo "Exiting.."
