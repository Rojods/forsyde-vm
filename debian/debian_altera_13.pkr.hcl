variable "debian_iso_url" {
  type = string
  default = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso"
}

variable "altera_13_download_url" {
  type = string
  default = "https://download.altera.com/akdlm/software/acdsinst/13.0sp1/232/ib_tar/Quartus-web-13.0.1.232-linux.tar"
}

variable "altera_13_local_tarfile" {
  type = string
  default = ""
}

variable "altera_13_use_local" {
  type = bool
  default = false
}

variable "debian_iso_url_md5" {
  type = string
  default = "ff7205a14937f1f34be84f4663d3c769"
}

locals {
  sudocmd = "echo 'packer' | sudo -S "
}

source "virtualbox-iso" "debian-virtualbox" {
  guest_os_type = "Debian_64"
  iso_url = "${var.debian_iso_url}"
  iso_checksum = "md5:${var.debian_iso_url_md5}"
  ssh_username = "packer"
  ssh_password = "packer"
  guest_additions_mode = "upload"
  guest_additions_path = "/tmp/VBoxGuestAdditions.iso"
  memory = 1024
  headless = true
  http_directory = "."
  boot_wait = "5s"
  boot_command = [
    "A<enter>", 
    "A<enter>", 
    "<wait50s>http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian-preseed.txt<enter>",
    "<wait5s><enter><enter>"
    // this last enter is for "Unable is to skip the harmless CD error"
    # "<wait95s><enter>"
  ]
  ssh_timeout = "15m"
  shutdown_command = "${local.sudocmd} shutdown -P now"
}

build {

  source "source.virtualbox-iso.debian-virtualbox" {
    disk_size = 30000
    vm_name = "forsyde-debian-altera13"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/install-required.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/install-ada.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/install-lustre-tools.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/patch-drivers.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/patch-user.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }};"
    script = "provisioners/install-forsyde-tools.sh"
  }

  provisioner "file" {
	only = ["var.altera_13_use_local"]
    source = "files/${var.altera_13_local_tarfile}"
    destination = "/tmp/${var.altera_13_local_tarfile}"
  }

  provisioner "shell" {
	only = ["var.altera_13_use_local"]
    environment_vars = ["QUARTUS_13_TAR_FILE=/tmp/${var.altera_13_local_tarfile}"]
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }}"
    script = "provisioners/install-quartus-tools-13.sh"
  }

  provisioner "shell" {
	except = ["var.altera_13_use_local"]
    environment_vars = ["QUARTUS_13_DOWNLOAD_URL=${var.altera_13_download_url}"]
    execute_command = "chmod +x {{ .Path }}; ${local.sudocmd} {{ .Vars }} {{ .Path }}"
    script = "provisioners/install-quartus-tools-13.sh"
  }
}

