#!/bin/bash
# Greetings and credits

header="$1"
auth="${_GRE}Jakub W. Narojczyk${_RST}"
email="${_GRE}narojczyk@ifmpan.poznan.pl${_RST}"

echo
printf "  %s\n" "$header"
printf "  author: %s (%s)\n" "$auth" "$email"
printf "  %s\n\n" "`date`"

return 0
