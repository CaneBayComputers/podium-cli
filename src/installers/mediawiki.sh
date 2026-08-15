INSTALL_DISPLAY="MediaWiki"
INSTALL_CREDENTIALS="admin / mediawiki123"
INSTALL_NOTES="The setup wizard is run for you by a one-shot installer service; LocalSettings.php lives in the mediawiki-config volume."
INSTALL_READY_RETRIES=40

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS mediawiki CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  # MediaWiki's web installer cannot write LocalSettings.php — /var/www/html is
  # root-owned in the official image — so it makes you download the file and put
  # it in place by hand. Run the CLI installer instead, drop the result in a
  # shared volume, and point the web container at it with MW_CONFIG_FILE. The
  # test -f guard makes every later start a no-op.
  mediawiki-install:
    image: mediawiki:1.46.0
    restart: "no"
    volumes:
      - mediawiki-config:/conf
    command:
      - sh
      - -c
      - >
        test -f /conf/LocalSettings.php ||
        php maintenance/run.php install
        --dbtype=mysql
        --dbserver=podium-mariadb
        --dbname=mediawiki
        --dbuser=root
        --dbpass=""
        --server=http://mediawiki
        --scriptpath=""
        --lang=en
        --pass=mediawiki123
        --confpath=/conf
        "Podium Wiki" admin

  app:
    image: mediawiki:1.46.0
    restart: unless-stopped
    environment:
      MW_CONFIG_FILE: /conf/LocalSettings.php
    volumes:
      - mediawiki-config:/conf
      - mediawiki-images:/var/www/html/images
    depends_on:
      mediawiki-install:
        condition: service_completed_successfully

volumes:
  mediawiki-config:
  mediawiki-images:
EOF
}
