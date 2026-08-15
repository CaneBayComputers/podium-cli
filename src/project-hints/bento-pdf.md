# BentoPDF

Privacy-first, fully client-side PDF toolkit — merge, split, compress, convert, sign and encrypt PDFs entirely in the browser.

**Image**: `ghcr.io/alam00000/bentopdf-simple:v2.8.7` (+ `nginx:1.29-alpine` proxy)
**Port**: 8080 inside the app container (via nginx proxy on 80)
**Database**: none — no server-side state at all
**Credentials**: none, open the site and go

## Key Notes
- Two different images exist: `bentopdf-simple` is the AGPL self-hosted build (use this one), `ghcr.io/alam00000/bentopdf:*` is the commercial build. Their version numbers are *not* in sync — `bentopdf-simple` is on 2.x while the commercial image is on 1.x.
- The image is a static web server on **port 8080**, not 80, so an `nginx` proxy is required to be the entry point.
- AGPL-licensed WASM modules (PyMuPDF, Ghostscript, CoherentPDF) are pulled from the jsDelivr CDN at runtime, so a handful of tools need outbound internet. Everything else works offline.
- No volumes needed — the container is stateless.
- The installer exists: run `podium install bento-pdf`.
