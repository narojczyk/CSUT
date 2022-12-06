#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
SNAME=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="${HOME}/main/work/dev/scripts/CSUT/src"
CSUT_CORE_INC="${CSUT_CORE}/includes"
CORE="${CSUT_CORE}/modules/cluster/eagle"

###############################################################################

# Surce top-level utility variables
source ${CSUT_CORE_INC}/colours.sh
source ${CSUT_CORE_INC}/init/set_constants.sh

# Script variables
header="${_BOLD}${_PURP}Retrive partial results from terminated simulations${_RESET}"
useSQL=0
logfile=`echo $0 | sed 's;^.*/;;' | sed 's;\./\(.*\)\..*;\1;'`
logmarker=`eval date +%F`
logsuffix=`date +%s`
chksumFile="JOB_salvage_checksum.sha1"
sawFile="script_at_work.here"

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

# Display greetings
source ${CORE}/init/credits.sh "${header}"

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/init/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

log="${JOBSTARTER}/${logfile}_${logmarker}_${logsuffix}.log"

# while getopts svm: argv
while getopts sv argv
do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=1 ;;
    esac
done

# When enabled, test if SQL database is availiable
if [ ${useSQL} -eq 1 ] && [[ `uname -n` = "eagle.man.poznan.pl" ]]; then
    useSQL=0
    echo " ${_RED}Cannot use SQL funcionality at the head node${_RESET}"
    printf " run:\n\tsrun -pstandard --pty /bin/bash\n"
    printf " or continue in non-SQL mode"; read trash
fi

if [ ${useSQL} -eq 1 ] && [ ! -f ${SQLDB} ]; then
  useSQL=0
elif [ ${useSQL} -eq 1 ] && [ -f ${SQLDB} ]; then
  printf " Running with SQL enabled. Using %s\n" ${SQLDB##/*/}
fi

# Get list of terminated jobs
if [ ${useSQL} -eq 1 ]; then
  TJlist=(`${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'terminated';"`);
else
  # Get the list of jobs to retrive based on the scratch dir inspection
  echo "not implemented yet."
  exit 0 
fi
TJCount=${#TJlist[@]}

if [ $TJCount -eq 0 ]; then
  echo " No jobs selected"
  exit 0
fi

cd $JOBSTARTER; 

i=0; TJCount=1
while [ $i -lt ${TJCount} ]; do

  job=${TJlist[$i]}
  inputFound=0;
  unset reconfigureJob;
  
  cd $JOBSTARTER; 
  printf "\n [%d/%d] %s\n" $(expr $i + 1) $TJCount $job
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
      #  hence overwritting links wit regular files
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
      printf " * salvage %2d files, " ${salvageListN}
      if [ $salvageListN -ne 0 ]; then
        cd ${SCRATCH}/${scratchJob}
        sha1sum ${salvageList[@]} > ${chksumFile}
        cd - >/dev/null
        cp ${SCRATCH}/${scratchJob}/${chksumFile} .

        q=0; printf "copying "
        while [ $q -lt ${salvageListN} ]; do
 #         cp ${SCRATCH}/${scratchJob}/${salvageList[$q]} .
          (( q++ ))
          printf "."
        done
        unset q

        # Verify that files were copied correctly
        printf "\n * sha1 "
        sha1sum -c ${chksumFile} --quiet 2>> $log
        shaEC=$?
        if [ $shaEC -eq 0 ]; then
          # Salvage copied with no errors. Proceed with job configuration
          printf "[ OK ] "
          reconfigureJob=1
        else
          printf "[ failed ] "
          echo " Salvage files corruped. Job reconfiguration interupted." >> $log
        fi

      else
        echo " nothing to do"
        echo " No previous results to salvage" >> $log
      fi
    
    else
      echo " No previous jobs to salvage"
    fi

    rm ${sawFile}  # remove warning sign
  else
    echo " Avoiding script colision - skipping"
  fi # sawFile conditional

  (( i++ ))
done
echo " Finished"

exit 0
