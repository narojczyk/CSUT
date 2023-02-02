#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
source ${HOME}/.bashrc
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

while getopts l:rsv argv; do
  case "${argv}" in
    l) TJlistLimit=${OPTARG} ;;
    r) reverseList=1 ;;
    s) useSQL=1 ;;
    v) VERBOSE=0 ;;
  esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Retrive partial results from terminated simulations${_RST}"

# Surce module-level resource paths
source ${CORE}/init/set_module_resource_paths.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# Surce module-level utility variables
source ${INITIALS}/set_module_constants.sh

log="${JOBSTARTER}/${logFileName}"

# When enabled, test if SQL database is availiable
SQLtestHostname

# Test if DB is present
SQLDBpresent

echo " Log to file: ${_YEL}${_BLD}${logFileName}${_RST} on JOBSTARTER"

# Get list of terminated jobs
if [ ${useSQL} -eq 1 ]; then
  if [ ${reverseList:-0} -eq 1 ]; then
    SQLQUERRY="SELECT JOBDIR FROM ${SQLTABLE} WHERE STATUS LIKE 'terminated' ORDER BY JOBDIR DESC;"
  else
    SQLQUERRY="SELECT JOBDIR FROM ${SQLTABLE} WHERE STATUS LIKE 'terminated';"
  fi
  TJlist=(`SQLconnect "${SQLQUERRY}"`);
else
  CMDLine=(`echo "${@}" | sed 's/^-[a-z][\ 0-9]*//g' | sed 's/SLID[0-9]*_//g'`)
  # Get the list of jobs to retrive based on the scratch dir inspection
  if [ ${#CMDLine[@]} -eq 0 ]; then 
    cd ${SCRATCH}
    # This will select only odd lines
    SelectLines="| sed 'n; d'"
    if [ ${reverseList:-0} -eq 1 ]; then
      # This will select even lines
      SelectLines="| sed '1d; n; d'"
    fi
    TJlist=(`eval "ls -1d SLID* ${SelectLines}"  | sed 's/^SLID[0-9]*_//'`)
  else
    # TODO: Check if the job is running or pending - if so, remove from the list
    TJlist=( "${CMDLine[@]}" )
  fi
fi

TJCount=${#TJlist[@]}
if [ ${TJlistLimit:-0} -gt 0 ] && [ ${TJlistLimit:-0} -le ${TJCount} ]; then
  TJCount=${TJlistLimit}
fi

if [ $TJCount -eq 0 ]; then
  echo " No job candidates to retrieve files from."
  exit 0
fi

# Set initial control array for printing progress bar (see IOfunctions)
dpctrl=( 0 0 66 ' ' )
WDTH=${#TJCount}

cd $JOBSTARTER; 

i=0; 
while [ $i -lt ${TJCount} ]; do

  job=${TJlist[$i]}
  inputFound=0;
  
  cd $JOBSTARTER; 
  printf "\n [%${WDTH}d/${TJCount}] %s\n" $(expr $i + 1) $job
  echo $job >> $log

  if [ ! -f ${job}/${lockFile} ]; then
    date > ${job}/${lockFile} 
    cd $job

    # get job's old ID based on files from previous run
    jobID=`ls -1 JOB_[0-9]*.[oe][ur][rt] 2>/dev/null | sed 's/JOB_\([0-9]*\).[oe].*$/\1/' | sort -u | tail -n 1`
    if [ ! -n "${jobID}" ]; then
      SQLQUERRY="SELECT JOBID FROM ${SQLTABLE} WHERE JOBDIR LIKE '${job}';"
      jobID=`SQLconnect "${SQLQUERRY}"`
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
        scratch_JB=`echo ${scratchJobs[0]##*/}`
        jobID=`echo ${scratch_JB} | eval "sed -e 's/_${job}//'" | sed 's/[Aa-Zz]//g'`
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
      fi
    else
      # Find job directory on scratch using job ID (no need to check multiple hits
      # queueing system will not assign one id to multiple jobs)
      scratch_JB=`ls -1d ${SCRATCH}/*${jobID}*  2>/dev/null | sed 's;^.*/;;'`
      if [ -n "${scratch_JB}" ]; then
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
      ls -l ${SCRATCH}/${scratch_JB}/*.* 2>/dev/null |\
        grep -v -e JOB_ -e sha1 -e ^-rwxr -e "\ 0\ " > ${salvageListFile}
      # remove files already present from beeing overwritten 
      q=0; while [ $q -lt ${preserveFilesN} ]; do
        eval "sed -i '/${preserveFiles[$q]}/d' ${salvageListFile}"
        (( q++ ))
      done
      unset q
    
      # Read list of files to copy from scratch
      salvageList=(`cat ${salvageListFile} | sed 's;^.*/;;'`)
      salvageListN=${#salvageList[@]}
      setAsReconfigured=0
      if [ $salvageListN -ne 0 ]; then
        cd ${SCRATCH}/${scratch_JB}
        sha1sum ${salvageList[@]} > ${chksumFile}
        cd - >/dev/null
        cp ${SCRATCH}/${scratch_JB}/${chksumFile} .

        wdth=${#salvageListN}
        printFormBar=" copying data from SCRATCH (%${wdth}d/${salvageListN})"
        dpctrl[1]=${salvageListN}
        q=0; while [ $q -lt ${salvageListN} ]; do
          cp ${SCRATCH}/${scratch_JB}/${salvageList[$q]} .
          (( q++ ))
          dpctrl[0]=${q}
          dpctrl[3]=`printf "${printFormBar}" ${q}`
          display_progres
        done
        unset q

        # Verify that files were copied correctly
        printf "\n Verify copied data "
        sha1sum -c ${chksumFile} --quiet >> $log 2>&1
        shaEC=$?
        if [ $shaEC -eq 0 ]; then
          # Flag the job status to be set as reconfigured
          setAsReconfigured=1 

          # Salvage copied with no errors. Proceed with job configuration
          printf "${G_ok}"

        else
          printf "${R_failed}"
          echo " Salvage files corruped. Job reconfiguration interupted." >> $log
        fi

      else
        echo " No new results to salvage for this job" 
        echo " No new results to salvage for this job" >> $log
        jobIDactive=`squeue -u ${USER} | grep ${jobID}`
        if [ ${#jobIDactive} -eq 0 ]; then
          # Flag the job status to be set as reconfigured
          setAsReconfigured=1 
        fi
      fi

      if [ $setAsReconfigured -eq 1 ]; then
        # Flag job as reconfigured
        SQLQUERRY="UPDATE ${SQLTABLE} SET STATUS='reconfigured' WHERE JOBDIR LIKE '${job}';"
        SQLconnect "${SQLQUERRY}"
        echo "${job} RECONFIGURED" >> $log
      fi
    
    else
      echo " No new files to retrive"
      echo " No new files to retrive" >> $log
        # TODO: change status of the job from 'terminated' to 'reconfigured'
    fi

    rm ${lockFile}  # remove warning sign
  else
    echo " Avoiding script colision - skipping"
  fi # lockFile conditional

  (( i++ ))
done
echo
exit 0
