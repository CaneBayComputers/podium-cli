#!/bin/bash

# Podium GUI Startup Script
# This script launches the Podium GUI application

set -e

# Check if GUI is already running
if pgrep -f "electron.*podium" > /dev/null; then
    echo "Podium GUI is already running"
    exit 0
fi

# Check if Podium CLI is configured
if [ ! -f "/usr/local/share/podium-cli/docker-stack/.env" ]; then
    zenity --error --text="Podium CLI is not configured. Please run 'podium config' first." 2>/dev/null || {
        echo "Error: Podium CLI is not configured. Please run 'podium config' first."
        exit 1
    }
fi

# Navigate to GUI directory
GUI_DIR="/home/shawn/repos/cbc/podium-gui"

if [ ! -d "$GUI_DIR" ]; then
    zenity --error --text="Podium GUI source not found at $GUI_DIR" 2>/dev/null || {
        echo "Error: Podium GUI source not found at $GUI_DIR"
        exit 1
    }
fi

# Launch GUI
cd "$GUI_DIR"
npm run dev > /dev/null 2>&1 &

echo "Podium GUI launched successfully"
