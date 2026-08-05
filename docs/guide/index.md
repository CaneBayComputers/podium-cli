---
title: Overview
layout: default
nav_order: 1
permalink: /guide/
---

# Podium CLI

Podium is a Docker-based local development environment manager for PHP, Python and Node projects — and a set of guardrails for AI coding agents working on your machine.

It does three things, and they reinforce each other.

---

## Shares one set of services across every project

One `podium-postgres`, one `podium-mariadb`, one `podium-redis`, one `podium-mongo`, one `podium-memcached` — used by every Podium project on the machine. Run ten projects, you still have one of each.

- **Projects talk to each other for free.** The same hostnames resolve from your browser (`http://my-api/`) and from inside containers (`psql -h podium-postgres`, `fetch('http://my-api/')`). A Laravel app can read another project's database with no networking setup.
- **No port roulette.** Every project lives at `http://project-name`. No `localhost:3001` vs `:3002` vs `:3003`, no `host.docker.internal` hacks. Ports only enter the picture when you want to reach a project from another machine on the LAN.
- **Resource consolidation.** Seven duplicate Postgres containers eating ~700MB becomes one eating ~100MB.
- **No conflicts.** Upstream compose files binding `5432:5432` or `80:80` get rewired to the shared services automatically.

## Runtimes that are already built

Three base images cover every supported stack — PHP 8.3, Python 3, Node 22 — each with nginx, supervisor, and every database driver already compiled in.

You never hunt down an image, compare tags, or write a Dockerfile. `pdo_mysql`, `pdo_pgsql`, `pdo_sqlite`, `redis`, `mongodb`, `gunicorn`, `uvicorn` — all present, on every project, from the first command.

See [Architecture]({{ site.baseurl }}/guide/architecture/) for what each image ships.

## Built for AI agents to work inside

Left alone, an AI agent will scaffold a project however it likes — its own ports, its own bundled database, its own compose file — with no regard for the other twelve projects on your machine. Podium gives the agent a fixed environment to work in:

- **A stable platform.** Shared services, hostname routing, `/etc/hosts` wiring, and known runtime images mean the agent builds your app instead of reinventing infrastructure.
- **Fewer tokens.** Framework scaffolding, networking, secret generation and 200+ app installs are pre-baked. The agent doesn't rediscover how to wire nginx + php-fpm every session.
- **Context that survives.** Every project gets an `AGENTS.md` describing its URL, database and commands, so a new agent session picks the project up cold.

---

## Where to go next

| | |
|---|---|
| [Installation]({{ site.baseurl }}/guide/installation/) | Install Podium on Linux or macOS |
| [Quick start]({{ site.baseurl }}/guide/quick-start/) | Your first project in one command |
| [Frameworks]({{ site.baseurl }}/guide/frameworks/) | `podium new` — scaffold a project you write |
| [App library]({{ site.baseurl }}/guide/app-library/) | `podium install` — 200+ ready-to-run apps |
| [AI workflow]({{ site.baseurl }}/guide/ai-workflow/) | `podium create`, `ai`, `resume` |
| [Command reference]({{ site.baseurl }}/guide/commands/) | Every command and flag |
| [Architecture]({{ site.baseurl }}/guide/architecture/) | Services, networking, base images |
| [Automation & JSON]({{ site.baseurl }}/guide/automation/) | Scripting, JSON output, debugging |

## Where Podium doesn't add much

If you run exactly one project and never touch another, plain `docker compose up` works fine. Podium earns its keep once you have several projects, or an AI agent, sharing one machine.
