# ⚡ Ollama-Turbo-RTX

> **1-Click Hardware Acceleration for Ollama on Windows (NVIDIA RTX 30 / 40 / 50 Series)**

Ollama on Windows runs in conservative mode by default (FP16 KV cache and disabled Flash Attention to avoid crashing older legacy GPUs).

**Ollama-Turbo** automatically enables low-level Tensor Core acceleration, unlocks Q8 KV caching (50% memory drop for context), and eliminates prompt ingest latency in Cursor, VS Code, and terminal workflows.

---

### 🚀 Quick Install (1 line in PowerShell)

Open PowerShell as **Administrator** and run:

```powershell
iwr -useb https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1 -OutFile "$env:TEMP\Ollama-Turbo-RTX.ps1"; powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\Ollama-Turbo-RTX.ps1"
```

Or clone / download the repo and double-click `Ollama-Turbo-RTX.bat`.

---

### 🎛️ Modes

| Mode | What it does |
|------|----------------|
| **Turbo Contexte (FA + Q8)** | Flash Attention + KV cache `q8_0` — ~50% less VRAM for context |
| **Turbo Vitesse Pure (FA seul)** | Flash Attention only, KV FP16 — max decode speed |
| **Rollback** | Restore stock Ollama env (no FA / no Q8) |
| **Benchmark** | Compare Stock vs Vitesse vs Contexte in a separate admin window |

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

---

### 👤 Author

[Masterm3u](https://github.com/Masterm3u)

### 📄 License

MIT
