# Strapi

## Empty directory requirement

`create-strapi-app` refuses to scaffold into a non-empty directory, and the Podium project directory always contains files (docker-compose.yaml, .env, etc.). Workaround:

1. Scaffold into a temp directory outside the project:
   ```
   podium exec npx create-strapi-app@latest /tmp/strapi-scaffold --no-run --skip-cloud
   ```
2. Copy the generated files into the project directory:
   ```
   podium exec bash -c "cp -r /tmp/strapi-scaffold/. /usr/share/nginx/html/"
   ```

## Port

The cbc node-nginx container proxies nginx port 80 → localhost:3000. Strapi defaults to port 1337. Set `PORT=3000` in the project `.env` (or export it before starting) so Strapi binds to the port nginx expects.

## Database

PostgreSQL is the recommended default for Strapi. Always pass `--database postgres` to `podium new` when creating a Strapi project.

## Admin panel

Strapi admin is at `http://<project-name>/admin`. First visit creates the admin account.
