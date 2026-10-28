# Ollama-Turbo-RTX — GUI (WPF / .NET 8)

Single-file Windows app: toggle Flash Attention + KV `q8_0` without Administrator rights.

## Build

```powershell
# .NET 8 SDK required
.\publish.ps1                 # framework-dependent (~0.2 MB)
.\publish.ps1 -SelfContained  # no runtime install on target (~60+ MB)
```

Output: `dist\OllamaTurboRTX.exe` (+ `.sha256`).

Framework-dependent builds need **[.NET 8+ Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)** (`Microsoft.WindowsDesktop.App`). `RollForward=LatestMajor` allows running on newer Desktop runtimes (e.g. .NET 10) when present.

## Behavior

1. Sets `OLLAMA_FLASH_ATTENTION` / `OLLAMA_KV_CACHE_TYPE` under **User** environment (`EnvironmentVariableTarget.User`).
2. Stops `ollama app` / `ollama` / `llama-server`.
3. Starts `%LOCALAPPDATA%\Programs\Ollama\ollama app.exe` with those variables in the child process.
4. Optional **Quick Bench** hits `http://127.0.0.1:11434/api/generate` with `num_ctx` 4096 or 16384.

For Machine-wide flags, health checks, multi-model bench, and watchdog, use the PowerShell tool at the repo root.
