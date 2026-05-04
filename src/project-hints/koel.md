# Koel

**Image**: `phanan/koel:latest`
**Port**: 80 (direct — Koel's Apache serves on port 80)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: `admin@example.com / KoelAdmin123` (set via `ADMIN_EMAIL` / `ADMIN_PASSWORD`)

## Key Notes
- Koel's `koel:init` command writes back to `.env` to persist `APP_KEY`. Bind-mounting `.env` fails due to AppArmor preventing writes to host-owned files from inside containers. The workaround is to write `.env` inside an ephemeral container and run init there:
  ```bash
  docker run --rm --network podium-cli_vpc --entrypoint /bin/sh phanan/koel:latest \
    -c "cat > /var/www/html/.env << 'EOF'
  APP_KEY=base64:$(openssl rand -base64 32)
  ...all env vars...
  EOF
  php artisan koel:init --no-assets --no-interaction"
  ```
- Set `SKIP_INIT: "1"` in the main container's environment so it skips the init wizard on every restart.
- Use `env_file: ./.env` in docker-compose so the persistent container reads the `.env` written by `write_files`.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE koel;"`
- Persist `koel-music` (mount at `/music`) and `koel-search-indexes` volumes.
- The installer exists: run `podium install koel`.
