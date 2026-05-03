# Repository Guidelines

## Initial Context Acquisition

**Read the following files** in the given order to become acquainted with the project’s architecture, dependencies, and conventions:

1. `README.md` – Overall purpose, setup, and deployment notes.
2. `src/podium`  – Entry script showing commands and options.
3. `src/scripts/functions.sh` – Helper functions.
4. `src/docker-stack/docker-compose.services.yaml` – Docker list of shared services used by projects.
5. `src/scripts/configure.sh` – Sets up Podium and dev environment.

## Project Structure & Module Organization
- `src/podium` is the Bash entrypoint; it wires subcommands and shared helpers from `src/scripts/`.
- Keep command logic inside `src/scripts/`, grouping related workflows beside their support files.
- Docker Compose templates and defaults live in `src/docker-stack/`; update `env.example` when you add variables.
- Installer wrappers (`install-ubuntu.sh`, `install-mac.sh`) are the only scripts that should touch host package managers; route runtime logs to `logs/` instead of the repo root.
- Runtime configuration is resolved from `/etc/podium-cli/.env`; ship repo defaults via examples rather than committed secrets.

## Build, Test, and Development Commands
- Run the CLI just as `podium <command>`. Do not run CLI from `./src/podium`.
- Exercise automation outputs with `podium <command> --json-output` or any subcommand that feeds the GUI. Not all commands have this option so check help first.
- Use `podium test-json-output [case]` for regression coverage and `podium cleanup-test-environment` to tear down fixtures after ad hoc runs.
- Static analysis and linting commands run inside the project container and expect project-relative paths (from the project root, for example `app/Console/Commands/Foo.php`):
  - `podium phpcs <relative-path>` – Run PHPCS with the default ruleset.
  - `podium phpcbf <relative-path>` – Run PHPCBF with the default ruleset to auto-fix.
  - `podium phpmd <relative-path>` – Run PHPMD against a file using the default rules.
  - `podium php -l <relative-path>` – Run PHP lint against a file.

## Coding Style & Naming Conventions
- Author scripts with `#!/bin/bash`, `set -e`, four-space indentation, and snake_case helpers (`init_projects_dir`).
- Prefer extending the shared utilities in `functions.sh` so color handling, JSON quiet mode, and logging stay consistent.
- New commands should follow the existing verb-first naming (`podium cleanup-test-environment`) and reuse the echo wrappers instead of raw `echo`.

## AI / Automation Usage Notes
- For non-interactive runs (CI, agents, scripts), prefer the non-TTY container execution commands:
  - `podium exec <cmd>` / `podium exec-root <cmd>` – run inside the project container without allocating a TTY.
  - Avoid interactive REPL-style commands (`podium bash`, `podium tinker`, `podium exec-tty*`) in agents; keep those for human-operated terminals.
- `podium exec` accepts either separate arguments (`podium exec python3 manage.py migrate`) or a single quoted string (`podium exec "python3 manage.py migrate"`). Both forms work.
- Python containers provide `python3`, not `python`. Use `podium python <args>` or `podium exec python3 <args>`. Never `podium exec python ...`.
- For Django management commands use `podium django manage <args>` (e.g. `podium django manage startapp myapp`, `podium django manage migrate`). This is the preferred shorthand over `podium exec python3 manage.py <args>`.

## Testing Guidelines
- Add new coverage by extending `src/scripts/test_json_output.sh`; name scenarios after the command under test (`new_laravel_latest`).
- Keep Docker noise isolated by using the `podium_test_` prefixes and calling `cleanup-test-environment` within failure handlers.
- Capture debugging data with the `--debug` flag and attach the relevant portion of `/tmp/podium-cli-debug.log` to reviews when issues arise.

## Configuration & Security Notes
- Document new environment variables in `src/docker-stack/env.example` and keep defaults non-sensitive.
- Any credentials belong in `/etc/podium-cli/.env` or developer-specific overrides, never in tracked files or example data.
