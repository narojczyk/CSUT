#!/bin/bash

# Define and declare additional environment variables for this script
#   directories
MODULES="$CORE/modules"
INITIALS="$CORE/init"
UTILS="${CSUT_CORE_INC}/utils"
GPLT="$CORE/gplt"
HELPERS="$CORE/helper_scripts"
SNPTDIR="$CODESDIR/SNpT"

#   utility programs
FPB="$UTILS/fancypb"    #TODO: check if exists
PYTHON="/usr/bin/python2"

script_dirs=( MODULES INITIALS UTILS GPLT HELPERS SNPTDIR )


