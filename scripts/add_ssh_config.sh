#!/bin/bash

function show_help() {
    printf "Usage: $0 -u <user_name> -f <key_file_name>\n"
    printf "Example: $0 -u toto -f id_rsa\n"
}

OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hu:f:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        u)
            user=$OPTARG
            ;;
        f)
            file=$OPTARG
            ;;
        :)
            echo "-$OPTARG option requires an argument"
            show_help
            exit 1
            ;;
        \?)
            echo "-$OPTARG: invalid option"
            show_help
            exit 1
            ;;
    esac
done

shift "$((OPTIND-1))" 

if [ -z "$user" ] || [ -z "$file" ]; then
    echo "missing required arguments"
    exit 1
fi

  if (grep "# b1e3-gr2" ~/.ssh/config); then
    lineinfile=$(sed -n '/# b1e3-gr2/=' ~/.ssh/config)
    linebefore=$(expr ${lineinfile} - 1)
    if [ -z "$(sed -n ${linebefore}p ~/.ssh/config)" ]; then
      lineinfile=$linebefore
    fi
    finalline=$(expr ${lineinfile} + 15)
    sed -i ${lineinfile},${finalline}d ~/.ssh/config
  fi
  echo "
# b1e3-gr2
# ------------------------------------------------------------------
Host bastion
        Hostname b1e3-gr2-bastion.westeurope.cloudapp.azure.com
        User $user
        Port 22
        IdentityFile ~/.ssh/$file
        ForwardAgent yes

Host appli
        Hostname 10.1.0.8
        User $user
        Port 22
        ProxyJump bastion
# ------------------------------------------------------------------" >> ~/.ssh/config
