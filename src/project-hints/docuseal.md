# DocuSeal

Document signing — build fillable PDF forms and collect legally binding signatures.

**Image**: `docuseal/docuseal:3.1.7`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL `docuseal` on podium-postgres
**Credentials**: Create the admin account on first visit

## Key Notes
- Do not set `FORCE_SSL`. Upstream's compose sets it because it pairs DocuSeal with Caddy and a real domain; under Podium the app is served over plain http and `FORCE_SSL` would redirect you into a loop.
- Signed documents and uploads live in the `docuseal-data` volume at `/data/docuseal`.
- SMTP is configured in the web UI under Settings, not by environment variable. Point it at `podium-mailhog:1025` to catch signing invitations in Mailpit.
- The installer exists: run `podium install docuseal`.
