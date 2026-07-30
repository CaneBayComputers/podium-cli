INSTALL_DISPLAY="LocalStack"
INSTALL_CREDENTIALS="no login — AWS API on http://$PROJECT_NAME/ (use test/test as access key/secret)"
INSTALL_NOTES="Local AWS emulator. Point the AWS CLI at it with: aws --endpoint-url=http://$PROJECT_NAME s3 ls. Needs the Docker socket so it can start Lambda containers."

write_files() {
    cat > docker-compose.yaml << 'COMPOSE'
services:
  app:
    image: localstack/localstack:4.0
    restart: unless-stopped
    environment:
      - DEBUG=0
      - PERSISTENCE=1
      - DOCKER_HOST=unix:///var/run/docker.sock
      - GATEWAY_LISTEN=0.0.0.0:80
    volumes:
      - localstack-data:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  localstack-data:
COMPOSE
}
