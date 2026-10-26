# Reddit launch kit (English)

Post when you have: (1) LICENSE live, (2) a real `assets/demo.gif`, (3) your own bench numbers pasted into the README.

## Target subs

| Sub | Angle |
|-----|--------|
| **r/LocalLLaMA** | #1 — local inference crowd; lead with numbers |
| **r/ollama** | Direct users; 1-click + env flags |
| **r/PowerShell** | Clean Windows automation |
| **r/nvidia** / **r/pcmasterrace** | Free RTX unlock, no hardware buy |

Tip: post r/LocalLLaMA first (highest signal). Wait for traction before cross-posting.

---

## Title (use as-is)

```
I made a 1-click script to fix Ollama's conservative defaults on Windows RTX GPUs (Flash Attention + Q8 KV Cache)
```

Alternate titles if the first is taken / too long:

```
Ollama on Windows leaves Flash Attention + Q8 KV off by default — 1-click PowerShell fix for RTX 30/40/50
```

```
Free VRAM + faster prompt ingest for Ollama on Windows RTX (open-source 1-liner)
```

---

## Body (r/LocalLLaMA / r/ollama)

```
Hey everyone,

Like many of you, I noticed Ollama runs in very conservative mode out-of-the-box on Windows (disabling Flash Attention and locking the KV cache in FP16 to avoid crashing legacy cards). On modern hardware like RTX 30, 40, and 50 series, this leaves massive performance on the table—especially prompt processing latency when loading large code files in Cursor/VS Code.

To solve this with zero friction, I built **Ollama-Turbo**: an open-source, multi-language PowerShell script that automatically detects your NVIDIA GPU, applies Flash Attention + Q8 KV caching, restarts the daemon cleanly, and includes a live inference benchmark.

### What it does
- **Turbo Context (FA + Q8)** — Flash Attention + `q8_0` KV → ~50% less context VRAM
- **Turbo Pure Speed (FA only)** — Flash Attention, FP16 KV → max decode quality/speed
- **Rollback** — one key to stock defaults
- **Live benchmark** — Stock vs Speed vs Context (t/s table in a second window)

### Install (Admin PowerShell, one line)

    irm https://masterm3u.github.io/turbo | iex

### Repo
https://github.com/Masterm3u/Ollama-Turbo-RTX

PolyForm Noncommercial (free for personal/non-commercial use). No telemetry. Happy to take feedback, especially real bench dumps from your cards (model + VRAM + Stock/Speed/Context t/s).

*(Optional: paste your own Stock | Speed | Context table here)*
```

---

## Short body (r/PowerShell)

```
Built a 1-click PowerShell tool (PolyForm Noncommercial) that sets Ollama Machine env vars on Windows RTX (Flash Attention + optional Q8 KV), self-elevates, restarts the daemon silently, and runs a comparative inference benchmark.

Install:

    irm https://masterm3u.github.io/turbo | iex

Repo: https://github.com/Masterm3u/Ollama-Turbo-RTX

i18n: EN/FR/ES/DE with OS language auto-detect + `-Lang` CLI.
```

---

## Short body (r/nvidia / r/pcmasterrace)

```
If you run local LLMs with Ollama on an RTX 30/40/50, Windows defaults often leave Flash Attention off and keep KV cache in FP16 “safe mode.” That’s free performance left on the table.

I open-sourced a 1-click script that enables FA + optional Q8 KV (~50% context VRAM), with rollback and a live tokens/s benchmark:

    irm https://masterm3u.github.io/turbo | iex

https://github.com/Masterm3u/Ollama-Turbo-RTX (PolyForm Noncommercial)
```

---

## Comment to pin under your own post

```
Quick FAQ:
- Needs Admin (Machine env vars)
- RTX 30/40/50 recommended; older GPUs can stay on stock/rollback
- Menu [4] = live bench — please reply with GPU + model + table if you try it
- Stars on the repo help others find it: https://github.com/Masterm3u/Ollama-Turbo-RTX
```
