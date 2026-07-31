INSTALL_DISPLAY="wger"
INSTALL_CREDENTIALS="admin / admin1234"
INSTALL_NOTES="Startup takes up to 5 minutes — the health check waits for Django to be ready."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE wger;" 2>/dev/null || true
}

write_files() {
    local secret_key signing_key
    secret_key=$(openssl rand -base64 37 | tr -d '\n')
    signing_key=$(openssl rand -base64 37 | tr -d '\n')

    mkdir -p config

    cat > config/prod.env << EOF
SECRET_KEY=$secret_key
SIGNING_KEY=$signing_key
TIME_ZONE=UTC
TZ=UTC

WGER_INSTANCE=https://wger.de
ALLOW_REGISTRATION=True
ALLOW_GUEST_USERS=True

USE_CELERY=True
CELERY_BROKER=redis://podium-redis:6379/2
CELERY_BACKEND=redis://podium-redis:6379/2
CELERY_FLOWER_PASSWORD=adminadmin
CELERY_WORKER_CONCURRENCY=2

DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_DATABASE=wger
DJANGO_DB_USER=root
DJANGO_DB_PASSWORD=password
DJANGO_DB_HOST=podium-postgres
DJANGO_DB_PORT=5432
DJANGO_PERFORM_MIGRATIONS=True

DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
DJANGO_CACHE_LOCATION=redis://podium-redis:6379/1
DJANGO_CACHE_TIMEOUT=1296000
DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient

AXES_ENABLED=True
AXES_FAILURE_LIMIT=10
AXES_COOLOFF_TIME=30
AXES_HANDLER=axes.handlers.cache.AxesCacheHandler
AXES_LOCKOUT_PARAMETERS=ip_address
AXES_IPWARE_PROXY_COUNT=1
AXES_IPWARE_META_PRECEDENCE_ORDER=HTTP_X_FORWARDED_FOR,REMOTE_ADDR

DJANGO_DEBUG=False
WGER_USE_GUNICORN=True
EXERCISE_CACHE_TTL=86400
SITE_URL=http://wger
WGER_PORT=80

ACCESS_TOKEN_LIFETIME=10
REFRESH_TOKEN_LIFETIME=24

LOG_LEVEL_PYTHON=INFO
USE_RECAPTCHA=False
DJANGO_CLEAR_STATIC_FIRST=False
DJANGO_COLLECTSTATIC_ON_STARTUP=True

DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_PASSWORD=admin1234
DJANGO_SUPERUSER_EMAIL=admin@example.com

NUMBER_OF_PROXIES=1
GUNICORN_CMD_ARGS="--workers 2 --threads 2 --worker-class gthread --timeout 240"

SYNC_EXERCISES_CELERY=True
SYNC_EXERCISE_IMAGES_CELERY=True
SYNC_INGREDIENTS_CELERY=True
CACHE_API_EXERCISES_CELERY=True
EOF

    cat > docker-compose.yaml << 'EOF'
services:
  web:
    image: wger/server:latest
    restart: unless-stopped
    env_file:
      - ./config/prod.env
    volumes:
      - wger-static:/home/wger/static
      - wger-media:/home/wger/media
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80"]
      interval: 10s
      timeout: 5s
      start_period: 300s
      retries: 5

  celery_worker:
    image: wger/server:latest
    restart: unless-stopped
    command: /start-worker
    env_file:
      - ./config/prod.env
    volumes:
      - wger-media:/home/wger/media
    depends_on:
      web:
        condition: service_healthy

  celery_beat:
    image: wger/server:latest
    restart: unless-stopped
    command: /start-beat
    env_file:
      - ./config/prod.env
    volumes:
      - wger-beat:/home/wger/beat/
    depends_on:
      celery_worker:
        condition: service_healthy

volumes:
  wger-static:
  wger-media:
  wger-beat:
EOF
}
