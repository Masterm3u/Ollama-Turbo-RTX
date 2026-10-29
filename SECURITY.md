# Security & trust

Ollama-Turbo-RTX ships **only readable PowerShell source**. There is **no compiled project `.exe`**, no obfuscation, and no telemetry.

## What the script can do (transparent)

When you approve Admin elevation it may:

- set/remove Machine environment variables (`OLLAMA_FLASH_ATTENTION`, `OLLAMA_KV_CACHE_TYPE`, `OLLAMA_HOST`)
- restart local `ollama` / `llama-server` processes
- call the local Ollama API (`127.0.0.1:11434`) for health / benchmark
- optionally register a **logon scheduled task** (`Ollama-Turbo-RTX-Watchdog`) that re-checks those Machine flags
- show optional Windows toast notifications (`-Notify` or preference under `%LOCALAPPDATA%\Ollama-Turbo-RTX`)

**Optional downloads (only after you confirm in the UI):**

- **Ollama updater** (health check **[6]** â†’ Y): downloads official `OllamaSetup.exe` via `curl.exe` / BITS from `ollama.com` or GitHub releases, then launches the vendor installer
- **NVIDIA driver**: never downloaded in PowerShell â€” **Y** only opens the official browser URL

It does **not** phone home for analytics. The one-liner `irm â€¦ | iex` only fetches this projectâ€™s bootstrap/`get.ps1` + main script from GitHub / GitHub Pages.

## Verify before you run

### 1. Read the source

- Main script: [`Ollama-Turbo-RTX.ps1`](Ollama-Turbo-RTX.ps1)
- Bootstrap: [`get.ps1`](get.ps1) (used by `irm https://masterm3u.github.io/turbo | iex`)
  - Resolves the latest **commit SHA** then downloads that exact file (avoids stale CDN `/main/` caches)

### 2. Check SHA-256

```powershell
Get-FileHash .\Ollama-Turbo-RTX.ps1 -Algorithm SHA256
Get-FileHash .\get.ps1 -Algorithm SHA256
# Compare with checksums.sha256 in this repo
```

Published hashes: [`checksums.sha256`](checksums.sha256)

### 3. VirusTotal report (public)

**Latest `Ollama-Turbo-RTX.ps1` SHA-256:** `8319afe8a4ada9c628027e48722fa5f4d7769dc474b811a1d64886e2a07d980d`

â†’ **0 / 61 clean:** [VirusTotal detection](https://www.virustotal.com/gui/file/8319afe8a4ada9c628027e48722fa5f4d7769dc474b811a1d64886e2a07d980d/detection)

**GUI MSI** (unsigned): Windows SmartScreen may show *Ã©diteur inconnu* â€” expected for new open-source builds. Prefer **Informations complÃ©mentaires â†’ ExÃ©cuter quand mÃªme**, or build from source under `gui/`.

### VirusTotal: vendors vs Crowdsourced Sigma Rules

- **Security vendors (engines)** at **0/61 undetected** = no AV product classifies the script as malware. That is the primary trust signal.
- **Crowdsourced Sigma rules** are *behavioral heuristics* (often noisy). They are **not** vendor detections. Older builds could match rules such as:
  - *Dynamic .NET Compilation Via Csc.EXE* / *Dot net compilerâ€¦* â€” caused by `Add-Type -TypeDefinition` (on-the-fly C# for console resize). **Removed** â€” resize now uses `$Host.UI.RawUI` only (no `csc.exe`).
  - *Sysmon File Executable Creation* / *Dynamic CSharp Compile Artefact* â€” side effects of that same compile. **Gone** with the change above.
  - *Suspicious Process Discovery With Get-Process* â€” legitimate local Ollama process checks. **Replaced** with `Get-CimInstance Win32_Process` for the same purpose.

After each code change, re-upload the new file and update this link + [`checksums.sha256`](checksums.sha256).

### 4. Safer install (no `iex` pipe)

```powershell
iwr -useb https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1 -OutFile "$env:TEMP\Ollama-Turbo-RTX.ps1"
notepad "$env:TEMP\Ollama-Turbo-RTX.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\Ollama-Turbo-RTX.ps1"
```

### 5. CI / automation

```powershell
.\Ollama-Turbo-RTX.ps1 -Action status -Quiet
.\Ollama-Turbo-RTX.ps1 -Action health -Quiet -Out .\health.json
.\Ollama-Turbo-RTX.ps1 -Action gpu-check -Quiet   # exit 2 if not NVIDIA
```

## Authenticode code signing (optional / enterprise)

See **[SIGNING.md](SIGNING.md)** and `tools\Sign-Release.ps1`.

- **Self-signed** â†’ trust only after deploying the cert (lab / company GPO). Does **not** clear SmartScreen for the public.
- **Commercial Code Signing (OV/EV)** â†’ proves author identity and integrity in transit; required for â€œno warningâ€ public Windows reputation.

The public GitHub source may ship **unsigned** so every commit stays reviewable; signed builds can be attached as [Releases](https://github.com/Masterm3u/Ollama-Turbo-RTX/releases) once a commercial cert is available.

## Reporting issues

If you believe something is unsafe, open a GitHub Issue on this repository.
