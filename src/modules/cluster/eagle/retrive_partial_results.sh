#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
SNAME=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="${HOME}/main/work/dev/scripts/CSUT/src"
CSUT_CORE_INC="${CSUT_CORE}/common"
CORE="${CSUT_CORE}/modules/cluster/eagle"

###############################################################################

# Surce top-level utility variables
source ${CSUT_CORE_INC}/settings/constants.sh

# Surce top-level IO functions
source ${CSUT_CORE_INC}/IOfunctions/basic_output.sh

# Surce top-level SQL functions
source ${CSUT_CORE_INC}/SQLfunctions/SQL_basics.sh

# Script variables
useSQL=0
logfile=`echo ${SNAME} | sed 's;^.*/;;'`
logmarker=`eval date +%F`
logsuffix=`date +%s`
chksumFile="JOB_salvage_checksum.sha1"
sawFile="${SNAME}.lock"
FPBlength=25

while getopts sv argv; do
  case "${argv}" in
    s) useSQL=1 ;;
    v) VERBOSE=0 ;;
  esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Retrive partial results from terminated simulations${_RST}"

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

log="${JOBSTARTER}/${logfile}_${logmarker}_${logsuffix}.log"

# When enabled, test if SQL database is availiable
SQLtestHostname

# Test if DB is present
SQLDBpresent

eval "echo \" Log info to $log\" | sed 's;${JOBSTARTER};JOBSTARTER;'"

# Get list of terminated jobs
if [ ${useSQL} -eq 1 ]; then
  TJlist=(`${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'terminated';"`);
else
  # Get the list of jobs to retrive based on the scratch dir inspection
  if [ ! $1 ]; then 
    echo " ${_RED}Pass the list of jobs to retrive as command line arguments${_RST}"
    exit 1
  else
    TJlist=( "$@" )
  fi
fi
TJCount=${#TJlist[@]}

if [ $TJCount -eq 0 ]; then
  echo " No jobs candidates found."
  exit 0
fi

# Set initial control array for printing progress bar (see IOfunctions)
dpctrl=( 0 0 66 ' ' )
printWidth=${#TJCount}

cd $JOBSTARTER; 

i=0; 
while [ $i -lt ${TJCount} ]; do

  job=${TJlist[$i]}
  inputFound=0;
  
  cd $JOBSTARTER; 
  printf "\n [%${printWidth}d/${TJCount}] %s\n" $(expr $i + 1) $job
  echo $job >> $log

  if [ ! -f ${job}/${sawFile} ]; then
    date > ${job}/${sawFile} 
    cd $job
 
    if [ ${useSQL} -eq 1 ]; then
      jobID=`${SQL} ${SQLDB} "SELECT JOBID FROM JOBS WHERE JOBDIR LIKE '${job}';"`
    else
      # get job's old ID based on files from previous run
      jobID=`ls -1 JOB_[0-9]*[rt] 2>/dev/null | head -n 1 | sed -e 's/JOB_//' -e 's/\..*//'`
    fi

    if [ ! -n "${jobID}" ]; then
      # if that fails check scratch dir based on job dir name
      unset scratchJobs
      scratchJobs=(`ls -1d ${SCRATCH}/*${job}*`);
      scratchJobsN=${#scratchJobs[@]}
  
      if [ $scratchJobsN -eq 0 ]; then
        # No imput was found
        echo " Previous input for this job not found"
        inputFound=0
      elif [ $scratchJobsN -eq 1 ]; then
        # One previous run was found (optimal case)
        inputFound=1
        # extract job ID from the scrach job directory name
        scratchJob=`echo ${scratchJobs[0]} | sed 's;^.*/;;' `
        jobID=`echo ${scratchJob} | eval "sed -e 's/_${job}//' | sed 's/[aA-zZ]//g'"`
      elif [ $scratchJobsN -gt 1 ]; then
        # Multiple old runs found (scratch needs cleaning)
        echo " Multiple old input found on SCRATCH(${scratchJobsN}):"
        inputFound=1
        q=0; while [ $q -lt ${scratchJobsN} ]; do
          printf " %d %s\n" $q ${scratchJobs[$q]} | sed 's;^.*/;;'
          (( q++ ))
        done
        unset q
        # TODO implement read user slection and continue
        exit 1
      else
        # this should never happen
        echo " Things took a wrong turn"
        exit 1
      fi
    else
      # Find job directory on scratch using job ID (no need to check multiple hits
      # queueing system will not assign one id to multiple jobs)
      scratchJob=`ls -1d ${SCRATCH}/*${jobID}*  2>/dev/null | sed 's;^.*/;;'`
      if [ -n "${scratchJob}" ]; then
        inputFound=1
      fi
    fi

    if [ $inputFound -eq 1 ]; then
      # Get list of files in current job directory to preserve
      # Consecutive masking by *.* avoids selection of binaries, 
      # hence overwritting links wit regular files
      preserveFiles=(`ls -1 *.* | grep -v -e JOB_ -e job.sh -e job2.sh -e configure.inf`)
      preserveFilesN=${#preserveFiles[@]}
    
      # Get list of files in scratch job directory (source of salvage) 
      ls -l ${SCRATCH}/${scratchJob}/*.* 2>/dev/null |\
        grep -v -e JOB_ -e sha1 -e ^-rwxr -e "\ 0\ " > JOB_salvage_list.txt
      # remove files already present from beeing overwritten 
      q=0; while [ $q -lt ${preserveFilesN} ]; do
        eval "sed -i '/${preserveFiles[$q]}/d' JOB_salvage_list.txt"
        (( q++ ))
      done
      unset q
    
      # Read list of files to copy from scratch
      salvageList=(`cat JOB_salvage_list.txt | sed 's;^.*/;;'`)
      salvageListN=${#salvageList[@]}
      if [ $salvageListN -ne 0 ]; then
        cd ${SCRATCH}/${scratchJob}
        sha1sum ${salvageList[@]} > ${chksumFile}
        cd - >/dev/null
        cp ${SCRATCH}/${scratchJob}/${chksumFile} .

        printFormBar=" copying data from SCRATCH (%${#salvageListN}d/${salvageListN})"
        dpctrl[1]=${salvageListN}
        q=0; while [ $q -lt ${salvageListN} ]; do
          cp ${SCRATCH}/${scratchJob}/${salvageList[$q]} .
          (( q++ ))
          dpctrl[0]=${i}
          dpctrl[3]=`printf "${printFormBar}" ${q}`
          display_progres
        done
        unset q

        # Verify that files were copied correctly
        printf "\n Verify copied data "
        sha1sum -c ${chksumFile} --quiet >> $log 2>&1
        shaEC=$?
        if [ $shaEC -eq 0 ]; then
          # Flag job as reconfigured
          if [ ${useSQL} -ne 0 ]; then
            sqlUpdateStatus=5
            sqlWatchDog=0
            while [ ${sqlUpdateStatus} -ne 0 ] && [ $sqlWatchDog -lt $WD_LIMIT_SEC ]; do
              ${SQL} ${SQLDB} "UPDATE ${SQLTABLE} SET STATUS='reconfigured' WHERE JOBDIR LIKE '${job}' ;"
              sqlUpdateStatus=$?
              if [ $sqlUpdateStatus -ne 0 ]; then
                (( sqlWatchDog++ ))
                sleep 1
              fi
            done
          else
            echo " ${job} RECONFIGURED" >> $log
          fi

          # Salvage copied with no errors. Proceed with job configuration
          printf "${G_ok}"

        else
          printf "${R_failed}"
          echo " Salvage files corruped. Job reconfiguration interupted." >> $log
        fi

      else
        echo " No previous results to salvage" 
        echo " No previous results to salvage" >> $log
      fi
    
    else
      echo " No new files to retrive"
    fi

    rm ${sawFile}  # remove warning sign
  else
    echo " Avoiding script colision - skipping"
  fi # sawFile conditional

  (( i++ ))
done
echo
exit 0
