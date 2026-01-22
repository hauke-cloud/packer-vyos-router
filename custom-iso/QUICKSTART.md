# Quick Start - Customizing Your VyOS ISO

This guide will help you quickly customize your VyOS ISO build.

## 🚀 Quick Steps

### 1. Set a Secure Password

Generate an encrypted password:
```bash
cd custom-iso
./generate-password.sh
```

Copy the output and paste it into `config/config.boot.default`:
```
system {
    login {
        user vyos {
            authentication {
                encrypted-password "$6$rounds=656000$YOUR_ENCRYPTED_PASSWORD_HERE"
            }
        }
    }
}
```

### 2. Customize Default Configuration

Edit `config/config.boot.default` to set your defaults:
- Hostname
- Network interfaces
- SSH settings
- NTP servers
- Any other VyOS configuration

### 3. Add Post-Install Commands (Optional)

Edit `scripts/postinst` to add commands that run after installation:
```bash
#!/bin/bash
source /opt/vyatta/sbin/install-functions

# Your custom commands here
echo "Custom setup completed at $(date)" > /var/log/custom-install.log
```

### 4. Add Additional Files (Optional)

Place any files in `includes/` following Linux filesystem structure:
```
includes/
├── etc/
│   └── custom-config.conf
├── usr/local/bin/
│   └── my-script.sh
└── opt/
    └── my-app/
```

### 5. Build Your ISO

Commit and push your changes:
```bash
git add custom-iso/
git commit -m "Customize VyOS ISO configuration"
git push
```

The GitHub Actions workflow will automatically:
1. Checkout the vyos-build repository
2. Copy your custom files into the build
3. Build the ISO with your customizations
4. Upload the ISO as a workflow artifact

### 6. Download Your Custom ISO

1. Go to GitHub Actions in your repository
2. Find the latest "VyOS nightly build" workflow run
3. Download the ISO artifact

## 📝 Common Customizations

### SSH with Public Key Only
```
service {
    ssh {
        port 22
        disable-password-authentication
    }
}
```

### Static Network Configuration
```
interfaces {
    ethernet eth0 {
        address 192.168.1.1/24
        description "LAN"
    }
    ethernet eth1 {
        address dhcp
        description "WAN"
    }
}
```

### Enable DHCP Server
```
service {
    dhcp-server {
        shared-network-name LAN {
            subnet 192.168.1.0/24 {
                default-router 192.168.1.1
                range 0 {
                    start 192.168.1.100
                    stop 192.168.1.200
                }
            }
        }
    }
}
```

## 🔧 Troubleshooting

**Q: My config.boot.default isn't being applied**
- Check file location: `custom-iso/config/config.boot.default`
- Verify VyOS syntax is correct
- Check GitHub Actions logs for copy errors

**Q: postinst script isn't running**
- Ensure it's executable: `chmod +x custom-iso/scripts/postinst`
- Check script syntax with `bash -n custom-iso/scripts/postinst`
- Look for errors in VyOS installation logs

**Q: How do I test my changes?**
- Build the ISO
- Boot in a VM (VirtualBox, QEMU, etc.)
- Check configuration: `show configuration`
- Install to disk and verify postinst ran

## 📚 Resources

- [VyOS Documentation](https://docs.vyos.io)
- [VyOS Build Guide](https://docs.vyos.io/en/latest/contributing/build-vyos.html)
- [VyOS Configuration Syntax](https://docs.vyos.io/en/latest/configuration/index.html)
- Full documentation: See `README.md` in this directory
