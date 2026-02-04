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
  default     = ""
  description = "VyOS customization package version used in the ISO. Should match the version embedded in the ISO filename."
}

variable "release_version" {
  type        = string
  default     = ""
  description = "Release version tag (e.g., 1.0.0). Used to mark official releases in snapshot labels."
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

  # Base labels that are always included
  base_labels = {
    "name"                       = "vyos"
    "packer.io/build.id"         = "${uuidv4()}"
    "packer.io/build.time"       = "{{timestamp}}"
    "packer.io/version"          = "{{packer_version}}"
    "vyos.version"               = var.vyos_version
    "vyos.customization.version" = var.vyos_customization_version
    "managed-by"                 = "packer"
  }

  # Conditional labels for releases
  release_labels = var.release_version != "" ? {
    "release.version" = var.release_version
    "protected"       = "true"
  } : {}

  # Merge base and release labels
  build_labels = merge(local.base_labels, local.release_labels)
}

source "hcloud" "vyos" {
  token       = var.hcloud_token
  image       = var.server_image
  location    = var.server_location
  server_type = var.server_type
  rescue      = "linux64"

  server_name = "${var.build_identifier}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  server_labels = {
    build      = var.build_identifier
    managed-by = "packer"
  }

  ssh_username = "root"

  snapshot_name   = "vyos-${var.vyos_version}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  snapshot_labels = local.build_labels
}

build {
  name = "vyos-hetzner"

  source "source.hcloud.vyos" {}

  # Upload VyOS ISO
  provisioner "file" {
    source      = local.iso_source
    destination = "/tmp/boot.iso"
  }

  # Upload direct installation script
  provisioner "file" {
    source      = "${path.root}/scripts/install_vyos_direct.sh"
    destination = "/tmp/install_vyos_direct.sh"
  }

  # Install VyOS directly from Debian rescue system (no reboot needed)
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_vyos_direct.sh",
      "/tmp/install_vyos_direct.sh"
    ]
  }
}
