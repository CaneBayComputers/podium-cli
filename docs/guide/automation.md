---
title: Automation & JSON
layout: default
nav_order: 9
---

# Automation, JSON and troubleshooting

---

## No interactive prompts

Every command except `podium configure` fails with a clear "required argument" error rather than prompting. Nothing ever blocks a script or an agent waiting for input.

Use `podium up-all` / `podium down-all` to act on every project rather than looping.

---

## JSON output

`--json-output` produces clean machine-readable output for GUIs and scripts.

```bash
podium status --json-output
podium new laravel myapp --version 11.x --json-output
```

```json
{
  "action": "new_project",
  "project_name": "myapp",
  "framework": "laravel",
  "database": "mysql",
  "status": "success"
}
```

Scripting examples:

```bash
# wait for the database to be up
if podium status --json-output | jq -r '.shared_services.mariadb.status' | grep -q RUNNING; then
    echo "Database is ready"
fi

# start every project, including stopped ones
for project in $(podium status --all --json-output | jq -r '.projects[].name'); do
    podium up "$project" --json-output
done
```

### Which commands support it

**Supported:** `status`, `new`, `clone`, `setup`, `remove`, `up`, `down`, `start-services`, `stop-services`, `configure`, `uninstall`.

**Not supported** — anything that runs inside a container or connects straight to a service: `composer`, `art`, `wp`, `php`, `npm`, `npx`, `node`, `python`, `pip`, `shell`, `django`, `exec`, `supervisor`, `redis`, `memcache`.

{: .warning }
**If you are an AI agent, never use `--json-output`.** It suppresses all human-readable output including the success/failure distinction, so you cannot tell whether a command actually worked. It exists for external programs that parse Podium's output, not for agents driving the CLI.

---

## Debugging

```bash
podium new laravel test-project --debug
tail -f /tmp/podium-cli-debug.log
```

`--debug` works on every command. Each invocation starts a fresh session and logs script flow, function calls and exit codes across scripts.

---

## Troubleshooting

| Symptom | Check |
|---|---|
| Services won't start | Docker is running; you're in the `docker` group (log out and back in after install) |
| Permission errors | Same — `docker` group membership needs a fresh login |
| Can't reach `http://project/` | `podium status <project>`; then `docker logs <project-name>` |
| Database connection refused | `podium status` — is the shared service running? |
| Project 502s after a restart | A dependency isn't in the base image. See [Architecture → Base images]({{ site.baseurl }}/guide/architecture/#base-images) |
| Fedora: permission denied on project files | SELinux — re-run `podium configure` to relabel. See [Installation]({{ site.baseurl }}/guide/installation/#fedora--rhel--selinux) |
| Arch: Docker won't start after install | The system upgrade replaced the running kernel — reboot |

Useful probes:

```bash
podium status                       # everything
podium status <project> --all       # include stopped projects
docker logs <project-name>
podium exec "ping podium-mariadb"   # networking from inside the container
```

---

## Graphics tooling

The installers ship ImageMagick (`convert`, `magick`) and `rsvg-convert` on the host, so projects needing graphics have no extra dependencies.

Prefer generating **SVG** — browsers render it perfectly and it's text an agent can write directly. Convert only when a raster is genuinely required:

```bash
rsvg-convert sprite.svg -o sprite.png                        # best SVG → PNG fidelity
convert -size 1200x800 gradient:'#1e3a8a-#04081d' bg.png     # procedural backgrounds
```

These are host tools — run them directly, not through `podium exec`.
