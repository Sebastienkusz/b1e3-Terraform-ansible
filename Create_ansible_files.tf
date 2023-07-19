# Create inventaire.ini for Ansible

resource "local_file" "inventaire" {
  filename        = "${path.module}/ansible/inventaire.ini"
  file_permission = "0644"
  content         = <<-EOT
[bastion]
${azurerm_public_ip.Public_IP_Bastion.fqdn}

[appli]
${azurerm_linux_virtual_machine.VM_Appli.private_ip_address}

[bastion:vars]
ansible_port=${local.nsg_bastion_rule_sshport}
ansible_ssh_private_key_file="../${local_file.admin_rsa_file.filename}"

[appli:vars]
ansible_port=22
ansible_ssh_private_key_file="../${local_file.admin_rsa_file.filename}"
ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ${local.admin}@${azurerm_public_ip.Public_IP_Bastion.fqdn}"'

[bdd]

[all:vars]
ansible_connection=ssh
ansible_ssh_user=${local.admin}
ansible_become=true
ansible_python_interpreter="/usr/bin/python3"
EOT

  depends_on = [
    local_file.admin_rsa_file
  ]
}

# Create appli/commun variables file for ansible
resource "local_file" "appli_commun_main_yml" {
  filename        = "${path.module}/ansible/roles/appli/commun/defaults/main.yml"
  file_permission = "0644"
  content         = <<-EOT
---

# DNS Wiki JS
wikijs_domain: "${azurerm_public_ip.Public_IP_Appli.fqdn}"

# Wikijs host
wikijs_host: "${azurerm_mariadb_server.serverdb.fqdn}"

# Base de données
wikijs_db_name: "${local.database_name}"
wikijs_db_host: "${local.resource_group_name}-${local.server_name}"

# Admin Base de données
wikijs_admin_user: "${azurerm_mariadb_server.serverdb.administrator_login}"
wikijs_admin_azuredb: "{{wikijs_admin_user}}@${local.resource_group_name}-${local.server_name}"
wikijs_admin_password: "${azurerm_mariadb_server.serverdb.administrator_login_password}"

# User Base de données
wikijs_db_user: "${local.mariadb_user}"
wikijs_db_password: "${local.mariadb_user_password}"

# Wikijs Data
wikijs_user: "${local.admin}"

# nom du dossier wikijs
wikijs_name: "${local.appli_name}"

# Dossiers d'installation
wikijs_tar_directory: "/tmp/"
wikijs_directory: "/var/www/{{wikijs_name}}/"
wikijs_storage: "/mnt/${azurerm_storage_share.share.name}/${azurerm_storage_share_directory.smb.name}/{{wikijs_name}}/"
wikijs_data: "{{wikijs_storage}}data"

# Url des sources Mediawiki
wikijs_archive_name: "${local.appli_archive_name}"
wikijs_archive_url: "${local.appli_archive_url}"

# Service
wikijs_service: "${local.appli_service}"
wikijs_service_content: |
  [Unit]
  Description=Wiki.js
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/bin/node server
  Restart=always
  # Consider creating a dedicated user for Wiki.js here:
  User=nobody
  Environment=NODE_ENV=production
  WorkingDirectory={{wikijs_directory}}

  [Install]
  WantedBy=multi-user.target

# Users
users:
...
templatefile("${path.module}/users.tftpl", { local.users })

EOT

  depends_on = [
    azurerm_public_ip.Public_IP_Appli
  ]
}