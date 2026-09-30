<!-- llm-readme-management spec=1 commit=b5cad5d538cb2e555d1f684fe27f3ddca2afed62 template=packer model=qwen3.8-27b-q4 digest=2f64bab03d35 generated=2026-09-30T14:39:36Z -->
<a href="https://hauke.cloud" target="_blank"><img src="https://img.shields.io/badge/home-hauke.cloud-brightgreen" alt="hauke.cloud" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud" target="_blank"><img src="https://img.shields.io/badge/github-hauke.cloud-blue" alt="hauke.cloud Github Organisation" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud/llm-readme-management" target="_blank"><img src="https://img.shields.io/badge/template-packer-orange" alt="Repository type - packer" style="display: block;" /></a>


# Template repository for Packer


<img src="https://raw.githubusercontent.com/hauke-cloud/.github/main/resources/img/organisation-logo-small.png" alt="hauke.cloud logo" width="109" height="123" align="right">


<llm header hint="Name the images this repository builds and the platform they are built for.">

This Packer template builds a customized VyOS router image as a Hetzner Cloud snapshot, injecting the `hauke-cloud/vyos-customization` and `hauke-cloud/vyos-hetzner-vrrp-failover` packages into the stock VyOS ISO. It is intended for operators with a Hetzner Cloud account who need to rebuild or reproduce the router snapshot used by hauke.cloud infrastructure.

</llm>


## :book: Description

<llm description>

This repository provides a Packer template and GitHub Actions pipeline that build a customized VyOS router image and publish it as a Hetzner Cloud snapshot. It targets operators who need to rebuild the VyOS router snapshot for a Hetzner Cloud environment.

The pipeline builds a VyOS ISO from upstream `vyos/vyos-build`, injecting custom `.deb` packages (`hauke-cloud/vyos-customization` and `hauke-cloud/vyos-hetzner-vrrp-failover`). It then runs Packer's `hcloud` builder in Hetzner rescue mode on a Debian 12 VM, where a script partitions the disk, copies the kernel, initrd, and squashfs, writes a default `config.boot`, and installs GRUB. The snapshot is named and labelled with version metadata.

- Builds a VyOS ISO from upstream source with custom packages
- Installs the ISO directly onto a Hetzner rescue VM
- Publishes the result as a labelled Hetzner Cloud snapshot
- Creates GitHub Releases with the ISO and metadata on version tags
- Runs nightly cleanup of old snapshots, keeping the latest per major version

Within the `hauke-cloud` organisation, this is one of the Packer template projects that feed the `hauke.cloud` infrastructure.

</llm>


## :clipboard: Requirements

<llm requirements hint="The Packer version, the plugins from the required_plugins block, and the cloud credentials the builders need.">

- HashiCorp Packer (no version pinned in the repository; CI installs the latest release)
- The `github.com/hetznercloud/hcloud` Packer plugin, `~> 1` (fetched automatically by `packer init`)
- A Hetzner Cloud account with an API token, supplied as the `HCLOUD_TOKEN` environment variable or the `hcloud_token` Packer variable
- A VyOS ISO file on local disk, referenced by the `vyos_iso_path` variable; obtain it from a `build-iso.yaml` GitHub Release or build it locally with Docker and the `vyos/vyos-build:current` image
- Read access to the latest GitHub Releases of `hauke-cloud/vyos-customization` and `hauke-cloud/vyos-hetzner-vrrp-failover` (each must contain a `.deb` asset)
- For CI runs: the GitHub repository secrets `HCLOUD_TOKEN`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, and the GitHub Environments `prod`, `lab`, `public`, and `docker.build`
- `pre-commit` for contributors (hooks pinned to `pre-commit/pre-commit-hooks` v4.4.0 and `zricethezav/gitleaks` v8.18.0)

</llm>


## 🚀 Getting started

<llm getting_started hint="packer init, validate and build with the real template paths and the variables the build requires.">

1. Clone the repository.

```bash
git clone https://github.com/hauke-cloud/packer-vyos-router.git
cd packer-vyos-router
```

2. With Packer installed, `HCLOUD_TOKEN` exported, and a VyOS ISO downloaded from a GitHub Release into the working directory, initialise the template to fetch the Hetzner Cloud plugin.

```bash
packer init vyos.pkr.hcl
```

3. Validate the template against your token and ISO path.

```bash
packer validate -var hcloud_token="$HCLOUD_TOKEN" -var vyos_iso_path="./vyos.iso" vyos.pkr.hcl
```

4. Build the snapshot in Hetzner Cloud.

```bash
packer build -var="vyos_iso_path=./vyos.iso" vyos.pkr.hcl
```

</llm>


## :airplane: Usage

<llm usage hint="Show how a built image is identified afterwards and how a variable file is passed in.">

Once you have a VyOS ISO (from a GitHub Release or a local build), you run the Packer template to produce a Hetzner Cloud snapshot.

**Run the Packer build**

```bash
packer init vyos.pkr.hcl
packer build \
  -var="vyos_iso_path=./vyos-1.5-rolling-202601261300.iso" \
  -var="vyos_customization_version=1.2.0" \
  -var="release_version=1.5.0" \
  vyos.pkr.hcl
```

The `hcloud_token` variable defaults to the `HCLOUD_TOKEN` environment variable, so export it before running. The `vyos_customization_version` and `release_version` flags are optional; when `release_version` is set the snapshot receives `protected=true` so the nightly cleanup job keeps it.

**Identify the resulting snapshot**

The snapshot is named `vyos-<vyos_version>-<YYYYMMDDhhmmss>` (for example `vyos-202601261300-20260126140000`) and carries the labels `name=vyos`, `managed-by=packer`, `vyos.version`, `vyos.customization.version`, and `vyos.vrrp-failover.version`. You can list matching snapshots with the `hcloud` CLI:

```bash
hcloud snapshot list --label name=vyos
```

**Build the ISO locally**

If you do not want to wait for a GitHub Release, `scripts/build-local-example.sh` clones `vyos/vyos-build`, pulls the `vyos/vyos-build:current` Docker image, and runs the build with the `hauke-cloud/vyos-customization` and `hauke-cloud/vyos-hetzner-vrrp-failover` packages injected:

```bash
./scripts/build-local-example.sh
```

The script honours the `BUILD_BY` (default `hauke-cloud`) and `BUILD_VERSION` (default `1.5-rolling-<UTC YYYYmmddHHMM>`) environment variables.

</llm>


## :wrench: Configuration

<llm configuration hint="A table of the variables the templates declare: name, type, default, required.">

The template `vyos.pkr.hcl` declares the variables below. All have defaults and none are hard-required by Packer, but `hcloud_token` and `vyos_iso_path` are effectively mandatory for a working build.

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `hcloud_token` | string (sensitive) | `env("HCLOUD_TOKEN")` | yes | Hetzner Cloud API token. |
| `vyos_iso_path` | string | `""` | yes | Local path to the VyOS ISO consumed by the file provisioner. |
| `vyos_iso_url` | string | `""` | no | Declared but never referenced; URL-based builds are not supported. |
| `build_identifier` | string | `"vyos-build"` | no | Used in the server name and `build=` label for cleanup. |
| `vyos_version` | string | `"202601261300"` | no | Stamped into the snapshot name and `vyos.version` label. |
| `vyos_customization_version` | string | `""` | no | Label-only; value comes from the ISO artifact metadata. |
| `vyos_vrrp_failover_version` | string | `""` | no | Label-only; value comes from the ISO artifact metadata. |
| `release_version` | string | `""` | no | When set, adds `release.version` and `protected=true` labels. |
| `server_location` | string | `"nbg1"` | no | Hetzner datacenter location. |
| `server_image` | string | `"debian-12"` | no | Rescue image for the build VM. |
| `server_type` | string | `"cx23"` | no | Server type after the rescue upgrade. |
| `server_base_type` | string | `"cx23"` | no | Server type at creation (rescue mode). |
| `ssh_username` | string | `"vyos"` | no | Declared but unused; the source hardcodes `root`. |
| `ssh_password` | string | `"vyos"` | no | Declared but unused. |

See `vyos.pkr.hcl` for the full declaration. CI workflows additionally pass `build_identifier`, `server_location`, `server_type`, and the version variables through the `build-image` composite action (`.github/actions/build-image/action.yml`).

</llm>


## 📄 License

This Project is licensed under the GNU General Public License v3.0

- see the [LICENSE](LICENSE) file for details.


## :coffee: Contributing

To become a contributor, please check out the [CONTRIBUTING](CONTRIBUTING.md) file.


## :email: Contact

For any inquiries or support requests, please open an issue in this
repository or contact us at [contact@hauke.cloud](mailto:contact@hauke.cloud).
