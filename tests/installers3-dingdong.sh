#!/bin/bash -l
# Installer batch 3 — dingdong (local)

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

echo "=== Installer Batch 3 (dingdong) — $(date) ===" | tee "$LOG"
echo ""

run_install "firefly-iii"
run_install "invoice-ninja"
run_install "flarum"
run_install "freescout"
run_install "leantime"
run_install "koel"
run_install "shlink"
run_install "cachet"

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
