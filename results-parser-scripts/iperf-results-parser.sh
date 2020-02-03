#/bin/sh
# By Narunas Kapocius
# 2020 01 05
# Iperf3 client run with sar logging script

#Variables
current_work_dir=`pwd`

#Read arguments
source_dir=$1
results_file=$2
if [ -z $source_dir ] || [ -z $results_file ]
then
  echo "Please provide source data directory and results file name to which write results"
  echo "./iperf-results-parser.sh source-data-dir results-file-name"
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
  test_name=`echo "$file_name" | grep -Po "kw\d\w{3}\d_kw\d\w{3}\d_\d-\d{8}-\d{6}"`
  results=`grep "0.00-300.00" $file_name | grep -Po "\d+ Mbits" | grep -Po "\d+"`
  results=`echo $results | tr '\n' ' '`
  printf "$test_name $results \\n" >> $current_work_dir/$results_file
done
