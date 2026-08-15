# Easy!Appointments

**Image**: `alextselegidis/easyappointments:1.6.0`
**Port**: 80 (Apache — served directly, no proxy)
**Database**: MariaDB (`podium-mariadb`, database `easyappointments`, user `root`, empty password)
**Credentials**: Created by you in the installation wizard on first visit

## Key Notes
- The image already serves HTTP on port 80, so the service is named `app` and no nginx proxy is used.
- Env vars are `DB_HOST` / `DB_NAME` / `DB_USERNAME` / `DB_PASSWORD` (not `MYSQL_*`), plus `BASE_URL`.
- `BASE_URL` must be `http://easyappointments` — a wrong base URL produces broken links and failed AJAX calls.
- The empty root password is passed as `DB_PASSWORD: ""`; the database itself must pre-exist (the installer creates it).
- First request redirects to `/index.php/installation`; that wizard creates the schema and the admin account.
- No volume is mounted — all state lives in MariaDB.
- The installer exists: run `podium install easyappointments`.
