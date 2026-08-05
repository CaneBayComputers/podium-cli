# MindsDB

Federated AI query engine — connect data sources and LLMs, then query them together in SQL from a browser editor.

**Image**: `mindsdb/mindsdb:v26.1.0` + `nginx:1.30.4-alpine`
**Port**: 47334, the HTTP API and SQL editor (behind the nginx reverse proxy on 80)
**Database**: None externally — internal metadata is SQLite in the `mindsdb-storage` volume
**Credentials**: None; the editor is unauthenticated

## Key Notes
- The image entrypoint hard-codes `--api=http,mysql`, so a MySQL-wire listener also comes up on **47335 inside the container**. It is never published — only the HTTP API on 47334 is proxied. `MINDSDB_APIS` cannot override the baked-in CLI flag.
- Storage must stay at `/root/mdb_storage`; models, handler state and the internal SQLite DB all live there.
- Expect a multi-GB pull and a slow first boot while integration handlers are imported — give it a few minutes before assuming it failed.
- `MINDSDB_DB_CON` can repoint internal metadata at `podium-postgres`, but the default SQLite is used here because a bad value bricks startup with no useful error.
- Note the upstream GitHub repo has pivoted to a different product; the `mindsdb/mindsdb` Docker images are still the MindsDB engine and are still published.
- The installer exists: run `podium install mindsdb`.
