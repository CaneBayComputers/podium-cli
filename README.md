# Zeltro CLI

## DevOps in-a-box!

**Pre-plumbed PHP, Python and Node environments so your AI agent can skip the setup and get straight to building.**

| | AI without Zeltro | AI with Zeltro |
|---|---|---|
| **Standing up an OSS app** | Re-derives the image, compose and env vars | `zeltro install grafana` |
| ↳ prompts | Several rounds of fixes | One |
| ↳ tokens | ~10–15k, lands *almost* right | ~800 |
| ↳ time | An afternoon | Under two minutes |
| **Databases** | One bundled per project | One shared — ~700MB → ~100MB |
| **URLs** | `localhost:3002`? `:3003`? | `http://grafana/` |
| **Project layout** | Reinvented every session | Fixed hostnames, IPs, images, credentials |
| **Other machines** | "Worked on my laptop" | Identical |

📖 **[Full documentation →](https://zeltro.build/guide/)**

---

## Why

- **It's a project manager.** Every project gets a name, a hostname, and the same shared services. Ten projects, one Postgres.
- **It keeps AI in bounds.** Left alone, an agent invents its own ports, database and compose file, ignoring everything else on your machine. Zeltro hands it a fixed environment instead.
- **It saves tokens.** Networking, scaffolding, secrets and 200+ app installs are pre-baked. The agent builds your app, not the plumbing.
- **The containers are already built.** PHP 8.3, Python 3, Node 22 — nginx, supervisor and every database driver compiled in. No image hunting, no Dockerfiles.
- **Nothing to configure.** No YAML, no env spelunking, no per-project setup.

---

## Install

**Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-ubuntu.sh | bash
```

Swap the script for your distro: `install-fedora.sh` or `install-arch.sh`.

**macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-mac.sh | bash
```

Installs the Xcode command line tools, Homebrew and Docker Desktop if they are
missing. Note that Docker Desktop keeps containers inside a VM, so on macOS you
reach a project by the port `zeltro status` prints rather than by container IP.

**Windows**

Zeltro is a Linux tool. On Windows it runs inside WSL2, which is a real Linux
kernel — so container IPs are directly routable, exactly as on a Linux host.
Right-click PowerShell and choose **Run as administrator**, then:

```powershell
irm https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-windows.ps1 | iex
```

It enables the WSL features, asks for one reboot, then resumes and finishes on
its own. Requires Windows 10 version 2004 (build 19041) or newer; older builds
are refused up front with an explanation.

Then, once:

```bash
zeltro configure
```

Log out and back in so Docker group access takes effect. Details and platform notes: **[Installation](https://zeltro.build/guide/installation/)**.

---

## Start here

```bash
zeltro create "A timeclock for employees in Django"
```

Describe what you want. **Zeltro** builds the project, database, environment and URL. The AI only customizes what sits on top — that's where the savings come from.

Name a framework if you have a preference — or don't, and let the agent choose:

```bash
zeltro create "A tool to track my guitar pedal collection"
```

Give it as much detail as you like:

```bash
zeltro create "A customer intake system for a small law firm. Clients submit a
form with their contact info, case type and a short description. Staff log in
to review submissions, assign each one to an attorney, and move it through new,
in progress and closed. Email the client whenever the status changes."
```

---

## Prefer to drive it yourself?

```bash
zeltro new flask my-api        # scaffold a project you write
zeltro install grafana         # deploy a ready-made app
zeltro clone work-directly <repo-url>
zeltro up my-api               # start it
```

Everything else — frameworks, the 200+ app library, the full command reference, architecture, and scripting — is in the **[docs](https://zeltro.build/guide/)**.

---

## Prefer not to use a terminal?

[**Zeltro GUI**](https://github.com/CaneBayComputers/zeltro-gui) is an optional
desktop front end — same projects, same shared services, same URLs, just visible
and clickable. It installs the same way this does — one command, which clones the repo for you:

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-gui/master/install-ubuntu.sh | bash
```

Swap for `install-fedora.sh`, `install-arch.sh` or `install-mac.sh`. On Linux and
macOS it installs this CLI first if `zeltro` is missing, so it is the only thing
you need to run.

To install a checkout you already have instead of a fresh clone, run the script
from inside it — it detects the local repository and builds that:

```bash
git clone https://github.com/CaneBayComputers/zeltro-gui.git
cd zeltro-gui && ./install-ubuntu.sh
```

On **Windows** the GUI runs natively, but there is no local Zeltro for it to
drive — it connects over SSH to machines that do have one (a Linux box, a Mac, a
Pi, an EC2 instance), added under **Settings → SSH Hosts**:

```powershell
irm https://raw.githubusercontent.com/CaneBayComputers/zeltro-gui/master/scripts/install-windows.ps1 | iex
```

---

Runs on Linux, macOS, and Windows via WSL2. Open source. Stop configuring, start building.
