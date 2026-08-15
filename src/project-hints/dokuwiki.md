# DokuWiki

Flat-file wiki — no database at all, pages are plain text on disk.

**Image**: `lscr.io/linuxserver/dokuwiki:version-2026-07-14a`
**Port**: 80 (served directly, no proxy)
**Database**: None (flat files in the `dokuwiki-config` volume)
**Credentials**: Create the admin at `http://dokuwiki/install.php`

## Key Notes
- The service is named `app` and listens on 80 already, so there is no nginx sidecar.
- Setup is a one-time visit to `/install.php`. Once you have an admin, delete it:
  `podium exec dokuwiki rm /app/dokuwiki/install.php`
- LinuxServer images are tagged by upstream release date (`version-YYYY-MM-DDx`), not semver.
- `PUID`/`PGID` decide who owns the files in `/config`; 1000 matches the usual first Linux user.
- The installer exists: run `podium install dokuwiki`.
