INSTALL_DISPLAY="Excalidraw"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  excalidraw-app:
    image: excalidraw/excalidraw:latest
    restart: unless-stopped
EOF
}
