---
title: AI workflow
layout: default
nav_order: 6
---

# AI workflow

Podium's command surface is shaped around AI-driven development. The point is to give an agent a fixed environment to work inside, so it builds your app instead of inventing infrastructure.

---

## Choosing an agent

```bash
podium ai-set --agent claude --model claude-opus-4-7
podium ai-set --agent codex  --model gpt-4.1
podium ai-set --agent gemini
podium ai-set --json-output          # inspect current settings
```

| Flag | Description |
|---|---|
| `--agent <name>` | `codex`, `claude`, `gemini`, or a custom command |
| `--model <name>` | Model name (optional) |
| `--api-key <key>` | API key (optional; Gemini uses Google account auth) |

Settings live in `/etc/podium-cli/.env`. Always change them with `podium ai-set` rather than editing the file.

{: .warning }
Podium starts your agent in a high-trust mode (`--dangerously-skip-permissions`, `--yolo`, or equivalent). Only use `podium ai` in project directories you're comfortable letting an AI modify extensively.

---

## `podium create` — idea to running project

```bash
podium create "A timeclock for employees in Django"
podium create "Set up n8n and configure a webhook that posts to Slack"
podium create "https://github.com/monicahq/monica"
```

Podium wraps your idea in platform instructions and hands the whole thing to your agent. The agent:

1. Asks which framework or stack, if the idea is ambiguous
2. Runs `podium new` / `podium clone` / `podium install` to create the project
3. Reads the generated `.env` to learn the database, cache and mail configuration
4. Builds the app with framework-native conventions — migrations, models, routes, templates
5. Verifies the site actually responds before declaring success
6. Updates the project README with the URL and any credentials

If your idea names an app that has an installer, the agent runs `podium install` first to get it live, then layers your customizations on top.

### Input options

```bash
podium create "an idea"        # argument
podium create -f spec.md       # from a file
podium create < spec.md        # stdin
cat spec.md | podium create    # pipe
podium create --one-off "..."  # stop after creation, no hand-off
```

---

## The `AGENTS.md` hand-off

When a project is created by `create`, `new`, `clone` or `install`, Podium writes an **`AGENTS.md`** into the project directory, then `cd`s into it and hands your agent a prompt whose only job is to read that file.

`AGENTS.md` records what an agent needs to pick the project up cold:

- Local URL, container name, project directory
- The resolved database, read from the project's `.env`
- Command patterns that work inside the container
- Shared-service hostnames and credentials
- Rules (never `--json-output`, `python3` not `python`, verify with curl before declaring done)

Because this context lives on disk rather than in a chat session, it survives closing your terminal, rebooting, and switching between Claude, Codex and Gemini.

The file is regenerated on each hand-off, but only between its markers — **anything you write outside the generated block is preserved**.

---

## `podium ai` — a prompt in the current project

```bash
cd ~/podium-projects/my-app
podium ai "Add a health-check endpoint at /ping"
podium ai --interactive "Let's refactor the auth flow"
```

One-off is the default: the agent receives the prompt, does the work, and exits. Durable context lives in `AGENTS.md`, so each prompt stands alone.

| Flag | Description |
|---|---|
| `--interactive`, `-i` | Open a persistent session instead |
| `--one-off` | Accepted for compatibility (now the default) |

## `podium resume`

```bash
podium resume my-project
```

Picks up a project's last agent session.

---

## Notes for agents

If you *are* an agent working with Podium, read `/usr/local/share/podium-cli/AGENTS.md` — it's the condensed platform reference, kept deliberately short because every byte is paid for on each run.

The rules that matter most:

- **Never pass `--json-output`.** It suppresses all human-readable output including the success/failure distinction, so you can't tell whether a command worked. It exists only for external scripts and GUIs.
- **Always pass explicit arguments.** Nothing prompts; a missing required argument is a hard error with a usage hint.
- **Prefer `podium exec`** over the TTY variants (`podium bash`, `podium exec-tty*`) — those allocate a terminal and aren't automation-friendly.
- **`podium supervisor restart all`**, never `podium exec supervisorctl ...`.
- **`python3`, not `python`.** For Django, prefer `podium django manage <args>`.
