INSTALL_DISPLAY="Excalidraw"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  excalidraw-app:
    image: excalidraw/excalidraw:sha-4bfc5bb
    restart: unless-stopped
EOF
}
