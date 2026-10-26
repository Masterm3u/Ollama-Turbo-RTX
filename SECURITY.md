# Security & trust

Ollama-Turbo-RTX ships **only readable PowerShell source**. There is **no compiled `.exe`**, no installer binary, no obfuscation, and no telemetry.

## What the script can do (transparent)

When you approve Admin elevation it may:

- set/remove Machine environment variables (`OLLAMA_FLASH_ATTENTION`, `OLLAMA_KV_CACHE_TYPE`, `OLLAMA_HOST`)
- restart local `ollama` / `llama-server` processes
- call the local Ollama API (`127.0.0.1:11434`) for the optional benchmark

It does **not** phone home, install drivers, or download third-party binaries (except your own `irm` of this repo’s script).

## Verify before you run

### 1. Read the source

- Main script: [`Ollama-Turbo-RTX.ps1`](Ollama-Turbo-RTX.ps1)
- Bootstrap: [`get.ps1`](get.ps1) (used by `irm https://masterm3u.github.io/turbo | iex`)

### 2. Check SHA-256

```powershell
Get-FileHash .\Ollama-Turbo-RTX.ps1 -Algorithm SHA256
# Compare with checksums.sha256 in this repo
```

Published hashes: [`checksums.sha256`](checksums.sha256)

### 3. VirusTotal report (public)

**Latest `Ollama-Turbo-RTX.ps1` SHA-256:** `7a4fb527a003fcb637a68c5f9b581950a2c4c85b6ceae6adb895169fe03d8746`

→ Lookup / upload: [VirusTotal file page](https://www.virustotal.com/gui/file/7a4fb527a003fcb637a68c5f9b581950a2c4c85b6ceae6adb895169fe03d8746)

Previous published build scanned **0 / 60 clean** (hash `d51c5599…`). After code comments / edits, **re-upload** the new file and restore the green 0/60 badge.

Bootstrap `get.ps1` hash: see [`checksums.sha256`](checksums.sha256)

### 4. Safer install (no `iex` pipe)

Prefer this if you want to inspect / scan first:

```powershell
iwr -useb https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1 -OutFile "$env:TEMP\Ollama-Turbo-RTX.ps1"
# Optional: upload that file to VirusTotal, or open it in Notepad
notepad "$env:TEMP\Ollama-Turbo-RTX.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\Ollama-Turbo-RTX.ps1"
```

## Authenticode code signing (optional / enterprise)

See **[SIGNING.md](SIGNING.md)** and `tools\Sign-Release.ps1`.

- **Self-signed** → trust only after deploying the cert (lab / company GPO). Does **not** clear SmartScreen for the public.
- **Commercial Code Signing (OV/EV)** → proves author identity and integrity in transit; required for “no warning” public Windows reputation.

The public GitHub source may ship **unsigned** so every commit stays reviewable; signed builds can be attached as [Releases](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases) once a commercial cert is available.

## Reporting issues

If you believe something is unsafe, open a GitHub Issue on this repository.
