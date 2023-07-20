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
  content = templatefile("${path.module}/users.tftpl",
    {
      tpl_users             = local.users
      tpl_random_password   = random_password.users_vms.result
      tpl_app_fqdn          = azurerm_public_ip.Public_IP_Appli.fqdn
      tpl_db_fqdn           = azurerm_mariadb_server.serverdb.fqdn
      tpl_db_name           = local.database_name
      tpl_rg                = local.resource_group_name
      tpl_server            = local.server_name
      tpl_admin_dbuser      = azurerm_mariadb_server.serverdb.administrator_login
      tpl_admin_dbpassword  = azurerm_mariadb_server.serverdb.administrator_login_password
      tpl_user_dbuser       = local.mariadb_user
      tpl_user_dbpassword   = local.mariadb_user_password
      tpl_admin_vm          = local.admin
      tpl_app_name          = local.appli_name
      tpl_storage_share     = azurerm_storage_share.share.name
      tpl_storage_directory = azurerm_storage_share_directory.smb.name
      tpl_archive_name      = local.appli_archive_name
      tpl_archive_url       = local.appli_archive_url
      tpl_app_service       = local.appli_service
  })
  depends_on = [
    azurerm_public_ip.Public_IP_Appli
  ]
}