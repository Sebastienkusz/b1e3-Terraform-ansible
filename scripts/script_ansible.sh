#/bin/bash

cd ../ansible
# Ping de bastion
ansible -i inventaire.ini -m ping bastion

# Ping de appli
ansible -i inventaire.ini -m ping appli

cd ../scripts