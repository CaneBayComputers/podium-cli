#!/bin/bash

# Enable or disable an optional shared service.
#
# Only redis, memcached and mailhog always run (8.7MB combined, and nearly every
# framework touches one). Everything else — databases included — sits behind a
# compose profile and is off until a machine asks for it. Databases are the
# expensive part and the part projects disagree about: a Postgres project should
# not pay for MariaDB and Mongo it will never open.
#
# Enabling happens two ways: automatically, when `podium new` is told which
# engine a project uses, and manually through this command.
#
# The enabled list lives in OPTIONAL_SERVICES in /etc/podium-cli/.env, so it
# survives reboots and applies to every subsequent `podium up`.

set -e

ORIG_DIR=$(pwd)
cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..
DEV_DIR=$(pwd)

source "$DEV_DIR/scripts/pre_check.sh"

# Keep in step with the profiles declared in docker-stack/docker-compose.services.yaml
# redis, memcached and mailhog are deliberately absent: they are always on.
# They cost 8.7MB combined, nearly every framework touches one, and their
# absence surfaces as a confusing 500 rather than a clear connection error.
AVAILABLE_OPTIONAL_SERVICES="mysql postgres mongo minio meilisearch phpmyadmin adminer mongo-express redisinsight"

# slug|group|description|address. The human listing and the --json-output
# listing are BOTH generated from this, so they cannot drift apart the way the
# hand-written usage text did — it advertised two services out of nine, and a
# consumer reading it would have shipped a menu missing seven.
OPTIONAL_SERVICE_CATALOG="\
mysql|database|MariaDB 12, MySQL-compatible|podium-mariadb:3306
postgres|database|PostgreSQL 17|podium-postgres:5432
mongo|database|MongoDB 8|podium-mongo:27017
phpmyadmin|admin-ui|Web admin for MariaDB/MySQL|http://podium-phpmyadmin
adminer|admin-ui|Web admin for MariaDB/MySQL, PostgreSQL, SQLite and MongoDB|http://podium-adminer:8080
mongo-express|admin-ui|Web admin for MongoDB|http://podium-mongo-express:8081
redisinsight|admin-ui|Web admin for Redis|http://podium-redisinsight:5540
minio|storage-search|S3-compatible object storage|http://podium-minio:9000
meilisearch|storage-search|Full-text search engine|http://podium-meilisearch:7700"

# The catalogue and the flat list are two spellings of one fact; disagreement
# means a service is unreachable or invisible. Cheap to check, so check.
_catalog_slugs="$(printf '%s\n' "$OPTIONAL_SERVICE_CATALOG" | cut -d'|' -f1 | sort | tr '\n' ' ')"
_avail_sorted="$(printf '%s\n' $AVAILABLE_OPTIONAL_SERVICES | sort | tr '\n' ' ')"
if [ "$_catalog_slugs" != "$_avail_sorted" ]; then
    echo "podium: internal error — optional service catalogue and list disagree" >&2
    echo "  catalogue: $_catalog_slugs" >&2
    echo "  list     : $_avail_sorted" >&2
    exit 1
fi

# Is a service currently enabled AND actually running? "Enabled" alone has been
# misleading: a failed pull used to leave the name recorded with no container.
service_state() {
    local svc="$1" cname
    case "$svc" in
        mysql) cname="podium-mariadb" ;;
        *)     cname="podium-$svc" ;;
    esac
    case " ${OPTIONAL_SERVICES:-} " in
        *" $svc "*) ;;
        *) printf 'disabled'; return 0 ;;
    esac
    if docker container inspect -f '{{.State.Running}}' "$cname" 2>/dev/null | grep -q true; then
        printf 'running'
    else
        printf 'enabled_not_running'
    fi
}

list_services_json() {
    local line slug group desc addr out=""
    while IFS='|' read -r slug group desc addr; do
        [ -n "$slug" ] || continue
        out="${out:+$out, }{\"slug\": \"$slug\", \"group\": \"$group\", \"description\": \"$desc\", \"address\": \"$addr\", \"state\": \"$(service_state "$slug")\"}"
    done <<< "$OPTIONAL_SERVICE_CATALOG"
    echo "{\"action\": \"list_services\", \"status\": \"success\", \"always_on\": [\"redis\", \"memcached\", \"mailhog\"], \"services\": [$out]}"
}

MODE="${PODIUM_SERVICE_MODE:-enable}"   # set by the podium dispatcher

usage() {
    echo-white "Usage: podium ${MODE}-service <name>"
    echo-white ""
    echo-white "Optional shared services (off by default):"
    local slug group desc addr last=""
    while IFS='|' read -r slug group desc addr; do
        [ -n "$slug" ] || continue
        [ "$group" != "$last" ] && { echo-white ""; echo-white "  ${group}:"; last="$group"; }
        echo-white "$(printf '  %-15s %s' "$slug" "$desc")"
        echo-white "$(printf '  %-15s   %s' "" "$addr")"
    done <<< "$OPTIONAL_SERVICE_CATALOG"
    echo-white ""
    echo-white "Always on, never listed above: redis, memcached, mailhog."
    echo-white ""
    echo-white "Databases are enabled automatically by 'podium new' when a project"
    echo-white "asks for them. Enabled services start with every 'podium up' and are"
    echo-white "reachable by hostname from inside any project container."
}

SERVICE=""
for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        --json-output) export JSON_OUTPUT=1 ;;
        --no-colors) export NO_COLOR=1 ;;
        -*) error "Unknown option: $arg" ;;
        *) SERVICE="$arg" ;;
    esac
done

if [[ -z "$SERVICE" ]]; then
    # A bare invocation is a request to see what exists. In JSON mode that is a
    # successful listing, not a usage error — the GUI asked for exactly this so
    # it could stop maintaining its own copy of the service list.
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        list_services_json
        exit 0
    fi
    usage
    exit 1
fi

if ! printf '%s\n' $AVAILABLE_OPTIONAL_SERVICES | grep -qx "$SERVICE"; then
    error "Unknown optional service '$SERVICE'. Available: $AVAILABLE_OPTIONAL_SERVICES"
fi

case "$SERVICE" in
    minio)       CONTAINER="${MINIO_CONTAINER_NAME:-podium-minio}" ;;
    meilisearch) CONTAINER="${MEILISEARCH_CONTAINER_NAME:-podium-meilisearch}" ;;
    *)           CONTAINER="podium-$SERVICE" ;;
esac

CURRENT="${OPTIONAL_SERVICES:-}"
NEW=""
for s in $CURRENT; do
    [[ "$s" == "$SERVICE" ]] && continue
    NEW="$NEW $s"
done
NEW="$(echo "$NEW" | xargs || true)"

if [[ "$MODE" == "enable" ]]; then
    NEW="$(echo "$NEW $SERVICE" | xargs)"
fi

# Persist the enabled list. The key may not exist yet on installs configured
# before optional services existed, so append it rather than assuming a line to
# rewrite. MUST be quoted: the .env is `source`d by bash, so a bare
# OPTIONAL_SERVICES=minio meilisearch assigns "minio" and then tries to RUN
# "meilisearch", breaking every later podium command with "command not found".
persist_optional_services() {
    if grep -q "^OPTIONAL_SERVICES=" /etc/podium-cli/.env 2>/dev/null; then
        sudo-podium-sed-change "/^OPTIONAL_SERVICES=/" "OPTIONAL_SERVICES=\"$1\"" /etc/podium-cli/.env
    else
        echo "OPTIONAL_SERVICES=\"$1\"" | sudo tee -a /etc/podium-cli/.env > /dev/null
    fi
    export OPTIONAL_SERVICES="$1"
}

if [[ "$MODE" == "enable" ]]; then
    # Start BEFORE recording. Writing the config first meant a service whose
    # image would not pull was left permanently listed as enabled with no
    # container behind it, and every consumer of OPTIONAL_SERVICES then had to
    # second-guess the config instead of trusting it. The profile is passed on
    # the command line, so nothing here needs the value persisted first.
    echo-cyan "Starting $SERVICE ..."
    if ! ( cd /etc/podium-cli && docker compose --profile "$SERVICE" up -d "$SERVICE" ); then
        [[ "$JSON_OUTPUT" == "1" ]] && json_error "failed to start $SERVICE; it was NOT enabled"
        error "Failed to start $SERVICE. It has NOT been enabled — nothing was changed."
    fi
    # `up -d` can report success and still leave a container that exited on
    # boot, which looks identical to a healthy enable from the config's side.
    if ! docker container inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
        ( cd /etc/podium-cli && docker compose --profile "$SERVICE" rm -sf "$SERVICE" >/dev/null 2>&1 ) || true
        [[ "$JSON_OUTPUT" == "1" ]] && json_error "$SERVICE started but is not running; it was NOT enabled"
        error "$SERVICE did not stay running. It has NOT been enabled. Check: docker logs $CONTAINER"
    fi
    persist_optional_services "$NEW"
    # The host needs to resolve the name too — the MinIO console is meant to be
    # opened in a browser, and `podium status` pings by hostname. Compose
    # profiles hide these services from `docker compose config`, so the entry
    # cannot come from configure.sh's usual sweep until it is re-run.
    _ip=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || true)
    if [[ -n "$_ip" ]]; then
        sudo-podium-sed "/[[:space:]]${CONTAINER}[[:space:]]*$/d" /etc/hosts 2>/dev/null || true
        echo "$_ip        $CONTAINER" | sudo tee -a /etc/hosts > /dev/null
        echo-white "  Added /etc/hosts entry: $_ip $CONTAINER"
    fi

    echo-green "$SERVICE enabled."
    case "$SERVICE" in
        minio)
            echo-white "  API:     http://podium-minio:9000  (from inside a container)"
            echo-white "  Console: http://podium-minio:9001"
            echo-white "  Keys:    root / password"
            ;;
        meilisearch)
            echo-white "  API:       http://podium-meilisearch:7700"
            echo-white "  Master key: podium-dev-master-key"
            ;;
        redisinsight)
            echo-white "  Open: http://podium-redisinsight:5540"
            echo-white "  The shared Redis is pre-registered as 'Podium Redis'. It stays"
            echo-white "  hidden until you accept the terms on the first-run screen —"
            echo-white "  RedisInsight only runs its discovery after that."
            ;;
        adminer)
            echo-white "  Open: http://podium-adminer:8080"
            echo-white "  Server is prefilled with podium-mariadb; change it and pick the"
            echo-white "  engine at the login screen for PostgreSQL or MongoDB."
            echo-white "  User: root"
            ;;
        mongo-express)
            echo-white "  Open: http://podium-mongo-express:8081"
            echo-white "  Already connected to podium-mongo; no login needed."
            ;;
        phpmyadmin)
            echo-white "  Open: http://podium-phpmyadmin"
            echo-white "  User: root  (no password)"
            ;;
    esac
else
    persist_optional_services "$NEW"
    echo-cyan "Stopping $SERVICE ..."
    ( cd /etc/podium-cli && docker compose --profile "$SERVICE" stop "$SERVICE" >/dev/null 2>&1 ) || true
    ( cd /etc/podium-cli && docker compose --profile "$SERVICE" rm -f "$SERVICE" >/dev/null 2>&1 ) || true
    sudo-podium-sed "/[[:space:]]${CONTAINER}[[:space:]]*$/d" /etc/hosts 2>/dev/null || true
    echo-green "$SERVICE disabled. Its data volume is kept — re-enable to get it back."
fi

if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"${MODE}_service\", \"service\": \"$SERVICE\", \"enabled\": \"$NEW\", \"status\": \"success\"}"
fi

cd "$ORIG_DIR"
