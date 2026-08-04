---
title: Cheap and local models
layout: default
nav_order: 8
---

# Cheap and local models

Podium doesn't sell you AI. It runs whichever agent you point it at, against
whichever model you want — including free ones running on your own machine.

The default agents bill at frontier-model prices. For a lot of Podium work —
scaffolding, wiring config, routine edits — a much cheaper model is fine, and the
difference is large:

| Model | Input / Output per 1M tokens |
|---|---|
| Claude Sonnet | ~$3 / ~$15 |
| Qwen3 Coder Next (OpenRouter) | **~$0.11 / ~$0.80** |
| Anything via local Ollama | **free** |

Podium already saves tokens before the model is involved: the environment,
networking, database and container plumbing are pre-built, so the agent spends
its context on your app instead of deriving Docker setup. Switching models
compounds that saving rather than replacing it.

---

## How it works

```bash
podium ai-set --agent <agent> --model <model> --api-base <url> --api-key <key>
```

`--api-base` is the important one. Podium hands it to the agent through whichever
environment variable that CLI reads:

| Agent | Variable | Endpoint it expects |
|---|---|---|
| `codex` | `OPENAI_BASE_URL` | OpenAI-compatible |
| `qwen` | `OPENAI_BASE_URL` | OpenAI-compatible |
| `aider` | `--openai-api-base` | OpenAI-compatible |
| `claude` | `ANTHROPIC_BASE_URL` | **Anthropic-compatible** |
| `gemini` | — | Google account auth only |

"OpenAI-compatible" covers OpenRouter, DeepInfra, Together, Fireworks, Ollama,
LM Studio and vLLM — nearly everything.

---

## OpenRouter (cheapest hosted)

```bash
podium ai-set --agent qwen \
  --model qwen/qwen3-coder-next \
  --api-base https://openrouter.ai/api/v1 \
  --api-key sk-or-v1-...
```

Pay-as-you-go, no subscription. Swap `--agent qwen` for `--agent codex` if you
prefer Codex's interface — both read the same variable.

## Ollama (free, local, private)

Install [Ollama](https://ollama.com), pull a coding model, point Podium at it:

```bash
ollama pull qwen2.5-coder:32b

podium ai-set --agent qwen \
  --model qwen2.5-coder:32b \
  --api-base http://localhost:11434/v1 \
  --api-key ollama
```

The key is a placeholder — Ollama ignores it, but the CLIs expect something.

Nothing leaves your machine, which matters for client work under NDA.

**Model size matters more than you would like**, and this is measured rather
than assumed. Tested here against `qwen2.5-coder:1.5b`, `podium create
--classify-only` returned *valid, correctly shaped JSON* — the plumbing is fine —
but recommended a **budgeting app for a guitar pedal tracker**, with the reason
"Laravel is great for building budgeting apps". Coherent output, incoherent
thinking.

So small models fail in the worst way: they succeed mechanically and are wrong
on the substance. 32B quantised on 24GB of VRAM is roughly the floor for agentic
work; below that, expect plausible nonsense rather than errors.

Qwen Code also requires **Node 22 or newer**. It installs and runs on Node 20 —
npm warns `EBADENGINE` and it works anyway — but that is unsupported.

## LM Studio or vLLM

Both expose an OpenAI-compatible server, so the shape is identical:

```bash
podium ai-set --agent codex --model <model> \
  --api-base http://localhost:1234/v1 --api-key local
```

## Claude Code against a local model

Claude Code speaks Anthropic's API shape, not OpenAI's, so it cannot talk to
Ollama directly. Put a translating proxy such as
[LiteLLM](https://github.com/BerriAI/litellm) in front:

```bash
podium ai-set --agent claude --api-base http://localhost:4000
```

Worth it only if you specifically want Claude Code's interface over a local
model. Otherwise `qwen` or `codex` is less machinery.

---

## Going back

```bash
podium ai-set --agent claude --api-base none --api-key ""
```

`none` clears the endpoint; an empty `--api-key` clears a stored key. Check where
you stand with `podium ai-set --json-output`.

---

## Choosing honestly

Cheaper models are genuinely worse at long autonomous work. The realistic split:

- **Routine edits, scaffolding, config, boilerplate** — a cheap or local model is
  fine and the savings are real.
- **`podium create` building a whole app from a sentence, or debugging something
  subtle** — frontier models still earn their price.

Nothing stops you switching per task. `podium ai-set` takes a second and the
setting is global rather than per-project.
