# Graylog

**Image**: `graylog/graylog:6.0` + `opensearchproject/opensearch:2.4.0`
**Port**: 9000 (nginx reverse proxy)
**Database**: MongoDB (`podium-mongo`) + OpenSearch sidecar (required)
**Credentials**: admin / admin

## Key Notes
- Requires OpenSearch sidecar (`opensearchproject/opensearch:2.4.0`) with `DISABLE_SECURITY_PLUGIN=true` and `discovery.type=single-node`.
- `GRAYLOG_ROOT_PASSWORD_SHA2` is `echo -n admin | sha256sum` = `8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918`.
- `GRAYLOG_PASSWORD_SECRET` must be at least 16 chars.
- `GRAYLOG_MONGODB_URI=mongodb://root:password@podium-mongo:27017/graylog?authSource=admin`
- nginx nginx must set `X-Graylog-Server-URL` header to the external URL.
- OpenSearch needs ulimits: `memlock=-1/-1` and `nofile=65536/65536`.
- First startup takes ~90 seconds. The installer exists: run `podium install graylog`.
