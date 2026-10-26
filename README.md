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

### 📊 Why it matters (proof, not vibes)

| Metric | Stock Ollama (Windows default) | Turbo Pure Speed (FA) | Turbo Context (FA + Q8) |
|--------|--------------------------------|------------------------|-------------------------|
| Flash Attention | Off | **On** | **On** |
| KV cache | FP16 | FP16 | **q8_0** |
| Context VRAM | 100% baseline | ~100% | **~50%** |
| Goal | Compatibility | Max decode quality/speed | Longer context / bigger models in VRAM |
| Verify | — | Menu **[4]** live bench | Menu **[4]** live bench |

Run **[4] Benchmark** after install and you get a **Stock | Speed | Context** tokens/s table on *your* GPU — the number that converts skeptics.

> **Tip for stars / Reddit:** paste your real table (GPU + model + t/s) into issues or your post. Devs trust screenshots of numbers, not slogans.

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
