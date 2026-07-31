INSTALL_DISPLAY="IT Tools"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  it-tools:
    image: corentinth/it-tools:2024.10.22-7ca5933
    restart: unless-stopped
EOF
}
