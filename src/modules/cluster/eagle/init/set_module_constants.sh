#!/bin/bash

# common
## logging
logDate=`eval date +%F`
logName=`echo ${SNAME} | sed 's;^.*/;;'`
logUniqueSuffix=`date +%s`
logFileName="${logName}_${logDate}_${logUniqueSuffix}.log"

# claim_results constants
averageJobStatsLog="average_exec_time_${dateTime}.csv"
overwrite_target="no"
overwrite_all_targets="no"
