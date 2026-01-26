# Advanced Terraform Example: VyOS as VPN Gateway with WireGuard

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

variable "ssh_keys" {
  description = "List of SSH key names"
  type        = list(string)
}

variable "wireguard_clients" {
  description = "WireGuard client configurations"
  type = map(object({
    public_key = string
    ip_address = string
  }))
  default = {}
}

provider "hcloud" {
  token = var.hcloud_token
}

# Get the VyOS snapshot
data "hcloud_image" "vyos" {
  with_selector = "os=vyos"
  most_recent   = true
}

# Private network
resource "hcloud_network" "main" {
  name     = "vyos-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "lan" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# VyOS Router/VPN Gateway
resource "hcloud_server" "vyos_gateway" {
  name        = "vyos-vpn-gateway"
  server_type = "cpx11"
  location    = "nbg1"
  image       = data.hcloud_image.vyos.id
  ssh_keys    = var.ssh_keys

  user_data = templatefile("${path.module}/cloud-init-gateway.yaml", {
    hostname          = "vyos-vpn-gateway"
    dns_servers       = ["1.1.1.1", "8.8.8.8"]
    wireguard_port    = 51820
    wireguard_network = "10.99.0.0/24"
    wireguard_clients = var.wireguard_clients
  })

  labels = {
    role = "vpn-gateway"
    os   = "vyos"
  }
}

resource "hcloud_server_network" "vyos_gateway_network" {
  server_id = hcloud_server.vyos_gateway.id
  network_id = hcloud_network.main.id
  ip        = "10.0.1.1"
}

# Example: Protected server behind VyOS
resource "hcloud_server" "backend" {
  name        = "backend-server"
  server_type = "cx11"
  location    = "nbg1"
  image       = "ubuntu-22.04"
  ssh_keys    = var.ssh_keys

  network {
    network_id = hcloud_network.main.id
    ip         = "10.0.1.10"
  }

  labels = {
    role = "backend"
  }
}

# Outputs
output "vyos_public_ip" {
  description = "VyOS Gateway public IP"
  value       = hcloud_server.vyos_gateway.ipv4_address
}

output "vyos_private_ip" {
  description = "VyOS Gateway private IP"
  value       = hcloud_server_network.vyos_gateway_network.ip
}

output "wireguard_config" {
  description = "WireGuard connection endpoint"
  value       = "${hcloud_server.vyos_gateway.ipv4_address}:51820"
}

output "ssh_commands" {
  value = {
    vyos    = "ssh vyos@${hcloud_server.vyos_gateway.ipv4_address}"
    backend = "ssh root@${hcloud_server.backend.ipv4_address}"
  }
}
