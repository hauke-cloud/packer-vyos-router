# VyOS ISO Customization

This directory contains custom configuration files that will be embedded into the VyOS ISO during the build process.

## Directory Structure

```
custom-iso/
├── config/
│   └── config.boot.default     # Default VyOS configuration
├── scripts/
│   └── postinst                # Post-installation script
├── includes/                   # Additional files to include in ISO
└── README.md                   # This file
```

## Automatic Cloud-Init Integration

Cloud-init example configurations from the repository root are automatically embedded in the ISO:

- `cloud-init.yaml.example` → `/opt/vyatta/etc/cloud-init/cloud-init.yaml.example`
- `cloud-init-vyos.yaml` → `/opt/vyatta/etc/cloud-init/cloud-init-vyos.example.yaml`
- `cloud-init-gateway.yaml` → `/opt/vyatta/etc/cloud-init/cloud-init-gateway.example.yaml`

A helper command `install-cloud-config` is also included in the ISO for easy installation.

## config.boot.default

This file contains the default VyOS configuration that will be present on newly installed systems. 

**Important Notes:**
- Use VyOS configuration syntax
- Set a secure encrypted password for the vyos user (generate with: `mkpasswd --method=sha-512`)
- Configure initial network settings, SSH, and other services as needed
- This becomes `/opt/vyatta/etc/config.boot.default` in the ISO

**Example: Generate encrypted password**
```bash
mkpasswd --method=sha-512 --rounds=656000
```

## postinst Script

This script runs after the VyOS system is installed to disk. Use it to:
- Perform one-time setup tasks
- Configure system-level settings
- Install additional packages
- Set up custom services or scripts

**Important Notes:**
- Must be executable (chmod +x)
- Runs as root during installation
- Located at `/opt/vyatta/etc/install-image/postinst` in the ISO
- Keep it lightweight - heavy operations should be done post-boot

## Using Cloud-Init in the ISO

After installing VyOS from the custom ISO, you can install cloud-init examples:

```bash
# List available cloud-init examples
install-cloud-config

# Install a specific example
install-cloud-config cloud-init-vyos

# This copies the example to /opt/vyatta/etc/cloud/cloud.cfg.d/99-custom.cfg
```

## Usage

1. **Edit config.boot.default**: Customize your default VyOS configuration
2. **Edit postinst**: Add any post-installation commands
3. **Add custom files**: Place any additional files in `includes/` directory
4. **Commit changes**: Push to your repository
5. **Build ISO**: The GitHub Actions workflow will automatically include your customizations

## Testing

After building the ISO with your customizations:
1. Boot the ISO in a VM
2. Check that the default config is applied: `show configuration`
3. Install to disk and verify the postinst script ran successfully
4. Check logs: `show log` or `/var/log/vyos/`
5. Test cloud-init installation: `install-cloud-config`

## Examples

### config.boot.default - Basic Setup
```
system {
    host-name vyos-router
    login {
        user admin {
            authentication {
                encrypted-password "$6$..."
            }
            level admin
        }
    }
}

interfaces {
    ethernet eth0 {
        address dhcp
        description "WAN"
    }
}

service {
    ssh {
        port 22
    }
}
```

### postinst - Custom Script
```bash
#!/bin/bash
# Install additional tools
if [ -d "/live/image" ]; then
    echo "Installation completed at $(date)" > /live/image/install.log
fi
```
