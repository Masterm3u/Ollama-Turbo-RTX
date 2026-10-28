# Ollama-Turbo-RTX — GUI (WPF / .NET 8)

Windows GUI that exposes **every PowerShell menu action** by launching the bundled `Ollama-Turbo-RTX.ps1` (Machine scope + UAC).

## Download

- **MSI installer:** https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX-Setup.msi
- **Portable EXE:** https://github.com/Masterm3u/Ollama-Turbo-RTX/releases/latest/download/OllamaTurboRTX.exe

App icon / branding assets: `OllamaTurboRTX/Assets/app.ico` (llama + lightning).

## Build

```powershell
# .NET 8 SDK required; MSI also needs: dotnet tool install -g wix
.\publish.ps1                 # framework-dependent (~0.2 MB)
.\publish.ps1 -SelfContained  # standalone (~170 MB)
.\build-msi.ps1 -Version 1.0.0
```

Output: `dist\OllamaTurboRTX.exe`, `dist\OllamaTurboRTX-Setup.msi` (+ `.sha256`).

Framework-dependent builds need **[.NET 8+ Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)** (`Microsoft.WindowsDesktop.App`). `RollForward=LatestMajor` allows running on newer Desktop runtimes (e.g. .NET 10) when present. The **MSI / SelfContained** builds embed the runtime.

## Behavior

1. Sets `OLLAMA_FLASH_ATTENTION` / `OLLAMA_KV_CACHE_TYPE` under **User** environment (`EnvironmentVariableTarget.User`).
2. Stops `ollama app` / `ollama` / `llama-server`.
3. Starts `%LOCALAPPDATA%\Programs\Ollama\ollama app.exe` with those variables in the child process.
4. Optional **Quick Bench** hits `http://127.0.0.1:11434/api/generate` with `num_ctx` 4096 or 16384.

For Machine-wide flags, health checks, multi-model bench, and watchdog, use the PowerShell tool at the repo root.
