# MediaWiki

The wiki engine Wikipedia runs on.

**Image**: `mediawiki:1.46.0`
**Port**: 80 (Apache, served directly)
**Database**: MariaDB `mediawiki` on podium-mariadb
**Credentials**: admin / mediawiki123

## Key Notes
- MediaWiki's *web* installer cannot finish under Docker: `/var/www/html` is root-owned in the official image, so the wizard makes you download `LocalSettings.php` and place it by hand. This installer sidesteps that with a one-shot `mediawiki-install` service that runs the CLI installer, writes `LocalSettings.php` into the shared `mediawiki-config` volume, and exits. The web container finds it via `MW_CONFIG_FILE=/conf/LocalSettings.php`.
- That init service is guarded by `test -f`, so later `podium up` runs skip it. To re-run setup from scratch, delete the `mediawiki-config` volume and the `mediawiki` database.
- `/` returns a 301 to `/index.php/Main_Page` — that is the normal, healthy response, not a misconfiguration.
- Uploads live in the `mediawiki-images` volume; wiki text lives in MariaDB.
- To add extensions or tweak settings, edit the file inside the volume:
  `podium exec mediawiki vi /conf/LocalSettings.php`
- The installer exists: run `podium install mediawiki`.
