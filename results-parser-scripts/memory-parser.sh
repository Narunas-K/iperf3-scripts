#/bin/sh
# By Narunas Kapocius
# 2020 02 16
# Sar output binary kbused file interrupts parameter parser script

#Variables
kbused_store_dir=`pwd`

#Read arguments
source_dir=$1
kbused_store_dir=$2
kbused_file=$3
parse_regex=$4

if [ -z $source_dir ] || [ -z $kbused_store_dir ] || [ -z $kbused_file ] || [ -z $parse_regex ]
then
  echo "Please provide source data directory, kbused store directory, file name to which write kbused and which regex to use for file names parser"
  echo "./interrupts-parser.sh source-data-dir kbused-store-dir kbused-file-name team|kube|phys"
  echo "Exiting.."
  exit
fi

#clean working files to prevent kbused overlap
echo "" > $kbused_store_dir/filesList.txt
echo "" > $kbused_store_dir/$kbused_file

#write sar kbused file list to fileList.txt
echo -n  "$(ls $source_dir > $kbused_store_dir/filesList.txt)"

files_array=`cat $kbused_store_dir/filesList.txt`

for file_name in $files_array
do
  if [ $parse_regex == "team" ]
  then
    test_name=`echo "$file_name" | grep -Po "kw\d\w{4}\d_kw\d\w{4}\d_\w{8}-\d_\w{3}-\d{2,4}_\d"`
  elif [ $parse_regex == "kube" ]
  then
    test_name=`echo "$file_name" | grep -Po "kube-worker\d-\w{3}-\d{2,4}_\d-\d{8}-\d{6}"`
  else
    test_name=`echo "$file_name" | grep -Po "kw\d\w{3}\d_kw\d\w{3}\d_\w{3}-\d{2,4}_\d-\d{8}-\d{6}"`
  fi
  echo "Processing $test_name"
  #parse kbcached memory and write to kbused to file
  kbused=`sadf -p $source_dir/$file_name -- -r  | grep -Po "kbmemused.\d*" | grep -Po "\d*"`
  kbbuffers=`sadf -p $source_dir/$file_name -- -r  | grep -Po "kbbuffers.\d*" | grep -Po "\d*"`
  kbcached=`sadf -p $source_dir/$file_name -- -r  | grep -Po "kbcached.\d*" | grep -Po "\d*"`
  printf "$kbused\\n" > $kbused_store_dir/$test_name\_kbused.txt
  printf "$kbbuffers\\n" > $kbused_store_dir/$test_name\_kbbuffers.txt
  printf "$kbcached\\n" > $kbused_store_dir/$test_name\_kbcached.txt
  kbused_value_array=`cat $kbused_store_dir/$test_name\_kbused.txt`
  kbbuffers_value_array=`cat $kbused_store_dir/$test_name\_kbbuffers.txt`
  kbcached_value_array=`cat $kbused_store_dir/$test_name\_kbcached.txt`
  idle_kbcommit_counter=0
  work_kbcommit_counter=0
  counter_idle=0
  counter_work=0
  for index in {1..240} #300
  do
    kbused_temp=`sed -n -e "$index"p $kbused_store_dir/$test_name\_kbused.txt`
    kbbuffers_temp=`sed -n -e "$index"p $kbused_store_dir/$test_name\_kbbuffers.txt`
    kbcached_temp=`sed -n -e "$index"p $kbused_store_dir/$test_name\_kbcached.txt`
    if [ $index -gt 190 ] #250
    then
      idle_kbcommit_counter=`lua -e "print($idle_kbcommit_counter+$kbused_temp-$kbbuffers_temp-$kbcached_temp)"`
    elif [ $index -gt 70 ] && [ $index -lt 171 ]
    then
      work_kbcommit_counter=`lua -e "print($work_kbcommit_counter+$kbused_temp-$kbbuffers_temp-$kbcached_temp)"`
    fi
    
  done
  idle_kbcommit_counter_avg=`lua -e "print($idle_kbcommit_counter/50)"`
  work_kbcommit_counter_avg=`lua -e "print($work_kbcommit_counter/100)"` 
  printf "$test_name $idle_kbcommit_counter_avg $work_kbcommit_counter_avg \\n" >> $kbused_store_dir/$kbused_file
done
