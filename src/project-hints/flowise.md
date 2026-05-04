# Flowise

**Image**: `flowiseai/flowise:latest`
**Port**: 3000 (nginx reverse proxy)
**Database**: None (SQLite internal)
**Credentials**: admin / flowise123

## Key Notes
- No external database needed — SQLite stored in the `flowise-data` volume.
- `FLOWISE_USERNAME` and `FLOWISE_PASSWORD` enable basic auth.
- nginx must include WebSocket upgrade headers for real-time chatbot interactions.
- First startup takes ~15 seconds.
- The installer exists: run `podium install flowise`.
