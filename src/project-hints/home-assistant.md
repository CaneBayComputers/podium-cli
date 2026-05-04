# Home Assistant

**Image**: `ghcr.io/home-assistant/home-assistant:stable`
**Port**: 8123 (nginx reverse proxy)
**Database**: None (SQLite internal)
**Credentials**: Set during onboarding wizard

## Key Notes
- Requires `configuration.yaml` with `http.use_x_forwarded_for: true` and `trusted_proxies: [10.0.0.0/8]` to accept reverse-proxy traffic.
- Home Assistant returns 405 for HEAD requests — nginx must convert HEAD to GET: `map $request_method $method { default $request_method; HEAD GET; }` then `proxy_method $method;`.
- Mount `./config:/config` (host directory) so configuration.yaml is writable. Do not use a named volume or the pre-written config won't be picked up.
- First visit shows the onboarding wizard.
- The installer exists: run `podium install home-assistant`.
