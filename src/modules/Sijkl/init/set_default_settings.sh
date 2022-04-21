#!/bin/bash

# Running mode flags
opMode=""
loadConfig=0
debugMode=0

showLastN=15 # Display N last entries of data array

# Default file names
usrConfig="none"
logFile="default.log"

# Temporary work dir marker
hereANDnow=`date +"%F_%H-%M-%S"`

# Work in main scratch folder by default
SCRATCH=$SCRATCH0

# Selected folder inside SIMDATA
dataSubRepository="sph3d_NpT_HS"

# Program selection
defaultBinary="SNpT"
defaultBinaryMarker="SNpT*"

# Stage 1 processing constants
merge_input="false"

# Default parameters for input data

# UI settings
pbLength=20

#################################################################### old trash
extract_errors_log="extr_err.txt"   #TODO: obsolete
scratch=$SCRATCH0   # TODO: Remove when replaced by 'SCRATCH'
###########################################################################
return 0
