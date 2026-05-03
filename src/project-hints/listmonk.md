# Listmonk

**Image**: `listmonk/listmonk:latest`
**Port**: 9000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: admin / admin12345 (set via env on first start)

## Key Notes
- Must run `--install --idempotent --yes` before starting to initialize the schema.
- Use a startup command: `sh -c "./listmonk --install --idempotent --yes --config '' && ./listmonk --upgrade --yes --config '' && ./listmonk --config ''"`
- Env uses double-underscore prefix: `LISTMONK_db__host=podium-postgres`, `LISTMONK_db__port=5432`, `LISTMONK_db__user=root`, `LISTMONK_db__password=password`, `LISTMONK_db__database=listmonk`.
- Set admin user via: `LISTMONK_ADMIN_USER=admin`, `LISTMONK_ADMIN_PASSWORD=admin12345`.
- The installer exists: run `podium install listmonk`.
