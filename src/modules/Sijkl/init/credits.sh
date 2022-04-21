#!/bin/bash
# Greetings and credits

header="$(tput bold)$(tput setaf 5)Utility for Sijkl calculations from MC NpT simulations in batch mode$(tput sgr0)"
auth="$(tput setaf 2)Jakub W. Narojczyk$(tput sgr0)"
email="$(tput setaf 2)narojczyk@ifmpan.poznan.pl$(tput sgr0)"

echo
printf "  %s %s %s %s %s %s %s %s %s %s %s\n" $header
printf "  author: %s %s %s (%s)\n" $auth $email
printf "  %s\n\n" "`date`"

return 0
