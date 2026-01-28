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

variable "vyos_iso_url" {
  type        = string
  default     = ""
  description = "VyOS ISO URL. If empty, will be constructed from vyos_version. Note: ISOs now include customization version in filename (e.g., vyos-1.5-rolling-VERSION-generic-amd64-custom-v0.0.1.iso)"
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
  # Note: The actual ISO filename includes the customization version
  # Format: vyos-1.5-rolling-${version}-generic-amd64-custom-${customization_version}.iso
  # Since customization_version is dynamic, specify the full URL with vyos_iso_url variable
  # or use the latest release URL
  iso_url = var.vyos_iso_url != "" ? var.vyos_iso_url : "https://github.com/hauke-cloud/packer-vyos-router/releases/latest/download/vyos-1.5-rolling-${var.vyos_version}-generic-amd64-custom-v0.0.1.iso"

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

  # Download the custom VyOS ISO that includes vyos-customization package
  # The ISO must be built with --customization-mirror and --customization-package
  # to include the vyos-auto-install script and default configuration
  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "echo 'Downloading VyOS ISO...'",
      "curl -L -o /tmp/boot.iso '${local.iso_url}'",
      "ls -lh /tmp/boot.iso"
    ]
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
  }

  # Verify vyos-customization package files are present in the ISO
  provisioner "shell" {
    inline = [
      "echo 'VyOS live system ready'",
      "cat /etc/os-release || true",
      "echo 'Checking for vyos-auto-install from vyos-customization package...'",
      "ls -l /usr/local/bin/vyos-auto-install 2>/dev/null && echo '✓ Found auto-install script at /usr/local/bin (from vyos-customization package)' || echo '✗ Auto-install script not found'",
      "ls -l /opt/vyatta/etc/config.boot.default 2>/dev/null && echo '✓ Found default config (from vyos-customization package)' || echo 'ℹ No custom default config'",
      "ls -l /opt/vyatta/etc/install-image/postinst 2>/dev/null && echo '✓ Found postinst script (from vyos-customization package)' || echo 'ℹ No custom postinst script'"
    ]
  }

  # Install VyOS to disk using vyos-auto-install
  # The vyos-auto-install script is provided by the vyos-customization package
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
