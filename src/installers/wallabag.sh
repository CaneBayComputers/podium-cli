INSTALL_DISPLAY="Wallabag"
INSTALL_CREDENTIALS="wallabag / wallabag"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  wallabag:
    image: wallabag/wallabag:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ""
      SYMFONY__ENV__DATABASE_DRIVER: pdo_mysql
      SYMFONY__ENV__DATABASE_HOST: podium-mariadb
      SYMFONY__ENV__DATABASE_PORT: 3306
      SYMFONY__ENV__DATABASE_NAME: wallabag
      SYMFONY__ENV__DATABASE_USER: root
      SYMFONY__ENV__DATABASE_PASSWORD: ""
      SYMFONY__ENV__DOMAIN_NAME: http://wallabag
      SYMFONY__ENV__SERVER_NAME: "Wallabag"
      SYMFONY__ENV__FOSUSER_REGISTRATION: "true"
      POPULATE_DATABASE: "true"
    volumes:
      - wallabag-images:/var/www/wallabag/web/assets/images

volumes:
  wallabag-images:
EOF
}
