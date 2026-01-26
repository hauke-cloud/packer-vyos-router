# Quick Start Guide

This guide provides quick instructions for using VyOS ISO releases from this repository.

## 📥 Download Release

### Option 1: Download Script (Recommended)

```bash
# Download the helper script
curl -O https://raw.githubusercontent.com/hauke-cloud/packer-vyos-router/main/download-release.sh
chmod +x download-release.sh

# Download latest release
./download-release.sh

# Or download specific version
./download-release.sh v1.5-rolling-202601221200
```

### Option 2: Manual Download

1. Visit [Releases page](../../releases)
2. Download the latest ISO file
3. Download cloud-init example files
4. Download SHA256SUMS for verification

## ✅ Verify Download

```bash
cd downloads
sha256sum -c SHA256SUMS
```

## 🚀 Using the ISO

### Install VyOS

1. **Boot from ISO** - Use the downloaded ISO in your VM/cloud environment
2. **Install to disk** - Follow VyOS installation prompts
3. **Configure cloud-init** (optional) - Use embedded examples

### Embedded Cloud-Init Examples

After installing VyOS from the ISO, cloud-init examples are available:

```bash
# List available configurations
install-cloud-config

# Install VyOS configuration
install-cloud-config cloud-init-vyos

# Install gateway configuration
install-cloud-config cloud-init-gateway
```

Files are located at: `/opt/vyatta/etc/cloud-init/`

## ☁️ Deploy to Cloud

### Hetzner Cloud with Packer Snapshot

```bash
# Set your token
export HCLOUD_TOKEN="your-token-here"

# Create server from snapshot with cloud-init
hcloud server create \
  --name vyos-router \
  --type cx23 \
  --image <snapshot-id-from-packer-build> \
  --location nbg1 \
  --user-data-from-file cloud-init-vyos.yaml
```

### Using ISO Directly

1. Upload ISO to your hypervisor/cloud platform
2. Create VM from ISO
3. Install VyOS to disk
4. Configure using cloud-init or manually

## 🔧 Customize Cloud-Init

Edit the downloaded cloud-init YAML files:

```yaml
#cloud-config
# VyOS cloud-init configuration

vyos_config_commands:
  - set system host-name my-router
  - set interfaces ethernet eth0 address dhcp
  - set service ssh port 22

# SSH keys
ssh_authorized_keys:
  - ssh-rsa AAAAB3...your-key...
```

## 📦 Build Custom ISO

To create your own customized ISO:

1. **Fork this repository**
2. **Customize files**:
   - `custom-iso/config/config.boot.default` - Default VyOS config
   - `custom-iso/scripts/postinst` - Post-install script
   - `cloud-init-*.yaml` - Cloud-init templates
3. **Push to main branch** - Automatic build via GitHub Actions
4. **Download from Releases** - Your custom ISO

## 🐛 Troubleshooting

### ISO won't boot
- Verify SHA256 checksum
- Try re-downloading the ISO
- Check your virtualization platform supports ISO boot

### Cloud-init not working
- Verify cloud-init is installed: `dpkg -l | grep cloud-init`
- Check cloud-init logs: `sudo cloud-init status --long`
- View detailed logs: `sudo cat /var/log/cloud-init.log`

### Can't find install-cloud-config
- Command is only available after installing from custom ISO
- Located at: `/usr/local/bin/install-cloud-config`
- Manually copy examples from `/opt/vyatta/etc/cloud-init/`

## 📚 Additional Resources

- [VyOS Documentation](https://docs.vyos.io/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Repository README](README.md)
- [Custom ISO Documentation](custom-iso/README.md)

## 💡 Examples

### Basic Router Setup

```bash
# Download release
./download-release.sh

# Extract and verify
cd downloads
sha256sum -c SHA256SUMS

# Edit cloud-init configuration
cp cloud-init-vyos.example.yaml my-config.yaml
nano my-config.yaml

# Deploy to Hetzner
hcloud server create \
  --name my-router \
  --type cx23 \
  --image <snapshot-id> \
  --location nbg1 \
  --user-data-from-file my-config.yaml
```

### Manual Installation

```bash
# Boot from ISO
# ... installation prompts ...

# After installation and boot
install-cloud-config cloud-init-vyos

# Verify configuration
show configuration
```

## 🤝 Support

For issues or questions:
- Open an issue on [GitHub](../../issues)
- Contact: contact@hauke.cloud
