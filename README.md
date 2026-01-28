

<a href="https://hauke.cloud" target="_blank"><img src="https://img.shields.io/badge/home-hauke.cloud-brightgreen" alt="hauke.cloud" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud" target="_blank"><img src="https://img.shields.io/badge/github-hauke.cloud-blue" alt="hauke.cloud Github Organisation" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud/readme-management" target="_blank"><img src="https://img.shields.io/badge/template-packer-orange" alt="Repository type - packer" style="display: block;" /></a>


# Packer VyOS Router


<img src="https://raw.githubusercontent.com/hauke-cloud/.github/main/resources/img/organisation-logo-small.png" alt="hauke.cloud logo" width="109" height="123" align="right">


Packer template to build a VyOS router server on Hetzner

## Features

- **Custom ISO Build Process**: Uses a wrapper script around VyOS's `build-vyos-image` to add custom APT repositories and packages
- **Automated Builds**: GitHub Actions workflow for nightly ISO builds
- **Package-Based Customization**: All customizations managed through the [vyos-customization](https://github.com/hauke-cloud/vyos-customization) Debian package
- **Cloud-Ready Images**: Generates VyOS images optimized for Hetzner Cloud

## Repository Structure

```
packer-vyos-router/
├── scripts/              # Build and deployment scripts
│   ├── build-vyos-image-wrapper    # VyOS build wrapper with custom repo support
│   ├── build-local-example.sh      # Local build example
│   ├── boot_iso.sh                 # ISO boot script for Packer
│   ├── install_vyos.sh             # VyOS installation script
│   └── download-release.sh         # Download VyOS ISO from releases
├── .github/workflows/    # GitHub Actions CI/CD workflows
├── vyos.pkr.hcl         # Packer template for Hetzner Cloud
└── release-artifacts/   # Build artifacts directory
```

See [PACKER_TEMPLATE.md](PACKER_TEMPLATE.md) for detailed documentation on the Packer template.

## Build Customization

This repository includes `build-vyos-image-wrapper`, a wrapper script that extends the official VyOS build process with support for custom APT repositories. This allows you to:

- Add custom APT repositories during the ISO build
- Install custom Debian packages from those repositories automatically
- Maintain all customizations in a versioned Debian package
- Maintain clean separation between upstream VyOS and your customizations

All configuration files, scripts, and customizations are now managed through the [vyos-customization](https://github.com/hauke-cloud/vyos-customization) Debian package, which is installed automatically during the ISO build process.

See [scripts/README.md](scripts/README.md) for detailed information about available scripts.


## 📄 License

This Project is licensed under the GNU General Public License v3.0

- see the [LICENSE](LICENSE) file for details.


## :coffee: Contributing

To become a contributor, please check out the [CONTRIBUTING](CONTRIBUTING.md) file.


## :email: Contact

For any inquiries or support requests, please open an issue in this
repository or contact us at [contact@hauke.cloud](mailto:contact@hauke.cloud).

