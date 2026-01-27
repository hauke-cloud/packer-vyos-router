# Scripts Directory

This directory contains various scripts used in the VyOS build and deployment process.

## Build Scripts

### build-vyos-image-wrapper
Wrapper around the official VyOS `build-vyos-image` script that adds support for custom APT repositories and packages.

**Usage:**
```bash
./build-vyos-image-wrapper \
  --customization-mirror "https://hauke-cloud.github.io/vyos-customization/" \
  --customization-package "vyos-customization" \
  --architecture amd64 \
  --build-by "hauke-cloud" \
  generic
```

See [BUILD_WRAPPER_DOCUMENTATION.md](../BUILD_WRAPPER_DOCUMENTATION.md) for detailed documentation.

### build-local-example.sh
Example script demonstrating how to build a VyOS ISO locally using Docker and the build wrapper.

**Usage:**
```bash
./build-local-example.sh
```

Configure via environment variables:
- `BUILD_BY`: Builder identifier (default: hauke-cloud)
- `BUILD_VERSION`: Build version (default: auto-generated)
- `ARCHITECTURE`: Target architecture (default: amd64)
- `CUSTOMIZATION_MIRROR`: Custom APT repository URL
- `CUSTOMIZATION_PACKAGE`: Package to install

## Deployment Scripts

### boot_iso.sh
Boots the VyOS ISO on a Hetzner Cloud server by configuring GRUB to load the ISO.

Used by Packer during the image build process.

### install_vyos.sh
Installs VyOS to disk using the auto-install functionality.

Used by Packer during the image build process.

### download-release.sh
Downloads a VyOS ISO from the GitHub releases.

**Usage:**
```bash
./download-release.sh [VERSION]
```

If no version is specified, downloads the latest release.

## Integration

These scripts are used by:
- GitHub Actions workflows (`.github/workflows/`)
- Packer templates (`vyos.pkr.hcl`)
- Manual builds and deployments
