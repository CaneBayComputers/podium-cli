INSTALL_DISPLAY="OpnForm"
INSTALL_CREDENTIALS="Create the admin account on the first-visit setup page"
INSTALL_NOTES="Free self-hosted instances are limited to 2 users total. Migrations run automatically on first boot (~60 seconds)."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE opnform;" 2>/dev/null || true
}

write_files() {
    local app_key jwt_secret
    app_key="base64:$(openssl rand -base64 32)"
    jwt_secret=$(openssl rand -hex 20)

    cat > docker-compose.yaml << EOF
x-api-env: &api-env
  APP_NAME: OpnForm
  APP_ENV: production
  APP_DEBUG: "false"
  APP_KEY: "$app_key"
  APP_URL: http://opnform
  FRONT_URL: http://opnform
  JWT_SECRET: "$jwt_secret"
  JWT_TTL: 1440
  LOG_CHANNEL: errorlog
  LOG_LEVEL: error
  DB_CONNECTION: pgsql
  DB_HOST: podium-postgres
  DB_PORT: 5432
  DB_DATABASE: opnform
  DB_USERNAME: root
  DB_PASSWORD: password
  REDIS_HOST: podium-redis
  REDIS_PORT: 6379
  CACHE_DRIVER: redis
  QUEUE_CONNECTION: redis
  SESSION_DRIVER: redis
  FILESYSTEM_DRIVER: local
  LOCAL_FILESYSTEM_VISIBILITY: public
  MAIL_MAILER: smtp
  MAIL_HOST: podium-mailhog
  MAIL_PORT: 1025
  MAIL_FROM_ADDRESS: opnform@example.com
  MAIL_FROM_NAME: OpnForm
  PHP_MEMORY_LIMIT: 1G
  PHP_MAX_EXECUTION_TIME: "600"
  PHP_UPLOAD_MAX_FILESIZE: 64M
  PHP_POST_MAX_SIZE: 64M

services:
  opnform-api:
    image: jhumanj/opnform-api:2.2.4
    container_name: opnform-api
    restart: unless-stopped
    environment: *api-env
    volumes:
      - opnform-storage:/usr/share/nginx/html/storage

  opnform-worker:
    image: jhumanj/opnform-api:2.2.4
    restart: unless-stopped
    command: ["php", "artisan", "queue:work"]
    environment: *api-env
    volumes:
      - opnform-storage:/usr/share/nginx/html/storage
    depends_on:
      - opnform-api

  opnform-scheduler:
    image: jhumanj/opnform-api:2.2.4
    restart: unless-stopped
    command: ["php", "artisan", "schedule:work"]
    environment: *api-env
    volumes:
      - opnform-storage:/usr/share/nginx/html/storage
    depends_on:
      - opnform-api

  opnform-client:
    image: jhumanj/opnform-client:2.2.4
    container_name: opnform-client
    restart: unless-stopped
    environment:
      NUXT_PUBLIC_APP_URL: /
      NUXT_PUBLIC_API_BASE: /api
      NUXT_PRIVATE_API_BASE: http://nginx/api
      NUXT_PUBLIC_ENV: production
    depends_on:
      - opnform-api

  nginx:
    image: nginx:1.30-alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - opnform-api
      - opnform-client

volumes:
  opnform-storage:
EOF

    cat > nginx.conf << 'NGINX'
map $request_uri $api_uri {
    ~^/api(/.*$) $1;
    default $request_uri;
}

server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html/public;
    client_max_body_size 64m;

    index index.html index.htm index.php;

    location / {
        proxy_http_version 1.1;
        proxy_pass http://opnform-client:3000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    location ~/(api|open|local\/temp|forms\/assets)/ {
        set $original_uri $uri;
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass opnform-api:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        fastcgi_param REQUEST_URI $api_uri;
        fastcgi_param HTTP_X_FORWARDED_FOR $proxy_add_x_forwarded_for;
        fastcgi_param HTTP_X_FORWARDED_HOST $http_x_forwarded_host;
        fastcgi_param HTTP_X_FORWARDED_PORT $http_x_forwarded_port;
        fastcgi_param HTTP_X_FORWARDED_PROTO $http_x_forwarded_proto;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX
}
