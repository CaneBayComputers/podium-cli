# Roundcube

**Image**: `roundcube/roundcubemail:latest`
**Port**: 80 (direct — no nginx proxy needed)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Depends on the IMAP server — Roundcube is a webmail client, not an auth source

## Key Notes
- Single-service compose — assigns the VPC IP directly to `roundcube-app` (no nginx sidecar).
- Roundcube is a webmail client — it requires an external IMAP server to log in. In a Podium local env, MailHog provides SMTP but not IMAP, so login will require a real mail account.
- Create DB before start: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"`
- SMTP set to `ROUNDCUBEMAIL_SMTP_SERVER: podium-mailhog` and `ROUNDCUBEMAIL_SMTP_PORT: 1025` for outbound dev mail.
- `ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE: 25M` controls attachment size.
- Persist `roundcube-data` at `/var/roundcube`.
- The installer exists: run `podium install roundcube`.
