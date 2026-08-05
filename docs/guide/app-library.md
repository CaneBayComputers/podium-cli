---
title: App library
layout: default
nav_order: 6
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

Every installer here was **installed on a real machine, checked over HTTP, and removed** before it was added — none were added on the strength of being generated. Images are pinned to specific versions.

{: .warning }
> **Verified means "installs and responds", not "usable".** A handful of apps need a browser *secure context* for `crypto.subtle` or service workers, which `http://<app>/` cannot provide — those were deliberately left out rather than shipped as something that boots and then fails in the browser.


| App | One-liner | Category |
|-----|-----------|----------|
| Activepieces | `podium install activepieces` | Automation |
| Actual Budget | `podium install actual-budget` | Finance |
| AFFiNE | `podium install affine` | Notes |
| Alexandrie | `podium install alexandrie` | Notes |
| AnythingLLM | `podium install anythingllm` | AI |
| Apache Superset | `podium install superset` | Analytics |
| Apprise API | `podium install apprise-api` | Notifications |
| Appsmith | `podium install appsmith` | Low-code |
| Appwrite | `podium install appwrite` | Backend |
| ArchiveBox | `podium install archivebox` | Archiving |
| Argilla | `podium install argilla` | AI |
| Audiobookshelf | `podium install audiobookshelf` | Media |
| authentik | `podium install authentik` | Auth |
| Baby Buddy | `podium install babybuddy` | Health |
| BentoPDF | `podium install bento-pdf` | Utilities |
| BookLore | `podium install booklore` | Books |
| BookStack | `podium install bookstack` | Wiki |
| BudgE | `podium install budge` | Finance |
| Budibase | `podium install budibase` | Low-code |
| Bugsink | `podium install bugsink` | Monitoring |
| Cachet | `podium install cachet` | Status Page |
| Cal.com | `podium install cal-com` | Scheduling |
| Calibre-Web | `podium install calibre-web` | Books |
| Calibre-Web Automated Book Downloader (Shelfmark) | `podium install calibre-web-automated-book-downloader` | Books |
| Campfire (ONCE) | `podium install once-campfire` | Chat |
| Cap (CAPTCHA) | `podium install cap-captcha` | Security |
| Changedetection.io | `podium install changedetection` | Monitoring |
| Checkmate | `podium install checkmate` | Monitoring |
| Chibisafe | `podium install chibisafe` | File sharing |
| ClassicPress | `podium install classicpress` | CMS |
| Cloudreve | `podium install cloudreve` | Files |
| Code-Server | `podium install code-server` | Dev Tools |
| CodiMD | `podium install codimd` | Notes |
| ConvertX | `podium install convertx` | Utilities |
| Coolify | `podium install coolify` | DevOps |
| CyberChef | `podium install cyberchef` | Utilities |
| Dashy | `podium install dashy` | Dashboard |
| Dify | `podium install dify` | AI / LLM |
| Directus | `podium install directus` | CMS |
| Docmost | `podium install docmost` | Wiki |
| Documenso | `podium install documenso` | Documents |
| DocuSeal | `podium install docuseal` | Documents |
| DokuWiki | `podium install dokuwiki` | Wiki |
| Dolibarr ERP/CRM | `podium install dolibarr` | ERP |
| Easy!Appointments | `podium install easyappointments` | Scheduling |
| ESPHome | `podium install esphome` | IoT |
| EspoCRM | `podium install espocrm` | CRM |
| Evolution API | `podium install evolution-api` | Messaging |
| Excalidraw | `podium install excalidraw` | Diagramming |
| Fider | `podium install fider` | Feedback |
| File Browser | `podium install filebrowser` | Files |
| FileFlows | `podium install fileflows` | Media |
| Firefly III | `podium install firefly-iii` | Finance |
| Fizzy | `podium install fizzy` | Utilities |
| Flame | `podium install flame` | Dashboard |
| Flarum | `podium install flarum` | Forum |
| Flipt | `podium install flipt` | Feature flags |
| Flowise | `podium install flowise` | AI / LLM |
| Forgejo | `podium install forgejo` | Git |
| FreeScout | `podium install freescout` | Help Desk |
| FreshRSS | `podium install freshrss` | RSS |
| Ghost | `podium install ghost` | Blogging |
| Gitea | `podium install gitea` | Git Server |
| Glance | `podium install glance` | Dashboard |
| Glances | `podium install glances` | Monitoring |
| GlitchTip | `podium install glitchtip` | Monitoring |
| GLPI | `podium install glpi` | IT Asset |
| GoatCounter | `podium install goatcounter` | Analytics |
| Gotify | `podium install gotify` | Notifications |
| GOWA (Go WhatsApp Web Multidevice) | `podium install gowa` | Messaging |
| Grafana | `podium install grafana` | Monitoring |
| Gramps Web | `podium install gramps-web` | Genealogy |
| Graylog | `podium install graylog` | Logging |
| Grist | `podium install grist` | Spreadsheet |
| Grocy | `podium install grocy` | Home |
| Healthchecks | `podium install healthchecks` | Monitoring |
| HedgeDoc | `podium install hedgedoc` | Docs |
| Heimdall | `podium install heimdall` | Dashboard |
| HeyForm | `podium install heyform` | Forms |
| Homarr | `podium install homarr` | Dashboard |
| Home Assistant | `podium install home-assistant` | Smart Home |
| Homebox | `podium install homebox` | Inventory |
| Homepage | `podium install homepage` | Dashboard |
| Homer | `podium install homer` | Dashboard |
| Hoppscotch | `podium install hoppscotch` | API |
| Immich | `podium install immich` | Photos |
| Infisical | `podium install infisical` | Secrets |
| Invoice Ninja | `podium install invoice-ninja` | Invoicing |
| IT Tools | `podium install it-tools` | Utilities |
| Jellyfin | `podium install jellyfin` | Media |
| Joplin Server | `podium install joplin` | Notes |
| Jupyter Notebook (Python) | `podium install jupyter-notebook-python` | Data |
| Kanboard | `podium install kanboard` | Project Mgmt |
| Karakeep | `podium install karakeep` | Bookmarks |
| Kavita | `podium install kavita` | Library |
| Keycloak | `podium install keycloak` | Auth |
| Kimai | `podium install kimai` | Time Tracking |
| Koel | `podium install koel` | Music |
| Label Studio | `podium install label-studio` | ML / AI |
| Langflow | `podium install langflow` | AI |
| Langfuse | `podium install langfuse` | AI |
| Laravel Livewire | `podium install livewire` | Starter Kit |
| Leantime | `podium install leantime` | Project Mgmt |
| Lemmy | `podium install lemmy` | Social |
| LibreChat | `podium install librechat` | AI |
| LibreSpeed | `podium install librespeed` | Network |
| LibreTranslate | `podium install libretranslate` | Localization |
| LimeSurvey | `podium install limesurvey` | Surveys |
| linkding | `podium install linkding` | Bookmarks |
| linkding (plus) | `podium install linkding-plus` | Bookmarks |
| Linkwarden | `podium install linkwarden` | Bookmarks |
| Listmonk | `podium install listmonk` | Newsletters |
| LiteLLM Proxy | `podium install litellm` | AI |
| LobeChat | `podium install lobe-chat` | AI |
| LocalStack | `podium install localstack` | Dev Tools |
| Lowcoder | `podium install lowcoder` | Low-code |
| Lychee | `podium install lychee` | Photos |
| Mage AI | `podium install mage-ai` | Data |
| Mailpit | `podium install mailpit` | Email |
| marimo | `podium install marimo` | Data |
| Mastodon | `podium install mastodon` | Social |
| Matomo | `podium install matomo` | Analytics |
| Mattermost | `podium install mattermost` | Team Chat |
| Mautic | `podium install mautic` | Marketing |
| Maybe Finance | `podium install maybe` | Finance |
| Mealie | `podium install mealie` | Recipes |
| MediaWiki | `podium install mediawiki` | Wiki |
| Meilisearch | `podium install meilisearch` | Search |
| Memos | `podium install memos` | Notes |
| Metabase | `podium install metabase` | Analytics |
| MindsDB | `podium install mindsdb` | AI |
| Miniflux | `podium install miniflux` | RSS |
| MinIO | `podium install minio` | Storage |
| Mixpost Lite | `podium install mixpost` | Social |
| Monica CRM | `podium install monica` | CRM |
| Moodle | `podium install moodle` | Learning |
| n8n | `podium install n8n` | Automation |
| Navidrome | `podium install navidrome` | Media |
| NetBox | `podium install netbox` | Networking |
| Netdata | `podium install netdata` | Monitoring |
| New API | `podium install newapi` | AI |
| Nextcloud | `podium install nextcloud` | File Hosting |
| Nginx Proxy Manager | `podium install nginx-proxy-manager` | Networking |
| NocoBase | `podium install nocobase` | Low-code |
| NocoDB | `podium install nocodb` | Database |
| NodeBB | `podium install nodebb` | Forum |
| ntfy | `podium install ntfy` | Notifications |
| Odoo | `podium install odoo` | ERP |
| Ollama + Open WebUI | `podium install ollama-with-open-webui` | AI |
| OneDev | `podium install onedev` | Git |
| Onetime Secret | `podium install onetimesecret` | Secrets |
| Open Archiver | `podium install open-archiver` | Archiving |
| Open WebUI | `podium install open-webui` | AI / LLM |
| OpnForm | `podium install opnform` | Forms |
| OrangeHRM | `podium install orangehrm` | HR |
| Outline | `podium install outline` | Wiki |
| ownCloud | `podium install owncloud` | Files |
| Paperless-ngx | `podium install paperless` | Documents |
| Paymenter | `podium install paymenter` | Billing |
| Penpot | `podium install penpot` | Design |
| PG Back Web | `podium install pgbackweb` | Backup |
| PhotoPrism | `podium install photoprism` | Photos |
| Pingvin Share | `podium install pingvinshare` | File sharing |
| Pixelfed | `podium install pixelfed` | Social |
| Plane | `podium install plane` | Project Mgmt |
| Plausible Analytics | `podium install plausible` | Analytics |
| PocketBase | `podium install pocketbase` | Backend |
| Portainer CE | `podium install portainer` | Docker UI |
| Pterodactyl Panel | `podium install pterodactyl` | Game panel |
| Pydio Cells | `podium install pydio-cells` | Files |
| Rallly | `podium install rallly` | Scheduling |
| Reactive Resume | `podium install reactive-resume` | Productivity |
| Readeck | `podium install readeck` | Bookmarks |
| Redash | `podium install redash` | Analytics |
| Redmine | `podium install redmine` | Project Mgmt |
| Roundcube | `podium install roundcube` | Webmail |
| Ryot | `podium install ryot` | Tracking |
| SearXNG | `podium install searxng` | Search |
| Shlink | `podium install shlink` | URL Shortener |
| SiYuan | `podium install siyuan` | Notes |
| Slash | `podium install slash` | Bookmarks |
| Snappymail | `podium install snappymail` | Webmail |
| Snipe-IT | `podium install snipe-it` | Asset Mgmt |
| SparkyFitness | `podium install sparkyfitness` | Health |
| Standard Notes | `podium install standard-notes` | Notes |
| Statusnook | `podium install statusnook` | Status |
| Stirling PDF | `podium install stirling-pdf` | Utilities |
| SuperTokens Core | `podium install supertokens` | Auth |
| Sure | `podium install sure` | Finance |
| Swetrix Analytics | `podium install swetrix` | Analytics |
| Taiga | `podium install taiga` | Project Mgmt |
| Tandoor Recipes | `podium install tandoor` | Recipes |
| Tolgee | `podium install tolgee` | Localization |
| Tooljet | `podium install tooljet` | Low-code |
| Traccar | `podium install traccar` | Tracking |
| TrailBase | `podium install trailbase` | Backend |
| Trilium Notes | `podium install trilium` | Notes |
| Trilium Notes (TriliumNext) | `podium install triliumnext` | Notes |
| Twenty CRM | `podium install twenty` | CRM |
| Typebot | `podium install typebot` | Forms |
| Umami | `podium install umami` | Analytics |
| Unleash | `podium install unleash` | Feature flags |
| Uptime Kuma | `podium install uptime-kuma` | Monitoring |
| Vaultwarden | `podium install vaultwarden` | Passwords |
| VERT | `podium install vert` | Utilities |
| Vikunja | `podium install vikunja` | Task Mgmt |
| Wallabag | `podium install wallabag` | Read Later |
| Web-Check | `podium install web-check` | Utilities |
| Weblate | `podium install weblate` | Localization |
| wger | `podium install wger` | Fitness |
| Whoogle Search | `podium install whoogle` | Search |
| Wiki.js | `podium install wikijs` | Wiki |
| Yamtrack | `podium install yamtrack` | Media |
| YOURLS | `podium install yourls` | URL Shortener |
| Zabbix | `podium install zabbix` | Monitoring |
| Zipline | `podium install zipline` | File sharing |
| Zulip | `podium install zulip` | Team Chat |

