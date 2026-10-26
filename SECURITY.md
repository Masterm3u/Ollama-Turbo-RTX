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

**Current `Ollama-Turbo-RTX.ps1` scan: 0 / 60 engines — clean**

→ [https://www.virustotal.com/gui/file/d51c5599308df8154d9d581f5bb419b16899043856ce4a620f61334f40c53783](https://www.virustotal.com/gui/file/d51c5599308df8154d9d581f5bb419b16899043856ce4a620f61334f40c53783)

SHA-256: `d51c5599308df8154d9d581f5bb419b16899043856ce4a620f61334f40c53783`

Anyone can open that link and see the multi-engine AV results. After you change the script, recompute the hash, re-upload, and update this URL.

Bootstrap `get.ps1` hash: `cd52cc795386c8a138dcb348ac68349f36b98c9f23741dc03e4b6ef15573897b`

### 4. Safer install (no `iex` pipe)

Prefer this if you want to inspect / scan first:

```powershell
iwr -useb https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1 -OutFile "$env:TEMP\Ollama-Turbo-RTX.ps1"
# Optional: upload that file to VirusTotal, or open it in Notepad
notepad "$env:TEMP\Ollama-Turbo-RTX.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\Ollama-Turbo-RTX.ps1"
```

## Reporting issues

If you believe something is unsafe, open a GitHub Issue on this repository.
