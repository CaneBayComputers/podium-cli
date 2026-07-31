# CLI issues found while re-syncing the GUI

Raised from `podium-gui` on 2026-07-31 against `podium-cli` branch `beta` at
`54bc46a` (working tree clean). Filed as a report only — nothing in this repo
was modified.

Scope: only cases where the CLI gives a **hard stop**, or where a command or
option that the CLI itself **documents as working** does not. Everything else
found during the audit was treated as "the CLI is right, the GUI is stale" and
fixed on the GUI side.

---

## 1. `podium new --framework <name>` is documented but rejected

**Severity: hard stop.** This is the one that matters most for the GUI.

Both of these advertise the flag:

- `podium help` → `NEW PROJECT OPTIONS:` → `--framework <name>  - Framework: laravel (default), kavera, ...`
- `podium new --help` → `--framework TYPE  Framework type: laravel, ... (required with --json-output)`

The second one goes further and calls it *required* when `--json-output` is
used. But `src/scripts/new_project.sh`'s argument loop has no `--framework`
case, so it falls through to the `-*` catch-all:

```
$ podium new --framework laravel my-app
Unknown option: --framework
Usage: /usr/local/share/podium-cli/src/scripts/new_project.sh <project_name> [organization] [version] [options]
...
```

Exit 1, nothing created.

The parser's actual contract is positional and in the opposite order to the
usage text it prints:

```bash
*)
    # Positional order: <framework> <name>
    if [ -z "$FRAMEWORK" ]; then
        FRAMEWORK="$1"
    elif [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
```

So `podium new laravel my-app` works, and both documented invocations do not.

**Related:** the `usage()` text in `new_project.sh` still describes the old
signature (`<project_name> [organization] [version]`) and its three examples all
use `--framework`, so every example it prints is a command that fails. The
"NEW PROJECT OPTIONS" block in `podium help` also omits `flask` from the
framework list that the parser accepts.

**Suggested fix:** either accept `--framework` as an alias alongside the
positional, or drop it from `podium help` and rewrite `usage()` + its examples
to match `<framework> <name>`. Either is fine for the GUI — it now uses the
positional form — but the docs and the parser currently disagree.

---

## 2. `podium install --help` is parsed as an app name

**Severity: hard stop.** Every other subcommand honours `--help`; `install` is
the only one where it is impossible to see the option list.

```
$ podium install --help
No installer found for: --help
Run 'podium install --list' to see available apps.
```

`podium help` documents `podium install <app> [name] [--image <ref>]`, so the
flag surface exists — there's just no way to read it from the command itself.
`--list` works and is a good fallback, but `--help` should not be treated as a
slug.

---

## 3. `start-services` / `stop-services` drop every argument

**Severity: hard stop for `--help`; documented option unreachable for
`--json-output`.**

The dispatcher invokes both scripts with no `"$@"`:

```bash
# src/podium:675
"start-services")
    "$SCRIPT_DIR/scripts/start_services.sh"
    ;;
# src/podium:686
"stop-services")
    "$SCRIPT_DIR/scripts/stop_services.sh"
    ;;
```

Two consequences:

- **`podium stop-services --help` stops the services** instead of printing
  help. This happened during the audit on a live machine — the flag is silently
  discarded and the script runs its normal path. Same shape for
  `start-services --help`, which starts them.
- **`--json-output` never reaches either script.** `podium help` lists
  `--json-output` as a global option, `podium help`'s own examples include
  `podium start-services --json-output`, and both scripts implement the flag in
  full (`start_services.sh:33`, `stop_services.sh:25`, with JSON emitters at
  `:87` and `:81`). None of it is reachable through the `podium` entrypoint.

Both parsers are already written and correct; they just need `"$@"` forwarded,
the way every neighbouring case in the dispatcher does it.

> Noted as fixed in conversation on 2026-07-31, but the tree at
> `54bc46a` (clean, branch `beta`) still shows the above. Re-verify before
> closing — the GUI currently avoids passing any flags to these two commands.

---

## 4. `remove --force` is documented as "skip prompts", actually deletes the DB

**Severity: destructive doc mismatch.**

`podium help` says:

```
REMOVE PROJECT OPTIONS:
  --force                   - Skip confirmation prompts
```

`src/scripts/remove_project.sh:63` says otherwise:

```bash
--force)
    # Legacy flag - now only affects database deletion since trash is default
    FORCE_DB_DELETE=true
    shift
    ;;
```

Since the interactive confirmation was removed (`remove_project.sh:151`, "No
interactive confirmation. The database is PRESERVED by default"), the flag's
documented purpose no longer exists and its only remaining effect is dropping
the database. Anything carrying `--force` forward from the old
skip-the-prompts contract — the GUI did — silently inverts the new
preserve-by-default behaviour.

Precedence is at least safe: `--preserve-database` is checked first
(`remove_project.sh:248`), so passing both preserves.

**Suggested fix:** drop `--force` from `podium help`, or from the parser
entirely, so `--force-db-delete` is the only way to destroy data.

---

## 5. All `memcache*` commands target a container that does not exist

**Severity: hard stop. These cannot work on any machine.**

Four call sites in `src/podium` hardcode the container name `memcached`, but the
container is named from `MEMCACHED_CONTAINER_NAME` in `/etc/podium-cli/.env`,
which defaults to `podium-memcached`:

```bash
# src/podium:562  (memcache)
echo "$@" | docker container exec -i memcached nc localhost 11211
# src/podium:566  (memcache-flush)
echo "flush_all" | docker container exec -i memcached nc localhost 11211
# src/podium:570  (memcache-stats)
echo "stats" | docker container exec -i memcached nc localhost 11211
```

Repro with services up:

```
$ podium memcache-stats
Error response from daemon: No such container: memcached
```

The neighbouring Redis cases do this correctly with
`"$REDIS_CONTAINER_NAME"` — the memcache ones just need the same treatment
with `$MEMCACHED_CONTAINER_NAME`.

---

## 6. `podium redis` / `podium redis-flush` require a TTY

**Severity: hard stop for any non-interactive caller (GUI, script, agent).**

```bash
# src/podium:543
docker container exec -it "$REDIS_CONTAINER_NAME" redis-cli "$@"
# src/podium:546
docker container exec -it "$REDIS_CONTAINER_NAME" redis-cli FLUSHALL
```

The `-t` makes these fail whenever stdin isn't a terminal:

```
$ podium redis INFO
cannot attach stdin to a TTY-enabled container because stdin is not a terminal
$ echo $?
1
```

`podium help` lists these under SERVICE MANAGEMENT as ordinary commands
(`podium redis <cmd>  - Run Redis CLI commands`) with no note that they are
interactive-only, and `AGENTS.md` separately advises preferring non-TTY
variants for automation — but for redis there isn't one.

**Suggested fix:** drop `-t` when there are arguments (a one-shot command like
`redis-cli INFO` needs no TTY) and keep `-it` only for the argument-less
interactive REPL case. `redis-flush` never needs a TTY at all.

Until then the GUI reads Redis/Memcached stats via `docker exec` directly,
using the container names from `/etc/podium-cli/.env`.

---

## Minor (no action needed for the GUI)

> **Status check — 2026-07-31, after `c192837`.** Re-tested all eight entries
> above from the GUI side. §1, §2, §3, §4 and both minors are fixed and verified
> working; `CLI_GUI_FIXES.md` records them as APPLIED.
>
> **§5 (memcache container name) and §6 (redis TTY) have no entry in
> `CLI_GUI_FIXES.md` at all** — not APPLIED, not OPEN, not REJECTED. They appear
> to have been missed rather than declined: batch 1 describes its source as
> "§1–4 plus its two minors", which maps its own #5/#6 onto the two minors below
> and skips these two entirely. They were appended after that batch was drafted.
>
> Both still reproduce on the current tree:
>
> ```
> $ podium memcache-stats
> Error response from daemon: No such container: memcached
> $ podium redis INFO
> cannot attach stdin to a TTY-enabled container because stdin is not a terminal
> ```
>
> `src/podium` is unchanged at the relevant lines — 545 and 548 still pass `-it`,
> and 564, 568, 572 still hardcode `memcached`. The GUI works around both (direct
> `docker exec` for Redis, a TCP socket for Memcached, container names read from
> `/etc/podium-cli/.env`) so nothing is blocked — but the CLI commands themselves
> remain broken for every caller.

> **Update — 2026-07-31, on the in-progress `src/podium` edit.** Caught this
> while the fix was still uncommitted, so it can be corrected before it lands.
>
> **The redis half is correct.** Gating the TTY on `[ $# -eq 0 ] && [ -t 0 ]` and
> using `-i` otherwise is exactly right — `podium redis INFO` works from a
> non-terminal, and the argument-less REPL keeps its TTY.
>
> **The memcache half is necessary but not sufficient.** Swapping the hardcoded
> `memcached` for `$MEMCACHED_CONTAINER_NAME` fixes the container name, but all
> three commands still fail — **the memcached image has no `nc`**:
>
> ```
> $ echo "stats" | docker container exec -i podium-memcached nc localhost 11211
> OCI runtime exec failed: exec: "nc": executable file not found in $PATH
> $ echo $?
> 127
> ```
>
> So `memcache`, `memcache-flush` and `memcache-stats` go from "wrong container"
> (exit 1) to "right container, missing binary" (exit 127). Same user-visible
> outcome: broken.
>
> The image does ship `bash`, so its `/dev/tcp` built-in works with no new
> dependency. Verified against the running container:
>
> ```bash
> docker container exec -i "$MEMCACHED_CONTAINER_NAME" bash -c \
>   'exec 3<>/dev/tcp/127.0.0.1/11211; printf "stats\r\nquit\r\n" >&3; cat <&3'
> # STAT pid 1
> # STAT uptime 1701
> # ... exit 0
> ```
>
> Note the memcached protocol wants CRLF line endings and a trailing `quit` so
> the socket closes instead of hanging on `cat`. Whatever shape you pick, please
> test `podium memcache-stats` end-to-end before marking §5 APPLIED — the
> container-name change alone reads as fixed in a diff but isn't.

> **New finding — 2026-07-31, from a clean install on a second machine.**
> Related to §3 but in files that fix did not touch.
>
> **Three of the four installers close by telling the user to run a command that
> now hard-errors.** After a successful install, `install-ubuntu.sh:407`,
> `install-mac.sh:403` and `install-arch.sh:345` all print:
>
> ```
>   3. Create your first project:
>        podium create "A task tracker with user login"
>      or use a specific framework:
>        podium new my-project --framework laravel      <-- removed flag, old arg order
> ```
>
> Reproduced end-to-end on a freshly wiped Linux Mint 22.3 box (Docker pruned,
> old CLI removed, current `beta` installed via `install-ubuntu.sh`, then
> `podium configure --non-interactive`):
>
> ```
> $ podium new my-project --framework laravel
> ...usage...
> $ echo $?
> 1
> ```
>
> This is the **first command a brand-new user is told to run**, and it fails on
> a correct install — which reads as "the install is broken" rather than "the
> docs are stale". `install-fedora.sh` does not carry the line.
>
> Same class as §3 (docs advertising a flag the parser rejects); worth a grep for
> `--framework` across the whole repo rather than per-file fixes. `README.md:79`
> is already correct (`podium new flask my-api`), so it is just the three
> installers.

- `podium projects-dir --json-output` ignores the flag and prints a bare path.
  The dispatcher handles `projects-dir` inline with `echo` and never looks at
  arguments. Harmless — the GUI reads the plain path — but it means the global
  `--json-output` isn't truly global.
- Every script's `usage()` prints its own absolute path as the program name
  (`Usage: /usr/local/share/podium-cli/src/scripts/new_project.sh ...`) rather
  than `podium new`. Cosmetic, but it makes copy-pasted help output unrunnable
  for anyone who installed via the normal path.
