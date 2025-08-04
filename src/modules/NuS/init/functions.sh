#!/bin/bash

write_config(){
  log_comment  "functions.sh" "Function write_config() is not defined"
}

echo_settings(){
  dispForm="  %-19s = %s\n"
  echo -e "\n $SNAME variables and settings:\n"
  echo " Core directories"
  printf "$dispForm" "CSUT_CORE" "$CSUT_CORE"
  printf "$dispForm" "CSUT_CORE" "$CSUT_CORE"
  printf "$dispForm" "CSUT_CORE_INC" "$CSUT_CORE_INC"
  printf "$dispForm" "CORE_UTILS" "$CORE_UTILS"
  printf "$dispForm" "CORE" "$CORE"
  printf "$dispForm" "INITIALS" "$INITIALS"
  printf "$dispForm" "MODULES" "$MODULES"
  printf "$dispForm" "UTILS" "$UTILS"
  printf "$dispForm" "GPLT" "$GPLT"
  printf "$dispForm" "HELPERS" "$HELPERS"
  printf "$dispForm" "SCRATCH0" "$SCRATCH0"
  printf "$dispForm" "CODESDIR" "$CODESDIR"
  printf "$dispForm" "BINARYDIR" "$BINARYDIR"
  printf "$dispForm" "SCRIPTDIR" "$SCRIPTDIR"
  printf "$dispForm" "SIMPLOTS" "$SIMPLOTS"
  printf "$dispForm" "SIMRESULTS" "$SIMRESULTS"
  printf "$dispForm" "SIMREPORTS" "$SIMREPORTS"
  echo " Core variables"
  printf "$dispForm" "msgItemFormat" "$msgItemFormat"
  printf "$dispForm" "cacheInfo" "$cacheInfo"
  printf "$dispForm" "loadConfig" "$loadConfig"
  printf "$dispForm" "debugMode" "$debugMode"
  printf "$dispForm" "showLastN" "$showLastN"
  printf "$dispForm" "logFile" "$logFile"
  printf "$dispForm" "SCRATCH" "$SCRATCH"
  printf "$dispForm" "dataSubRepository" "$dataSubRepository"
  printf "$dispForm" "defaultBinary" "$defaultBinary"
  printf "$dispForm" "defaultBinaryMarker" "$defaultBinaryMarker"
  printf "$dispForm" "pthInterpretter" "$pthInterpretter"
  printf "$dispForm" "pbLength" "$pbLength"
}

echo_usage(){
  echo -e "\n $SNAME usage options:\n"

  echo -e " -g | --skip-graphics"
  echo -e "\tOnly process Sijkl data and calculate Poisson's ratio." \
     "Do not plot any results.\n"

  echo -e " -s | --settings \n\tOutput settings.\n"

  echo -e " -h | --help \n\tPrint this message"
}
