# Tandoor Recipes

**Image**: `vabene1111/recipes:latest`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Create admin via Django admin or `manage.py createsuperuser`

## Key Notes
- Env: `DB_ENGINE=django.db.backends.postgresql`, `POSTGRES_HOST=podium-postgres`, `POSTGRES_PORT=5432`, `POSTGRES_USER=root`, `POSTGRES_PASSWORD=password`, `POSTGRES_DB=tandoor`.
- Set `SECRET_KEY` to a random 50+ char string and `ALLOWED_HOSTS=*`.
- Set `CSRF_TRUSTED_ORIGINS=http://tandoor` to prevent CSRF errors.
- Persist two volumes: `/opt/recipes/mediafiles` and `/opt/recipes/staticfiles`.
- Tandoor uses gunicorn on port 8080 internally; a separate nginx is needed.
- The nginx config should serve `/media/` and `/static/` directly from the shared volumes for performance.
- The installer exists: run `podium install tandoor`.
