#!/bin/bash -l
# Installer batch 3 — cami

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/installers3-sessions
LOG=/tmp/podium-tests/installers3-master.log
PODIUM="/usr/local/bin/podium"

run_install() {
    local name="$1"
    local logfile="/tmp/podium-tests/installers3-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    TERM=xterm $PODIUM install "$name" > "$logfile" 2>&1
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

echo "=== Installer Batch 3 (cami) — $(date) ===" | tee "$LOG"
echo ""

run_install "strapi"
run_install "directus"
run_install "excalidraw"
run_install "meilisearch"
run_install "metabase"
run_install "healthchecks"
run_install "netbox"
run_install "label-studio"

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
