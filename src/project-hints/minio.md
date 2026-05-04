# MinIO

**Image**: `quay.io/minio/minio:latest`
**Port**: 9001 (web console) → nginx; API on port 9000 (internal)
**Database**: None
**Credentials**: minioadmin / minioadmin123

## Key Notes
- Command: `server /data --console-address ":9001"` — both API (9000) and console (9001) start.
- nginx proxies port 80 → MinIO console (9001). API clients connect to port 9000 internally.
- S3-compatible API endpoint for applications: `http://minio:9000` (internal VPC, not proxied).
- The installer exists: run `podium install minio`.
