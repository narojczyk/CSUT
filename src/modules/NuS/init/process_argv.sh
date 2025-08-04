#!/bin/bash
# This code will process command line arguments passed to the script
# This code expects equals-separated key-value arguments

for i in "$@"; do
  case $i in
    -g|--skip-graphics)
      graphResults=0
      shift # past argument with no value
      ;;
#     -N=*|--limit-input-lines=*)
#       NlinesLimit="${i#*=}"
#       # Test if parameter passed is a valid number
#       re='^[0-9]+$'
#       if [ ${#NlinesLimit} -gt 0 ] && ! [[ $NlinesLimit =~ $re ]] ; then
#         if [ "$NlinesLimit" != "auto" ]; then
#           echo "ERR: -N is not a number" >&2; exit 1
#         fi
#       fi
#       shift # past argument=value
#       ;;
#     -o=*|--operation-mode=*)
#       opMode="${i#*=}"
#       shift # past argument=value
#       ;;
#     -r=*|--repository=*)
#       alternateRepositoryFlag=1
#       repoSource="${i#*=}"
#       shift # past argument=value
#       ;;
#     --debug|--debug=*)
#       debugMode=1
#       shift
#       ;;
#     -e=*|--exclude-ids-file=*)
#       excludeIDsFile="${i#*=}"
#       plotWithoutExcluded=1
#       ;;
#     -c=*|--config-file=*)
#       usrConfig="${i#*=}"
#       write_config
#       exit 0
#       ;;
#     -l=*|--load-config-file=*)
#       usrConfig="${i#*=}"
#       loadConfig=1
#       shift
#       ;;
    -s|--settings)
      settingsOutput=1
      echo_settings
      exit 0
      ;;
    -h|--help)
      echo_usage
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done


