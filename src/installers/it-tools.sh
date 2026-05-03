INSTALL_DISPLAY="IT Tools"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  it-tools:
    image: corentinth/it-tools:latest
    restart: unless-stopped
EOF
}
