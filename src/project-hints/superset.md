# Apache Superset

**Image**: `apache/superset:latest` (requires custom Dockerfile to add `psycopg2-binary`)
**Port**: 8088 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: `admin / admin` (created via `superset fab create-admin` in the startup command)

## Key Notes
- The base image does not include `psycopg2-binary` — a custom Dockerfile is required:
  ```dockerfile
  FROM apache/superset:latest
  USER root
  RUN uv pip install --python /app/.venv/bin/python --no-cache psycopg2-binary
  USER superset
  ```
- A `superset_config.py` file must be mounted at `/app/pythonpath/superset_config.py` with at minimum:
  ```python
  import os
  SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]
  SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]
  ENABLE_PROXY_FIX = True
  WTF_CSRF_ENABLED = True
  TALISMAN_ENABLED = False
  ```
- `SUPERSET_CONFIG_PATH` must point to that file.
- The container command runs `superset db upgrade && superset fab create-admin ... && superset init && gunicorn ...`.
- `DATABASE_URL` format: `postgresql+psycopg2://root:password@podium-postgres:5432/superset`.
- `SUPERSET_SECRET_KEY` — generate with `openssl rand -hex 32`.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE superset;"`
- nginx must forward `X-Forwarded-Host` and `X-Forwarded-Proto` headers for `ENABLE_PROXY_FIX` to work.
- First startup takes ~2 minutes for migrations and UI build.
- The installer exists: run `podium install superset`.
