# Wiki.js

**Image**: `ghcr.io/requarks/wiki:2`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Set on first visit (admin setup wizard)

## Key Notes
- DB env vars: `DB_TYPE=postgres`, `DB_HOST=podium-postgres`, `DB_PORT=5432`, `DB_USER=root`, `DB_PASS=password`, `DB_NAME=wikijs`.
- Create the DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE wikijs;"`
- The setup wizard runs on first visit to create the admin account.
- The installer exists: run `podium install wikijs`.
