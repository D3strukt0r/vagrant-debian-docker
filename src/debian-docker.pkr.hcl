variable "box_basename" {
  type    = string
  default = "bento/debian-11"
}

variable "build_directory" {
  type    = string
  default = "../build"
}

variable "guest_additions_url" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = "D3strukt0r/debian-docker"
}

variable "version" {
  type    = string
  default = "TIMESTAMP"
}

variable "cloud_token" {
  type      = string
  sensitive = true
  default   = "${env("VAGRANT_CLOUD_TOKEN")}"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

packer {
  required_plugins {
    vagrant = {
      version = ">= 1.0.2"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "vagrant" "base" {
  communicator = "ssh"
  source_path  = var.box_basename
  provider     = "virtualbox"
  add_force    = true
  output_dir   = var.build_directory
}

build {
  name    = "debian-docker"
  sources = ["source.vagrant.base"]

  #provisioner "shell" {
  #  execute_command = "{{ .Vars }} sudo -E -S sh '{{ .Path }}'"
  #  inline          = ["mount -o loop $${HOME}/VBoxGuestAdditions.iso /mnt", "/mnt/VBoxLinuxAdditions.run install", "umount /mnt", "rm $${HOME}/VBoxGuestAdditions.iso"]
  #}

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant"]
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "provision.sh"
  }

  #post-processors {
  #  post-processor "artifice" {
  #    files = ["${var.build_directory}/package.box"]
  #  }
  #  #post-processor "vagrant-cloud" {
  #  #  access_token = var.cloud_token
  #  #  box_tag      = var.name
  #  #  version      = "0.1.${local.timestamp}"
  #  #}
  #}
}
