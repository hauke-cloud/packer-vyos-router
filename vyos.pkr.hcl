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
  description = "VyOS build version (e.g., 202601260039). Must match a release built with vyos-customization package."
}

variable "vyos_customization_version" {
  type        = string
  default     = "v0.0.3"
  description = "VyOS customization package version. Note: This is only for reference; the actual ISO filename includes the customization version."
}

variable "vyos_iso_url" {
  type        = string
  default     = ""
  description = "VyOS ISO URL. If empty, will be constructed from vyos_version. Note: ISOs now include customization version in filename (e.g., vyos-1.5-rolling-VERSION-generic-amd64-custom-v0.0.1.iso)"
}

variable "vyos_iso_path" {
  type        = string
  default     = ""
  description = "Path to local VyOS ISO file. If provided, this takes precedence over vyos_iso_url."
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
  # Use local ISO path if provided, otherwise use URL
  iso_source = var.vyos_iso_path

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

  provisioner "file" {
    source      = local.iso_source
    destination = "/tmp/boot.iso"
  }

  # Boot into VyOS live ISO
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
    pause_after = "60s"
  }

  provisioner "shell" {
    inline = [
      "sudo /usr/local/bin/install-image",
      "sudo reboot -f"
    ]
  }
}
