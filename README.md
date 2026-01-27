

<a href="https://hauke.cloud" target="_blank"><img src="https://img.shields.io/badge/home-hauke.cloud-brightgreen" alt="hauke.cloud" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud" target="_blank"><img src="https://img.shields.io/badge/github-hauke.cloud-blue" alt="hauke.cloud Github Organisation" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud/readme-management" target="_blank"><img src="https://img.shields.io/badge/template-packer-orange" alt="Repository type - packer" style="display: block;" /></a>


# Packer VyOS Router


<img src="https://raw.githubusercontent.com/hauke-cloud/.github/main/resources/img/organisation-logo-small.png" alt="hauke.cloud logo" width="109" height="123" align="right">


Packer template to build a VyOS router server on Hetzner

## Features

- **Custom ISO Build Process**: Uses a wrapper script around VyOS's `build-vyos-image` to add custom APT repositories and packages
- **Automated Builds**: GitHub Actions workflow for nightly ISO builds
- **Customization Support**: Integrates with [vyos-customization](https://github.com/hauke-cloud/vyos-customization) Debian packages
- **Cloud-Ready Images**: Generates VyOS images optimized for Hetzner Cloud

## Build Customization

This repository includes `build-vyos-image-wrapper`, a wrapper script that extends the official VyOS build process with support for custom APT repositories. This allows you to:

- Add custom APT repositories during the ISO build
- Install custom Debian packages from those repositories
- Maintain separation between upstream VyOS and your customizations

See [BUILD_WRAPPER_DOCUMENTATION.md](BUILD_WRAPPER_DOCUMENTATION.md) for detailed information about the wrapper script.


## 📄 License

This Project is licensed under the GNU General Public License v3.0

- see the [LICENSE](LICENSE) file for details.


## :coffee: Contributing

To become a contributor, please check out the [CONTRIBUTING](CONTRIBUTING.md) file.


## :email: Contact

For any inquiries or support requests, please open an issue in this
repository or contact us at [contact@hauke.cloud](mailto:contact@hauke.cloud).

