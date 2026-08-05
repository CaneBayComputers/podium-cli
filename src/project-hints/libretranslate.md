# LibreTranslate

Self-hosted machine translation API and web UI, built on Argos Translate.

**Image**: `libretranslate/libretranslate:v1.9.6` (behind `nginx:alpine`)
**Port**: 5000 (via nginx proxy)
**Database**: None (models cached on a volume)
**Credentials**: none

## Key Notes
- The container runs as the non-root `libretranslate` user, so it cannot bind port 80 itself — the nginx proxy is not optional.
- `LT_LOAD_ONLY: "en,es,fr,de"` is set on purpose. Without it the first boot downloads **every** language model (multiple GB) before the service answers. Remove the var for the full set, or edit the list.
- Models land in `/home/libretranslate/.local`, which is on a named volume — otherwise every container restart re-downloads them.
- The container reports unhealthy/unreachable until the models finish downloading and loading; that is normal on first start.
- API test: `curl -X POST http://libretranslate/translate -H 'Content-Type: application/json' -d '{"q":"hello","source":"en","target":"es"}'`.
- The installer exists: run `podium install libretranslate`.
