# Podium CLI

**Local dev environment manager for PHP, Python and Node — and a guardrail for AI coding agents.**

📖 **[Full documentation →](https://canebaycomputers.github.io/podium-cli/)**

---

## Why

- **It's a project manager.** Every project gets a name, a hostname, and one shared set of services. Ten projects, one Postgres — not ten.
- **It keeps AI in bounds.** Left alone, an agent scaffolds a project however it likes — its own ports, its own bundled database, its own compose file — ignoring everything else on your machine. Podium gives it a fixed environment to build inside.
- **It saves AI tokens.** Networking, scaffolding, secrets and 100+ app installs are pre-baked. Your agent builds the app instead of rediscovering how to wire nginx + php-fpm every session.
- **The containers are already built.** PHP 8.3, Python 3, Node 22 — nginx, supervisor and every database driver compiled in. Nobody tracks down an image or writes a Dockerfile.
- **No port juggling.** Every project is `http://project-name`. No `localhost:3001` vs `:3002`. Ports only appear when you want to reach a project from another machine on the LAN.
- **Nothing to configure.** No YAML, no env spelunking, no first-run wizards.

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

Log out and back in so Docker group access takes effect. Details and platform notes: **[Installation](https://canebaycomputers.github.io/podium-cli/installation/)**.

---

## Start here

```bash
podium create "A timeclock for employees in Django"
```

Describe what you want. Your AI agent creates the project, wires up the database and environment, builds the app, and hands you a working URL.

```bash
podium create "A customer check-in system in Laravel"
podium create "An inventory tracker in Express"
podium create "New Grafana"
```

Set your agent first with `podium ai-set --agent claude` (or `codex`, `gemini`).

---

## Prefer to drive it yourself?

```bash
podium new flask my-api        # scaffold a project you write
podium install grafana         # deploy a ready-made app
podium clone work-directly <repo-url>
podium up my-api               # start it
```

Everything else — frameworks, the 100+ app library, the full command reference, architecture, and scripting — is in the **[docs](https://canebaycomputers.github.io/podium-cli/)**.

---

Runs on Linux and macOS. Open source. Stop configuring, start building.
