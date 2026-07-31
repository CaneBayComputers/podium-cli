# CLI fixes arising from the GUI re-sync

Companion to `CLI_GUI_ISSUES.md`. That file is what the GUI session *reported*;
this file is what was *verified* and what the fix is.

**This file is append-only for prose.** Add new entries at the bottom under a
new dated batch heading. Do not rewrite an entry's analysis — amend it by
appending a `**Update <date>:**` line inside the entry, so the history of what
we believed and when stays readable.

**The `Status:` line is the exception** and must be kept current in place —
it is a field, not a record. When a fix lands, change it to `APPLIED` and cite
the commit, so nobody has to cross-reference the summary table to find out
whether an entry is still outstanding.

Status values: `VERIFIED` (reproduced, fix agreed, not yet applied) ·
`APPLIED` (in the tree) · `REJECTED` (report was wrong, or fix conflicts with
current architecture) · `DEFERRED`.

---

# Batch 1 — 2026-07-31

**Outcome: all six APPLIED, verified, and pushed to `beta` as `c192837`.**
A seventh issue (§7) was found while regression-testing this batch and is
deliberately left OPEN.

Source: `CLI_GUI_ISSUES.md` §1–4 plus its two minors. All six reproduced against
branch `beta`. **Nothing in this batch conflicts with current architecture** —
every one is a mismatch between what the CLI documents and what it parses, not
the GUI misreading Podium.

Fix order below is by blast radius, not by the order they were reported.

---

## 1. `stop-services` / `start-services` discard every argument

**Status: APPLIED** (`c192837`) — was the destructive one; fixed first.

`podium stop-services --help` **stops the services** instead of printing help.
It did this to a live machine during the audit, and again to the shared services
on this box.

Cause is the dispatcher, not the scripts. `src/podium`:

```bash
"start-services")
    "$SCRIPT_DIR/scripts/start_services.sh"          # no "${@:2}"
"stop-services")
    "$SCRIPT_DIR/scripts/stop_services.sh"           # no "${@:2}"
```

Both scripts already parse `--help`, `--json-output` and `--no-colors` correctly
(`stop_services.sh:37`, `start_services.sh:33`). They are simply never handed the
arguments, so every flag is silently dropped and the script runs its default
path.

**Fix:** append `"${@:2}"` to both arms, matching every neighbouring case.

**Scope check:** these are the *only* two arms in the dispatcher that drop
arguments. `uninstall` and `remove` — the other destructive commands — forward
correctly, so `uninstall --help` is safe.

---

## 2. `remove --force` is documented as "skip prompts" but deletes the database

**Status: APPLIED** (`c192837`) — was a data-loss shape; fixed second.

`podium help` says:

```
  --force                   - Skip confirmation prompts
```

`remove_project.sh:63`:

```bash
--force)
    # Legacy flag - now only affects database deletion since trash is default
    FORCE_DB_DELETE=true
```

The interactive confirmation it claims to skip **no longer exists**
(`remove_project.sh:150`: "No interactive confirmation. The database is
PRESERVED by default"). So the flag's documented purpose is gone and its only
surviving effect is destroying data. Any caller carrying `--force` forward from
the old skip-the-prompt contract silently inverts preserve-by-default — the GUI
was doing exactly this.

**Fix:** remove `--force` from `podium help`'s REMOVE PROJECT OPTIONS so
`--force-db-delete` is the only documented way to drop a database. Keep the
parser case for backward compatibility, but retitle its comment to say plainly
that it is a destructive alias.

**Precedence is already safe:** `--preserve-database` is evaluated before
`FORCE_DB_DELETE` (`remove_project.sh:248`), so passing both preserves. No change
needed there.

---

## 3. `podium new --framework <name>` is documented but not parsed

**Status: APPLIED** (`c192837`) — hard stop, and partly self-inflicted.

Two places advertise the flag; the parser has no case for it, so it hits the
`-*` catch-all and exits 1 having created nothing:

```
$ podium new --framework laravel my-app
Unknown option: --framework
```

**The important nuance — do NOT blanket-remove this flag.** `--framework` is
legitimate on two other commands and must stay there:

| Command | Parses `--framework`? | `podium help` line |
|---|---|---|
| `new` | **no** | 138 — **wrong, fix this one** |
| `clone` | yes | 148 — correct, leave alone |
| `setup` | yes | 157 — correct, leave alone |

**Fix:** align the docs to the parser rather than adding a flag alias. The
positional form `podium new <framework> <name>` is already the contract in
README, AGENTS.md, the docs site and the completion script; adding `--framework`
back would create two ways to do one thing in the one command that doesn't need
it.

1. Delete line 138 from `src/podium` (NEW PROJECT OPTIONS only).
2. Rewrite `new_project.sh` `usage()` — it still describes the pre-2026
   signature `<project_name> [organization] [version]`, and **all three of its
   examples use `--framework`**, so every example it prints is a command that
   fails.
3. That help block also omits `flask` from the framework list.

**Self-inflicted note:** the framework lists on lines 138/148/157 were edited
earlier this session to add `flask`, `kavera` and `octobercms`. Line 138 was
already wrong and that edit made a wrong doc more wrong. Worth remembering that
updating a help string is not evidence the flag it describes exists.

---

## 4. `podium install --help` is parsed as an app name

**Status: APPLIED** (`c192837`) — hard stop.

```
$ podium install --help
No installer found for: --help
```

`install.sh` has no `--help` case, so the flag falls through to the positional
that becomes `$APP`. It is the only subcommand where the option list cannot be
read from the command itself. `--list` works and is a reasonable fallback, but a
flag should never be treated as a slug.

**Fix:** add a `--help|-h` case to `install.sh`'s argument loop documenting
`<app> [name]`, `--image <ref>`, `--one-off` and `--list`.

---

## 5. `podium projects-dir --json-output` ignores the flag

**Status: APPLIED** (`c192837`) — minor.

Handled inline in the dispatcher (`src/podium:692`) with a bare `echo`; arguments
are never examined. Harmless in practice — the GUI reads the plain path — but it
means the "global" `--json-output` is not actually global.

**Fix:** either emit `{"projects_dir": "..."}` when the flag is present, or drop
the claim that `--json-output` is global from `podium help`. Prefer the former;
it is two lines and keeps the global contract honest.

---

## 6. `usage()` prints an absolute script path as the program name

**Status: APPLIED** (`c192837`) — cosmetic, affected every script.

```
Usage: /usr/local/share/podium-cli/src/scripts/new_project.sh <project_name> ...
```

Every `usage()` uses `$0`, which is the sourced script, not the command the user
typed. Copy-pasting any printed help gives an unrunnable command for anyone who
installed normally.

**Fix:** print `podium <command>` instead. Cheapest approach is for the
dispatcher to export something like `PODIUM_CMD="podium $1"` and have `usage()`
use `${PODIUM_CMD:-$0}`, so the scripts still work when invoked directly.

---

## Batch 1 status

| # | Issue | Severity | Status |
|---|---|---|---|
| 1 | `start`/`stop-services` drop args | destructive | **APPLIED** |
| 2 | `remove --force` deletes DB | data loss | **APPLIED** |
| 3 | `new --framework` documented, unparsed | hard stop | **APPLIED** |
| 4 | `install --help` treated as slug | hard stop | **APPLIED** |
| 5 | `projects-dir` ignores `--json-output` | minor | **APPLIED** |
| 6 | `usage()` prints `$0` | cosmetic | **APPLIED** |
| 7 | `--help` exit codes inconsistent | GUI-affecting | **APPLIED** (batch 3) |

**Update 2026-07-31:** all six applied and verified. Notes on what the fixing
turned up:

- **#2 grew.** `remove_project.sh`'s own `usage()` also still described the
  removed prompt ("User is prompted about database deletion") and an interactive
  picker that no longer exists. Both corrected alongside the help entry.
- **#5 was fixed wrong the first time.** The obvious implementation — test
  `"${@:2}"` for `--json-output` — silently never matched, because `src/podium`
  strips that flag from `"$@"` at line 29 and exports `JSON_OUTPUT=1` instead.
  Testing the variable is both correct and consistent with every other script.
- **#3 held to the narrow fix.** Only the NEW PROJECT OPTIONS entry was removed;
  the `clone` and `setup` entries stayed, and `podium --help` still shows exactly
  two `--framework NAME` lines. Confirmed by count, not by eye.
- **#6 needed a mechanism, not a string edit.** The dispatcher now exports
  `PODIUM_CMD="podium <subcommand>"` and 12 scripts print `${PODIUM_CMD:-$0}`,
  so they still work when invoked directly.

Verified after: `stop-services --help` exits 0 with **9 of 9 services still
running**, `install --help` exits 0, `projects-dir --json-output` emits JSON,
`new --help` prints `Usage: podium new <framework> <name>`, and every script
still parses.

---

## 7. `--help` exit codes are inconsistent

**Status: APPLIED** (`3bdcb9d`) — see the update at the end of this entry.

Found while regression-testing batch 1. `--help` exits differently depending on
which command you ask:

| Command | `--help` exit |
|---|---|
| `configure`, `install`, `start-services`, `stop-services` | 0 |
| `new`, `remove`, `clone`, `setup` | **1** |

The scripts in the second group route `--help` through `usage()`, which ends in
`error "usage" 1`. That is correct when `usage()` is reached because the
arguments were bad, and wrong when the user explicitly asked for help.

This matters for the GUI specifically: anything checking exit codes reads a
successful `--help` as a failure.

**Why it is not fixed here:** `usage()` serves both callers, so the fix is not a
one-line change — it needs either a parameter (`usage 0` from the `--help` case,
`usage 1` from the error paths) or a separate `show_help()`. Both are reasonable;
picking one is a call for whoever owns the CLI's conventions, not something to
decide inside a bug-fix pass.

**Pre-existing** — batch 1 did not introduce it. Note that `install --help`,
added in #4, deliberately exits 0 and so currently sits on the correct side of an
inconsistency it did not create.

**Update 2026-07-31 — resolved, see batch 3 below.** The owner's call was "do what
makes sense", so the decision was made on the evidence in the tree rather than
invented: **both conventions were already present**, and the newer one won.


**Cross-cutting observation:** five of six are the same class — a documented
option that the parser does not accept, or accepts with different meaning.
There is no test anywhere that asserts `podium help` agrees with the parsers.
A ~20-line check that extracts every `--flag` from the help text and greps for a
matching case in the corresponding script would have caught 1, 3, 4 and 5 before
they shipped. Worth considering as its own piece of work.

---

# Batch 2 — 2026-07-31

**Outcome: both APPLIED, verified end-to-end, and pushed to `beta` as `d322a02`.**

Source: `CLI_GUI_ISSUES.md` §5–6, appended by the GUI session *after* batch 1 was
drafted. Batch 1's scope line ("§1–4 plus its two minors") maps onto the two
minors at the bottom of that file, not onto these — they were not skipped, they
did not exist yet.

Both reproduced on `beta` before fixing. Both align with current architecture:
the neighbouring Redis arms already read `"$REDIS_CONTAINER_NAME"` from `.env`,
so these were the outliers, not a competing convention.

---

## 8. All `memcache*` commands target a container that does not exist

**Status: APPLIED** (`d322a02`) — and it was broken twice over.

`src/podium` hardcoded the container name at three call sites:

```bash
echo "$@" | docker container exec -i memcached nc localhost 11211
```

The container is `podium-memcached` (`MEMCACHED_CONTAINER_NAME` in
`/etc/podium-cli/.env`). Live repro: `No such container: memcached`.

**The reported fix was necessary but not sufficient.** Substituting
`"$MEMCACHED_CONTAINER_NAME"` fixes the name, and all three commands still fail
— **the memcached image ships no `nc`**, so they go from exit 1 ("wrong
container") to exit 127 ("right container, missing binary"). Identical
user-visible outcome. This was caught by running the command rather than
reading the diff; the container-name change alone *reads* as fixed.

Credit where due: the GUI session caught the same gap independently and
appended it as an update mid-fix, including a verified alternative.

**Fix:** a new `memcache-send` helper in `functions.sh`, next to the existing
`check-memcached`. It talks to the daemon over bash's `/dev/tcp` built-in from
inside the container — the image has `bash` even though it has no netcat, so
this adds no dependency. The protocol needs CRLF endings and a trailing `quit`,
otherwise the server holds the socket open and `cat` blocks forever. The helper
also fails early with a readable message when the service is down, instead of
leaking a Docker daemon error.

**Adjacent fix, not reported by the GUI:** `memcache set <key> <val>` now works.
Storage commands are two-line — a header declaring the byte count, then the
payload — so the single-line form the help text has always advertised could
never have worked against any implementation. Since this path was being
rewritten anyway, and batch 1's cross-cutting observation was precisely
"documented option the parser does not accept", leaving a knowingly false help
block in place would have been reintroducing the bug class by hand.

---

## 9. `podium redis` / `podium redis-flush` require a TTY

**Status: APPLIED** (`d322a02`).

```bash
docker container exec -it "$REDIS_CONTAINER_NAME" redis-cli "$@"
docker container exec -it "$REDIS_CONTAINER_NAME" redis-cli FLUSHALL
```

`-t` allocates a TTY unconditionally, so every non-terminal caller — the GUI,
CI, a script, an agent — gets `cannot attach stdin to a TTY-enabled container
because stdin is not a terminal`. `podium redis INFO` is a one-shot command and
never wanted a TTY in the first place.

**Fix:** as the GUI session proposed — gate on `[ $# -eq 0 ] && [ -t 0 ]`, so
only the argument-less REPL requests a TTY, and only when stdin genuinely is a
terminal. Everything else uses `-i`. `redis-flush` is never interactive and now
always uses `-i`.

The `[ -t 0 ]` half is an addition to the reported fix: without it, a bare
`podium redis` piped from a script would still have tried to allocate a TTY.

---

## Batch 2 status

| # | Issue | Severity | Status |
|---|---|---|---|
| 8 | `memcache*` wrong container **and** no `nc` in image | hard stop | **APPLIED** |
| 9 | `redis` / `redis-flush` force a TTY | hard stop | **APPLIED** |

**Verified after** — every command run end-to-end, not diff-read:

- `podium memcache-stats` → `STAT pid 1 …`, exit 0; and again with
  `< /dev/null` for the non-TTY case, exit 0.
- `podium memcache version` → `VERSION 1.6.39`.
- Round-trip: `memcache set greeting "hello from podium"` → `STORED`,
  `memcache get greeting` → `hello from podium`.
- `memcache-flush` → `OK`, and the following `get` correctly returns a miss.
- Bare `podium memcache` still prints its help block.
- `redis PING` → `PONG`, `SET`/`GET` round-trip, `redis-flush` → key gone,
  `redis INFO` → 237 lines, all from a non-terminal.
- All scripts in `src/` still parse; **9 of 9 shared services still running**
  (batch 1's destructive regression did not recur).

**Note on §7 (`--help` exit codes):** still **OPEN**. Unchanged by this batch —
it needs a convention decision, not a bug fix.

---

# Batch 3 — 2026-07-31

**Outcome: §7 resolved and APPLIED, pushed to `beta` as `3bdcb9d`.**

Not a GUI report — this is the convention decision §7 was waiting on, made after
the owner said "no preference, do what makes sense."

---

## 7 (resolved). `--help` exit codes are now 0 everywhere

**Status: APPLIED** (`3bdcb9d`).

### The decision, and why it wasn't a coin flip

§7 framed this as a choice between parameterising `usage()` and adding a separate
`show_help()`. That framing missed the useful fact: **the tree already contained
both conventions**, so this was a question of which existing one to standardise
on, not which new one to invent.

| Convention | Scripts | `usage()` |
|---|---|---|
| Caller owns the exit code | `ai`, `ai_set`, `create`, `create_installer`, `update_installer` | pure output |
| Exit baked into `usage()` | `clone`, `enable_service`, `new`, `remove`, `setup`, `status` | ends `error "usage" 1` |

The first group is the newer code, matches ordinary Unix behaviour, and puts the
exit code where a reader can see it instead of hiding it inside a function called
from six places with two different meanings. The six older scripts were moved to
it. No new mechanism was added.

### The part that was actually dangerous

Deleting `error "usage" 1` from a `usage()` **removes a control-flow exit**. Every
call site that relied on `usage()` never returning now falls through and keeps
going with arguments it has already rejected — and two of those call sites are
`podium new` and `podium remove`. This is a strictly larger change than the
one-line edit §7 anticipated.

All 17 `usage` invocations across `src/scripts` were enumerated and each given an
explicit exit: `--help` paths exit 0, error paths (unknown option, too many
arguments, missing service) exit 1. Verified mechanically rather than by eye —
a script asserted that every invocation is followed by an `exit`.

`enable_service`'s `[[ -z "$SERVICE" ]] && usage` became an `if` block while
gaining its exit. A `set -e` concern was raised against the old `&&` form and
then **tested and disproved** — `set -e` exempts a failing command inside an
`&&` list, so it had never aborted. The rewrite is readability only, not a fix,
and is recorded as such so nobody later "re-fixes" a bug that was not there.

### Adjacent tidy

Collapsed 8 doubled `${PODIUM_CMD:-${PODIUM_CMD:-$0}}` expansions in
`new_project.sh` and `install.sh` — batch 1's fix #6 applied its substitution to
text that already had it. Evaluates identically, so this was cosmetic.

### Verified

- `--help` exits **0** for all 14 commands — `configure`, `install`,
  `start-services`, `stop-services`, `new`, `remove`, `clone`, `setup`, `status`,
  `enable-service`, `disable-service`, `ai`, `ai-set`, `create` — each printing
  `Usage: podium <cmd> …` (fix #6 still holding).
- Error paths exit **1**: `new --bogus`, `new a b c d`, `remove --bogus`,
  `remove a b c`, `clone --bogus`, `setup --bogus`, `status --bogus`,
  `enable-service` (no arg), `enable-service nosuchsvc`.
- **No fall-through:** no project created, none removed, 9 of 9 shared services
  still running, `enable-service` still idempotent.
- Every script in `src/` parses.

### Worth noting for whoever picks this up next

Batch 1 closed with the observation that nothing asserts `podium help` agrees
with the parsers. Batch 3 is the same gap from the other side: nothing asserts
that `--help` *exits 0*. Both are cheap to check in one script, and between them
they would have caught issues 1, 3, 4, 5 and 7. Still unwritten.
