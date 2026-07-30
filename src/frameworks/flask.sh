#!/bin/bash
# Flask framework hooks

FRAMEWORK_IS_PYTHON=1
FRAMEWORK_DOCKER_TEMPLATE="python3-project"

framework_scaffold() {
    echo-return; echo-cyan "Flask project selected!"

    cat > app.py << 'EOF'
from flask import Flask, jsonify
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(
        message="Hello from Flask!",
        project=os.getenv("APP_NAME", "my-project"),
    )


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Local convenience only — in the container gunicorn serves the app
    # (see PYTHON_APP_COMMAND in docker-compose.yaml).
    app.run(host="127.0.0.1", port=8000, debug=True)
EOF

    cat > requirements.txt << 'EOF'
flask
gunicorn
python-dotenv
sqlalchemy
psycopg2-binary
pymysql
pymongo
redis
EOF

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial Flask project setup" > /dev/null 2>&1
    else
        git init; git add .; git commit -m "Initial Flask project setup"
    fi

    echo-green "Flask project structure created!"
}

framework_python_start_command() {
    # nginx in cbc:nginx-python3 reverse-proxies port 80 to localhost:8000.
    # gunicorn rather than `flask run` so the default scaffold isn't the
    # development server.
    echo "gunicorn --bind 127.0.0.1:8000 --workers 2 --access-logfile - app:app"
}

framework_setup_env() {
    should_write_env ".env" || return 0
    echo-cyan "Setting up .env file ..."; echo-white

    local db_connection db_host db_port db_username db_password
    # SQLite overrides this with a FILE PATH; every server engine uses the name.
    local db_database="$DB_NAME"
    case $DATABASE_ENGINE in
        "sqlite"|"sqlite3")
            # The file MUST sit in the project directory: that is the only path
            # bind-mounted into the container, so a database anywhere else is
            # destroyed when the container is recreated on `podium up`.
            db_connection="sqlite"; db_host=""; db_port=""
            db_username=""; db_password=""
            db_database="/usr/share/nginx/html/${FRAMEWORK_SQLITE_PATH:-database.sqlite}"
            ;;
        "postgres"|"postgresql"|"pgsql")
            db_connection="postgresql"; db_host="$POSTGRES_CONTAINER_NAME"; db_port="5432"
            db_username="root"; db_password="password"
            ;;
        "mongo"|"mongodb")
            db_connection="mongodb"; db_host="$MONGO_CONTAINER_NAME"; db_port="27017"
            db_username="root"; db_password=""
            ;;
        *)
            db_connection="mysql"; db_host="$MARIADB_CONTAINER_NAME"; db_port="3306"
            db_username="root"; db_password=""
            ;;
    esac

    cat > .env << EOF
APP_NAME=$PROJECT_NAME
APP_ENV=local
APP_DEBUG=true
APP_URL=http://$PROJECT_NAME
FLASK_APP=app.py
FLASK_ENV=development
DB_CONNECTION=$db_connection
DB_HOST=$db_host
DB_PORT=$db_port
DB_DATABASE=$db_database
DB_USERNAME=$db_username
DB_PASSWORD=$db_password
REDIS_HOST=$REDIS_CONTAINER_NAME
REDIS_PORT=6379
MAIL_HOST=$MAILHOG_CONTAINER_NAME
MAIL_PORT=1025
EOF

    echo-green "The .env file has been created!"; echo-white
}

framework_run_migrations() {
    # Plain Flask has no migration system. Run Flask-Migrate only if the
    # project actually uses it (migrations/ directory present).
    [ -d "migrations" ] || return 0
    grep -qi "flask-migrate" requirements.txt 2>/dev/null || return 0

    echo-cyan 'Applying Flask-Migrate migrations ...'; echo-white
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && flask db upgrade" > /dev/null 2>&1 || true
    else
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && flask db upgrade" || true
    fi
    echo-green 'Migrations applied.'; echo-white
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
*.sqlite
*.sqlite3
__pycache__/
*.py[cod]
*.egg-info/
.env
.venv/
venv/
instance/
*.log
.DS_Store
GITEOF

    [[ "$JSON_OUTPUT" != "1" ]] && echo-green ".gitignore created for Flask project!"
}
