#/bin/sh
# By Narunas Kapocius
# 2020 02 16
# Sar output binary results file interrupts parameter parser script

#Variables
results_store_dir=`pwd`
res_grp_file_name_ptrn=`echo "mss-88 mss-216 mss-472 mss-984 mss1-460"`

#Read arguments
source_dir=$1
results_store_dir=$2
results_file=$3

if [ -z $source_dir ] || [ -z $results_store_dir ] || [ -z $results_file ]
then
  echo "Please provide source data directory and results file name to which write results"
  echo "./interrupts-parser.sh source-data-dir results-store-dir results-file-name"
  echo "Exiting.."
  exit
fi

#clean working files to prevent results overlap
echo "" > $results_store_dir/filesList.txt
echo "" > $results_store_dir/$results_file

#write sar results file list to fileList.txt
echo -n  "$(ls $source_dir > $results_store_dir/filesList.txt)"

files_array=`cat $results_store_dir/filesList.txt`

for file_name in $files_array
do
  test_name=`echo "$file_name" | grep -Po "kw\d\w{3}\d_kw\d\w{3}\d_\w{3}-\d{2,4}_\d-\d{8}-\d{6}"`
  echo "Processing $test_name"
  results=`sadf -p $source_dir/$file_name -- -I SUM | grep -Po "\d+\.\d+"`
  printf "$results\\n" > $results_store_dir/$test_name\_interrupts_per_second.txt
  interrupt_value_array=`cat $results_store_dir/$test_name\_interrupts_per_second.txt`
  counter=0
  idle_interrupt_counter=0
  work_interrupt_counter=0
  for value in $interrupt_value_array
  do
    if [ $counter -lt 60 ] || [ $counter -gt 239 ]
    then
      idle_interrupt_counter=`lua -e "print($idle_interrupt_counter+$value)"`
    else
      work_interrupt_counter=`lua -e "print($work_interrupt_counter+$value)"`
    fi
    counter=$(($counter+1))
  done
  idle_interrupt_counter_avg=`lua -e "print($idle_interrupt_counter/120)"`
  work_interrupt_counter_avg=`lua -e "print($work_interrupt_counter/180)"` 
  printf "$test_name $idle_interrupt_counter_avg $work_interrupt_counter_avg \\n" >> $results_store_dir/$results_file
done
