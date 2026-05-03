#!/bin/bash
# Plain Python framework hooks

FRAMEWORK_IS_PYTHON=1
FRAMEWORK_DOCKER_TEMPLATE="python3-project"

framework_scaffold() {
    echo-return; echo-cyan "Python project selected!"

    cat > main.py << 'EOF'
from dotenv import load_dotenv
import os

load_dotenv()

def main():
    print(f"Hello from {os.getenv('APP_NAME', 'my-project')}!")

if __name__ == "__main__":
    main()
EOF

    cat > requirements.txt << 'EOF'
python-dotenv
EOF

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial Python project setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial Python project setup"
    fi

    echo-green "Python project structure created!"
}

framework_python_start_command() {
    echo "python3 main.py"
}

framework_setup_env() {
    echo-cyan "Setting up .env file ..."; echo-white

    local db_connection db_host db_port
    case $DATABASE_ENGINE in
        "postgresql") db_connection="pgsql"; db_host="$POSTGRES_CONTAINER_NAME"; db_port="5432" ;;
        "mongodb")    db_connection="mongodb"; db_host="$MONGO_CONTAINER_NAME"; db_port="27017" ;;
        *)            db_connection="mysql"; db_host="$MARIADB_CONTAINER_NAME"; db_port="3306" ;;
    esac

    cat > .env << EOF
APP_NAME=$PROJECT_NAME
APP_ENV=local
APP_DEBUG=true
APP_URL=http://$PROJECT_NAME
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

framework_run_migrations() { :; }

framework_setup_gitignore() {
    [ -f ".gitignore" ] && {
        if ! grep -q "docker-compose.yaml" .gitignore; then
            printf '\n# Docker infrastructure\ndocker-compose.yaml\n' >> .gitignore
        fi
        return
    }

    cat > .gitignore << 'GITEOF'
docker-compose.yaml
__pycache__/
*.py[cod]
*.egg-info/
.env
.venv/
venv/
*.log
.DS_Store
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for Python project!"
}
