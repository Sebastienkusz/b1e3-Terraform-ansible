#!/bin/bash

  if (grep "# Admin ssh key" ../.gitignore); then
    lineinfile=$(sed -n '/# Admin ssh key/=' ../.gitignore)
    linebefore=$(expr ${lineinfile} - 1)
    if [ -z "$(sed -n ${linebefore}p ../.gitignore)" ]; then
      lineinfile=${linebefore}
    fi
    finalline=$(expr ${lineinfile} + 2)
    sed -i ${lineinfile},${finalline}d ../.gitignore
  fi
  echo "
# Admin ssh key
azureuser" >> ../.gitignore
