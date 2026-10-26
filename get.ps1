# Ollama-Turbo-RTX - bootstrap compatible irm | iex (pas de bloc param)
$ErrorActionPreference = "Stop"
$src = "https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1"
$dst = Join-Path $env:TEMP "Ollama-Turbo-RTX.ps1"

Write-Host "[*] Ollama-Turbo-RTX - telechargement..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $src -OutFile $dst -UseBasicParsing
$ErrorActionPreference = "Continue"

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $admin) {
    Write-Host "[*] Ouverture d'une fenetre Administrateur..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dst`"" -Verb RunAs | Out-Null
} else {
    # Meme processus : pas de second powershell.exe dans la fenetre
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    & $dst
}
