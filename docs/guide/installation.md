---
title: Installation
layout: default
nav_order: 2
---

# Installation

Zeltro runs on Linux, macOS, and Windows via WSL2.

On Windows, `install-windows.ps1` enables WSL2, installs Ubuntu, and installs
Zeltro inside it. It runs in two stages because enabling the WSL Windows
features needs a reboot; the installer schedules itself to resume automatically
after you log back in, so you reboot once and it finishes on its own. Run it
PowerShell as administrator: right-click it and choose Run as administrator.

WSL2 needs hardware virtualization: VT-x/AMD-V turned on in BIOS/UEFI, plus
SLAT. If the hypervisor cannot start, the Ubuntu download succeeds and then
registering it fails with `HCS_E_HYPERV_NOT_INSTALLED`. Note that this also
rules out running Zeltro inside a VirtualBox VM — VirtualBox does not pass
SLAT through to a guest, so WSL2 cannot start there at all.

Two things behave differently on Windows:

- **WSL shuts an idle distro down and stops its containers with it.** Keep a
  terminal open, or run `wsl -d Ubuntu-24.04 -u root -e sleep infinity`.
- **Browse projects with the LAN ACCESS address `zeltro status` prints.** It is
  the WSL VM's address, and it changes when WSL restarts — read it from status
  rather than bookmarking it.

---

## One-line install

Pick the line for your platform, then run `zeltro configure` once.

| Platform | Command |
|---|---|
| Debian / Ubuntu / Mint / Pop | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-ubuntu.sh \| bash` |
| Fedora / RHEL / Rocky / Alma | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-fedora.sh \| bash` |
| Arch / Manjaro / EndeavourOS | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-arch.sh \| bash` |
| macOS | `curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-mac.sh \| bash` |
| Windows (via WSL2) | `irm https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-windows.ps1 \| iex` |

Then, on every platform:

```bash
zeltro configure
```

Each installer sets up Docker, Node.js, Git, `jq`, `trash-cli`, ImageMagick and `rsvg-convert`, then installs the `zeltro` command to `/usr/local/bin`.

`zeltro configure` writes `/etc/zeltro-cli/.env`, picks a private Docker subnet, creates your projects directory, and installs bash tab-completion.

---

## Platform notes

### All Linux

You are added to the `docker` group during install. **Log out and back in** (or reboot) before using Zeltro, or Docker calls will be denied.

### macOS

You may need to start Docker Desktop manually after installation.

### Arch

`pacman -Syu` runs a full system upgrade, which often replaces the running kernel. When that happens Docker cannot start until you reboot — the installer detects this and prints a `REBOOT NOW` step. Reboot, then re-run the installer to finish.

### Fedora / RHEL — SELinux

Fedora and RHEL ship SELinux enforcing, and Zeltro bind-mounts each project directory into its container.

Docker CE disables SELinux confinement by default (containers run unconfined as `spc_t`), so this doesn't bite on a stock install. But the moment Docker's SELinux support is enabled (`"selinux-enabled": true` in `/etc/docker/daemon.json`), an unlabeled project directory gives every container `Permission denied`.

`zeltro configure` labels your projects directory `container_file_t` so Zeltro works either way. If you move your projects directory by hand, re-run `zeltro configure` to relabel it.

---

## Install from a local checkout

Use this if you want to hack on Zeltro itself. Running an installer from inside a checkout skips the `git clone` and symlinks `/usr/local/share/zeltro-cli` to your folder.

```bash
git clone https://github.com/CaneBayComputers/zeltro-cli.git
cd zeltro-cli
./install-ubuntu.sh      # or install-fedora.sh / install-arch.sh / install-mac.sh
```

---

## Configuration

Re-running `zeltro configure` is safe — existing values from `/etc/zeltro-cli/.env` are kept as defaults.

| Option | Description |
|---|---|
| `--git-name <name>` | Git user name |
| `--git-email <email>` | Git user email |
| `--projects-dir <dir>` | Projects directory (default `~/zeltro-projects`) |
| `--vpc-subnet <A.B.C>` | Docker VPC subnet (default: existing, or a random `10.x.x`) |
| `--non-interactive`, `-y` | Never prompt; accept defaults for anything not passed as a flag |

For a fully unattended setup — scripts, CI, provisioning an agent's machine:

```bash
zeltro configure --non-interactive \
  --git-name "Your Name" --git-email "you@example.com"
```

Zeltro does **not** ask for AWS credentials or GitHub authentication. Neither is
required: nothing in Zeltro uses AWS, and GitHub auth only matters for the
optional `--github` flags and `clone fork` / `clone new-repo`, which warn and
tell you to run `gh auth login` at the moment you actually use them.

The Docker VPC subnet is chosen for you — a private `/24` in the `10.x.x` range,
never `10.0.x`, so it can't collide with the `10.0.0.0/24` most home and office
LANs use. Override with `--vpc-subnet` if you need a specific range.

Tab-completion is installed for commands, project names, framework names and installer names:

```
zeltro ins<TAB>            → install
zeltro install gr<TAB>     → grafana  graylog  grocy
zeltro up <TAB>            → (your project names)
zeltro new <TAB>           → laravel  wordpress  fastapi  flask  django  ...
```

---

## The desktop app

[Zeltro GUI](https://github.com/CaneBayComputers/zeltro-gui) is optional. It
installs with one command, exactly like the CLI, and on Linux and macOS brings
this CLI with it if `zeltro` is missing:

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-gui/master/install-ubuntu.sh | bash
```

Swap for `install-fedora.sh`, `install-arch.sh` or `install-mac.sh`.

On Windows the GUI runs natively but drives Zeltro on *other* machines over SSH,
since there is no local Zeltro for it to talk to. See
[Downloads](../downloads/) for the details.

---

## Updating

```bash
zeltro update           # git pull the CLI only — nothing else is touched
zeltro update --full    # also re-run the platform installer and re-pull Docker images
```

`--full` stops running projects.

---

## Uninstalling

```bash
zeltro uninstall                    # remove Zeltro's Docker containers, volumes, networks, hosts entries
zeltro uninstall --delete-images    # also remove the Docker images

sudo rm -f /usr/local/bin/zeltro
sudo rm -rf /usr/local/share/zeltro-cli
sudo rm -rf /etc/zeltro-cli         # optional: also remove configuration
```

On macOS with Homebrew, `brew uninstall zeltro-cli` runs the cleanup for you.

**Removed:** Zeltro service containers, project containers, volumes, networks, `/etc/hosts` entries. Project `docker-compose.yaml` files are backed up as `.backup`.

**Kept:** all your project source code, non-Zeltro containers and images, and Docker itself.
