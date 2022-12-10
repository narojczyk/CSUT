#!/bin/bash
# Greetings and credits

header="${_BLD}${_PRP}Utility for Sijkl calculations from MC NpT simulations in batch mode${_RST}"
auth="${_GRE}Jakub W. Narojczyk${_RST}"
email="${_GRE}narojczyk@ifmpan.poznan.pl${_RST}"

echo
printf "  %s %s %s %s %s %s %s %s %s %s %s\n" $header
printf "  author: %s %s %s (%s)\n" $auth $email
printf "  %s\n\n" "`date`"

return 0
