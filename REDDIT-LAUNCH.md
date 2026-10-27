# Reddit launch kit (English)

Post when you have: (1) LICENSE live, (2) optional `assets/demo.gif`, (3) real bench numbers in the README (done).

## Target subs

| Sub | Angle |
|-----|--------|
| **r/LocalLLaMA** | #1 — local inference crowd; lead with numbers |
| **r/ollama** | Direct users; 1-click + env flags |
| **r/PowerShell** | Clean Windows automation |
| **r/nvidia** / **r/pcmasterrace** | Free RTX unlock, no hardware buy |

Tip: post **r/LocalLLaMA** first. Wait for traction before cross-posting.

---

## Title (use as-is)

```
I made a 1-click script to fix Ollama's conservative defaults on Windows RTX GPUs (Flash Attention + Q8 KV Cache)
```

Alternate titles:

```
Ollama on Windows leaves Flash Attention + Q8 KV off by default — 1-click PowerShell fix for RTX 30/40/50 (+29% t/s on my RTX 5080)
```

```
Free VRAM + +29% gen speed for Ollama on Windows RTX (open-source 1-liner, real bench included)
```

---

## Body (r/LocalLLaMA / r/ollama) — ready to paste

```
Hey everyone,

Like many of you, I noticed Ollama runs in very conservative mode out-of-the-box on Windows (disabling Flash Attention and locking the KV cache in FP16 to avoid crashing legacy cards). On modern hardware like RTX 30, 40, and 50 series, this leaves performance on the table—especially with long contexts in Cursor/VS Code.

I built **Ollama-Turbo**: a 1-click, multi-language PowerShell script that detects your NVIDIA GPU, applies Flash Attention + optional Q8 KV caching, restarts the daemon cleanly, and includes a live Stock vs Turbo benchmark.

### Real numbers on my box (not a slide deck)

- GPU: NVIDIA GeForce RTX 5080 (~15.9 GB)
- CPU: Intel Core Ultra 9 285K
- RAM: 31 GB
- OS: Windows 11 Pro
- Model: qwen-64k:latest
- Context: 16384 tokens

| Config | t/s | vs Stock | KV VRAM |
|--------|-----:|--------:|--------:|
| Stock (Windows default) | 107.6 | — | 100% |
| Turbo Pure Speed (FA only) | 107.81 | +0.2% | 100% |
| **Turbo Context (FA + Q8)** | **139.28** | **+29.4%** | **−50%** |

On this machine the winner is **FA + Q8**: ~**+29%** generation throughput and **half** the context VRAM.

Methodology (built into the script): for each mode → 1 warm-up (discarded) + **3 timed runs**, reported value = **average t/s**. Fresh unique prompt each pass + `keep_alive=0` so prompt cache can’t fake the score.

### What it does
- Turbo Context (FA + Q8) / Turbo Pure Speed (FA) / Rollback
- Live bench + multi-model (7B/14B/32B) + JSON/CSV/Reddit card export
- Health check (Ollama + NVIDIA driver links) / VRAM presets / watchdog after reboot
- Quiet/CI mode, AMD/Intel clear “not supported” + docs links
- EN/FR/ES/DE + OS language auto-detect · menu [S] = star + coffee

### Install (Admin PowerShell, one line)

    irm https://masterm3u.github.io/turbo | iex

### Repo
https://github.com/Masterm3u/Ollama-Turbo-RTX

PolyForm Noncommercial (personal/non-commercial free). No telemetry. Pure PowerShell source (no .exe). VirusTotal **0/60 clean**: https://www.virustotal.com/gui/file/d51c5599308df8154d9d581f5bb419b16899043856ce4a620f61334f40c53783 — more trust notes: https://github.com/Masterm3u/Ollama-Turbo-RTX/blob/main/SECURITY.md

If you try it, please reply with GPU + model + your Stock/Speed/Context table — curious how this scales on 3090/4090/5090 etc.

If it helped: a GitHub star goes a long way, and optional coffee is at https://buymeacoffee.com/masterm3u
```


---

## Short body (r/PowerShell)

```
Built a 1-click PowerShell tool that sets Ollama Machine env vars on Windows RTX (Flash Attention + optional Q8 KV), self-elevates, restarts the daemon, and runs a comparative inference benchmark.

On my RTX 5080 / qwen-64k @ 16k ctx: Stock 107.6 t/s → FA+Q8 139.28 t/s (+29.4%) with ~50% less KV VRAM.

Install:

    irm https://masterm3u.github.io/turbo | iex

Repo: https://github.com/Masterm3u/Ollama-Turbo-RTX
```

---

## Short body (r/nvidia / r/pcmasterrace)

```
If you run local LLMs with Ollama on an RTX 30/40/50, Windows defaults often leave Flash Attention off and keep KV in FP16 “safe mode.”

I open-sourced a 1-click script + live bench. On my RTX 5080 (qwen-64k, 16k ctx):

Stock 107.6 t/s → Turbo Context (FA+Q8) 139.28 t/s (+29.4%) and ~50% less context VRAM.

    irm https://masterm3u.github.io/turbo | iex

https://github.com/Masterm3u/Ollama-Turbo-RTX
```

---

## Comment to pin under your own post

```
Quick FAQ:
- Needs Admin (Machine env vars)
- RTX 30/40/50 required for Turbo; AMD/Intel get a clear “not supported” + Ollama GPU docs links
- Menu [4] = live bench (warns if 15+ min on fat cards) · [M] = multi-model · exports JSON + Reddit card
- [6] health · [7] VRAM preset · [W] watchdog after reboot · [S] star/coffee
- CLI: -Action install-context|bench|health|smart -Quiet -Out report.json
- Full raw report: https://github.com/Masterm3u/Ollama-Turbo-RTX/blob/main/benchmarks/RTX5080_qwen-64k_2026-10-26.txt
- Docs: https://github.com/Masterm3u/Ollama-Turbo-RTX#interactive-menu
- Stars: https://github.com/Masterm3u/Ollama-Turbo-RTX · coffee: https://buymeacoffee.com/masterm3u
```

