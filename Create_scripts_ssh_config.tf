# Create script to add shortcuts in .ssh/config

resource "local_file" "script_ssh_config" {
  filename        = "${path.module}/scripts/add_ssh_config.sh"
  file_permission = "0774"
  content         = <<-EOT
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

  if (grep "# ${local.resource_group_name}" ~/.ssh/config); then
    lineinfile=$(sed -n '/# ${local.resource_group_name}/=' ~/.ssh/config)
    linebefore=$(expr $${lineinfile} - 1)
    if [ -z "$(sed -n $${linebefore}p ~/.ssh/config)" ]; then
      lineinfile=$linebefore
    fi
    finalline=$(expr $${lineinfile} + 15)
    sed -i $${lineinfile},$${finalline}d ~/.ssh/config
  fi
  echo "
# ${local.resource_group_name}
# ------------------------------------------------------------------
Host bastion
        Hostname ${azurerm_public_ip.Public_IP_Bastion.fqdn}
        User $user
        Port ${local.nsg_bastion_rule_sshport}
        IdentityFile ~/.ssh/$file
        ForwardAgent yes

Host appli
        Hostname ${azurerm_linux_virtual_machine.VM_Appli.private_ip_address}
        User $user
        Port 22
        ProxyJump bastion
# ------------------------------------------------------------------" >> ~/.ssh/config
EOT

  depends_on = [
    azurerm_linux_virtual_machine.VM_Appli
  ]
}