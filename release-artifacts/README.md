# VyOS Custom ISO Release

## Files Included

- **ISO File**: `vyos-1.5-rolling-202601260003-generic-amd64.iso` - The custom VyOS ISO image
- **manifest.json**: Build manifest with metadata
- **cloud-init examples**: Example cloud-init configuration files

## Usage

### 1. Download the ISO

Download the ISO file from this release and use it to install VyOS.

### 2. Cloud-Init Configuration

The included cloud-init example files show how to configure VyOS on first boot:

- `cloud-init.yaml.example` - Basic cloud-init template
- `cloud-init-vyos.example.yaml` - VyOS-specific configuration
- `cloud-init-gateway.example.yaml` - Gateway/router configuration

### 3. Using with Hetzner Cloud

```bash
# Create server with cloud-init
hcloud server create \
  --name vyos-router \
  --type cx23 \
  --image <snapshot-id> \
  --location nbg1 \
  --user-data-from-file cloud-init-vyos.yaml
```

## Build Information

- **Version**: 1.5-rolling-202601260003
- **Built by**: hauke-cloud
- **Build time**: 2026-01-26T00:03:11Z
- **Architecture**: amd64
- **Type**: rolling release

## Customizations

This ISO includes custom configurations from the repository:
- Custom default configuration (if present)
- Post-installation scripts (if present)
- Additional packages and modifications

See the repository for full customization details.
