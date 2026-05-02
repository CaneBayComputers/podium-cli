#!/bin/bash
# WordPress framework hooks

FRAMEWORK_IS_PYTHON=0
FRAMEWORK_DOCKER_TEMPLATE="project"

framework_scaffold() {
    echo-return; echo-cyan "Downloading WordPress..."

    if [ "$WP_VERSION" = "latest" ]; then
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            curl -sO https://wordpress.org/latest.tar.gz
            tar -xzf latest.tar.gz --strip-components=1
            rm latest.tar.gz
        else
            curl -O https://wordpress.org/latest.tar.gz
            tar -xzf latest.tar.gz --strip-components=1
            rm latest.tar.gz
        fi
    else
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            curl -sO "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz"
            tar -xzf "wordpress-${WP_VERSION}.tar.gz" --strip-components=1
            rm "wordpress-${WP_VERSION}.tar.gz"
        else
            curl -O "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz"
            tar -xzf "wordpress-${WP_VERSION}.tar.gz" --strip-components=1
            rm "wordpress-${WP_VERSION}.tar.gz"
        fi
    fi

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial WordPress setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial WordPress setup"
    fi

    echo-green "WordPress downloaded and initialized!"
}

framework_python_start_command() { echo ""; }

framework_setup_env() {
    [ ! -f "wp-config-sample.php" ] && return

    echo-cyan "Configuring WordPress for containerized setup..."

    cat > wp-config.php << EOF
<?php
define('DB_NAME', '$PROJECT_NAME_SNAKE');
define('DB_USER', 'root');
define('DB_PASSWORD', '');
define('DB_HOST', '$MARIADB_CONTAINER_NAME');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('AUTH_KEY',         '$(openssl rand -base64 32)');
define('SECURE_AUTH_KEY',  '$(openssl rand -base64 32)');
define('LOGGED_IN_KEY',    '$(openssl rand -base64 32)');
define('NONCE_KEY',        '$(openssl rand -base64 32)');
define('AUTH_SALT',        '$(openssl rand -base64 32)');
define('SECURE_AUTH_SALT', '$(openssl rand -base64 32)');
define('LOGGED_IN_SALT',   '$(openssl rand -base64 32)');
define('NONCE_SALT',       '$(openssl rand -base64 32)');

\$table_prefix = 'wp_';

define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

    echo-green "WordPress configuration created!"
    echo-white
    echo-cyan "WordPress will be automatically set up when the container starts."
    echo-white "After setup completes, visit http://$PROJECT_NAME to complete the WordPress installation."
}

framework_run_migrations() {
    # WordPress has no CLI migrations — setup happens via browser
    :
}

framework_setup_gitignore() {
    [ -f ".gitignore" ] && {
        if ! grep -q "docker-compose.yaml" .gitignore; then
            printf '\n# Docker infrastructure\ndocker-compose.yaml\n' >> .gitignore
        fi
        return
    }

    cat > .gitignore << 'GITEOF'
# Docker infrastructure
docker-compose.yaml

# WordPress core files
wp-config.php
wp-content/uploads/
wp-content/cache/
wp-content/backup-db/
wp-content/advanced-cache.php
wp-content/wp-cache-config.php
wp-content/plugins/hello.php
wp-content/plugins/akismet/
wp-content/upgrade/
wp-content/debug.log

# Environment files
.env
.env.local

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for WordPress project!"
}
