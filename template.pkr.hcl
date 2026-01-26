packer {
  required_version = ">= 1.5.1"
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "hcloud_token" {
  type = string
}

variable "hcloud_location" {
  type    = string
  default = "nbg1"
}

variable "build_identifier" {
  type    = string
}

variable "instance_type" {
  type    = string
  default = "cx22"
}

variable "instance_image" {
  type    = string
  default = "ubuntu-22.04"
}

variable "github_branch" {
  type    = string
  default = "dev"
}

variable "version" {
  type    = string
  default = "dev"
}

variable "snapshot_name" {
  type    = string
}

locals {
  build_labels = {
    "name"                 = "wireguard-router"
    "os-flavor"            = "ubuntu"
    "packer.io/build.id"   = "${uuidv4()}"
    "packer.io/build.time" = "{{timestamp}}"
    "packer.io/version"    = "{{packer_version}}"
    "branch"               = var.github_branch
    "version"              = var.version
  }
}

source "hcloud" "ubuntu" {
  token         = var.hcloud_token
  image         = var.instance_image
  location      = var.hcloud_location

  server_type   = var.instance_type
  server_labels = {
    build = var.build_identifier
  }

  ssh_username  = "root"
  ssh_keys_labels = {
    build = var.build_identifier
  }

  snapshot_labels = local.build_labels
  snapshot_name   = var.snapshot_name
}

build {
  sources = [
    "source.hcloud.ubuntu"
  ]

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-checkdns.service"
    destination = "/etc/systemd/system/wireguard-checkdns.service"
  }

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-checkdns.sh"
    destination = "/usr/local/bin/wireguard-checkdns.sh"
  }

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-checkdns.timer"
    destination = "/etc/systemd/system/wireguard-checkdns.timer"
  }

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-check-connection.service"
    destination = "/etc/systemd/system/wireguard-check-connection.service"
  }

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-check-connection.sh"
    destination = "/usr/local/bin/wireguard-check-connection.sh"
  }

  provisioner "file" {
    source      = "src/wireguard-router/wireguard-check-connection.timer"
    destination = "/etc/systemd/system/wireguard-check-connection.timer"
  }

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y wireguard wireguard-tools",
      "systemctl enable wg-quick@wg0",
      "chmod +x /usr/local/bin/wireguard-checkdns.sh",
      "chmod +x /usr/local/bin/wireguard-check-connection.sh",
      "systemctl enable wireguard-checkdns.timer",
      "systemctl enable wireguard-check-connection.timer",
      "cloud-init clean --logs --machine-id --seed --configs all",
      "rm -rf /run/cloud-init/*",
      "rm -rf /var/lib/cloud/*",
      "apt-get -y autopurge",
      "apt-get -y clean",
      "rm -rf /var/lib/apt/lists/*",
      "journalctl --flush",
      "journalctl --rotate --vacuum-time=0",
      "find /var/log -type f -exec truncate --size 0 {} \\;",
      "find /var/log -type f -name '*.[1-9]' -delete",
      "find /var/log -type f -name '*.gz' -delete",
      "rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub",
      "dd if=/dev/zero of=/zero bs=4M || true",
      "sync",
      "rm -f /zero"
    ]
  }
}
