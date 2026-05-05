# October CMS

Laravel-based content management system. The installer ships the official `octobercms/october` image, which is a bundled all-in-one (Apache + PHP-FPM + MariaDB).

**Image**: `octobercms/october` (digest pin — only `:latest` is published upstream)
**Port**: 80 direct (Apache inside the container)
**Database**: bundled MariaDB *inside the container*, not `podium-mariadb`
**Credentials**: `admin` / `password` for the backend at `http://octobercms/backend`

## Key Notes

- The official image is the only one upstream maintains. It refuses to use an external database — the entrypoint hard-copies its own `.env` over anything you mount and starts a MariaDB at `localhost:3306` inside the container. This is the one Podium installer that intentionally does not consolidate to `podium-mariadb`.
- October has no public registration and no first-run wizard. The installer's `podium-init.sh` wrapper waits for migrations to finish, then inserts an admin user via `Backend\Models\User`. If you delete the volumes (`octobercms-app`, `octobercms-mysql`) the wrapper re-creates the admin on next boot.
- Backend login is at `/backend` (the upstream default, set by the image's `.env`). The frontend demo theme is served at `/`.
- First boot takes ~60–90s while the image copies its source tree into the volume and runs migrations. `podium install`'s 75s wait may flag it as "still initializing" — re-curl after another 30s.
- The bundled MariaDB binds to `0.0.0.0:3306` inside the container's network namespace, so other Podium projects can reach it as `octobercms:3306` (root/root) if they ever need to read its data — but treat that as a debugging affordance, not an integration point.

The installer exists: run `podium install octobercms`.
