# Web-Check

All-in-one OSINT / website analysis dashboard — headers, DNS, TLS, cookies, tech stack, carbon footprint and more for any URL.

**Image**: `lissy93/web-check:2.2.2` (+ `nginx:1.29-alpine` proxy)
**Port**: 3000 inside the app container (via nginx proxy on 80)
**Database**: none — completely stateless
**Credentials**: none

## Key Notes
- No environment variables are required. Every documented var is an optional third-party API key (Shodan, SecurityTrails, URLScan, BuiltWith, Google Cloud, Tranco, WhoAPI, Cloudmersive); a missing key just greys out that one card instead of breaking the page.
- Mirrored at `ghcr.io/lissy93/web-check` with identical tags.
- The internal listen port is fixed at 3000 — there is no env var for it, so the nginx proxy is required.
- Give the proxy a long `proxy_read_timeout`: some checks (traceroute, screenshot, DNS server scan) take tens of seconds.
- It makes outbound requests to whatever host you scan, so it needs internet access to be useful.
- No volumes — nothing is persisted between restarts.
- The installer exists: run `podium install web-check`.
