---
title: App library
layout: default
nav_order: 5
---

# App library — `podium install`

`podium install <app> [name]` deploys a **finished third-party app** — fully configured, running, reachable at `http://<app>/`, usually in under two minutes.

```bash
podium install grafana       # monitoring dashboards
podium install gitea         # self-hosted git
podium install n8n           # workflow automation
podium install nextcloud     # file hosting
podium install --list        # everything available
```

For scaffolding a project *you write*, see [Frameworks]({{ site.baseurl }}/guide/frameworks/) instead. Guess wrong and Podium points you at the right command.

---

## What an installer does for you

Each installer captures one app's quirks once, so you (or your agent) never re-derive them:

- Creates the right databases and users
- Generates secrets and app keys
- Writes a compose file wired to Podium's shared services instead of bundled databases
- Assigns a VPC IP and hostname
- Starts the container and waits for HTTP 200

Image tags are **pinned to specific versions**, not `:latest`, so an install that worked yesterday works the same today and upgrades are deliberate.

## Options

| Option | Description |
|---|---|
| `[name]` | Install under a different project name / hostname |
| `--image <ref>` | Override the image the installer would use |
| `--one-off` | Skip the AI hand-off after install |
| `--list` | List every available app |

```bash
podium install livewire sign-tools
podium install livewire sign-tools --image canebaycomputers/cbc:nginx-php8-vector
```

## Keeping installers current

```bash
podium update-installer <app>     # refresh one against current upstream, via AI
podium update-installer --all
podium create-installer "<idea>"  # write a brand-new installer, via AI
```

Both emit a prepared prompt telling an agent to fetch upstream, diff against the current installer, regenerate, verify end-to-end, and commit.

---

## Available apps

| App | One-liner | Category |
|-----|-----------|----------|
| Actual Budget | `podium install actual-budget` | Finance |
| Appsmith | `podium install appsmith` | Low-code |
| Appwrite | `podium install appwrite` | Backend |
| Apache Superset | `podium install superset` | Analytics |
| ArchiveBox | `podium install archivebox` | Archiving |
| Audiobookshelf | `podium install audiobookshelf` | Media |
| Baby Buddy | `podium install babybuddy` | Health |
| BookStack | `podium install bookstack` | Wiki |
| Budibase | `podium install budibase` | Low-code |
| Cachet | `podium install cachet` | Status Page |
| Cal.com | `podium install cal-com` | Scheduling |
| Changedetection.io | `podium install changedetection` | Monitoring |
| Code-Server | `podium install code-server` | Dev Tools |
| Coolify | `podium install coolify` | DevOps |
| Dashy | `podium install dashy` | Dashboard |
| Dify | `podium install dify` | AI / LLM |
| Directus | `podium install directus` | CMS |
| Excalidraw | `podium install excalidraw` | Diagramming |
| Firefly III | `podium install firefly-iii` | Finance |
| Flowise | `podium install flowise` | AI / LLM |
| Flarum | `podium install flarum` | Forum |
| Flame | `podium install flame` | Dashboard |
| FreeScout | `podium install freescout` | Help Desk |
| FreshRSS | `podium install freshrss` | RSS |
| Ghost | `podium install ghost` | Blogging |
| Gitea | `podium install gitea` | Git Server |
| Glances | `podium install glances` | Monitoring |
| Grafana | `podium install grafana` | Monitoring |
| Grocy | `podium install grocy` | Home |
| Graylog | `podium install graylog` | Logging |
| Healthchecks | `podium install healthchecks` | Monitoring |
| HedgeDoc | `podium install hedgedoc` | Docs |
| Heimdall | `podium install heimdall` | Dashboard |
| Homer | `podium install homer` | Dashboard |
| Home Assistant | `podium install home-assistant` | Smart Home |
| Immich | `podium install immich` | Photos |
| Invoice Ninja | `podium install invoice-ninja` | Invoicing |
| IT Tools | `podium install it-tools` | Utilities |
| Jellyfin | `podium install jellyfin` | Media |
| Kanboard | `podium install kanboard` | Project Mgmt |
| Kavita | `podium install kavita` | Library |
| Kimai | `podium install kimai` | Time Tracking |
| Koel | `podium install koel` | Music |
| Label Studio | `podium install label-studio` | ML / AI |
| Leantime | `podium install leantime` | Project Mgmt |
| Lemmy | `podium install lemmy` | Social |
| LimeSurvey | `podium install limesurvey` | Surveys |
| Linkwarden | `podium install linkwarden` | Bookmarks |
| Listmonk | `podium install listmonk` | Newsletters |
| LocalStack | `podium install localstack` | Dev Tools |
| Lychee | `podium install lychee` | Photos |
| Mastodon | `podium install mastodon` | Social |
| Matomo | `podium install matomo` | Analytics |
| Mattermost | `podium install mattermost` | Team Chat |
| Mautic | `podium install mautic` | Marketing |
| Mealie | `podium install mealie` | Recipes |
| Meilisearch | `podium install meilisearch` | Search |
| Memos | `podium install memos` | Notes |
| Metabase | `podium install metabase` | Analytics |
| Miniflux | `podium install miniflux` | RSS |
| MinIO | `podium install minio` | Storage |
| Monica | `podium install monica` | CRM |
| n8n | `podium install n8n` | Automation |
| Netdata | `podium install netdata` | Monitoring |
| NetBox | `podium install netbox` | Networking |
| Nextcloud | `podium install nextcloud` | File Hosting |
| Nginx Proxy Manager | `podium install nginx-proxy-manager` | Networking |
| NocoDB | `podium install nocodb` | Database |
| October CMS | `podium install octobercms` | CMS |
| Open WebUI | `podium install open-webui` | AI / LLM |
| Outline | `podium install outline` | Wiki |
| Paperless-ngx | `podium install paperless` | Documents |
| Penpot | `podium install penpot` | Design |
| PhotoPrism | `podium install photoprism` | Photos |
| Pixelfed | `podium install pixelfed` | Social |
| Plane | `podium install plane` | Project Mgmt |
| Plausible | `podium install plausible` | Analytics |
| Portainer | `podium install portainer` | Docker UI |
| Redash | `podium install redash` | Analytics |
| Redmine | `podium install redmine` | Project Mgmt |
| Roundcube | `podium install roundcube` | Webmail |
| SearXNG | `podium install searxng` | Search |
| Shlink | `podium install shlink` | URL Shortener |
| Snappymail | `podium install snappymail` | Webmail |
| Snipe-IT | `podium install snipe-it` | Asset Mgmt |
| Standard Notes | `podium install standard-notes` | Notes |
| Stirling PDF | `podium install stirling-pdf` | Utilities |
| Taiga | `podium install taiga` | Project Mgmt |
| Tandoor | `podium install tandoor` | Recipes |
| Tooljet | `podium install tooljet` | Low-code |
| Trilium Notes | `podium install trilium` | Notes |
| Typebot | `podium install typebot` | Forms |
| Umami | `podium install umami` | Analytics |
| Uptime Kuma | `podium install uptime-kuma` | Monitoring |
| Vaultwarden | `podium install vaultwarden` | Passwords |
| Vikunja | `podium install vikunja` | Task Mgmt |
| Wallabag | `podium install wallabag` | Read Later |
| wger | `podium install wger` | Fitness |
| Wiki.js | `podium install wikijs` | Wiki |
| Yourls | `podium install yourls` | URL Shortener |
| Zabbix | `podium install zabbix` | Monitoring |
| Zulip | `podium install zulip` | Team Chat |

