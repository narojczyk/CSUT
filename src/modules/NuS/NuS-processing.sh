#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
SNAME=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`
iam=$SNAME  #TODO: remove 'iam'

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="${HOME}/main/work/dev/scripts/CSUT/src"
CSUT_CORE_INC="${CSUT_CORE}/common"
CORE="${CSUT_CORE}/modules/NuS"

###############################################################################

# Surce top-level utility variables
source ${CSUT_CORE_INC}/settings/constants.sh

# Surce top-level utility functions
source ${CSUT_CORE_INC}/IOfunctions/log_and_configs.sh
source ${CSUT_CORE_INC}/IOfunctions/check_user_input.sh

# Script variables


# Display greetings and define output messages
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Utility for Poisson's ratio calculations from Sij data in batch mode${_RST}"

# get names of system-wide env. variables
env_dirs=( SCRATCH0 CODESDIR SCRIPTDIR SIMPLOTS SIMRESULTS SIMREPORTS )

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

DATAREPO="${SIMRESULTS}/${dataSubRepository}"

# Check required resources
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh \
  DATAREPO #pthInterpretter

# Inspect data repository and display contents
source ${MODULES}/sub_browse_data.sh

# Select binary to use
source ${CSUT_CORE_INC}/sub_modules/sub_select_binary.sh

# Prepare and change to work directory
source ${CSUT_CORE_INC}/sub_modules/sub_workdir.sh

# Link selected binary
ln -s $BINARYDIR/$binary 2>> $logFile

# Link data




cd $startdir
exit 0
