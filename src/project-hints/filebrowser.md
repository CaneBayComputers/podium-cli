# File Browser

Web file manager over a directory, single Go binary.

**Image**: `filebrowser/filebrowser:v2.63.23`
**Port**: 80 (native — no proxy needed)
**Database**: none (embedded BoltDB at `/database/filebrowser.db`)
**Credentials**: `admin` / a random password printed in the container log on first boot

## Key Notes
- The image already defaults to `"port": 80` in `/defaults/settings.json`, so it is a direct entry-point service — no nginx sidecar.
- On first boot with an empty database it runs "quick setup" and logs: `User 'admin' initialized with randomly generated password: ...`. Read it with `podium logs` / `docker logs`.
- To set your own password: `docker exec -it <container> filebrowser users update admin --password newpass -d /database/filebrowser.db`. The `--password` *flag* at boot expects a bcrypt hash, not plaintext, so it is not usable from the compose env.
- Three separate volumes matter: `/config` (settings.json), `/database` (users/settings DB), `/srv` (the files being served). Losing `/database` resets all users.
- The installer exists: run `podium install filebrowser`.
