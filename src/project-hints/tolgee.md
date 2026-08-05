# Tolgee

Open-source localization platform with in-context translating and an SDK for web apps.

**Image**: `tolgee/tolgee:v3.216.4` (behind `nginx:alpine`)
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `tolgee`, user=root, password=password)
**Credentials**: admin / admin123

## Key Notes
- Tolgee **starts its own PostgreSQL inside the container by default**. `TOLGEE_POSTGRES_AUTOSTART_ENABLED: "false"` is required, otherwise the `SPRING_DATASOURCE_*` settings are ignored and your data lands in a throwaway embedded DB.
- Env-var names use underscores where the YAML config uses dashes: `tolgee.postgres-autostart.enabled` becomes `TOLGEE_POSTGRES_AUTOSTART_ENABLED`.
- Without `TOLGEE_AUTHENTICATION_INITIAL_PASSWORD`, Tolgee generates a random admin password and writes it to `/data/initial.pwd` — retrievable with `docker exec tolgee cat /data/initial.pwd`.
- It's a Spring Boot app: first boot takes 30–60s of JVM startup plus Liquibase migrations before the port answers.
- The installer exists: run `podium install tolgee`.
