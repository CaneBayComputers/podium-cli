#!/bin/bash -l
# Installer batch 2 — cami

mkdir -p /tmp/podium-tests/installers2-sessions
LOG=/tmp/podium-tests/installers2-master.log
PODIUM="/usr/local/bin/podium"

run_install() {
    local name="$1"
    local logfile="/tmp/podium-tests/installers2-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    TERM=xterm $PODIUM install "$name" > "$logfile" 2>&1
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

echo "=== Installer Batch 2 (cami) — $(date) ===" | tee "$LOG"
echo ""

run_install "monica"
run_install "listmonk"
run_install "hedgedoc"
run_install "linkwarden"
run_install "tandoor"
run_install "n8n"
run_install "actual-budget"
run_install "nextcloud"

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
