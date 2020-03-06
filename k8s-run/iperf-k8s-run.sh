#!/bin/sh
# By Narunas Kapocius
# 2020 03 06
# Iperf3 client and server  run for K8s with sar logging script

# Read arguments
server_name=$1
iperf_server_port=$2
test_name=$3
mss=$4
iperf_client_port=$5
iperf_service_file=$6
iperf_server_file=$7
iperf_client_file=$8
server_pod_name=$9
client_pod_name=${10}
instance_name=${11}
if [ -z $server_name ] || [ -z $iperf_server_port ] || [ -z $test_name ] || [ -z $mss ] || [ -z $iperf_client_port ] || [ -z $iperf_service_file ] || [ -z $iperf_server_file ] || [ -z $iperf_client_file ] || [ -z $server_pod_name ] || [ -z $client_pod_name ] || [ -z $instance_name ]
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

iperf_results_dir="/tmp/phys-tcp-throughput-test/iperf-results"
iperf_results_file_name=$host-$test_name-$todays_date-iperf-client.results

idle_timer_before_measurement=60
performance_measurement_timer=180
idle_timer_after_measurement=60
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

# Iperf3 logging part
echo "Creating iperf server service"
kubectl apply -f $iperf_service_file
echo "Starting iperf3 server and client pods"
kubectl apply -f $iperf_server_file
kubectl apply -f $iperf_client_file

echo "iperf3 results are stored in $iperf_results_dir/$iperf_results_file_name"
until [ $(kubectl get pod $server_pod_name -o jsonpath='{.status.containerStatuses[0].ready}') = "true" ] &&  [ $(kubectl get pod $client_pod_name -o jsonpath='{.status.containerStatuses[0].ready}') = "true" ]
do
  echo "waiting for iperf server to come up"
  sleep 1
  if [ $iperf_loop_counter -eq $max_iperf_client_retries ]
  then
    echo "Could not connect to iperf sever even after $iperf_loop_counter retries. Aborting.."
    kill -9 $(/usr/sbin/pidof sar)
    exit
  fi
  iperf_loop_counter=$((iperf_loop_counter+1))
  echo $iperf_loop_counter
done

echo $client_pod_name
echo $server_pod_name
#start iperf client
echo "kubectl exec -it $client_pod_name -- iperf3 -c $server_pod_name -t $performance_measurement_timer -p $iperf_server_port --set-mss $mss --cport $iperf_client_port"
kubectl exec -it $client_pod_name -- iperf3 -c $server_pod_name -t $performance_measurement_timer -p $iperf_server_port --set-mss $mss --cport $iperf_client_port > $iperf_results_dir/$iperf_results_file_name 2>&1 &
echo "going to sleep for $performance_measurement_timer seconds"
#sleep $performance_measurement_timer
sleep $performance_measurement_timer
# Delete server and client pods
echo "Deleting client and server pods"
echo "$(kubectl get pods -l instance=$instance_name | grep -P -o "iperf3.{8}" | awk '/iperf3/ {print $1}')"
kubectl delete pod $(kubectl get pods -l instance=$instance_name | grep -P -o "iperf3.{8}" | awk '/iperf3/ {print $1}') &
echo "going to sleep for $idle_timer_after_measurement seconds"
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
echo "    iperf3 results: $iperf_results_dir/$iperf_results_file_name"
echo "Exiting.."

