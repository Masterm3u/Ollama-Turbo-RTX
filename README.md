# ⚡ Ollama-Turbo-RTX

[![License: PolyForm Noncommercial](https://img.shields.io/badge/License-PolyForm%20Noncommercial-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?logo=windows)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GPU: RTX 30/40/50](https://img.shields.io/badge/NVIDIA-RTX%2030%20%2F%2040%20%2F%2050-76B900?logo=nvidia)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)](https://github.com/Masterm3u/Ollama-Turbo-RTX)
[![GitHub stars](https://img.shields.io/github/stars/Masterm3u/Ollama-Turbo-RTX?style=social)](https://github.com/Masterm3u/Ollama-Turbo-RTX)

> **1-Click Hardware Acceleration for Ollama on Windows (NVIDIA RTX 30 / 40 / 50 Series)**

<!-- Drop assets/demo.gif then uncomment:
![Demo](assets/demo.gif)
-->

Ollama on Windows runs in **conservative mode** by default (FP16 KV cache, Flash Attention off — safer for legacy GPUs). On modern RTX cards that leaves performance on the table, especially **prompt ingest** in Cursor / VS Code.

**Ollama-Turbo** enables Tensor Core–friendly flags in one line, unlocks **Q8 KV** (~50% less context VRAM), restarts Ollama cleanly, and ships a **live Stock vs Turbo benchmark**.

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

### 👤 Author

[Masterm3u](https://github.com/Masterm3u) — [github.com/Masterm3u/Ollama-Turbo-RTX](https://github.com/Masterm3u/Ollama-Turbo-RTX)

### 📄 License

[PolyForm Noncommercial License 1.0.0](LICENSE) — free for personal, academic, and non-commercial use. Commercial use requires written permission from Masterm3u.
