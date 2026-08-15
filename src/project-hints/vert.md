# VERT

Browser-side file converter — images, audio and documents are converted locally in WASM, nothing is uploaded.

**Image**: `ghcr.io/vert-sh/vert:sha-e1c83ba` (direct)
**Port**: 80 (direct — the image's nginx already listens on 80)
**Database**: None (fully client-side)
**Credentials**: none

## Key Notes
- VERT publishes **no semver tags at all** — only `latest`, `main` and `sha-*`. `sha-e1c83ba` is the immutable digest-equivalent of `latest` as of pinning; bump it by finding the `sha-*` tag whose manifest digest matches `latest`.
- **Video conversion does not work here.** It needs the separate `vertd` daemon, and its file-hashing step calls `crypto.subtle.digest`, which is undefined outside a browser secure context. Image, audio and document conversion are unaffected — VERT deliberately ships the *single-threaded* ffmpeg core, so it needs neither `SharedArrayBuffer` nor cross-origin isolation.
- The wasm-caching service worker won't register over plain HTTP (service workers are secure-context-only). It degrades gracefully — the ffmpeg core is just re-downloaded each session.
- First use fetches wasm cores from `cdn.jsdelivr.net`, so the browser needs internet access even though conversion itself is local.
- `PUB_HOSTNAME` and friends are **build args**, not runtime env — setting them on the prebuilt image has no effect.
- The installer exists: run `podium install vert`.
