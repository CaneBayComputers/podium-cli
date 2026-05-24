#!/bin/bash
# PHP framework hooks

FRAMEWORK_IS_PYTHON=0
FRAMEWORK_DOCKER_TEMPLATE="project"

framework_scaffold() {
    echo-return; echo-cyan "Creating PHP project structure..."

    mkdir -p public src
    cat > public/index.php << 'EOF'
<?php
echo "Hello, World! This is your PHP project.";
?>
EOF

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial PHP project setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial PHP project setup"
    fi

    echo-green "PHP project structure created!"
}

framework_python_start_command() { echo ""; }

framework_setup_env() {
    should_write_env "config.inc.php" || return 0
    if [ -f "config.example.inc.php" ]; then
        cp -f config.example.inc.php config.inc.php
        podium-sed "s/DB_HOSTNAME/$MARIADB_CONTAINER_NAME/" config.inc.php
        podium-sed "s/DB_USERNAME/root/" config.inc.php
        podium-sed "s/DB_PASSWORD//" config.inc.php
        podium-sed "s/DB_NAME/$DB_NAME/" config.inc.php
    fi
    # Plain PHP projects don't need a .env by default
}

framework_run_migrations() {
    if [ -f "create_tables.sql" ]; then
        echo-cyan 'Creating tables ...'; echo-white
        docker container exec -i "$MARIADB_CONTAINER_NAME" mariadb -u"root" "$DB_NAME" < create_tables.sql
    fi
}

framework_setup_gitignore() {
    # Ensure public/index.php exists as entry point
    if [ ! -f "index.php" ] && [ ! -f "public/index.php" ]; then
        mkdir -p public
        cat > public/index.php << 'EOF'
<?php
echo "Hello, World! This is your PHP project.";
?>
EOF
        [[ "$JSON_OUTPUT" != "1" ]] && echo-green "Created public/index.php entry point!"
    fi

    [ -f ".gitignore" ] && {
        if ! grep -q "docker-compose.yaml" .gitignore; then
            printf '\n# Docker infrastructure\ndocker-compose.yaml\n' >> .gitignore
        fi
        return
    }

    cat > .gitignore << 'GITEOF'
# Docker infrastructure
docker-compose.yaml

# Dependencies
vendor/
node_modules/

# Environment files
.env
.env.local

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for PHP project!"
}
