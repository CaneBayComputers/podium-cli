# Podium CLI

## DevOps in-a-box!

**Pre-plumbed PHP, Python and Node environments so your AI agent can skip the setup and get straight to building.**

| | AI without Podium | AI with Podium |
|---|---|---|
| **Standing up an OSS app** | Re-derives the image, compose and env vars | `podium install grafana` |
| ↳ prompts | Several rounds of fixes | One |
| ↳ tokens | ~10–15k, lands *almost* right | ~800 |
| ↳ time | An afternoon | Under two minutes |
| **Databases** | One bundled per project | One shared — ~700MB → ~100MB |
| **URLs** | `localhost:3002`? `:3003`? | `http://grafana/` |
| **Project layout** | Reinvented every session | Fixed hostnames, IPs, images, credentials |
| **Other machines** | "Worked on my laptop" | Identical |

📖 **[Full documentation →](https://podiumcli.com/guide/)**

---

## Why

- **It's a project manager.** Every project gets a name, a hostname, and the same shared services. Ten projects, one Postgres.
- **It keeps AI in bounds.** Left alone, an agent invents its own ports, database and compose file, ignoring everything else on your machine. Podium hands it a fixed environment instead.
- **It saves tokens.** Networking, scaffolding, secrets and 100+ app installs are pre-baked. The agent builds your app, not the plumbing.
- **The containers are already built.** PHP 8.3, Python 3, Node 22 — nginx, supervisor and every database driver compiled in. No image hunting, no Dockerfiles.
- **Nothing to configure.** No YAML, no env spelunking, no per-project setup.

---

## Install

```bash
# Debian / Ubuntu / Mint
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash
```

Swap the script for your platform: `install-fedora.sh`, `install-arch.sh`, or `install-mac.sh`.

Then, once:

```bash
podium configure
```

Log out and back in so Docker group access takes effect. Details and platform notes: **[Installation](https://podiumcli.com/guide/installation/)**.

---

## Start here

```bash
podium create "A timeclock for employees in Django"
```

Describe what you want. **Podium** builds the project, database, environment and URL. The AI only customizes what sits on top — that's where the savings come from.

Name a framework if you have a preference — or don't, and let the agent choose:

```bash
podium create "A tool to track my guitar pedal collection"
```

Give it as much detail as you like:

```bash
podium create "A customer intake system for a small law firm. Clients submit a
form with their contact info, case type and a short description. Staff log in
to review submissions, assign each one to an attorney, and move it through new,
in progress and closed. Email the client whenever the status changes."
```

---

## Prefer to drive it yourself?

```bash
podium new flask my-api        # scaffold a project you write
podium install grafana         # deploy a ready-made app
podium clone work-directly <repo-url>
podium up my-api               # start it
```

Everything else — frameworks, the 100+ app library, the full command reference, architecture, and scripting — is in the **[docs](https://podiumcli.com/guide/)**.

---

Runs on Linux and macOS. Open source. Stop configuring, start building.
