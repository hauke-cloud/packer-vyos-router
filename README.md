<!-- llm-readme-management spec=1 commit=b5cad5d538cb2e555d1f684fe27f3ddca2afed62 template=packer model=qwen3.8-27b-q4 digest=2f64bab03d35 generated=2026-10-12T10:49:48Z -->
<a href="https://hauke.cloud" target="_blank"><img src="https://img.shields.io/badge/home-hauke.cloud-brightgreen" alt="hauke.cloud" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud" target="_blank"><img src="https://img.shields.io/badge/github-hauke.cloud-blue" alt="hauke.cloud Github Organisation" style="display: block;" /></a>
<a href="https://github.com/hauke-cloud/llm-readme-management" target="_blank"><img src="https://img.shields.io/badge/template-packer-orange" alt="Repository type - packer" style="display: block;" /></a>


# Template repository for Packer


<img src="https://raw.githubusercontent.com/hauke-cloud/.github/main/resources/img/organisation-logo-small.png" alt="hauke.cloud logo" width="109" height="123" align="right">


<llm header hint="Name the images this repository builds and the platform they are built for.">

This Packer template builds a VyOS 1.5 router snapshot image for Hetzner Cloud, pre-loaded with the `vyos-customization` and `vyos-hetzner-vrrp-failover` packages. If you need a ready-to-deploy VyOS router with Hetzner VRRP failover support, or you maintain the CI pipelines that produce and manage those snapshots, this repository is for you.

</llm>


## :book: Description

<llm description>

This repository provides a Packer build pipeline that produces a ready-to-use VyOS 1.5 router snapshot for Hetzner Cloud. The snapshot is built from a custom VyOS ISO that bundles two hauke-cloud packages—`vyos-customization` and `vyos-hetzner-vrrp-failover`—providing Hetzner-specific VRRP failover support.

The pipeline runs in GitHub Actions. A "Build ISO" workflow compiles the ISO from `vyos/vyos-build` with the custom packages injected. On success, "Packer LAB" and "Packer PROD" workflows download the ISO, boot a Hetzner server in rescue mode, run a direct installer (disk partitioning, GRUB, initial VyOS config), and publish a public snapshot labelled with version metadata. A nightly workflow prunes unprotected snapshots, keeping only the latest per major version.

- Builds a VyOS 1.5 ISO with `vyos-customization` and `vyos-hetzner-vrrp-failover`
- Installs VyOS on a Hetzner Cloud server and creates a public snapshot
- Labels snapshots with `vyos.version`, `vyos.customization.version`, `vyos.vrrp-failover.version`, and optional `release.version`
- Runs separate lab and prod builds per ISO
- Nightly cleanup of stale, unprotected snapshots

The repository is one component of the `hauke-cloud` organisation's infrastructure tooling; the snapshot it produces is intended to be deployed as a Hetzner Cloud router instance.

</llm>


## :clipboard: Requirements

<llm requirements hint="The Packer version, the plugins from the required_plugins block, and the cloud credentials the builders need.">

- Packer with the `github.com/hetznercloud/hcloud` plugin (`~> 1`). No Packer version is pinned; CI installs `latest`.
- A Hetzner Cloud API token (exported as `HCLOUD_TOKEN`) with permission to create and destroy servers, create public snapshots, and delete images.
- A local VyOS ISO file. The `vyos_iso_path` variable must point to it; `vyos_iso_url` is declared but never consumed by the build.
- For GitHub Actions CI: repository secrets `HCLOUD_TOKEN`, `DOCKERHUB_USERNAME`, and `DOCKERHUB_TOKEN`.
- For the ISO build workflow: Docker with privileged container support, plus access to the `vyos/vyos-build:current` image and current GitHub releases of `hauke-cloud/vyos-customization` and `hauke-cloud/vyos-hetzner-vrrp-failover`.
- For contributors: `pre-commit` (see `CONTRIBUTING.md`).

</llm>


## 🚀 Getting started

<llm getting_started hint="packer init, validate and build with the real template paths and the variables the build requires.">

1. Clone the repository.

```bash
git clone https://github.com/hauke-cloud/packer-vyos-router.git
cd packer-vyos-router
```

2. Export your Hetzner Cloud API token. The template's `hcloud_token` variable defaults to `env("HCLOUD_TOKEN")`, so this is the conventional way to supply it locally.

```bash
export HCLOUD_TOKEN="your-hcloud-api-token"
```

3. Initialise the template to download the HCloud plugin.

```bash
packer init vyos.pkr.hcl
```

4. Validate the template with the variables your build requires.

```bash
packer validate \
  -var hcloud_token="$HCLOUD_TOKEN" \
  -var build_identifier="vyos-build" \
  -var vyos_iso_path="./vyos-1.5-custom-<version>.iso" \
  -var vyos_customization_version="<version>" \
  vyos.pkr.hcl
```

5. Run the build. Packer creates a Hetzner server in rescue mode, uploads the ISO and installer script, runs the VyOS installation, and publishes a public snapshot named `vyos-<vyos_version>-<timestamp>`.

```bash
packer build -color=false -force -on-error=cleanup \
  -var hcloud_token="$HCLOUD_TOKEN" \
  -var build_identifier="vyos-build" \
  -var vyos_iso_path="./vyos-1.5-custom-<version>.iso" \
  -var vyos_customization_version="<version>" \
  vyos.pkr.hcl
```

</llm>


## :airplane: Usage

<llm usage hint="Show how a built image is identified afterwards and how a variable file is passed in.">

Once you have a VyOS ISO (produced by the `build-iso.yaml` workflow or built locally), you create a Hetzner Cloud snapshot with `packer build`. Set your Hetzner API token as an environment variable, then pass the ISO path and version metadata as `-var` flags:

```bash
export HCLOUD_TOKEN="your-hetzner-api-token"

packer build \
  -var="vyos_iso_path=./VyOS-1.5-custom-1.2.3.iso" \
  -var="vyos_customization_version=1.2.3" \
  -var="release_version=1.0.0" \
  vyos.pkr.hcl
```

The build boots a `cx23` server in `nbg1` rescue mode, uploads the ISO and installer script, runs the partitioning and GRUB setup, and creates a public snapshot. In CI the command additionally uses `-on-error=cleanup` so Packer destroys the server if the build fails.

**Identifying the snapshot.** The resulting image is named `vyos-<vyos_version>-<YYYYMMDDhhmmss>` (for example `vyos-202601261300-20260126140000`). It carries the labels `name=vyos`, `vyos.version`, `vyos.customization.version`, `vyos.vrrp-failover.version`, and `managed-by=packer`. When you set `release_version`, the snapshot also receives `release.version` and `protected=true`, which exempts it from the nightly `cleanup-snapshots.yaml` job that otherwise deletes unprotected snapshots older than the latest per major version.

**CI pipeline.** Pushing to `main`, creating a tag matching `v*.*.*`, or dispatching the "Build ISO" workflow triggers the full pipeline: the ISO is built inside a privileged `vyos/vyos-build:current` Docker container, then both the `lab` and `prod` Packer builds run automatically in their respective GitHub environments.

</llm>


## :wrench: Configuration

<llm configuration hint="A table of the variables the templates declare: name, type, default, required.">

The Packer template `vyos.pkr.hcl` declares the variables below. All have defaults, so none are strictly required at parse time; however, `hcloud_token` and `vyos_iso_path` must be supplied at build time.

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `hcloud_token` | string (sensitive) | `env("HCLOUD_TOKEN")` | no | Hetzner Cloud API token. |
| `build_identifier` | string | `vyos-build` | no | Label applied to the build server and snapshot (`build=<id>`). |
| `vyos_version` | string | `202601261300` | no | VyOS build version; used in snapshot name and labels. |
| `vyos_customization_version` | string | `""` | no | Version of the `vyos-customization` package embedded in the ISO. |
| `vyos_vrrp_failover_version` | string | `""` | no | Version of the `vyos-hetzner-vrrp-failover` package in the ISO. |
| `release_version` | string | `""` | no | Semantic version (e.g. `1.0.0`); when set, adds `release.version` and `protected=true` labels to the snapshot. |
| `vyos_iso_path` | string | `""` | no | Local path to the VyOS ISO; the only ISO source consumed by the `file` provisioner. |
| `vyos_iso_url` | string | `""` | no | Declared but never referenced in the build; use `vyos_iso_path` instead. |
| `server_location` | string | `nbg1` | no | Hetzner datacenter location. |
| `server_image` | string | `debian-12` | no | Base image for rescue mode. |
| `server_type` | string | `cx23` | no | Hetzner server type to upgrade to. |
| `server_base_type` | string | `cx23` | no | Server type at creation. |
| `ssh_username` | string | `vyos` | no | Declared but not wired into the HCloud source (rescue mode hardcodes `root`). |
| `ssh_password` | string | `vyos` | no | Default VyOS password for live ISO boot. |

The full set lives in `vyos.pkr.hcl`.

</llm>


## 📄 License

This Project is licensed under the GNU General Public License v3.0

- see the [LICENSE](LICENSE) file for details.


## :coffee: Contributing

To become a contributor, please check out the [CONTRIBUTING](CONTRIBUTING.md) file.


## :email: Contact

For any inquiries or support requests, please open an issue in this
repository or contact us at [contact@hauke.cloud](mailto:contact@hauke.cloud).
