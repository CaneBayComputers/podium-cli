# Dolibarr ERP/CRM

**Image**: `dolibarr/dolibarr:23.0.3`
**Port**: 80 (Apache inside the container — no proxy needed)
**Database**: MariaDB (`podium-mariadb`), dedicated user `dolibarr` / `dolibarr`
**Credentials**: admin / admin123

## Key Notes
- Dolibarr's auto-installer refuses an empty DB password, so the installer creates a dedicated `dolibarr` MariaDB user rather than using `root` with a blank password.
- `DOLI_INSTALL_AUTO=1` runs the install non-interactively; the very first boot takes ~60s while it builds the schema. A 502/blank page before that is expected.
- `DOLI_URL_ROOT` must match the browser URL (`http://dolibarr`) or generated links and the setup redirect break.
- `DOLI_PROD=1` hides the install wizard once setup finishes; the `install.lock` lives in the `dolibarr-documents` volume, so deleting that volume re-triggers the wizard.
- Volumes are `/var/www/documents` (uploads, config, lock) and `/var/www/html/custom` (add-on modules).
- The installer exists: run `podium install dolibarr`.
