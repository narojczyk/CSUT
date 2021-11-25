#!/bin/bash

basic_msg() {
  echo "Missing mandatory arguments"
  echo "Usage: $0 [-h|i] | [-u <prepare|cluster|data>]" 1>&2;
  exit 1;
  }

help_msg() {
  echo "Help information: $0";
  echo -ne "  -h\tprint this help\n"
  echo -ne "  -i\tprint this help with extended usage examples\n";
  echo -ne "  -c\tprint script configuration settings and check dependencies\n";
  echo -ne "  -u\tselect utility (possible values: prepare|cluster|data)\n";
  exit 0;
}

usage_msg() {
  echo "dupa"
  exit 0;
}

print_config() { echo "print_config"; }
self_diagnostic() { echo "self_diagnostic"; }


return 0;
