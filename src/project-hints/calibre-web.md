# Calibre-Web

Web UI for browsing, reading and downloading books from an existing Calibre library.

**Image**: `linuxserver/calibre-web:0.6.26-ls393` + `nginx:1.30.4-alpine`
**Port**: 8083 (behind the nginx reverse proxy on 80)
**Database**: None — SQLite config in the `calibre-web-config` volume; the library index is Calibre's own `metadata.db`
**Credentials**: `admin` / `admin123`

## Key Notes
- Calibre-Web does **not** create a library. The first screen asks for the "Location of Calibre database"; enter `/books`, and a Calibre library (a `metadata.db`) must already be there. Copy an existing library into the `calibre-web-books` volume, or create one with Calibre on the desktop first.
- Until a valid `metadata.db` is found the app only serves the setup page — that is expected, not a failure.
- Ebook conversion and the "send to Kindle" feature need the optional `DOCKER_MODS=linuxserver/mods:universal-calibre` mod; it is not enabled here because it adds ~1 GB to the image.
- LinuxServer images pin as `<upstream>-ls<build>`; `0.6.26` is the current upstream release.
- The installer exists: run `podium install calibre-web`.
