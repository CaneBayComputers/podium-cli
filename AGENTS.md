# Repository Guidelines

## Project Structure & Module Organization
- `src/podium` is the Bash entrypoint; it wires subcommands and shared helpers from `src/scripts/`.
- Keep command logic inside `src/scripts/`, grouping related workflows beside their support files.
- Docker Compose templates and defaults live in `src/docker-stack/`; update `env.example` when you add variables.
- Installer wrappers (`install-ubuntu.sh`, `install-mac.sh`) are the only scripts that should touch host package managers; route runtime logs to `logs/` instead of the repo root.
- Runtime configuration is resolved from `/etc/podium-cli/.env`; ship repo defaults via examples rather than committed secrets.

## Build, Test, and Development Commands
- Run the CLI in place with `./src/podium <command>`; most development happens against `configure`, `up`, `down`, and `status`.
- Exercise automation outputs with `./src/podium --json-output status` or any subcommand that feeds the GUI.
- Use `./src/podium test-json-output [case]` for regression coverage and `./src/podium cleanup-test-environment` to tear down fixtures after ad hoc runs.
- When adjusting installers, test in a disposable VM by piping the relevant `install-*.sh` script; never run against your primary host.

## Coding Style & Naming Conventions
- Author scripts with `#!/bin/bash`, `set -e`, four-space indentation, and snake_case helpers (`init_projects_dir`).
- Prefer extending the shared utilities in `functions.sh` so color handling, JSON quiet mode, and logging stay consistent.
- New commands should follow the existing verb-first naming (`podium cleanup-test-environment`) and reuse the echo wrappers instead of raw `echo`.

## Testing Guidelines
- Add new coverage by extending `src/scripts/test_json_output.sh`; name scenarios after the command under test (`new_laravel_latest`).
- Keep Docker noise isolated by using the `podium_test_` prefixes and calling `cleanup-test-environment` within failure handlers.
- Capture debugging data with the `--debug` flag and attach the relevant portion of `/tmp/podium-cli-debug.log` to reviews when issues arise.

## Commit & Pull Request Guidelines
- Follow the existing log style: short, imperative subjects (`docs: refine JSON flags`) with detail in the body when context is needed.
- Reference related issues and list the Podium commands or installer scripts you touched; include `podium test-json-output` results in PR summaries.
- Screenshots are optional—prefer clipped command output or log excerpts to demonstrate behaviour changes.

## Configuration & Security Notes
- Document new environment variables in `src/docker-stack/env.example` and keep defaults non-sensitive.
- Any credentials belong in `/etc/podium-cli/.env` or developer-specific overrides, never in tracked files or example data.
