INSTALL_DISPLAY="YOURLS"
INSTALL_CREDENTIALS="admin / admin123"
INSTALL_NOTES="Visit http://$PROJECT_NAME/admin/ to manage your short links."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS yourls CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    mkdir -p apache

    cat > apache/ports.conf << 'EOF'
Listen 80
EOF

    cat > apache/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName yourls
    ServerAlias *
    DocumentRoot /var/www/html

    <Directory "/var/www/html">
        Options -Indexes +FollowSymLinks -MultiViews
        AllowOverride None
        Require all granted

        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^.*$ /yourls-loader.php [L]
        </IfModule>
    </Directory>
</VirtualHost>
EOF

    cat > index.php << 'EOF'
<?php
header('Location: /admin/');
exit;
EOF

    cat > docker-compose.yaml << 'EOF'
services:
  yourls:
    image: ghcr.io/yourls/yourls:latest
    restart: unless-stopped
    environment:
      YOURLS_DB_HOST: podium-mariadb
      YOURLS_DB_USER: root
      YOURLS_DB_PASS: ""
      YOURLS_DB_NAME: yourls
      YOURLS_SITE: http://yourls
      YOURLS_USER: admin
      YOURLS_PASS: admin123
    volumes:
      - ./apache/ports.conf:/etc/apache2/ports.conf:ro
      - ./apache/000-default.conf:/etc/apache2/sites-enabled/000-default.conf:ro
      - ./index.php:/var/www/html/index.php:ro

volumes: {}
EOF
}
