#!/bin/bash
# Greetings and credits

header="$1"
auth="${_GREEN}Jakub W. Narojczyk${_RESET}"
email="${_GREEN}narojczyk@ifmpan.poznan.pl${_RESET}"

echo
printf "  %s\n" "$header"
printf "  author: %s (%s)\n" "$auth" "$email"
printf "  %s\n\n" "`date`"

return 0
