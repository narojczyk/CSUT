#!/bin/bash

# Running mode flags
loadConfig=0
debugMode=0

# showLastN=15 # Display N last entries of data array

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
defaultBinary="NuS_csut"
defaultBinaryMarker="NuS*"

# Python interpretter (default setting in declare_environment_vars.sh)
pthInterpretter=${PYTHON}

# Stage 1 processing constants

# Default parameters for input data

# UI settings
pbLength=20

# Plot settings

return 0
