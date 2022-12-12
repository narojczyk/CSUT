#!/bin/bash

# common
## logging
logDate=`eval date +%F`
logName=`echo ${SNAME} | sed 's;^.*/;;'`
logUniqueSuffix=`date +%s`
logFileName="${logName}_${logDate}_${logUniqueSuffix}.log"

## lock file to indicate work in the given directory
lockFile="${SNAME}.lock"

# claim_results constants
averageJobStatsLog="average_exec_time_${dateTime}.csv"
timeFileName="job_execution_times.csv"
stepFileName="job_mc_steps.csv"
JBexecTime="JOB_exec_time.txt"
overwrite_target="no"
overwrite_all_targets="no"

# retrive_partial_results constants
chksumFile="JOB_salvage_checksum.sha1"
salvageListFile="JOB_salvage_list.txt"
