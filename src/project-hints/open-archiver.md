# Open Archiver

Self-hosted email archiving and eDiscovery — ingests IMAP, Google Workspace and Microsoft 365 mailboxes and makes them full-text searchable.

**Image**: `logiclabshq/open-archiver:v0.5.2`
**Port**: 3000 frontend (via nginx proxy); the backend on 4000 stays internal
**Database**: PostgreSQL (`podium-postgres`, db `open_archiver`) + Redis (`podium-redis`) + a bundled Meilisearch
**Credentials**: first visit creates the admin account

## Key Notes
- Tag discipline matters here: `v0.5.2` is the open-source build. The `v1.5.x-enterprise` / `latest-enterprise` tags in the same repo are the paid edition and expect a licence.
- **Do not set `REDIS_PASSWORD` or `REDIS_USER`.** Upstream's compose runs Valkey with `--requirepass`; `podium-redis` has no auth, and sending AUTH to an unauthenticated Redis makes BullMQ fail at boot.
- Meilisearch is bundled per-project (upstream pins `v1.38`) rather than using Podium's optional shared `podium-meilisearch`, which is behind a compose profile and off by default.
- `ORIGIN` must equal the URL the browser uses — SvelteKit rejects form POSTs whose Origin header doesn't match, which shows up as a failing login rather than an obvious error.
- Apache Tika is optional: leave `TIKA_URL` unset and the built-in parser handles attachments. Setting it means adding a ~1 GB Tika container.
- PST/mbox imports can be multi-GB — hence `client_max_body_size 2G` and `proxy_request_buffering off` on nginx.
- The installer exists: run `podium install open-archiver`.
