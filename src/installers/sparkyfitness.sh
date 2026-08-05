INSTALL_DISPLAY="SparkyFitness"
INSTALL_CREDENTIALS="Register on first visit — register admin@example.com to get the admin panel"
INSTALL_NOTES="The backend bootstraps its own schema and a limited app DB role on first boot; give it a minute before the UI works."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE sparkyfitness;" 2>/dev/null || true
}

write_files() {
    local api_key auth_secret app_db_password
    api_key=$(openssl rand -hex 32)
    auth_secret=$(openssl rand -hex 32)
    app_db_password=$(openssl rand -hex 16)

    cat > docker-compose.yaml << EOF
services:
  sparkyfitness-server:
    image: codewithcj/sparkyfitness_server:v1.6.1
    restart: unless-stopped
    environment:
      SPARKY_FITNESS_LOG_LEVEL: ERROR
      NODE_ENV: production
      TZ: Etc/UTC
      SPARKY_FITNESS_DB_HOST: podium-postgres
      SPARKY_FITNESS_DB_PORT: "5432"
      SPARKY_FITNESS_DB_NAME: sparkyfitness
      SPARKY_FITNESS_DB_USER: root
      SPARKY_FITNESS_DB_PASSWORD: password
      SPARKY_FITNESS_APP_DB_USER: sparkyfitness_app
      SPARKY_FITNESS_APP_DB_PASSWORD: "$app_db_password"
      SPARKY_FITNESS_API_ENCRYPTION_KEY: "$api_key"
      BETTER_AUTH_SECRET: "$auth_secret"
      SPARKY_FITNESS_FRONTEND_URL: http://sparkyfitness
      SPARKY_FITNESS_ADMIN_EMAIL: admin@example.com
      SPARKY_FITNESS_DISABLE_SIGNUP: "false"
      SPARKY_FITNESS_FORCE_EMAIL_LOGIN: "true"
      ALLOW_PRIVATE_NETWORK_CORS: "true"
      PUID: "1000"
      GUID: "1000"
    volumes:
      - sparkyfitness-backup:/app/SparkyFitnessServer/backup
      - sparkyfitness-uploads:/app/SparkyFitnessServer/uploads

  web:
    image: codewithcj/sparkyfitness:v1.6.1
    restart: unless-stopped
    environment:
      SPARKY_FITNESS_FRONTEND_URL: http://sparkyfitness
      SPARKY_FITNESS_SERVER_HOST: sparkyfitness-server
      SPARKY_FITNESS_SERVER_PORT: "3010"
      PUID: "1000"
      GUID: "1000"
    depends_on:
      - sparkyfitness-server

volumes:
  sparkyfitness-backup:
  sparkyfitness-uploads:
EOF
}
