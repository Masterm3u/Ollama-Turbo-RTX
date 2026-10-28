# Ollama-Turbo-RTX — Boost Ollama on Windows RTX (+30% Speed, -50% VRAM in 1 Click)

[![License: PolyForm Noncommercial](https://img.shields.io/badge/License-PolyForm%20Noncommercial-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?logo=windows)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GPU: RTX 30/40/50](https://img.shields.io/badge/NVIDIA-RTX%2030%20%2F%2040%20%2F%2050-76B900?logo=nvidia)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GitHub stars](https://img.shields.io/github/stars/Masterm3u/Ollama-Turbo-RTX?style=social)](https://github.com/Masterm3u/Ollama-Turbo-RTX/stargazers)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/masterm3u)
[![Download MSI](https://img.shields.io/badge/Download-MSI%20Installer-0078D6?logo=windows&logoColor=white)](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX-Setup.msi)
[![GitHub release](https://img.shields.io/github/v/release/Masterm3u/Ollama-Turbo-RTX?include_prereleases)](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-re--scan%20after%20update-yellow?logo=virustotal&logoColor=white)](https://www.virustotal.com/gui/file/da7b1f773dead7237bcfb9ca193bd058a56e2cc6433e1da3842ae45221fc85a7)

> **1-click Ollama optimizer for Windows 10/11 + NVIDIA RTX 30 / 40 / 50** — turn on Flash Attention, set `OLLAMA_KV_CACHE_TYPE=q8_0`, free ~50% context VRAM, and compare Stock vs Turbo tokens/s in a live benchmark.

<!-- Drop assets/demo.gif then uncomment:
![Demo](assets/demo.gif)
-->

### 📥 Download (Windows GUI — MSI)

| | |
|--|--|
| **Installer (recommended)** | **[OllamaTurboRTX-Setup.msi](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX-Setup.msi)** |
| **Portable EXE** | [OllamaTurboRTX.exe](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX.exe) |
| **All releases** | [github.com/Masterm3u/Ollama-Turbo-RTX/releases](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases) |
| **Checksums** | `OllamaTurboRTX-Setup.msi.sha256` / `OllamaTurboRTX.exe.sha256` on the same release page |

Self-contained x64 MSI (GUI **v1.1** = **full PowerShell menu parity**: Context / Speed / Stock / Bench / Multi / Health / Smart / Workflow / Undo / VRAM / Watchdog / Support). Machine env vars → **UAC/Admin** like the `.ps1`. If SmartScreen says *éditeur inconnu*, click **Informations complémentaires** → **Exécuter quand même** (unsigned open-source build).

Prefer script / full toolkit? Use the [PowerShell one-liner](#-quick-install-admin-powershell) below.

### What Ollama-Turbo does for your local LLM

Out of the box, **Ollama on Windows** keeps **Flash Attention** off and locks the **KV cache** to **FP16** so old GPUs don’t crash. On an **NVIDIA RTX 3060, 3070, 3080, 3090, 4060, 4070, 4080, 4090, 5070, 5080, or 5090**, that “safe mode” costs you speed and memory: longer waits when a big prompt hits the model, more **VRAM** burned by context, and a sluggish feel in **Cursor**, **VS Code Continue**, Open WebUI, or any **local LLM** chat.

**Ollama-Turbo-RTX** flips those flags for you in one Admin PowerShell command — no manual registry edits, no guessing `OLLAMA_FLASH_ATTENTION` / `OLLAMA_KV_CACHE_TYPE`.

| Advantage | What you get |
|-----------|----------------|
| **Faster inference** | **Flash Attention** uses Tensor Cores so attention scales better on long prompts — better **tokens/s** and snappier replies |
| **Lower VRAM for context** | **Q8 KV cache** (`q8_0`) roughly **halves context memory** vs FP16, so you can keep larger models or longer chats loaded |
| **Longer context windows** | Same card, more room for big codebases, RAG chunks, and multi-turn history |
| **Measurable proof** | Built-in **Stock vs Turbo benchmark** (3-pass average) shows your real **tokens/s** gain — not marketing claims |
| **Zero friction** | Detects your GPU, applies Machine env vars, restarts Ollama cleanly, **rollback** in one key |
| **Safe to try** | Non-destructive; stock defaults restored anytime |

**Bottom line:** keep using Ollama as usual — Turbo just unlocks the RTX performance Windows leaves disabled, so local AI feels closer to what your GPU paid for.

---

### 🚀 Quick Install (Admin PowerShell)

```powershell
irm https://masterm3u.github.io/turbo | iex
```

Zero clone. Zero installer. Menu in color → optimize → optional live bench. Writes **Machine** env vars (Admin).

**Prefer to inspect first?** Download, open in Notepad / scan on VirusTotal, then run — see [Security & trust](#-security--trust).

### 🖥️ Optional GUI (no Admin / User env)

Lightweight WPF app (dark UI): Turbo Context · Pure Speed · Stock · Quick Bench (`4096` / `16384`). Writes **User** environment variables and restarts `ollama app.exe` with FA/KV injected — **no UAC**.

**Download ready-made installer:** [OllamaTurboRTX-Setup.msi](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX-Setup.msi) — see [Download section](#-download-windows-gui--msi).

```powershell
# Build from source (.NET 8 SDK + WiX CLI)
cd gui
.\publish.ps1 -SelfContained   # portable exe
.\build-msi.ps1 -Version 1.0.0 # → dist\OllamaTurboRTX-Setup.msi
```

Source: [`gui/OllamaTurboRTX/`](gui/OllamaTurboRTX/) · installer: [`gui/installer/`](gui/installer/) · docs: [`gui/README.md`](gui/README.md).

| | PowerShell script | WPF GUI |
|--|-------------------|--------|
| Scope | Machine (Admin) | User (no Admin) |
| Bench | Full Stock/FA/FA+Q8 | Quick local tokens/s |
| Best for | Full toolkit / automation | Double-click daily toggle |

---

### 🔒 Security & trust

**Primary tool:** open-source **PowerShell** — no packed binary, no obfuscation, no telemetry. You can read every line before it runs.

**Optional GUI:** open-source **WPF / .NET 8** under [`gui/`](gui/) — build the single-file `.exe` yourself (see below); do not trust random third-party binaries claiming to be this app.

| Check | How |
|-------|-----|
| **Source** | [`Ollama-Turbo-RTX.ps1`](Ollama-Turbo-RTX.ps1) — plain text |
| **Checksums** | [`checksums.sha256`](checksums.sha256) — verify with `Get-FileHash` |
| **VirusTotal** | Re-scan after this release — SHA256 [`da7b1f77…`](https://www.virustotal.com/gui/file/da7b1f773dead7237bcfb9ca193bd058a56e2cc6433e1da3842ae45221fc85a7) (matches [`checksums.sha256`](checksums.sha256)) |
| **Details** | Full policy: [`SECURITY.md`](SECURITY.md) |
| **Code signing** | Not required — trust = open source + checksums + VirusTotal. Optional later: [`SIGNING.md`](SIGNING.md) |

```powershell
# Verify integrity after download
Get-FileHash "$env:TEMP\Ollama-Turbo-RTX.ps1" -Algorithm SHA256
# Compare with: https://github.com/Masterm3u/Ollama-Turbo-RTX/blob/main/checksums.sha256
```

> Honesty note: nobody can prove “100% forever virus-free” for every future commit. Trust comes from **readable source + checksums + a clean VirusTotal report on the file you actually run**. After each update, re-check the hash and re-scan.

---

### 📊 Real benchmark (author hardware — not marketing)

Measured with the built-in live bench (**menu [4]**), same model & context for all three modes:

| | |
|--|--|
| **GPU** | NVIDIA GeForce RTX 5080 (~15.9 GB) |
| **CPU** | Intel Core Ultra 9 285K |
| **RAM** | 31 GB |
| **OS** | Windows 11 Pro 64-bit (build 10.0.26300) |
| **Model** | `qwen-64k:latest` |
| **Context** | 16384 tokens |
| **Date** | 2026-10-26 |

| Configuration | Generation (t/s) | Speed vs Stock | Context VRAM |
|---------------|-----------------:|---------------:|-------------:|
| **[Stock]** Windows default | 107.6 | — | 100% |
| **[2] Turbo Pure Speed (FA)** | 107.81 | **+0.2%** | 100% |
| **[1] Turbo Context (FA + Q8)** | **139.28** | **+29.4%** | **−50%** |

**Winner on this machine:** Turbo Context (FA + Q8) → **+29.4% tokens/s** and **half the KV VRAM**.

#### How the benchmark works

For **each** mode (Stock → Turbo Speed → Turbo Context):

1. Apply the env flags and restart Ollama cleanly  
2. **1 warm-up** pass (load weights / CUDA) — not counted  
3. **3 timed passes** (`num_predict=128`, same context size)  
4. Report **the average** of those 3 generation rates (t/s)  
5. Every pass uses a **fresh unique heavy prompt** + `keep_alive=0` (no prompt-cache inflation)

Raw report: [`benchmarks/RTX5080_qwen-64k_2026-10-26.txt`](benchmarks/RTX5080_qwen-64k_2026-10-26.txt)

> Results vary by GPU / model / drivers. Run **[4]** or **[M]** yourself and compare — that’s the point. On RTX 5080, a full bench often takes **8–15+ minutes** (multi-model **15–30+**); the script warns and shows an elapsed chrono.

---

### ✨ Features

- **Multilingual UI** EN / FR / ES / DE (OS auto-detect + menu **[5]** / `-Lang`)
- **Turbo Context (FA+Q8)** & **Turbo Pure Speed (FA)** + one-key **Rollback**
- **Live benchmark** Stock vs FA vs FA+Q8 (3-pass avg) + **multi-model** 7B/14B/32B
- **Exports**: Desktop TXT + **JSON** + CSV + **Reddit card** (clipboard + `*-reddit.txt`)
- **Health check**: Ollama version vs GitHub, NVIDIA driver vs Game Ready (browser link only), API, FA/KV
- **Smart VRAM presets** (8 / 12 / 16 / 24GB+ tiers) + Coding vs Fast Chat workflows
- **VRAM context estimate** FP16 vs Q8 tokens max for your card
- **Watchdog** after reboot (scheduled task re-applies Machine flags if lost)
- **Undo history** snapshots of FA/KV before changes
- **Quiet / Minimal theme** for CI (`-Quiet`, `-Theme Minimal`, menu **[T]**)
- **AMD / Intel**: clear **not supported** message + docs links (no silent NVIDIA-only abort)
- **Support links** in-menu (**[S]** → GitHub star + Buy Me a Coffee)

---

### 🎛️ Interactive menu

| Key | Action |
|-----|--------|
| **[1]** | Turbo Context — Flash Attention + KV `q8_0` (~50% context VRAM) |
| **[2]** | Turbo Pure Speed — Flash Attention only (KV FP16) |
| **[3]** | Rollback to stock Ollama env |
| **[4]** | Live benchmark (1 model) — Admin window; duration warning + chrono |
| **[5]** | Change language |
| **[6]** | System health check (Ollama / NVIDIA driver / API / FA·KV) |
| **[7]** | Smart GPU preset from VRAM table |
| **[8]** | Workflow: Coding/Cursor (FA+Q8) or Fast Chat (FA) |
| **[9]** | Undo / restore history snapshot |
| **[A]** | VRAM context estimate (FP16 vs Q8) |
| **[M]** | Multi-model benchmark (7B / 14B / 32B chain) |
| **[W]** | Watchdog after reboot (install / check / remove) + notify prefs |
| **[S]** | Open GitHub star and/or Buy Me a Coffee in the browser |
| **[T]** | Theme Full ↔ Minimal |
| **[Q]** | Quit |

#### VRAM preset tiers **[7]**

| Tier | Mode | `num_ctx` hint |
|------|------|----------------|
| ~8 GB | Context FA+Q8 | ~4096 |
| ~12 GB | Context FA+Q8 | ~8192 |
| ~16 GB (e.g. RTX 5080) | Context FA+Q8 | ~16384 |
| ~24 GB+ | Speed FA | ~32768 |

---

### ✅ Prerequisites

- Windows 10 / 11
- **NVIDIA RTX 30 / 40 / 50** (required for Turbo flags; RTX 20xx Turing minimum for Flash Attention). AMD / Intel: Ollama may still run — this tool explains non-support and links to [Ollama GPU docs](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- Auto GPU probe via `nvidia-smi` (PATH / `System32`) + WMI — warns if below RTX 2000
- [Ollama](https://ollama.com/download) installed
- Run as **Administrator** (Machine environment variables). Restart injects `OLLAMA_*` into `ollama app.exe` so flags apply **without** Windows logout

---

### 📦 Local run & CLI

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1 -Lang fr
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1 -Theme Minimal
```

#### Parameters

| Param | Description |
|-------|-------------|
| `-Action` | Non-interactive action (see below) |
| `-Lang` | `en` \| `fr` \| `es` \| `de` |
| `-Model` | Bench model name (e.g. `llama3.1:8b`) |
| `-Models` | Multi-bench list: `7b,14b,32b` or exact names |
| `-Ctx` | Bench `num_ctx` (`4096` or `16384`; interactive picker if omitted) |
| `-Out` | Report path (`.json` or `.txt`) |
| `-Notify` | Windows toast on install / bench / watchdog |
| `-Quiet` | CI-friendly output (`OK` / `WARN` / `ERROR`), no banner/Pause |
| `-Theme` | `Full` \| `Minimal` |

#### `-Action` values

| Action | What it does |
|--------|----------------|
| `install-context` / `install` | Apply Turbo Context (FA+Q8) |
| `install-speed` | Apply Turbo Pure Speed (FA) |
| `restore` | Stock rollback |
| `status` | Print current mode / FA / KV / GPU |
| `gpu-check` | NVIDIA vs AMD/Intel + arch (Ampere/Ada/Blackwell); exit `2` if unsupported; warns if &lt; RTX 2000 |
| `bench` | Single-model Stock/FA/FA+Q8; pick `num_ctx` 4096 / 16384 / both |
| `bench-multi` | Chain 7B/14B/32B (or `-Models`) |
| `health` | Full health check; optional `-Out health.json` |
| `smart` | Apply VRAM-based preset |
| `vram` | Print FP16 vs Q8 context estimates |
| `watchdog` | Repair Machine flags from saved state |
| `watchdog-install` | Register logon scheduled task |
| `watchdog-remove` | Unregister watchdog task |

#### CLI examples

```powershell
# Optimize + toast
.\Ollama-Turbo-RTX.ps1 -Action install-context -Notify

# CI / automation
.\Ollama-Turbo-RTX.ps1 -Action install-context -Quiet
.\Ollama-Turbo-RTX.ps1 -Action status -Quiet
.\Ollama-Turbo-RTX.ps1 -Action health -Quiet -Out .\health.json
.\Ollama-Turbo-RTX.ps1 -Action gpu-check -Quiet

# Benchmark → JSON (4096 = standard, 16384 = long context where Q8 shines)
.\Ollama-Turbo-RTX.ps1 -Action bench -Model llama3.1:8b -Ctx 4096 -Out .\report-4k.json
.\Ollama-Turbo-RTX.ps1 -Action bench -Model llama3.1:8b -Ctx 16384 -Out .\report-16k.json
.\Ollama-Turbo-RTX.ps1 -Action bench-multi -Models "7b,14b,32b" -Ctx 16384 -Out .\multi.json

# VRAM estimate / smart preset / watchdog
.\Ollama-Turbo-RTX.ps1 -Action vram
.\Ollama-Turbo-RTX.ps1 -Action smart -Quiet
.\Ollama-Turbo-RTX.ps1 -Action watchdog-install
```

Exit codes: `0` success · `2` unsupported GPU (AMD/Intel/none).

---

### 🩺 Health check **[6]** highlights

- Ollama CLI version vs latest GitHub release → optional install (`curl.exe`, not slow `Invoke-WebRequest`)
- NVIDIA Game Ready: compare driver → **Y** opens browser download (no PS download of the .exe)
- API `127.0.0.1:11434`, loaded models, Machine `FA` / `KV`
- Quiet: one-line summary; `-Out health.json` for machines

---

### 📣 Launch kit

Ready-to-post Reddit titles + bodies: **[REDDIT-LAUNCH.md](REDDIT-LAUNCH.md)**.  
After a bench, the script also copies a paste-ready card and writes `Ollama_Turbo_Bench_*-reddit.txt` on the Desktop.

Demo GIF tips: **[assets/README.md](assets/README.md)**.

---

### ⭐ Support the project

Menu **[S]** opens the links in your browser, or:

1. **Star the repo** → [github.com/Masterm3u/Ollama-Turbo-RTX](https://github.com/Masterm3u/Ollama-Turbo-RTX)
2. **Buy me a coffee** → [buymeacoffee.com/masterm3u](https://buymeacoffee.com/masterm3u)

<a href="https://buymeacoffee.com/masterm3u" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40"></a>

### 👤 Author

[Masterm3u](https://github.com/Masterm3u) / [Buy me a coffee](https://buymeacoffee.com/masterm3u) — [github.com/Masterm3u/Ollama-Turbo-RTX](https://github.com/Masterm3u/Ollama-Turbo-RTX)

### 📄 License

[PolyForm Noncommercial License 1.0.0](LICENSE) — free for personal, academic, and non-commercial use. Commercial use requires written permission from Masterm3u.
