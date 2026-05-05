INSTALL_DISPLAY="October CMS"
INSTALL_CREDENTIALS="admin / password (backend at http://octobercms/backend)"
INSTALL_NOTES="First boot copies files and runs migrations (~60-90s). The official image bundles its own MariaDB internally — this is the only image upstream ships and it ignores external DB env, so podium-mariadb is not used here."

write_files() {
    cat > podium-init.sh << 'INIT'
#!/bin/bash
# Wrapper around the upstream octobercms entrypoint. Runs admin-user creation in the
# background once migrations finish; the upstream entrypoint runs as the main process.
(
    for _ in $(seq 1 120); do
        if mysql -u root -proot octobercms -e 'SELECT 1 FROM backend_users LIMIT 1;' &>/dev/null; then
            break
        fi
        sleep 3
    done
    if ! mysql -u root -proot octobercms -Nse 'SELECT id FROM backend_users WHERE login="admin" LIMIT 1;' 2>/dev/null | grep -q .; then
        cd /var/www/html
        php artisan tinker --execute='
            $u = new Backend\Models\User;
            $u->first_name = "Admin";
            $u->last_name = "User";
            $u->login = "admin";
            $u->email = "admin@admin.com";
            $u->password = "password";
            $u->password_confirmation = "password";
            $u->is_superuser = true;
            $u->is_activated = true;
            $u->save();
            echo "Podium: admin user created (admin / password)\n";
        '
    fi
) &
exec /usr/local/bin/entrypoint.sh "$@"
INIT
    chmod +x podium-init.sh

    cat > docker-compose.yaml << 'COMPOSE'
services:
  app:
    image: octobercms/october@sha256:775852dc4c7cba6f6e48b81f4a970d8a6c3afc001c36a185a11049276903a8c3
    restart: unless-stopped
    entrypoint: ["/usr/local/bin/podium-init.sh"]
    volumes:
      - ./podium-init.sh:/usr/local/bin/podium-init.sh:ro
      - octobercms-app:/var/www/html
      - octobercms-mysql:/var/lib/october-mysql

volumes:
  octobercms-app:
  octobercms-mysql:
COMPOSE
}
