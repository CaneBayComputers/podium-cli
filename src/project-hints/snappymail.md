# Snappymail

**Image**: `djmaze/snappymail:latest`
**Port**: 8888 (nginx reverse proxy)
**Database**: None (file-based)
**Credentials**: Set admin password on first visit at http://snappymail/?admin

## Key Notes
- Set `SNAPPYMAIL_INCLUDE_ADMINPANEL=True` to expose the admin panel at `/?admin`.
- No database needed — config and state stored in the `snappymail-data` volume.
- Webmail client only — requires external IMAP/SMTP servers configured in the admin panel.
- The installer exists: run `podium install snappymail`.
