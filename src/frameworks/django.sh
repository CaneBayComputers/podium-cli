#!/bin/bash
# Django framework hooks

FRAMEWORK_IS_PYTHON=1
FRAMEWORK_DOCKER_TEMPLATE="python3-project"

framework_scaffold() {
    echo-return; echo-cyan "Django project selected!"

    PROJECT_NAME_SNAKE=$(echo "$PROJECT_NAME" | sed 's/-/_/g')

    if ! command -v django-admin >/dev/null 2>&1; then
        pip3 install django --break-system-packages > /dev/null 2>&1
    fi

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        django-admin startproject "$PROJECT_NAME_SNAKE" . > /dev/null 2>&1
    else
        django-admin startproject "$PROJECT_NAME_SNAKE" .
    fi

    cat > requirements.txt << 'EOF'
django
gunicorn
python-dotenv
pymysql
psycopg2-binary
pymongo
redis
EOF

    # Patch settings.py: prepend dotenv + pymysql shim, fix ALLOWED_HOSTS and DATABASES
    local settings_file="${PROJECT_NAME_SNAKE}/settings.py"
    printf 'from dotenv import load_dotenv\nfrom pathlib import Path\nimport os\nimport pymysql\npymysql.install_as_MySQLdb()\nload_dotenv(Path(__file__).resolve().parent.parent / ".env")\n\n' | \
        cat - "$settings_file" > /tmp/podium_settings_tmp.py && mv /tmp/podium_settings_tmp.py "$settings_file"

    sed -i "s|^ALLOWED_HOSTS = \[.*\]|ALLOWED_HOSTS = ['*']|" "$settings_file"

    python3 - "$settings_file" << 'PYEOF'
import re, sys
path = sys.argv[1]
content = open(path).read()
new_db = """DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.' + os.getenv('DB_CONNECTION', 'mysql'),
        'NAME': os.getenv('DB_DATABASE', ''),
        'USER': os.getenv('DB_USERNAME', 'root'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', ''),
        'PORT': os.getenv('DB_PORT', '3306'),
    }
}"""
content = re.sub(r'DATABASES\s*=\s*\{[^}]*\{[^}]*\}[^}]*\}', new_db, content, flags=re.DOTALL)
open(path, 'w').write(content)
PYEOF

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial Django project setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial Django project setup"
    fi

    echo-green "Django project structure created!"
}

framework_python_start_command() {
    local snake
    snake=$(echo "$PROJECT_NAME" | sed 's/-/_/g')
    echo "gunicorn ${snake}.wsgi:application --bind 127.0.0.1:8000 --workers 2"
}

framework_setup_env() {
    [ -f ".env" ] && return  # already exists (e.g. cloned project)
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

framework_run_migrations() {
    [ ! -f "manage.py" ] && return
    echo-cyan 'Running Django initial migrations ...'; echo-white

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && python3 manage.py migrate" > /dev/null 2>&1
    else
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && python3 manage.py migrate"
    fi

    echo-green 'Django migrations complete!'; echo-white
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
__pycache__/
*.py[cod]
*.egg-info/
.env
.venv/
venv/
*.log
.DS_Store
staticfiles/
media/
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for Django project!"
}
