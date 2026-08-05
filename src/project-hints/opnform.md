# OpnForm

**Image**: `jhumanj/opnform-api:2.2.4` (PHP-FPM) + `jhumanj/opnform-client:2.2.4` (Nuxt SSR)
**Port**: nginx 80 → client 3000 and api 9000 (FastCGI, not HTTP)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password), database `opnform`, plus shared `podium-redis`
**Credentials**: Create the admin account on the first-visit setup page

## Key Notes
- **The all-in-one `jhumanj/opnform` image is deprecated** (last built ~2 years ago). The supported layout is separate api/client images, which is what this uses.
- The nginx config is upstream's own design, and two details are load-bearing:
  - The `map` block **strips the `/api` prefix** from `REQUEST_URI` before Laravel sees it.
  - `root /usr/share/nginx/html/public` is a path that does **not** exist in the nginx container. `try_files` always misses and falls through to `/index.php`, and `SCRIPT_FILENAME` is then resolved on the *api* container's filesystem, where that exact path does exist. The two paths must stay in sync.
- `NUXT_PRIVATE_API_BASE` points back at the **nginx service by name** for server-side rendering. Renaming the nginx service breaks SSR while the browser side keeps working — a confusing half-broken state.
- The api entrypoint runs `migrate --force` and `storage:link` itself, so no manual migration step. Only the `opnform-api` service does this; the worker and scheduler deliberately skip it.
- `APP_KEY` must be `base64:` + base64 of 32 bytes (Laravel format); `JWT_SECRET` is a plain 40-char string.
- The three api containers share one image and one storage volume, differing only by command.
- Free self-hosted instances are capped at 2 users; more needs an Enterprise license.
- The installer exists: run `podium install opnform`.
