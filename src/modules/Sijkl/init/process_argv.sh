#!/bin/bash
# This code will process command line arguments passed to the script
# This code expects equals-separated key-value arguments

for i in "$@"; do
  case $i in
    -o=*|--operation-mode=*)
      opMode="${i#*=}"
      shift # past argument=value
      ;;
    -s|--settings)
      settingsOutput=1
      shift # past argument with no value
      ;;
    --debug|--debug=*)
      debugMode=1
      shift 
      ;;
    -c=*|--config-file=*)
      usrConfig="${i#*=}"
      write_config
      exit 0
      ;;
    -l=*|--load-config-file=*)
      usrConfig="${i#*=}"
      loadConfig=1
      shift
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


