#!/bin/bash -l
# OSS batch 4 — cassie, agent: gemini

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/oss4-sessions
LOG=/tmp/podium-tests/oss4-master.log
PODIUM="/usr/local/bin/podium"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/oss4-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 2400 bash -l -c "TERM=xterm $PODIUM create --one-off \"$idea\" > \"$logfile\" 2>&1"
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

SUMMARY_SUFFIX='

After the site is verified, create a file called SETUP_SUMMARY.md inside the project directory with exactly these sections:
## Project
[project name and Docker image used]
## Commands Run
[bulleted list of key commands you ran]
## Issues & Fixes
[any problems you hit and how you resolved them, or "None" if it went smoothly]
## Result
HTTP status: [e.g. 200 or 302]
URL: http://[project-name]/
Credentials: [default login/password if any, or "None required"]
## Verdict
[one sentence: did setup go smoothly or were there major problems?]'

echo "=== OSS Batch 4 (cassie / gemini) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

IDEA_PLANE='Deploy Plane on this Podium server. The project name is plane — use this exact name, no changes.

Plane is an open-source project management tool. It uses multiple Docker images. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE plane;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/plane
3. Write docker-compose.yaml with these services:
   plane-api service (image: makeplane/plane-backend:stable; env: DATABASE_URL=postgres://root:password@podium-postgres:5432/plane, REDIS_URL=redis://podium-redis:6379/0, SECRET_KEY=$(openssl rand -hex 25), WEB_URL=http://plane, CORS_ALLOWED_ORIGINS=http://plane, USE_MINIO=0, DJANGO_SETTINGS_MODULE=plane.settings.docker; command: ./bin/takeoff)
   plane-worker service (image: makeplane/plane-worker:stable; same env as plane-api; command: ./bin/worker)
   plane-beat-worker service (image: makeplane/plane-beat-worker:stable; same env as plane-api; command: ./bin/beat)
   plane-frontend service (image: makeplane/plane-frontend:stable; env: NEXT_PUBLIC_API_BASE_URL=http://plane, NEXT_PUBLIC_DEPLOY_URL=http://plane)
   nginx service (container_name=plane, static VPC IP). Write nginx.conf with two upstreams: location /api/ and /auth/ proxy to plane-api:8000; all other traffic proxies to plane-frontend:3000.
4. cd ~/podium-projects/plane && podium setup plane --no-startup && podium up plane
5. Wait 60 seconds for migrations, then curl -sI http://plane/ — expect 200 or 302. Visit http://plane/ to create admin account.'"$SUMMARY_SUFFIX"

IDEA_DIFY='Deploy Dify on this Podium server. The project name is dify — use this exact name, no changes.

Dify is an open-source LLM application development platform. It requires multiple services. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE dify;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/dify
3. Write docker-compose.yaml with these services:
   dify-api service (image: langgenius/dify-api:latest; env: MODE=api, DB_USERNAME=root, DB_PASSWORD=password, DB_HOST=podium-postgres, DB_PORT=5432, DB_DATABASE=dify, REDIS_HOST=podium-redis, REDIS_PORT=6379, REDIS_DB=0, CELERY_BROKER_URL=redis://podium-redis:6379/1, SECRET_KEY=$(openssl rand -hex 32), STORAGE_TYPE=local, INIT_PASSWORD=DifyAdmin123, VECTOR_STORE=qdrant, QDRANT_URL=http://dify-qdrant:6333)
   dify-worker service (image: langgenius/dify-api:latest; same env as dify-api; env: MODE=worker)
   dify-web service (image: langgenius/dify-web:latest; env: CONSOLE_API_URL=http://dify, APP_API_URL=http://dify)
   dify-qdrant service (image: qdrant/qdrant:latest; volumes: dify-qdrant-data:/qdrant/storage)
   nginx service (container_name=dify, static VPC IP). Write nginx.conf: location /console/api, /api, /v1, /files proxy to dify-api:5001; location / proxy to dify-web:3000.
4. cd ~/podium-projects/dify && podium setup dify --no-startup && podium up dify
5. Wait 60 seconds for initialization, then curl -sI http://dify/ — expect 200 or 302. Visit http://dify/ to initialize with password DifyAdmin123.'"$SUMMARY_SUFFIX"

IDEA_MASTODON='Deploy Mastodon on this Podium server. The project name is mastodon — use this exact name, no changes.

Mastodon is a federated social network. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379). Do NOT use Elasticsearch.

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE mastodon_production;" 2>/dev/null || true
2. Generate VAPID keys: docker run --rm --network podium-cli_vpc ghcr.io/mastodon/mastodon:latest bundle exec rake mastodon:webpush:generate_vapid_key 2>/dev/null — capture VAPID_PRIVATE_KEY and VAPID_PUBLIC_KEY from output.
3. mkdir -p ~/podium-projects/mastodon
4. Write docker-compose.yaml with these services (all use same env):
   ENV: LOCAL_DOMAIN=mastodon, SINGLE_USER_MODE=false, SECRET_KEY_BASE=$(openssl rand -hex 64), OTP_SECRET=$(openssl rand -hex 64), VAPID_PRIVATE_KEY=<from step 2>, VAPID_PUBLIC_KEY=<from step 2>, DB_HOST=podium-postgres, DB_PORT=5432, DB_NAME=mastodon_production, DB_USER=root, DB_PASS=password, REDIS_HOST=podium-redis, REDIS_PORT=6379, ES_ENABLED=false, SMTP_SERVER=podium-mailhog, SMTP_PORT=1025, SMTP_AUTH_METHOD=none, SMTP_OPENSSL_VERIFY_MODE=none, SMTP_FROM_ADDRESS=noreply@mastodon
   mastodon-web service (image: ghcr.io/mastodon/mastodon:latest; command: bundle exec puma -C config/puma.rb)
   mastodon-streaming service (image: ghcr.io/mastodon/mastodon:latest; command: node ./streaming)
   mastodon-sidekiq service (image: ghcr.io/mastodon/mastodon:latest; command: bundle exec sidekiq)
   nginx service (container_name=mastodon, static VPC IP). Write nginx.conf proxying / to mastodon-web:3000.
5. Run DB migrations: docker run --rm --network podium-cli_vpc <same env vars> ghcr.io/mastodon/mastodon:latest bundle exec rails db:migrate 2>/dev/null
6. cd ~/podium-projects/mastodon && podium setup mastodon --no-startup && podium up mastodon
7. Wait 30 seconds, then create admin: docker exec $(docker ps -q -f name=mastodon-web) tootctl accounts create admin --email admin@mastodon.local --confirmed --role Owner 2>/dev/null || true
8. curl -sI http://mastodon/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_LEMMY='Deploy Lemmy on this Podium server. The project name is lemmy — use this exact name, no changes.

Lemmy is a federated link aggregator. It uses a Rust backend, Node.js frontend, and a pictrs image service. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE lemmy;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/lemmy/config
3. Write ~/podium-projects/lemmy/config/config.hjson (the lemmy config file):
{
  database: {
    uri: "postgres://root:password@podium-postgres:5432/lemmy"
  }
  hostname: "lemmy"
  port: 8536
  tls_enabled: false
  pictrs: {
    url: "http://lemmy-pictrs:8080/"
    api_key: "lemmy_pictrs_key"
  }
  email: {
    smtp_server: "podium-mailhog:1025"
    smtp_from_address: "noreply@lemmy"
    tls_type: "none"
  }
  setup: {
    admin_username: "admin"
    admin_password: "Admin12345!"
    admin_email: "admin@lemmy.local"
    site_name: "My Lemmy"
  }
}
4. Write docker-compose.yaml with these services:
   lemmy-app service (image: dessalines/lemmy:latest; volumes: ./config:/config; env: RUST_LOG=warn)
   lemmy-ui service (image: dessalines/lemmy-ui:latest; env: LEMMY_UI_LEMMY_INTERNAL_HOST=lemmy-app:8536, LEMMY_UI_LEMMY_EXTERNAL_HOST=lemmy, LEMMY_UI_HTTPS=false)
   lemmy-pictrs service (image: asonix/pictrs:0.5.0; env: PICTRS__API_KEY=lemmy_pictrs_key; volumes: lemmy-pictrs-data:/mnt)
   nginx service (container_name=lemmy, static VPC IP). Write nginx.conf: route /api, /pictrs, /feeds, /nodeinfo, /.well-known to lemmy-app:8536; all other traffic to lemmy-ui:1234.
5. cd ~/podium-projects/lemmy && podium setup lemmy --no-startup && podium up lemmy
6. Wait 30 seconds, then curl -sI http://lemmy/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_PIXELFED='Deploy Pixelfed on this Podium server. The project name is pixelfed — use this exact name, no changes.

Pixelfed is a federated image sharing platform (image: pixelfed/pixelfed:latest). It serves on port 80 via Apache internally — no extra nginx needed. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty) and shared Redis (host=podium-redis, port=6379).

Steps:
1. Create DB: docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS pixelfed CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/podium-projects/pixelfed
3. Generate APP_KEY: base64:$(openssl rand -base64 32)
4. Write docker-compose.yaml: single service pixelfed-app (image: pixelfed/pixelfed:latest; env: APP_KEY=<generated>, APP_URL=http://pixelfed, DB_CONNECTION=mysql, DB_HOST=podium-mariadb, DB_PORT=3306, DB_DATABASE=pixelfed, DB_USERNAME=root, DB_PASSWORD=, REDIS_HOST=podium-redis, REDIS_PORT=6379, SESSION_DRIVER=redis, CACHE_DRIVER=redis, QUEUE_DRIVER=redis, OPEN_REGISTRATION=true, ENFORCE_EMAIL_VERIFICATION=false, MAIL_DRIVER=log, MAIL_FROM_ADDRESS=noreply@pixelfed, ACTIVITY_PUB=true, IMAGE_QUALITY=80; volumes: pixelfed-storage:/var/www/storage; container_name=pixelfed, static VPC IP).
5. cd ~/podium-projects/pixelfed && podium setup pixelfed --no-startup && podium up pixelfed
6. Wait 30 seconds, then run migrations: docker exec pixelfed php artisan migrate --force 2>/dev/null || docker exec $(docker ps -q -f name=pixelfed) php artisan migrate --force
7. Run storage link: docker exec pixelfed php artisan storage:link 2>/dev/null || true
8. Wait 15 seconds, then curl -sI http://pixelfed/ — expect 200 or 302. Visit http://pixelfed/ to register the first admin user.'"$SUMMARY_SUFFIX"

IDEA_HOMEASSISTANT='Deploy Home Assistant on this Podium server. The project name is home-assistant — use this exact name, no changes.

Home Assistant is a home automation platform (image: ghcr.io/home-assistant/home-assistant:stable). It listens on port 8123. Use an nginx reverse proxy. No external database needed (uses SQLite internally).

Steps:
1. mkdir -p ~/podium-projects/home-assistant
2. Write docker-compose.yaml: home-assistant-app service (image: ghcr.io/home-assistant/home-assistant:stable; env: TZ=UTC; volumes: home-assistant-config:/config) + nginx service (container_name=home-assistant, static VPC IP). Write nginx.conf proxying to home-assistant-app:8123 with the following headers: proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade".
3. cd ~/podium-projects/home-assistant && podium setup home-assistant --no-startup && podium up home-assistant
4. Wait 20 seconds, then curl -sI http://home-assistant/ — expect 200 or 302. First visit shows onboarding wizard.'"$SUMMARY_SUFFIX"

IDEA_ZULIP='Deploy Zulip on this Podium server. The project name is zulip — use this exact name, no changes.

Zulip is a team chat platform (image: zulip/zulip:latest). It serves on port 80 directly — no additional nginx needed. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379). Zulip also requires RabbitMQ and Memcached sidecars.

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE zulip;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/zulip
3. Write docker-compose.yaml with FOUR services:
   zulip-rabbitmq service (image: rabbitmq:3.7.7-management; env: RABBITMQ_DEFAULT_USER=zulip, RABBITMQ_DEFAULT_PASS=zulip)
   zulip-memcached service (image: memcached:1.5.10-alpine)
   zulip-app service (image: zulip/zulip:latest; env: DB_HOST=podium-postgres, DB_HOST_PORT=5432, DB_USER=root, SETTING_DATABASES__default__PASSWORD=password, SECRETS_rabbitmq_password=zulip, SETTING_RABBITMQ_HOST=zulip-rabbitmq, SETTING_RABBITMQ_USER=zulip, SETTING_MEMCACHED_LOCATION=zulip-memcached:11211, SETTING_REDIS_HOST=podium-redis, SETTING_REDIS_PORT=6379, SECRETS_redis_password=, SECRETS_secret_key=$(openssl rand -hex 32), SETTING_EXTERNAL_HOST=zulip, SETTING_ZULIP_ADMINISTRATOR=admin@zulip.local, SSL_CERTIFICATE_GENERATION=self-signed; volumes: zulip-data:/data; depends_on: [zulip-rabbitmq, zulip-memcached]; container_name=zulip, static VPC IP).
4. cd ~/podium-projects/zulip && podium setup zulip --no-startup && podium up zulip
5. Wait 120 seconds for initial setup and migrations, then curl -sI http://zulip/ — expect 200 or 302. Create admin at http://zulip/accounts/find/.'"$SUMMARY_SUFFIX"

IDEA_GRAYLOG='Deploy Graylog on this Podium server. The project name is graylog — use this exact name, no changes.

Graylog is a log management platform (image: graylog/graylog:6.0). It listens on port 9000. Use an nginx reverse proxy. Use the shared MongoDB (host=podium-mongo, port=27017, user=root, password=password). Graylog also requires an OpenSearch sidecar.

Steps:
1. mkdir -p ~/podium-projects/graylog
2. Generate password: GRAYLOG_ROOT_PASSWORD_SHA2=$(echo -n admin | sha256sum | cut -d" " -f1)
3. Write docker-compose.yaml with TWO app services:
   graylog-opensearch service (image: opensearchproject/opensearch:2.4.0; env: discovery.type=single-node, OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m, DISABLE_INSTALL_DEMO_CONFIG=true, DISABLE_SECURITY_PLUGIN=true; volumes: graylog-opensearch-data:/usr/share/opensearch/data)
   graylog-app service (image: graylog/graylog:6.0; depends_on: [graylog-opensearch]; env: GRAYLOG_PASSWORD_SECRET=$(openssl rand -hex 16), GRAYLOG_ROOT_PASSWORD_SHA2=<from step 2>, GRAYLOG_HTTP_EXTERNAL_URI=http://graylog/, GRAYLOG_MONGODB_URI=mongodb://root:password@podium-mongo:27017/graylog?authSource=admin, GRAYLOG_ELASTICSEARCH_HOSTS=http://graylog-opensearch:9200; volumes: graylog-data:/usr/share/graylog/data)
   nginx service (container_name=graylog, static VPC IP). Write nginx.conf proxying to graylog-app:9000.
4. cd ~/podium-projects/graylog && podium setup graylog --no-startup && podium up graylog
5. Wait 90 seconds for startup (OpenSearch takes time), then curl -sI http://graylog/ — expect 200 or 302. Default credentials: admin / admin.'"$SUMMARY_SUFFIX"

IDEA_TAIGA='Deploy Taiga on this Podium server. The project name is taiga — use this exact name, no changes.

Taiga is a project management platform. It requires multiple services. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password) and shared Redis (host=podium-redis, port=6379). Taiga also needs two RabbitMQ instances.

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE taiga;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/taiga
3. Write docker-compose.yaml with these services (TAIGA_SECRET_KEY=$(openssl rand -hex 32), TAIGA_URL=http://taiga):
   taiga-rabbitmq-async service (image: rabbitmq:3.8-management-alpine; env: RABBITMQ_DEFAULT_USER=taiga, RABBITMQ_DEFAULT_PASS=taiga, RABBITMQ_DEFAULT_VHOST=taiga-async)
   taiga-rabbitmq-events service (image: rabbitmq:3.8-management-alpine; env: RABBITMQ_DEFAULT_USER=taiga, RABBITMQ_DEFAULT_PASS=taiga, RABBITMQ_DEFAULT_VHOST=taiga-events)
   taiga-back service (image: ghcr.io/taigaio/taiga-back:latest; env: POSTGRES_DB=taiga, POSTGRES_USER=root, POSTGRES_PASSWORD=password, POSTGRES_HOST=podium-postgres, TAIGA_SECRET_KEY=<key>, TAIGA_SITES_SCHEME=http, TAIGA_SITES_DOMAIN=taiga, TAIGA_SUBPATH=, RABBITMQ_USER=taiga, RABBITMQ_PASS=taiga, RABBITMQ_VHOST=taiga-async, RABBITMQ_HOST=taiga-rabbitmq-async, RABBITMQ_PORT=5672, REDIS_HOST=podium-redis, REDIS_PORT=6379; volumes: taiga-static:/taiga-back/static, taiga-media:/taiga-back/media; depends_on: [taiga-rabbitmq-async])
   taiga-async service (image: ghcr.io/taigaio/taiga-async:latest; same env as taiga-back; depends_on: [taiga-rabbitmq-async, taiga-back])
   taiga-front service (image: ghcr.io/taigaio/taiga-front:latest; env: TAIGA_URL=http://taiga, TAIGA_WEBSOCKETS_URL=ws://taiga)
   taiga-events service (image: ghcr.io/taigaio/taiga-events:latest; env: RABBITMQ_USER=taiga, RABBITMQ_PASS=taiga, RABBITMQ_VHOST=taiga-events, RABBITMQ_HOST=taiga-rabbitmq-events, RABBITMQ_PORT=5672, TAIGA_SECRET_KEY=<key>; depends_on: [taiga-rabbitmq-events])
   taiga-protected service (image: ghcr.io/taigaio/taiga-protected:latest; env: MAX_AGE=360, SECRET_KEY=<key>)
   taiga-gateway service (image: ghcr.io/taigaio/taiga-gateway:latest; volumes: taiga-static:/taiga/static, taiga-media:/taiga/media; container_name=taiga, static VPC IP; depends_on: [taiga-front, taiga-back, taiga-events, taiga-protected])
4. cd ~/podium-projects/taiga && podium setup taiga --no-startup && podium up taiga
5. Wait 60 seconds for startup, then curl -sI http://taiga/ — expect 200 or 302. Visit http://taiga/ to register.'"$SUMMARY_SUFFIX"

IDEA_ZABBIX='Deploy Zabbix on this Podium server. The project name is zabbix — use this exact name, no changes.

Zabbix is an enterprise monitoring platform. Use a two-service setup: zabbix-server (zabbix/zabbix-server-pgsql:alpine-latest) and zabbix-web (zabbix/zabbix-web-nginx-pgsql:alpine-latest, port 8080). Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE zabbix;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/zabbix
3. Write docker-compose.yaml with THREE services:
   zabbix-server-app service (image: zabbix/zabbix-server-pgsql:alpine-latest; env: DB_SERVER_HOST=podium-postgres, DB_SERVER_PORT=5432, POSTGRES_DB=zabbix, POSTGRES_USER=root, POSTGRES_PASSWORD=password, ZBX_STARTPOLLERS=5)
   zabbix-web-app service (image: zabbix/zabbix-web-nginx-pgsql:alpine-latest; depends_on: [zabbix-server-app]; env: ZBX_SERVER_HOST=zabbix-server-app, DB_SERVER_HOST=podium-postgres, DB_SERVER_PORT=5432, POSTGRES_DB=zabbix, POSTGRES_USER=root, POSTGRES_PASSWORD=password, PHP_TZ=UTC, ZBX_SERVER_NAME=Zabbix)
   nginx service (container_name=zabbix, static VPC IP). Write nginx.conf proxying to zabbix-web-app:8080.
4. cd ~/podium-projects/zabbix && podium setup zabbix --no-startup && podium up zabbix
5. Wait 60 seconds for DB initialization, then curl -sI http://zabbix/ — expect 200 or 302. Default credentials: Admin / zabbix.'"$SUMMARY_SUFFIX"

run_project "plane"          "$IDEA_PLANE" &
run_project "dify"           "$IDEA_DIFY" &
run_project "mastodon"       "$IDEA_MASTODON" &
run_project "lemmy"          "$IDEA_LEMMY" &
run_project "pixelfed"       "$IDEA_PIXELFED" &
run_project "home-assistant" "$IDEA_HOMEASSISTANT" &
run_project "zulip"          "$IDEA_ZULIP" &
run_project "graylog"        "$IDEA_GRAYLOG" &
run_project "taiga"          "$IDEA_TAIGA" &
run_project "zabbix"         "$IDEA_ZABBIX" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
