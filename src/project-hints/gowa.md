# GOWA (Go WhatsApp Web Multidevice)

**Image**: `aldinokemal2104/go-whatsapp-web-multidevice:v9.0.0`
**Port**: 3000 (via nginx proxy)
**Database**: SQLite in the `gowa-storages` volume (`DB_URI=file:storages/whatsapp.db`)
**Credentials**: admin / admin123 (HTTP basic auth, set by `APP_BASIC_AUTH`)

## Key Notes
- The binary needs a subcommand: `command: ["rest", "--port=3000"]`. Without `rest` the container starts in another mode and nothing serves HTTP.
- It runs as a non-root user, so it cannot bind port 80 itself — nginx proxies to it.
- `APP_BASIC_AUTH=user:pass` protects both the UI and the REST API; nginx passes the `Authorization` header through unchanged.
- Link a phone by scanning the QR at `/app/login`; the WhatsApp session persists in `/app/storages`, so don't delete that volume unless you want to re-pair.
- WebSocket upgrade headers are required — live QR and message events use a socket.
- The installer exists: run `podium install gowa`.
