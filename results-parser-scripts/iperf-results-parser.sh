#/bin/sh
# By Narunas Kapocius
# 2020 02 02
# Iperf3 results file parser script

#Variables
current_work_dir=`pwd`

#Read arguments
source_dir=$1
results_file=$2
parse_team=$3
if [ -z $source_dir ] || [ -z $results_file ] || [ -z $parse_team ]
then
  echo "Please provide source data directory, results file name to which write results, and if to use regex to parse teamed interfaces results"
  echo "./iperf-results-parser.sh source-data-dir results-file-name true"
  echo "Exiting.."
  exit
fi

cd "$source_dir"
echo -n  "$(ls > $current_work_dir/filesList.txt)"

files_array=`cat $current_work_dir/filesList.txt`

#clean results file
echo "" > $current_work_dir/$results_file

for file_name in $files_array
do
  if [ $parse_team == "true" ]
  then
    test_name=`echo "$file_name" | grep -Po "kw\d\w{4}\d_kw\d\w{4}\d_\w{8}-\d_\w{3}-\d{2,4}_\d-\d{8}-\d{6}"`
  else  
    test_name=`echo "$file_name" | grep -Po "kw\d\w{3}\d_kw\d\w{3}\d_\w{3}-\d{2,4}_\d-\d{8}-\d{6}"`
  fi
  results=`grep "0.00-180.00" $source_dir/$file_name | grep -Po "\d+ Mbits" | grep -Po "\d+"`
  results=`echo $results | tr '\n' ' '`
  printf "$test_name $results \\n" >> $current_work_dir/$results_file
done
