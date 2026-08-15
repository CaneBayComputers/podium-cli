# CyberChef

GCHQ's "cyber swiss army knife" — encoding, encryption, compression and data analysis in the browser.

**Image**: `mpepping/cyberchef:v11.2.0` (behind `nginx:alpine`)
**Port**: 8000 (via nginx proxy)
**Database**: None
**Credentials**: none

## Key Notes
- Entirely client-side; nothing is persisted, so there are no volumes.
- Unlike most crypto-flavoured web apps, CyberChef works fine over plain HTTP. Its only `crypto.subtle` usage is in the vendored GOST modules and it is feature-detected with a pure-JS fallback — nothing depends on a browser secure context.
- `client_max_body_size 200M` is set because CyberChef's "open file as input" posts through the proxy.
- The installer exists: run `podium install cyberchef`.
