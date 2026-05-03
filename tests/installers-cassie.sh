#!/bin/bash -l
# Installer tests — cassie
# Tests: stirling-pdf, it-tools, changedetection, flame, heimdall, umami, dashy, limesurvey

mkdir -p /tmp/podium-tests/installer-sessions
LOG=/tmp/podium-tests/installer-master.log
PODIUM="/usr/local/bin/podium"

run_install() {
    local name="$1"
    local logfile="/tmp/podium-tests/installer-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Installing: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 600 bash -l -c "TERM=xterm $PODIUM install $name > \"$logfile\" 2>&1"
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

echo "=== Installer Tests (cassie) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

run_install "stirling-pdf"
run_install "it-tools"
run_install "changedetection"
run_install "flame"
run_install "heimdall"
run_install "umami"
run_install "dashy"
run_install "limesurvey"

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
