packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
  default   = env("HCLOUD_TOKEN")
}

variable "build_identifier" {
  type    = string
  default = "vyos-build"
}

variable "vyos_version" {
  type        = string
  default     = "202601261300"
  description = "VyOS build version (e.g., 202601260039)"
}

variable "vyos_iso_url" {
  type        = string
  default     = ""
  description = "VyOS ISO URL. If empty, will be constructed from vyos_version"
}

variable "server_location" {
  type    = string
  default = "nbg1"
}

variable "server_image" {
  type    = string
  default = "debian-12"
}

variable "server_type" {
  type        = string
  default     = "cx23"
  description = "Server type for building. cx22 is cost-efficient for builds."
}

variable "ssh_username" {
  type    = string
  default = "vyos"
}

variable "ssh_password" {
  type        = string
  default     = "vyos"
  description = "Default VyOS password for live ISO boot"
}

locals {
  iso_url = var.vyos_iso_url != "" ? var.vyos_iso_url : "https://github.com/hauke-cloud/packer-vyos-router/releases/download/v1.5-rolling-${var.vyos_version}/vyos-1.5-rolling-${var.vyos_version}-generic-amd64.iso"

  build_labels = {
    "name"                 = "vyos"
    "packer.io/build.id"   = uuidv4()
    "packer.io/build.time" = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    "packer.io/version"    = packer.version
    "vyos.version"         = var.vyos_version
    "managed-by"           = "packer"
  }
}

source "hcloud" "vyos" {
  token       = var.hcloud_token
  image       = var.server_image
  location    = var.server_location
  server_type = var.server_type

  server_name = "${var.build_identifier}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  server_labels = {
    build      = var.build_identifier
    managed-by = "packer"
  }

  ssh_username = var.ssh_username
  # After ISO boot, we need to use password auth since SSH keys are lost
  ssh_password = var.ssh_password

  user_data = <<-EOF
    #cloud-config
    system_info:
      default_user:
        name: ${var.ssh_username}
  EOF

  snapshot_name   = "vyos-${var.vyos_version}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  snapshot_labels = local.build_labels
}

build {
  name = "vyos-hetzner"

  source "source.hcloud.vyos" {}

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "echo 'Downloading VyOS ISO...'",
      "curl -L -o /tmp/boot.iso '${local.iso_url}'",
      "ls -lh /tmp/boot.iso"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/boot_iso.sh"
    destination = "/tmp/boot_iso.sh"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "chmod +x /tmp/boot_iso.sh",
      "sudo /tmp/boot_iso.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'VyOS live system ready'",
      "cat /etc/os-release || true",
      "ls -l /usr/local/bin/vyos-auto-install 2>/dev/null && echo 'Found auto-install script at /usr/local/bin' || true",
      "ls -l /usr/bin/vyos-auto-install 2>/dev/null && echo 'Found auto-install script at /usr/bin' || true",
      "[ ! -f /usr/local/bin/vyos-auto-install ] && [ ! -f /usr/bin/vyos-auto-install ] && echo 'Auto-install script not found in ISO' || true"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/install_vyos.sh"
    destination = "/tmp/install_vyos.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_vyos.sh",
      "/tmp/install_vyos.sh"
    ]
  }
}
