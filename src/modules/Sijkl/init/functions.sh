#!/bin/bash

write_config(){
  if [ -z ${usrConfig:+x} ] || [ "$usrConfig" == "-c" ]; then
    usrConfig="${SNAME}_default.cfg"
  fi
  cfg="${STARTDIR}/${usrConfig}"

  # Output program settings to user config file (optional)
  if [ $loadConfig -eq 0 ]; then
    echo " Writting selected configuration options to $usrConfig"
    echo " Run again with '-l=$usrConfig' option, to take effect"
    #TODO: Check not to overwrite a file (check write premissions)
    echo > $cfg

    echo "# Selected folder inside SIMDATA"     >> $cfg
    echo  "dataSubRepository=\"sph3d_NpT_HS\""  >> $cfg
    echo\
      "# Uncomment to process data for several runs as a singe input"   >> $cfg
    echo  "#merge_input=\"false\""              >> $cfg
  fi

  echo "# Display last N entries for data arrays with a lot of entries" >> $cfg
  echo "# Set to any high-enough number to display the full list"       >> $cfg
  echo  "showLastN=15"  >> $cfg
  echo "# UI settings"  >> $cfg
  echo  "pbLength=20"   >> $cfg
  echo "# Python interpretter"  >> $cfg
  echo  "pthInterpretter=${PYTHON}" >> $cfg
}

load_config(){
  cfg="${STARTDIR}/${usrConfig}"
  if [ -f $cfg ] && [ -r $cfg ]; then
    echo " Loading user settings from $cfg"
    source $cfg
  fi
}

echo_usage(){
  echo -e "\n $SNAME usage options:\n"

  echo -e " -g | --skip-graphics"
    echo -e "\tOnly process MC simulation data and calculate elastic compliance (S)" \
     "and elastic constants (B) matrices. Do not plot any results.\n"

#   echo -e " -s | --settings\n\tOutput settings" # TODO check this
  echo -e " -o=MODE | --operation-mode=MODE\n\tCurrently supported modes:"
  echo -e "\t'aux' write to auxilary SCRATCH1 directory (env. var.)"
  echo -e "\t'dev' run in debug directory\n"

  echo -e " -c=FILE | --config-file=FILE"
  echo -e "\tWrite default config to FILE\n"

  echo -e " -l=FILE | --load-config-file=FILE"
  echo -e "\tLoad user config from FILE\n"

  echo -e " -h | --help\n\tPrint this message"
}
