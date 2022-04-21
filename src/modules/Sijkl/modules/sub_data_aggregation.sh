#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

# Get the array of all the different structure marker ('s') values present on workdir
svalues=(`ls -1 *s*.part00 | sed 's/^.*_s//' | sed 's/\.part00//'`)
dat_filesN=${#svalues[@]}

#This int is required while preparing a gnuplot script for Sij plots
last_s=`echo ${svalues[@]} | sed 's/^.*\ //' | sed 's/^0*//'`

j=0
while [ $j -lt $dat_filesN ]; do
  # Get current-structure-marker to select respective simulation files
  csm=${svalues[$j]}

  # Set file name for selected partial data
  bininput=`ls *s${csm}.part00 | sed 's/part00$/csv/'`
  fullinput=`ls *s${csm}.part00 | sed 's/\.part00$/_full\.csv/'`

  # elastic calculation data
  cat *s${csm}.part* | sed 's/#.*$//' > ${bininput}

  # full data
  cat *s${csm}.part* | sed 's/#//' > ${fullinput}

  (( j++ ))

  progress_bar=`$FPB $j $dat_filesN $pbLength`
  progress_msg=`printf "$msgItemFormat" "aggregating partial files" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done
echo

# Cache file names for later use
echo "lastBinInput=${bininput}" >> $cacheInfo
echo "lastFullInput=${fullinput}" >> $cacheInfo

# remove patrtial files after merging
rm *.part*