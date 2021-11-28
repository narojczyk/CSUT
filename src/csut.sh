#!/bin/bash

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="/home/jwn/main/work/dev/scripts/CSUT/src";

###############################################################################

source ${CSUT_CORE}/includes/IOfunctions/basic_output.sh;

if [ $# -eq 0 ]; then
  # runtine parameters are required
  # echo basic usage information and exit
  basic_msg;
  exit 1;
fi

while getopts ihcu: argv
do
    case "${argv}" in
        i) usage_msg; exit 0;;
        h) help_msg;  exit 0;;
        c) print_config;  self_diagnostic; exit 0;;
        u) echo "u";  exit 0;;
        *) basic_msg; exit 1;;
    esac
done



exit 0
