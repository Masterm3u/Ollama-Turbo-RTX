# Ollama-Turbo-RTX — Enable Flash Attention & Q8 KV Cache on Windows (NVIDIA RTX)

[![License: PolyForm Noncommercial](https://img.shields.io/badge/License-PolyForm%20Noncommercial-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?logo=windows)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GPU: RTX 30/40/50](https://img.shields.io/badge/NVIDIA-RTX%2030%20%2F%2040%20%2F%2050-76B900?logo=nvidia)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GitHub stars](https://img.shields.io/github/stars/Masterm3u/Ollama-Turbo-RTX?style=social)](https://github.com/Masterm3u/Ollama-Turbo-RTX/stargazers)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/groupeplatinium)

> **1-click Ollama optimizer for Windows 10/11 + NVIDIA RTX 30 / 40 / 50** — turn on Flash Attention, set `OLLAMA_KV_CACHE_TYPE=q8_0`, free ~50% context VRAM, and compare Stock vs Turbo tokens/s in a live benchmark.

<!-- Drop assets/demo.gif then uncomment:
![Demo](assets/demo.gif)
-->

### The problem (why Ollama feels slow on Windows)

By default, **Ollama on Windows** runs in **conservative mode**: **Flash Attention is disabled** and the **KV cache stays FP16**. That protects older GPUs, but on a modern **NVIDIA GeForce RTX** (30-series, 40-series, 50-series) you leave free performance on the table — slower **prompt processing / time-to-first-token**, higher **VRAM** use on long context, and a weaker experience when loading large files in **Cursor**, **VS Code**, or any local LLM chat.

People search for: *enable Ollama Flash Attention Windows*, *OLLAMA_FLASH_ATTENTION*, *Ollama Q8 KV cache*, *reduce Ollama VRAM*, *Ollama RTX 4090 / 5080 optimize* — this repo is the 1-click answer.

### The fix (Ollama-Turbo)

**Ollama-Turbo-RTX** is a free **PowerShell** tool that:

- sets **`OLLAMA_FLASH_ATTENTION=1`** (Tensor Core–friendly Flash Attention)
- optionally sets **`OLLAMA_KV_CACHE_TYPE=q8_0`** (quantized KV cache → **~50% less context VRAM**)
- restarts the **Ollama** daemon cleanly
- runs a **live Stock vs Turbo benchmark** (tokens/s) so you can verify the gain on *your* GPU

One Admin PowerShell line. No installer. Rollback included.

---

### 🚀 Quick Install (Admin PowerShell)

```powershell
irm https://masterm3u.github.io/turbo | iex
```

Zero clone. Zero installer. Menu in color → optimize → optional live bench.

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

> Results vary by GPU / model / drivers. Run **[4]** yourself and compare — that’s the point.

---

### ✨ Features

- **Auto-detects** the Windows OS language on launch
- **Full multilingual UI** (4 languages): English (worldwide default), French, Spanish, and German
- **Switch language anytime** from the menu, or via CLI (`-Lang en`, `-Lang fr`, `-Lang es`, `-Lang de`)
- **All tools in one place**: optimization (Flash Attention + KV Q8), rollback, detailed status, and live benchmark

---

### 🎛️ Modes

| Mode | What it does |
|------|----------------|
| **Turbo Context (FA + Q8)** | Flash Attention + KV `q8_0` — ~50% less VRAM for context |
| **Turbo Pure Speed (FA only)** | Flash Attention, KV FP16 — max decode speed/quality |
| **Rollback** | Restore stock Ollama env |
| **Benchmark** | Stock vs Speed vs Context in a separate admin window |

---

### ✅ Prerequisites

- Windows 10 / 11
- NVIDIA RTX 30 / 40 / 50 series
- [Ollama](https://ollama.com/download) installed
- Run as **Administrator** (Machine environment variables)

---

### 📦 Local run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1
```

Force a language:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1 -Lang fr
```

---

### 📣 Launch kit

Ready-to-post Reddit titles + bodies (r/LocalLLaMA, r/ollama, r/PowerShell, r/nvidia): see **[REDDIT-LAUNCH.md](REDDIT-LAUNCH.md)**.

Demo GIF instructions: **[assets/README.md](assets/README.md)**.

---

### ⭐ Support the project

If this saved you time or VRAM:

1. **Star the repo** → [github.com/Masterm3u/Ollama-Turbo-RTX](https://github.com/Masterm3u/Ollama-Turbo-RTX) (helps others find it)
2. **Buy me a coffee** → [buymeacoffee.com/groupeplatinium](https://buymeacoffee.com/groupeplatinium)

<a href="https://buymeacoffee.com/groupeplatinium" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40"></a>

### 👤 Author

[Masterm3u](https://github.com/Masterm3u) / [groupeplatinium](https://buymeacoffee.com/groupeplatinium) — [github.com/Masterm3u/Ollama-Turbo-RTX](https://github.com/Masterm3u/Ollama-Turbo-RTX)

### 📄 License

[PolyForm Noncommercial License 1.0.0](LICENSE) — free for personal, academic, and non-commercial use. Commercial use requires written permission from Masterm3u.
