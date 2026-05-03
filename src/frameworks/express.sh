#!/bin/bash
# Express framework hooks

FRAMEWORK_IS_PYTHON=0
FRAMEWORK_IS_NODE=1
FRAMEWORK_DOCKER_TEMPLATE="node-project"

framework_scaffold() {
    echo-return; echo-cyan "Express project selected!"

    cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "dotenv": "^16.0.0",
    "express": "^4.18.0"
  }
}
EOF

    cat > server.js << 'EOF'
require('dotenv').config();
const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.json({
        message: 'Hello from Express!',
        project: process.env.APP_NAME || 'my-project'
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on 0.0.0.0:${port}`);
});
EOF

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial Express project setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial Express project setup"
    fi

    echo-green "Express project structure created!"
}

framework_python_start_command() { echo ""; }

framework_node_start_command() {
    echo "node server.js"
}

framework_setup_env() {
    echo-cyan "Setting up .env file ..."; echo-white

    local db_connection db_host db_port
    case $DATABASE_ENGINE in
        "postgres"|"postgresql"|"pgsql") db_connection="postgresql"; db_host="$POSTGRES_CONTAINER_NAME"; db_port="5432" ;;
        "mongo"|"mongodb")    db_connection="mongodb"; db_host="$MONGO_CONTAINER_NAME"; db_port="27017" ;;
        *)            db_connection="mysql"; db_host="$MARIADB_CONTAINER_NAME"; db_port="3306" ;;
    esac

    cat > .env << EOF
APP_NAME=$PROJECT_NAME
APP_ENV=local
APP_DEBUG=true
APP_URL=http://$PROJECT_NAME
PORT=3000
DB_CONNECTION=$db_connection
DB_HOST=$db_host
DB_PORT=$db_port
DB_DATABASE=$PROJECT_NAME_SNAKE
DB_USERNAME=root
DB_PASSWORD=
REDIS_HOST=$REDIS_CONTAINER_NAME
REDIS_PORT=6379
MAIL_HOST=$MAILHOG_CONTAINER_NAME
MAIL_PORT=1025
EOF

    echo-green "The .env file has been created!"; echo-white
}

framework_run_migrations() {
    # Express uses no built-in migration runner — run manually or via a migration library
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
docker-compose.yaml
node_modules/
.env
*.log
.DS_Store
dist/
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for Express project!"
}
