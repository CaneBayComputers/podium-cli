# Glance

Fast, single-binary dashboard that puts feeds, bookmarks and monitors on one page.

**Image**: `glanceapp/glance:v0.8.5` + `nginx:1.30.4-alpine`
**Port**: 8080 (behind the nginx reverse proxy on 80)
**Database**: None — a single `glance.yml` config file
**Credentials**: None by default (auth is opt-in via the `auth:` block)

## Key Notes
- Glance **exits on a malformed config**. The installer ships a known-good minimal `glance.yml`; validate edits with `podium logs glance` after saving.
- The config is bind-mounted from the project directory as `./glance.yml` (not a named volume) so it can be edited directly; Glance auto-reloads it.
- Column layout rules are strict: max 3 columns per page and exactly one must be `size: full`.
- The bundled `hacker-news`/`lobsters` widgets fetch over the internet; they render an error card offline but the page still loads.
- The installer exists: run `podium install glance`.
