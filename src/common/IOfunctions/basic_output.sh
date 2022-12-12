#!/bin/bash

head_msg(){
  printf "[$0]" | sed -e 's/\.sh]/]/' -e 's;\[\./;[;'; }

basic_msg() {
  echo `head_msg` "Missing mandatory arguments" 1>&2;
  echo "Usage: $0 [-h|i] | [-c] | [-u <prepare|fetch|cluster|data>]" 1>&2;
  }

help_msg() {
  echo `head_msg` "Help information:";
  echo -ne "  -h\tprint this help\n"
  echo -ne "  -i\tprint this help with extended usage examples\n";
  echo -ne "  -c\tprint script configuration settings and check dependencies\n";
  echo -ne "  -u\tselect utility (possible values: prepare|cluster|data)\n";
}

usage_msg() { echo "usage_msg"; }
print_config() { echo "print_config"; }
self_diagnostic() {
# run this in the current shell (space after '.')
. ${CSUT_CORE}/includes/SelfTest/check_environment_vars.sh;
}

display_progres(){
  if [ $VERBOSE -eq 1 ]; then
    cc=${dpctrl[0]}  # Current counter value
    CM=${dpctrl[1]}  # Maximal counter value
    LL=${dpctrl[2]}  # Total line length
    PBS="${dpctrl[3]}" # Formated string to prepend to FPB

    # PBS=" pre-bar string (opt.)" | BS="FPB output"
    FPBL=$(expr $LL - ${#PBS} - 12) # Auto adjust the length of FPB to fill LL
    if [ $FPBL -lt 10 ]; then
      FPBL=10
    fi
    # Prepare progres bar
    BS=`$FPB ${cc} ${CM} ${FPBL}`
    progres_msg=`printf "%s %s" "${PBS}" "${BS}"`

    # Display progress bar
    echo -ne "${progres_msg}"\\r
  fi
}


return 0;
