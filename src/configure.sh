#!/bin/bash

echo "[$0] This will configure CSUT on new location" |\
  sed -e 's/\.sh]/]/' -e 's;\[\./;[;';


exit 0;
