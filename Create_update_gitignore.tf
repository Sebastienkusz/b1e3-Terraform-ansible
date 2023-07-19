# Create script to update .gitignore
resource "local_file" "update_gitignore" {
  filename        = "${path.module}/scripts/update_gitignore.sh"
  file_permission = "0744"
  content         = <<-EOT
#!/bin/bash

  if (grep "# Admin ssh key" ../.gitignore); then
    lineinfile=$(sed -n '/# Admin ssh key/=' ../.gitignore)
    linebefore=$(expr $${lineinfile} - 1)
    if [ -z "$(sed -n $${linebefore}p ../.gitignore)" ]; then
      lineinfile=$${linebefore}
    fi
    finalline=$(expr $${lineinfile} + 2)
    sed -i $${lineinfile},$${finalline}d ../.gitignore
  fi
  echo "
# Admin ssh key
${local.admin}" >> ../.gitignore
EOT
}