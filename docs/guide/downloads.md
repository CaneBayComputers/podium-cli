---
title: Downloads
layout: default
nav_order: 3
---

# Downloads

Podium is two pieces. The **CLI** does the work; the **GUI** is an optional
desktop front end for it. The GUI cannot run without the CLI, and installs it
for you if it is missing.

---

## Podium CLI

The CLI is shell scripts — nothing to compile, no dependencies to resolve — so it
installs with one command rather than a package:

```bash
# Debian / Ubuntu / Mint / Pop
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash
```

Swap the script for your platform: `install-fedora.sh`, `install-arch.sh`, or
`install-mac.sh`. Then run `podium configure` once.

Full details in **[Installation](../installation/)**.

**Why no `.deb` for the CLI?** There is nothing for a package to do here. The
installer places shell scripts and `podium update` keeps them current with a git
pull — a package manager would fight that rather than help it. The GUI is a
compiled Electron application, which is a genuinely different problem, so it
ships as packages.

---

## Podium GUI — v1.0.0-beta.1

{: .warning }
> **Beta.** Linux only, x86_64 only. See the caveats below before installing.

| Platform | Download |
|---|---|
| Debian / Ubuntu / Mint | [`podium-gui_1.0.0-beta.1_amd64.deb`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui_1.0.0-beta.1_amd64.deb) |
| Fedora / RHEL / Rocky | [`podium-gui-1.0.0-beta.1.x86_64.rpm`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui-1.0.0-beta.1.x86_64.rpm) |
| Arch / Manjaro | [`podium-gui-1.0.0-beta.1-x86_64.pkg.tar.zst`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui-1.0.0-beta.1-x86_64.pkg.tar.zst) |
| Checksums | [`SHA256SUMS.txt`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/SHA256SUMS.txt) |

[All release assets →](https://github.com/CaneBayComputers/podium-gui/releases/tag/v1.0.0-beta.1)

Verify before installing:

```bash
sha256sum -c SHA256SUMS.txt --ignore-missing
```

Installing the GUI also installs the CLI if `podium` is not already on your
machine, so you do not need both downloads.

### What is actually tested

Being straight about this, because "it built" and "it works" are different
claims:

- **`.deb` — installed and launched on a real machine** (Linux Mint): correct
  metadata, desktop entry appears, application starts.
- **`.rpm` and `.pkg.tar.zst` — built and inspected, not installed.** No Fedora
  or Arch machine was available to test on. They are very likely fine; they are
  not proven. If one fails, [open an issue](https://github.com/CaneBayComputers/podium-gui/issues)
  and it will get fixed quickly.

### Not available yet

- **macOS.** There is no `.dmg`. The packages are built on Linux, and macOS
  packaging requires a macOS host. Until that is set up, run the GUI from source
  on a Mac — see the [repository README](https://github.com/CaneBayComputers/podium-gui).
  The **CLI works fine on macOS** via `install-mac.sh`; only the desktop app is
  missing.
- **arm64.** x86_64 only for now, so no Raspberry Pi or Apple Silicon build.

---

## Versions

`podium --version` reports the CLI version. The GUI's About panel shows both, and
warns if they have drifted apart.

A mismatch is a **warning, not an error**. The GUI checks for individual CLI
capabilities rather than gating on a version number, so a newer GUI against an
older CLI loses specific features rather than refusing to start. You do not need
to upgrade both at the same time.

---

## Source

- [CaneBayComputers/podium-cli](https://github.com/CaneBayComputers/podium-cli) — MIT
- [CaneBayComputers/podium-gui](https://github.com/CaneBayComputers/podium-gui) — MIT

Podium is free and always will be. If it saves you time,
[buy me a coffee](https://ko-fi.com/canebaycomputers).
