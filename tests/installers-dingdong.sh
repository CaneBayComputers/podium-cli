#!/bin/bash -l
# Installer tests — dingdong
# Tests: portainer, netdata, miniflux, grafana, vikunja, mealie, vaultwarden, kanboard

mkdir -p /tmp/zeltro-tests/installer-sessions
LOG=/tmp/zeltro-tests/installer-master.log
ZELTRO="/usr/local/bin/zeltro"

run_install() {
    local name="$1"
    local logfile="/tmp/zeltro-tests/installer-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Installing: $name ===" | tee -a "$LOG"

    TERM=xterm $ZELTRO remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 600 bash -l -c "TERM=xterm $ZELTRO install $name > \"$logfile\" 2>&1"
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

echo "=== Installer Tests (dingdong) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

run_install "portainer"
run_install "netdata"
run_install "miniflux"
run_install "grafana"
run_install "vikunja"
run_install "mealie"
run_install "vaultwarden"
run_install "kanboard"

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
