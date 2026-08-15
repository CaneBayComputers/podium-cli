# SuperTokens Core

Self-hosted authentication core — a headless API, not a web app.

**Image**: `supertokens/supertokens-postgresql:12.0.9`
**Port**: 3567 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `supertokens`)
**Credentials**: none — there is no UI. `GET http://supertokens/hello` returns `Hello` when it is healthy.

## Key Notes
- This is the core service only. The login screens and the user dashboard come from the SuperTokens backend/frontend SDKs in *your* app; point the backend SDK's `connectionURI` at `http://supertokens`.
- Use the `-postgresql` image variant; the plain `supertokens/supertokens-*` tags are per-database builds and the MySQL one will not read `POSTGRESQL_CONNECTION_URI`.
- The empty database must exist first; the core creates and migrates its own tables on boot.
- Set `API_KEYS` if you want the core locked down — without it any container on the network can call it.
- The installer exists: run `podium install supertokens`.
