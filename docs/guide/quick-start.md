---
title: Quick start
layout: default
nav_order: 3
---

# Quick start

---

## Let an AI build it

```bash
podium create "A timeclock for employees in Django"
```

Describe what you want in plain English. Podium wraps your idea in platform instructions and hands it to your configured AI CLI, which creates the project, wires up the database and environment, builds the app using framework-native conventions, and updates the README with the local URL and any credentials.

```bash
podium create "A customer check-in system in Laravel"
podium create "An inventory tracker in Express"
podium create "New Grafana"
podium create "https://github.com/monicahq/monica"
```

Long prompts can come from a file or stdin:

```bash
podium create -f spec.md
podium create < spec.md
cat spec.md | podium create
```

Set your agent first with [`podium ai-set`]({{ site.baseurl }}/guide/ai-workflow/#choosing-an-agent). See [AI workflow]({{ site.baseurl }}/guide/ai-workflow/) for the full picture.

---

## Or scaffold it yourself

Framework first, then name:

```bash
podium new laravel my-shop
podium new django survey-app
podium new flask my-api
podium new express my-service
```

The database is auto-selected per framework (PHP/Node → MySQL, Python → PostgreSQL). Override it:

```bash
podium new flask notes --database sqlite
podium new express api --database postgres
```

Full list of frameworks and options: [Frameworks]({{ site.baseurl }}/guide/frameworks/).

---

## Or install something ready-made

```bash
podium install grafana
podium install gitea
podium install n8n
```

Fully configured and reachable at `http://grafana/` in under two minutes. Browse all 100+: [App library]({{ site.baseurl }}/guide/app-library/).

**`new` vs `install`:** `new` scaffolds an empty project *you write*. `install` deploys a finished app *someone else wrote*. If you guess wrong, Podium tells you the right command.

---

## Or bring an existing project

```bash
# clone a repo and adapt it
podium clone work-directly https://github.com/user/my-app
podium clone fork https://github.com/user/my-app
podium clone new-repo https://github.com/user/my-app my-app

# already have the folder in ~/podium-projects/
podium setup my-project
podium up my-project
```

Podium adapts a project's existing `docker-compose.yaml` automatically — bundled databases are removed and repointed at the shared services, and the original is preserved as `docker-compose.upstream.yaml`. See [Architecture → Compose adaptation]({{ site.baseurl }}/guide/architecture/#compose-adaptation).

---

## Daily driving

```bash
podium up my-project      # start one project (shared services start too)
podium up-all             # start everything
podium down my-project    # stop one project
podium down-all           # stop everything (shared services keep running)
podium status             # what's running
podium stop-services      # stop the shared services too
```

Your project is at `http://my-project/` in any browser on the machine.
