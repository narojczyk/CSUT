#!/bin/bash

printf "\n %-60s " "Preparing temporary directory on scratch"
# Prepare tmp_workdir name
if [ $debugMode -eq 1 ]; then
  tmp_workdir=`echo "dev_${hereANDnow}_${binary}_processing"`
else
  randMarker=${RANDOM}${RANDOM}
  tmp_workdir=`echo "${hereANDnow}_${binary}_processing_id${randMarker:0:5}"`
fi

# Create the tmp_workdir in designated scratch folder
if [ ! -d $SCRATCH/$tmp_workdir ]; then
  mkdir $SCRATCH/$tmp_workdir
  if [ $? -eq 0 ]; then
    printf " [ %s ]\n" $G_done
  else
    printf " [ %s ]\n" $R_failed
  fi
else
  printf " [ %s ]\n" $G_found
  if [ $debugMode -ne 1 ]; then
    printf " [ %s ] temporary directory exists\n" $R_err
    echo " This should not happend while debugMode=$debugMode (-ne 1)"
    exit 1
  fi
fi

# Change to working directory
scratchWorkDir=$SCRATCH/$tmp_workdir
cd $scratchWorkDir
printf "\n * working in: %s\n" ${scratchWorkDir/*$USER/"~"}

return 0
