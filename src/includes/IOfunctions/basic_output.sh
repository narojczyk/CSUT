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
self_diagnostic() { echo "self_diagnostic"; }


return 0;
