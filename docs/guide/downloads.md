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
> **Beta.** Linux x86_64 and macOS. Read the macOS note and the testing status below before installing.

| Platform | Download | Size |
|---|---|---|
| Debian / Ubuntu / Mint / Zorin / Pop!_OS | [`.deb`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui_1.0.0-beta.1_amd64.deb) | 71 MB |
| Fedora / RHEL / Rocky / openSUSE | [`.rpm`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui-1.0.0-beta.1.x86_64.rpm) | 71 MB |
| Arch / Manjaro / EndeavourOS | [`.pkg.tar.zst`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/podium-gui-1.0.0-beta.1-x86_64.pkg.tar.zst) | 77 MB |
| macOS — Apple Silicon | [`arm64.dmg`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/Podium-1.0.0-beta.1-arm64.dmg) | 92 MB |
| macOS — Intel | [`.dmg`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/Podium-1.0.0-beta.1.dmg) | 97 MB |
| Checksums | [`SHA256SUMS.txt`](https://github.com/CaneBayComputers/podium-gui/releases/download/v1.0.0-beta.1/SHA256SUMS.txt) | |

[All release assets →](https://github.com/CaneBayComputers/podium-gui/releases/tag/v1.0.0-beta.1)

Verify before installing:

```bash
sha256sum -c SHA256SUMS.txt --ignore-missing
```

Installing the GUI also installs the CLI if `podium` is not already on your
machine, so you do not need both downloads.

### What's in it

Create with AI, the full app library, new project and clone, start/stop of the
shared services, embedded tabbed terminals for AI sessions, and a Settings panel
with AI agent configuration and a theme picker. Five themes ship — Retro (the
default), Dark, Light, Matrix and Podium — each with its own 16-colour terminal
palette so output stays readable, including on Light.

### What is actually tested

Being straight about this, because "it built" and "it works" are different
claims:

- **`.deb` — installed and launched on a real machine** (Linux Mint): correct
  metadata, desktop entry appears, application starts.
- **`.rpm` — installed and launched on a real machine** (Fedora 43): installs
  cleanly, desktop entry registered, launches into a GNOME Wayland session.
  Worth knowing that the *first* `.rpm` build could not be installed at all — it
  required the bare capability `docker`, which the `docker-ce` packages our own
  Fedora installer lays down do not provide, so dnf tried to pull Fedora's
  conflicting `moby-engine`. Podium's installer produced a machine Podium's own
  package could not install on. The dependency was dropped (Docker legitimately
  arrives half a dozen ways, and no package name covers them all) and the
  release asset was replaced. If you grabbed an `.rpm` before 2026-08-04,
  re-download it.
- **`.pkg.tar.zst` and both `.dmg` — built and inspected, never installed.**
  No Arch or macOS machine has run these yet. The `.dmg` files in particular
  have never been opened on a Mac, so they are the least proven thing here. If
  one fails, [open an issue](https://github.com/CaneBayComputers/podium-gui/issues)
  and it will get fixed quickly.

### macOS: the app is unsigned

There is no Apple Developer ID behind these builds, so **Gatekeeper will refuse
to open the app on first launch** with an "unidentified developer" message. That
is a property of unsigned software, not a broken download. Two ways past it:

- Right-click the app in Applications → **Open** → **Open**, or
- ```bash
  xattr -dr com.apple.quarantine /Applications/Podium.app
  ```

Signing and notarizing requires a paid Apple Developer account, which this
project does not currently have.

### Not available yet

- **Linux arm64.** The Linux packages are x86_64 only, so no Raspberry Pi build.
  Apple Silicon *is* covered by the arm64 `.dmg` above.

---

## Versions

`podium --version` reports the CLI version. The GUI's About panel shows both.

**The two version independently and are not expected to match.** Compatibility is
handled by feature detection, not by comparing version numbers — the GUI asks the
installed CLI what it can do and hides anything it cannot, so an older CLI loses
individual features rather than failing outright. Upgrade either one on its own
whenever you like.

---

## Source

- [CaneBayComputers/podium-cli](https://github.com/CaneBayComputers/podium-cli) — MIT
- [CaneBayComputers/podium-gui](https://github.com/CaneBayComputers/podium-gui) — MIT

## Support

Podium is free and always will be — both parts are MIT. If it saves you time and
you want to chip in:

- [GitHub Sponsors](https://github.com/sponsors/shrimpwagon) — GitHub covers the fees
- [Ko-fi](https://ko-fi.com/canebaycomputers) — quickest, no account needed
- [Patreon](https://patreon.com/canebaycomputers) — monthly
- [Credit card](https://donate.podiumcli.com) — direct, via Cane Bay Computers' processor
