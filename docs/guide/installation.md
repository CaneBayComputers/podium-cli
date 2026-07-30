---
title: Installation
layout: default
nav_order: 2
---

# Installation

Podium runs on Linux and macOS. Windows is not supported — WSL may work but issues there will not be addressed.

---

## One-line install

Pick the line for your platform, then run `podium configure` once.

| Platform | Command |
|---|---|
| Debian / Ubuntu / Mint / Pop | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh \| bash` |
| Fedora / RHEL / Rocky / Alma | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-fedora.sh \| bash` |
| Arch / Manjaro / EndeavourOS | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-arch.sh \| bash` |
| macOS | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-mac.sh \| bash` |

Then, on every platform:

```bash
podium configure
```

Each installer sets up Docker, Node.js, Git, `jq`, `trash-cli`, ImageMagick and `rsvg-convert`, then installs the `podium` command to `/usr/local/bin`.

`podium configure` writes `/etc/podium-cli/.env`, picks a private Docker subnet, creates your projects directory, and installs bash tab-completion.

---

## Platform notes

### All Linux

You are added to the `docker` group during install. **Log out and back in** (or reboot) before using Podium, or Docker calls will be denied.

### macOS

You may need to start Docker Desktop manually after installation.

### Arch

`pacman -Syu` runs a full system upgrade, which often replaces the running kernel. When that happens Docker cannot start until you reboot — the installer detects this and prints a `REBOOT NOW` step. Reboot, then re-run the installer to finish.

### Fedora / RHEL — SELinux

Fedora and RHEL ship SELinux enforcing, and Podium bind-mounts each project directory into its container.

Docker CE disables SELinux confinement by default (containers run unconfined as `spc_t`), so this doesn't bite on a stock install. But the moment Docker's SELinux support is enabled (`"selinux-enabled": true` in `/etc/docker/daemon.json`), an unlabeled project directory gives every container `Permission denied`.

`podium configure` labels your projects directory `container_file_t` so Podium works either way. If you move your projects directory by hand, re-run `podium configure` to relabel it.

---

## Install from a local checkout

Use this if you want to hack on Podium itself. Running an installer from inside a checkout skips the `git clone` and symlinks `/usr/local/share/podium-cli` to your folder.

```bash
git clone https://github.com/CaneBayComputers/podium-cli.git
cd podium-cli
./install-ubuntu.sh      # or install-fedora.sh / install-arch.sh / install-mac.sh
```

---

## Configuration

Re-running `podium configure` is safe — existing values from `/etc/podium-cli/.env` are kept as defaults.

| Option | Description |
|---|---|
| `--git-name <name>` | Git user name |
| `--git-email <email>` | Git user email |
| `--projects-dir <dir>` | Projects directory (default `~/podium-projects`) |
| `--vpc-subnet <A.B.C>` | Docker VPC subnet (default: existing, or a random `10.x.x`) |
| `--non-interactive`, `-y` | Never prompt; accept defaults for anything not passed as a flag |

For a fully unattended setup — scripts, CI, provisioning an agent's machine:

```bash
podium configure --non-interactive \
  --git-name "Your Name" --git-email "you@example.com"
```

Podium does **not** ask for AWS credentials or GitHub authentication. Neither is
required: nothing in Podium uses AWS, and GitHub auth only matters for the
optional `--github` flags and `clone fork` / `clone new-repo`, which warn and
tell you to run `gh auth login` at the moment you actually use them.

The Docker VPC subnet is chosen for you — a private `/24` in the `10.x.x` range,
never `10.0.x`, so it can't collide with the `10.0.0.0/24` most home and office
LANs use. Override with `--vpc-subnet` if you need a specific range.

Tab-completion is installed for commands, project names, framework names and installer names:

```
podium ins<TAB>            → install
podium install gr<TAB>     → grafana  graylog  grocy
podium up <TAB>            → (your project names)
podium new <TAB>           → laravel  wordpress  fastapi  flask  django  ...
```

---

## Updating

```bash
podium update           # git pull the CLI only — nothing else is touched
podium update --full    # also re-run the platform installer and re-pull Docker images
```

`--full` stops running projects.

---

## Uninstalling

```bash
podium uninstall                    # remove Podium's Docker containers, volumes, networks, hosts entries
podium uninstall --delete-images    # also remove the Docker images

sudo rm -f /usr/local/bin/podium
sudo rm -rf /usr/local/share/podium-cli
sudo rm -rf /etc/podium-cli         # optional: also remove configuration
```

On macOS with Homebrew, `brew uninstall podium-cli` runs the cleanup for you.

**Removed:** Podium service containers, project containers, volumes, networks, `/etc/hosts` entries. Project `docker-compose.yaml` files are backed up as `.backup`.

**Kept:** all your project source code, non-Podium containers and images, and Docker itself.
