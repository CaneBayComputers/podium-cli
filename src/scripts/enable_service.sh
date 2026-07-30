#!/bin/bash

# Enable or disable an optional shared service.
#
# Core shared services (mariadb, postgres, redis, mongo, memcached, mailhog)
# always run, because nearly every project needs a database. Optional ones sit
# behind compose profiles and are off until a machine asks for them — most
# projects need neither object storage nor a search engine, and making every
# install pay that RAM to benefit a few is the wrong trade.
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
AVAILABLE_OPTIONAL_SERVICES="minio meilisearch"

MODE="${PODIUM_SERVICE_MODE:-enable}"   # set by the podium dispatcher

usage() {
    echo-white "Usage: podium ${MODE}-service <name>"
    echo-white ""
    echo-white "Optional shared services (off by default):"
    echo-white "  minio         S3-compatible object storage  — podium-minio:9000"
    echo-white "  meilisearch   Full-text search engine       — podium-meilisearch:7700"
    echo-white ""
    echo-white "Enabled services start with every 'podium up' and are reachable by"
    echo-white "hostname from inside any project container, like the core services."
    error "usage" 1
}

SERVICE=""
for arg in "$@"; do
    case "$arg" in
        --help|-h) usage ;;
        --json-output) export JSON_OUTPUT=1 ;;
        --no-colors) export NO_COLOR=1 ;;
        -*) error "Unknown option: $arg" ;;
        *) SERVICE="$arg" ;;
    esac
done

[[ -z "$SERVICE" ]] && usage

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

# Persist. The key may not exist yet on installs configured before optional
# services existed, so append it rather than assuming a line to rewrite.
# MUST be quoted: the .env is `source`d by bash, so a bare
# OPTIONAL_SERVICES=minio meilisearch assigns "minio" and then tries to RUN
# "meilisearch", breaking every later podium command with "command not found".
if grep -q "^OPTIONAL_SERVICES=" /etc/podium-cli/.env 2>/dev/null; then
    sudo-podium-sed-change "/^OPTIONAL_SERVICES=/" "OPTIONAL_SERVICES=\"$NEW\"" /etc/podium-cli/.env
else
    echo "OPTIONAL_SERVICES=\"$NEW\"" | sudo tee -a /etc/podium-cli/.env > /dev/null
fi

export OPTIONAL_SERVICES="$NEW"

if [[ "$MODE" == "enable" ]]; then
    echo-cyan "Starting $SERVICE ..."
    ( cd /etc/podium-cli && docker compose --profile "$SERVICE" up -d "$SERVICE" ) || \
        error "Failed to start $SERVICE"
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
    esac
else
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
