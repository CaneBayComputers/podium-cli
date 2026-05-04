INSTALL_DISPLAY="Invoice Ninja"
INSTALL_CREDENTIALS="admin@example.com / changeme!"

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ninja CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    cat > docker-compose.yaml << EOF
services:
  invoice-ninja-app:
    image: invoiceninja/invoiceninja:5
    restart: unless-stopped
    environment:
      APP_NAME: "Invoice Ninja"
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: http://invoice-ninja
      APP_KEY: $app_key
      APP_CIPHER: AES-256-CBC
      DB_TYPE: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: ninja
      DB_USERNAME: root
      DB_PASSWORD: ""
      DB_STRICT: "false"
      REQUIRE_HTTPS: "false"
      TRUSTED_PROXIES: "*"
      IS_DOCKER: "true"
      NINJA_ENVIRONMENT: selfhost
      CACHE_DRIVER: file
      SESSION_DRIVER: file
      QUEUE_CONNECTION: database
      MAIL_MAILER: smtp
      MAIL_HOST: podium-mailhog
      MAIL_PORT: 1025
      MAIL_ENCRYPTION: "null"
      MAIL_FROM_ADDRESS: admin@invoice-ninja.local
      MAIL_FROM_NAME: "Invoice Ninja"
      IN_USER_EMAIL: admin@example.com
      IN_PASSWORD: "changeme!"
    volumes:
      - invoice-ninja-public:/var/www/app/public
      - invoice-ninja-storage:/var/www/app/storage

  # nginx uses fastcgi to invoice-ninja-app PHP-FPM on port 9000
  # it shares the invoice-ninja-public volume to serve static assets
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - invoice-ninja-public:/var/www/app/public:ro
    depends_on:
      - invoice-ninja-app

volumes:
  invoice-ninja-public:
  invoice-ninja-storage:
EOF

    cat > nginx.conf << 'NGINX'
server {
    listen 80;
    root /var/www/app/public;
    index index.php index.html;
    client_max_body_size 64M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass invoice-ninja-app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS off;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINX
}
