#!/bin/bash
# Greetings and credits

header="${_BOLD}${_PURP}Utility for Sijkl calculations from MC NpT simulations in batch mode${_RESET}"
auth="${_GREEN}Jakub W. Narojczyk${_RESET}"
email="${_GREEN}narojczyk@ifmpan.poznan.pl${_RESET}"

echo
printf "  %s %s %s %s %s %s %s %s %s %s %s\n" $header
printf "  author: %s %s %s (%s)\n" $auth $email
printf "  %s\n\n" "`date`"

return 0
