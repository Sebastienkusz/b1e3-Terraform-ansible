#!/bin/bash

echo " "
echo "------------------------------------------------------------------------------------"
echo " update repositories and install dos2unix in ordre to format scripts files"
echo " "
sudo apt -y update
sudo apt -y install dos2unix

dos2unix *.sh

echo " "
echo "------------------------------------------------------------------------------------"
echo " delete ssh links"
echo " "
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "b1e3-gr2-bastion.westeurope.cloudapp.azure.com"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.1.0.4"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.1.0.5"

echo " "
echo "------------------------------------------------------------------------------------"
echo " update .gitignore"
echo " "
./update_gitignore.sh

echo " "
echo "------------------------------------------------------------------------------------"
echo " Test Ansible ping pong"
./script_ansible.sh

echo " "
echo "------------------------------------------------------------------------------------"
echo " "
echo "run this command to add ssh config"
echo " "
echo "./add_ssh_config.sh -u johann -f id_rsa"
echo "or"
echo "./add_ssh_config.sh -u sebastien -f sebastien_rsa"