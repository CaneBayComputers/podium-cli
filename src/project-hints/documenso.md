# Documenso

Open-source DocuSign alternative — upload a PDF, place fields, collect digital signatures.

**Image**: `ghcr.io/documenso/documenso:v2.16.0`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL `documenso` on podium-postgres
**Credentials**: Register on first visit

## Key Notes
- Documenso needs a PKCS#12 signing certificate at `NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH`. Without a readable one it still boots, but logs "Certificate not found or not readable" and cannot sign. The installer generates a throwaway self-signed `cert.p12` in the project directory and mounts it read-only. Signatures made with it are cryptographically valid but anchored to nothing — replace it before signing anything that matters. Check status at `/api/certificate-status`.
- Two non-obvious things about that file. It is exported with SHA1/3DES (`-certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1`) because OpenSSL 3's AES-256 default produces a bundle Documenso's node-forge reader cannot parse. And it is `chmod 644` because openssl writes it 0600 owned by your user while the container runs as uid 1001 — left at 0600 it mounts fine and still reads as "not found".
- Several environment variables are hard-required — the container exits immediately if any of `NEXTAUTH_SECRET`, `NEXT_PRIVATE_ENCRYPTION_KEY`, `NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY`, `NEXT_PUBLIC_WEBAPP_URL`, `NEXT_PRIVATE_DATABASE_URL`, `NEXT_PRIVATE_SMTP_TRANSPORT`, `NEXT_PRIVATE_SMTP_FROM_NAME` or `NEXT_PRIVATE_SMTP_FROM_ADDRESS` is missing.
- Uploads use `NEXT_PUBLIC_UPLOAD_TRANSPORT=database`, so no S3 bucket is needed.
- First boot runs Prisma migrations and is slow; `INSTALL_READY_RETRIES=60` covers it.
- The installer exists: run `podium install documenso`.
