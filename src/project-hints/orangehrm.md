# OrangeHRM

**Image**: `orangehrm/orangehrm:5.9`
**Port**: 80 (Apache inside the container — no proxy needed)
**Database**: MariaDB (`podium-mariadb`), dedicated user `orangehrm` / `orangehrm`, database `orangehrm`
**Credentials**: Set during the web install wizard

## Key Notes
- **This image has no environment variables at all.** It is a plain `php:8.3-apache` with the OrangeHRM zip unpacked into the webroot and the stock PHP entrypoint — there is no `ORANGEHRM_DATABASE_*` anything, despite what various blog posts claim. Configuration happens only through the browser wizard.
- The wizard writes its config into `lib/confs/` **inside the webroot**, which is why the whole `/var/www/html` tree is a volume. That means app code and data share one volume, so upgrading means re-running the installer.
- Feed the wizard these values: host `podium-mariadb`, port `3306`, database `orangehrm`, user `orangehrm`, password `orangehrm`. Choose the "use an existing database" path — the pre-created schema and grants are already in place.
- The wizard asks you to create the admin account; there is no default login.
- The installer exists: run `podium install orangehrm`.
