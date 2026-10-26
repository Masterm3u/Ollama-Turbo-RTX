# Ollama-Turbo-RTX — bootstrap compatible irm | iex (pas de bloc param)
$ErrorActionPreference = "Stop"
$src = "https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1"
$dst = Join-Path $env:TEMP "Ollama-Turbo-RTX.ps1"

Write-Host "[*] Ollama-Turbo-RTX — telechargement..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $src -OutFile $dst -UseBasicParsing

$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$dst`""
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $admin) {
    Write-Host "[*] Elevation Administrateur..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList $arg -Verb RunAs | Out-Null
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
}
