#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

if [ ! $1 ]; then
    printf " [%s] %s: Missing mandatory parameter.\n" $iam $R_err
    exit 1;
fi

id=$1
# Test is id does not point to empty element
if [ ${#Tdset[$i]} -eq 0 ]; then
    printf " [%s] %s: ID %d points to empty array element.\n" $iam $R_err $id
    exit 1;
fi


# For all the files belonging to a given data set ...
data_set=(`ls -1 $DATAREPO/$subrepository/${Tdset[$id]}*`)
data_setN=${#data_set[@]}

# Generate base name for the results files
res_base_name=${data_set[0]##*/} #`echo ${data_set[0]} | sed 's;^.*/;;' |sed 's/_[0-9][0-9][0-9]\....$//'`
res_base_name=${res_base_name%_[0-9][0-9][0-9].*}
printf "  %s\n" $res_base_name

# ... link archives and extract simulation data files
j=0
anyErroros=0
while [ $j -lt $data_setN ]; do
  current_data=${data_set[$j]}
  archive=`echo $current_data | sed 's;^.*/;;'`
  logExtract="${archive}.extr.log"

  ln -s $current_data  2>> $logFile

  tar -xjf $archive \
    --wildcards '*dat' \
    --wildcards '*part*' \
    --wildcards '[md]*ini' 2> $logExtract

  if [ $? -ne 0 ]; then
    (( anyErroros++ ))
  fi

  (( j++ ))

  progress_bar=`$FPB $j $data_setN $pbLength`
  progress_msg=`printf "$msgItemFormat" "extracting simulation archives" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done
echo

# Check for error logs
if [ $anyErroros -ne 0 ]; then
  printf " [%s] %s: Errors during extraction (%d).\n"\
    $iam $R_err $anyErroros
  unset elogs
  j=0
  elogs=(`ls -1 *extr.log`)
  while [ $j -lt ${#elogs[@]} ]; do
    elog=${elogs[$j]} 
    echo $elog >> $logFile
    cat $elog >> $logFile
    rm $elog
    (( j++ ))
  done
fi 
rm *extr.log 2>> $logFile


    