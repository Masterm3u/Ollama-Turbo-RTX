# Ollama-Turbo-RTX — bootstrap 1-clic (irm | iex)
# Télécharge et lance le script principal depuis GitHub.
$ErrorActionPreference = "Stop"
$repoRaw = "https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1"
$localDir = Join-Path $env:TEMP "Ollama-Turbo-RTX"
$localPs1 = Join-Path $localDir "Ollama-Turbo-RTX.ps1"

New-Item -ItemType Directory -Force -Path $localDir | Out-Null
Write-Host "[*] Downloading Ollama-Turbo-RTX..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoRaw -OutFile $localPs1 -UseBasicParsing

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $localPs1 @args
