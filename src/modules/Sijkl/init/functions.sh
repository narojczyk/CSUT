#!/bin/bash

write_config(){
    if [ -z ${usrConfig:+x} ] || [ "$usrConfig" == "-c" ]; then
        usrConfig="${SNAME}_default.cfg"
    fi  
    cfg="${startdir}/${usrConfig}"

    # Output program settings to user config file (optional)
    if [ $loadConfig -eq 0 ]; then
        echo "writting config file $usrConfig"
        #TODO: Check not to overwrite a file (check write premissions)
        echo > $cfg
       
        echo "# Selected folder inside SIMDATA"       >> $cfg
        echo    "dataSubRepository=\"sph3d_NpT_HS\""  >> $cfg
        echo "# Uncomment to process data for several runs as a singe input\n" >> $cfg
        echo    "#merge_input=\"false\""              >> $cfg
    fi

    echo "# Display last N entries for data arrays with a lot of entries"   >> $cfg
    echo "# Set to any high-enough number to display the full list"         >> $cfg
    echo    "showLastN=15"  >> $cfg
    echo "# UI settings"    >> $cfg
    echo    "pbLength=20"   >> $cfg
}

load_config(){
    cfg="${startdir}/${usrConfig}"
    if [ -f $cfg ] && [ -r $cfg ]; then
        echo "loading $cfg"
        source $cfg
    else
        echo "missing config, running on defaults"
    fi
}