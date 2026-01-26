terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.44"
    }
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "snapshot_name" {
  description = "Name of the VyOS snapshot created by Packer"
  type        = string
  default     = "vyos-1.4-rolling-latest"
}

variable "ssh_keys" {
  description = "List of SSH key IDs or names to add to the server"
  type        = list(string)
  default     = []
}

provider "hcloud" {
  token = var.hcloud_token
}

# Get the VyOS snapshot
data "hcloud_image" "vyos" {
  with_selector = "os=vyos"
  most_recent   = true
}

# Create a server from the VyOS snapshot
resource "hcloud_server" "vyos" {
  name        = "vyos-router"
  server_type = "cx21"
  location    = "nbg1"
  image       = data.hcloud_image.vyos.id
  ssh_keys    = var.ssh_keys

  # Cloud-init configuration for VyOS
  user_data = templatefile("${path.module}/cloud-init-vyos.yaml", {
    hostname   = "vyos-router"
    ssh_keys   = var.ssh_keys
    dns_servers = ["1.1.1.1", "8.8.8.8"]
  })

  labels = {
    type = "router"
    os   = "vyos"
  }

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys
    ]
  }
}

# Optional: Create a private network
resource "hcloud_network" "private" {
  name     = "vyos-private-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Attach server to private network
resource "hcloud_server_network" "vyos_network" {
  server_id = hcloud_server.vyos.id
  network_id = hcloud_network.private.id
  ip        = "10.0.1.1"
}

# Outputs
output "vyos_ipv4" {
  description = "Public IPv4 address of VyOS server"
  value       = hcloud_server.vyos.ipv4_address
}

output "vyos_ipv6" {
  description = "Public IPv6 address of VyOS server"
  value       = hcloud_server.vyos.ipv6_address
}

output "vyos_private_ip" {
  description = "Private IP address of VyOS server"
  value       = hcloud_server_network.vyos_network.ip
}

output "vyos_ssh_command" {
  description = "SSH command to connect to VyOS"
  value       = "ssh vyos@${hcloud_server.vyos.ipv4_address}"
}
