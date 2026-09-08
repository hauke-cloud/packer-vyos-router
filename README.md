<!-- llm-readme-management spec=1 commit=b5cad5d538cb2e555d1f684fe27f3ddca2afed62 template=packer model=qwen3.6-35b-a3b digest=2f64bab03d35 generated=2026-09-08T22:45:57Z -->
<a href="https://hauke.cloud" target="_blank"><img src="https://img.shields.io/badge/home-hauke.cloud-brightgreen" alt="hauke.cloud" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud" target="_blank"><img src="https://img.shields.io/badge/github-hauke.cloud-blue" alt="hauke.cloud Github Organisation" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud/llm-readme-management" target="_blank"><img src="https://img.shields.io/badge/template-packer-orange" alt="Repository type - packer" style="display: block;" /></a>


# Template repository for Packer


<img src="https://raw.githubusercontent.com/hauke-cloud/.github/main/resources/img/organisation-logo-small.png" alt="hauke.cloud logo" width="109" height="123" align="right">


<llm header hint="Name the images this repository builds and the platform they are built for.">

This Packer template builds customized VyOS router images for deployment on Hetzner Cloud. It packages custom Debian modules into a bootable ISO, provisions a rescue VM to install the OS, and generates labeled server snapshots. Keep reading if you manage reproducible infrastructure automation for the hauke.cloud operations team or similar Hetzner-based deployments.

</llm>


## :book: Description

<llm description>

You use this repository to support the hauke.cloud infrastructure team by building customized VyOS router images for Hetzner Cloud. The Packer template and CI pipeline produce reproducible server snapshots that embed specific Debian packages, such as `vyos-customization` and `vyos-hetzner-vrrp-failover`, directly into the operating system before provisioning.

The workflow downloads a VyOS 1.5 rolling ISO, injects custom `.deb` packages from GitHub releases, and passes the result to the official `vyos/vyos-build` container. Packer provisions a Debian 12 rescue VM on Hetzner, installs VyOS via a direct-install script, creates a labeled snapshot, and tears down the build server.

*   Builds customized VyOS ISOs with pinned custom packages in a two-stage CI pipeline.
*   Provisions Hetzner Cloud servers using Packer with the `hcloud` provider.
*   Creates production or lab snapshots based on consumed ISO artifacts.
*   Manages nightly cleanup of un-protected snapshots and weekly expiry of tangling images.

</llm>


## :clipboard: Requirements

<llm requirements hint="The Packer version, the plugins from the required_plugins block, and the cloud credentials the builders need.">

Before using this repository, you must have:
- A Hetzner Cloud account with an API token (`HCLOUD_TOKEN`) granting read/write access to servers, images/snapshots, and SSH keys.
- Docker Hub credentials (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`) for the ISO-build step.
- Packer (latest version) and the `hcloud` plugin (`~> 1`).
- The `hcloud` CLI (installed via `3bit/setup-hcloud@v2`).
- Docker Engine configured with privileged mode.
- An Ubuntu 22.04 runner environment for ISO builds, preinstalled with git, build-essential, python3, python3-pip, python3-venv, squashfs-tools, genisoimage, fakechroot, and jq.
- GitHub environments configured: `docker.build`, `prod`, and `lab`/`public`.

</llm>


## 🚀 Getting started

<llm getting_started hint="packer init, validate and build with the real template paths and the variables the build requires.">

1. You clone the repository and enter its directory.
```bash
git clone https://github.com/hauke-cloud/packer-vyos-router.git
cd packer-vyos-router
```
2. You initialize Packer to download the required `hcloud` plugin for your environment.
```bash
packer init vyos.pkr.hcl
```
3. You validate the template with your Hetzner Cloud token and any custom variables.
```bash
packer validate -var hcloud_token=$TOKEN ... vyos.pkr.hcl
```
4. You build the customized VyOS snapshot on a Hetzner rescue server.
```bash
packer build -color=false -force -on-error=cleanup -var hcloud_token=$TOKEN ... vyos.pkr.hcl
```

</llm>


## :airplane: Usage

<llm usage hint="Show how a built image is identified afterwards and how a variable file is passed in.">

- **Run a local build.** Prepare a variable file with your Hetzner credentials and environment settings, then initialize the plugin and execute the template. Packer provisions a Debian 12 rescue VM on Hetzner, upgrades it to `cx23`, installs VyOS from the prepared ISO, and creates a snapshot.
  ```bash
  packer init vyos.pkr.hcl
  packer build -color=false -force -on-error=cleanup -var-file=vars.pkrvars.hcl vyos.pkr.hcl
  ```

- **Pass configuration via a variable file.** Store sensitive tokens and environment overrides in a `.pkrvars.hcl` file to keep your command line clean. The template accepts `hcloud_token`, `build_identifier`, `server_location`, and `release_version`.
  ```hcl
  hcloud_token = "your-hcloud-api-token"
  build_identifier = "vyos-build-2024"
  server_location = "nbg1"
  release_version = "1.5-rolling"
  ```

- **Identify the built image.** After provisioning finishes, Packer leaves a labeled snapshot on Hetzner Cloud. You locate it using the `build_identifier` tag, or if you provided `release_version`, the snapshot is permanently protected and labeled accordingly. The temporary build server is automatically destroyed during cleanup.

</llm>


## :wrench: Configuration

<llm configuration hint="A table of the variables the templates declare: name, type, default, required.">

This repository exposes configuration through Packer variables defined in `vyos.pkr.hcl`. You can override these values at build time to target different Hetzner Cloud environments, specify custom VyOS versions, or inject local ISO files instead of downloading them. The following table lists the primary variables declared by the template:

| Name | Type | Default | Required |
|------|------|---------|----------|
| `hcloud_token` | string (sensitive) | from env `HCLOUD_TOKEN` | Yes |
| `build_identifier` | string | `"vyos-build"` | No |
| `vyos_version` | string | `"202601261300"` | No |
| `vyos_customization_version` | string | `""` (empty) | No |
| `vyos_vrrp_failover_version` | string | `""` (empty) | No |
| `release_version` | string | `""` (empty) | No |
| `vyos_iso_url` | string | `""` (empty) | No |
| `vyos_iso_path` | string | `""` (empty) | No |
| `server_location` | string | `"nbg1"` | No |
| `server_image` | string | `"debian-12"` | No |
| `server_type` | string | `"cx23"` | No |
| `server_base_type` | string | `"cx23"` | No |
| `ssh_username` | string | `"vyos"` | No |
| `ssh_password` | string | `"vyos"` | No |

The table covers the core inputs. You pass these variables via `-var` flags or environment files when invoking Packer. The long tail is omitted; refer to `vyos.pkr.hcl` for the complete declaration set.

</llm>


## 📄 License

This Project is licensed under the GNU General Public License v3.0

- see the [LICENSE](LICENSE) file for details.


## :coffee: Contributing

To become a contributor, please check out the [CONTRIBUTING](CONTRIBUTING.md) file.


## :email: Contact

For any inquiries or support requests, please open an issue in this
repository or contact us at [contact@hauke.cloud](mailto:contact@hauke.cloud).
