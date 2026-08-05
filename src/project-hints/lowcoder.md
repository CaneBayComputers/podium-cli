# Lowcoder

Open-source low-code app builder (Retool/Appsmith alternative), running from the official all-in-one image.

**Image**: `lowcoderorg/lowcoder-ce:2.7.6`
**Port**: 3000 (via nginx proxy, WebSocket upgrade required)
**Database**: MongoDB (`podium-mongo`, db `lowcoder`) + Redis (`podium-redis`)
**Credentials**: register the first account on first visit — it becomes the workspace admin

## Key Notes
- The all-in-one image normally starts its **own** mongo and redis under supervisord. `LOWCODER_MONGODB_ENABLED=false` and `LOWCODER_REDIS_ENABLED=false` are what redirect it at the shared Podium services — without them you get two databases fighting over the same data.
- The mongo URL **must** carry `?authSource=admin` because `podium-mongo` keeps the root user in the admin db.
- Lowcoder's bundled mongod runs standalone (no replica set), so the standalone `podium-mongo` is a drop-in — no transactions/replica-set requirement.
- `LOWCODER_DB_ENCRYPTION_PASSWORD` / `_SALT` encrypt datasource credentials at rest. They are generated per install; changing them later makes existing datasource secrets unreadable.
- Cold start is slow (Spring Boot API service); allow ~60s before the UI answers.
- The installer exists: run `podium install lowcoder`.
