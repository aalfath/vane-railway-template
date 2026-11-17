[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/vane-perplexica?utm_medium=integration&utm_source=button&utm_campaign=vane)

# Vane (formerly Perplexica) on Railway

One-click Railway template for [Vane](https://github.com/ItzCrazyKns/Vane) (the project was called Perplexica until 2026), an open-source, self-hosted AI answering engine: it searches the web through its bundled SearXNG, reads the pages and answers with cited sources, using the LLM provider you choose (OpenAI, Anthropic, Gemini, Groq, Ollama, LM Studio, any OpenAI-compatible API).

## What this template deploys

| | |
|---|---|
| App | Vane **v1.12.2**, official image `itzcrazykns1337/vane:v1.12.2@sha256:61f2bbf3386ff3df08911fb3de0e1893b04702a4d49ef13fbadbda937b47ab7c` (includes SearXNG and headless Chromium) |
| Login | Caddy **2.11.9** (`caddy:2.11.9@sha256:4851e54a…`) in front of Vane with HTTP basic auth. Vane itself has no accounts, and its `/api/config` returns the provider API keys you save, so the template never exposes it without a login |
| Storage | One volume at `/home/vane/data`: settings and provider keys (`config.json`), chat history (`db.sqlite`) and uploaded files |
| Health check | `GET /healthz` (no login), 200 once Vane is serving |

SearXNG and Vane listen on `127.0.0.1` only; Caddy on `$PORT` (8080) is the only public listener.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `VANE_USERNAME` | `admin` | Login user name |
| `VANE_PASSWORD` | `${{secret(24)}}` | Login password, generated per deploy. Read it in the service's **Variables** tab. Minimum 12 characters; the container refuses to start without it |
| `PORT` | `8080` | Port Caddy listens on (not 3000 or 8888, which are used inside the container) |

LLM provider keys are not template variables: add them in Vane's setup screen after the first login (they are stored on the volume). You can still set `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `GROQ_API_KEY`, `OLLAMA_BASE_URL` and the like as service variables; Vane adds them as providers on start.

## After deploying

1. Open the service's public URL and log in with `admin` and the `VANE_PASSWORD` value.
2. In the setup screen, add at least one chat model provider and pick a chat and an embedding model.
3. Ask a question.

## Updates

This template builds from this repository. When a new Vane release is out, we bump the pinned version and digest in the `Dockerfile` and add a `CHANGELOG.md` entry; Railway then shows an "update available" notice on your project, and you choose when to apply it. Your volume is kept across updates. Read `CHANGELOG.md` first: breaking changes are listed at the top of each entry.

## Files

- `Dockerfile`: the pinned Vane image plus the Caddy binary and the start script.
- `Caddyfile`: login in front of Vane, unauthenticated `/healthz`.
- `start.sh`: starts SearXNG, Vane and Caddy, and exits if any of them stops so Railway restarts the container.

Vane is MIT licensed. This wrapper is not affiliated with the Vane project.
