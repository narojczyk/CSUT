#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
SNAME=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`
iam=$SNAME  #TODO: remove 'iam'

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="${HOME}/main/work/dev/scripts/CSUT/src"
CSUT_CORE_INC="${CSUT_CORE}/common"
CORE="${CSUT_CORE}/modules/Sijkl"

###############################################################################

# Surce top-level utility variables
source ${CSUT_CORE_INC}/settings/constants.sh

# Surce top-level utility functions
source ${CSUT_CORE_INC}/IOfunctions/log_and_configs.sh
source ${CSUT_CORE_INC}/IOfunctions/check_user_input.sh

# Script variables
NlinesLimit=""
graphResults=1;

# Display greetings and define output messages
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Utility for Sijkl calculations from MC NpT simulations in batch mode${_RST}"

# get names of system-wide env. variables
env_dirs=( SCRATCH0 CODESDIR SCRIPTDIR SIMDATA SIMPLOTS SIMRESULTS SIMREPORTS )

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# Source constants for this scripts
source ${CORE}/init/set_module_constants.sh

# Source default settings for variables
source ${INITIALS}/set_default_settings.sh

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

  # Check if the optional env. variables are set and act accordingly
  # if they are not set.

  if [ -z ${SCRATCH1:+x} ] || [ ! -d ${SCRATCH1} ]; then
    error_msg "SCRATCH1" "WRN"
    # default to primary scratch if the secondary does not exist
    export SCRATCH1="${SCRATCH0}"
  fi

# Source functions used during ARGV processing
source ${INITIALS}/functions.sh

# Process commanline options
source ${INITIALS}/process_argv.sh $@

# Apply commanline settings
source ${INITIALS}/apply_argv.sh

# Load user settings if they exist
load_config

DATAREPO="${SIMDATA}/${dataSubRepository}"

# Check required resources
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh DATAREPO pthInterpretter

# Inspect data repository and display contents
source ${MODULES}/sub_browse_data.sh

# Select binary to use
source ${CSUT_CORE_INC}/sub_modules/sub_select_binary.sh

# Prepare work directory
source ${MODULES}/sub_workdir.sh

# Link selected binary
ln -s $BINARYDIR/$binary 2>> $logFile

# Link and extract data
i=$dset_sta_id
w=${#dset_end_id}     # to set the width of the printf filed

while [ $i -le $dset_end_id ]; do

  printf "\n Now processing %${w}d of %${w}d data ID's\n" \
    $i $dset_end_id

  source ${MODULES}/sub_link_and_extract_data.sh $i

  # # Generate base name for the results files
  # res_base_name=`echo $archive | sed 's/_[0-9][0-9][0-9]\....$//'`
  # printf " using base name for the results:\n%s\n" $res_base_name

  # # This code is left here for historical purposes, but is most likely obsolete by now
  # ls n0*s0*part00 1>/dev/null 2>/dev/null
  # if [ $? -eq 0 ]; then
  # printf " renaiming input files to new format\n"
  #   ff=(`ls -1 n0*`)
  #   ffi=0
  #   while [ $ffi -lt ${#ff[@]} ]; do
  #     ffn=`echo ${ff[$ffi]} | sed 's/n0000000/mc3D_HS_/'`
  #     mv ${ff[$ffi]} $ffn
  #     (( ffi++ ))
  #   done
  # fi

  # Agregate data for respective runs
  source ${MODULES}/sub_data_aggregation.sh

  # if [ "$merge_input" == "true" ]; then
    # TODO: This mode is not up-to-date. Thus cannot be used
    # source ${MODULES}/sub_process_merged_input.sh
  # else
    source ${MODULES}/sub_process_input.sh
  # fi

  # Run binary
  progress_msg=`printf "running ./%s %s" $binary $binconfig`
  printf "$msgItemFormat" "$progress_msg" ""
  ./$binary $binconfig 1> $bin_stdout  2> $bin_stderr
  echo $G_done
  
  source ${MODULES}/sub_results_postprocessing.sh

  if [ $graphResults -eq 1 ]; then
    # Prepare plots for processed data
    source ${MODULES}/sub_plotting_data.sh

    # Clean gnuplot files for this data set
    rm plot*gplt

    # Use Latex and imagemagick to get images in final formats
    source ${MODULES}/sub_image_postprocessing.sh
  fi

  # Clean the input files for this data set
  rm *dat [^2]*csv 20*.bz2 [^S]*.ini $cacheInfo

  # Proceed with next data set
  (( i++ ))
done

cd $startdir
exit 0
