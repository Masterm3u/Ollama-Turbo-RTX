# Ollama-Turbo-RTX - bootstrap compatible irm | iex (pas de bloc param)
# Toujours le commit tip (evite le cache CDN de /main/ qui sert parfois un vieux .ps1)
$ErrorActionPreference = "Stop"
$repo = "Masterm3u/Ollama-Turbo-RTX"
$dst  = Join-Path $env:TEMP "Ollama-Turbo-RTX.ps1"

Write-Host "[*] Ollama-Turbo-RTX - telechargement (latest commit)..." -ForegroundColor Cyan

$sha = $null
try {
    $headers = @{
        "User-Agent"    = "Ollama-Turbo-RTX"
        "Accept"        = "application/vnd.github+json"
        "Cache-Control" = "no-cache"
    }
    $sha = [string](Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/main" -Headers $headers -TimeoutSec 15).sha
} catch {}

if ($sha) {
    $src = "https://raw.githubusercontent.com/$repo/$sha/Ollama-Turbo-RTX.ps1"
    Write-Host ("    commit: {0}" -f $sha.Substring(0, 7)) -ForegroundColor DarkGray
} else {
    $bust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $src = "https://cdn.jsdelivr.net/gh/$repo@main/Ollama-Turbo-RTX.ps1?t=$bust"
    Write-Host "    mirror: jsDelivr" -ForegroundColor DarkGray
}

Remove-Item $dst -Force -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $src -OutFile $dst -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache"; "Pragma" = "no-cache" }

# Refuse un script obsolete (sans prompt NVIDIA)
$probe = Get-Content $dst -Raw -ErrorAction SilentlyContinue
if (-not $probe -or $probe -notmatch 'pendingNvidia') {
    Write-Host "[!!] Script obsolete/incomplet - nouvel essai via jsDelivr..." -ForegroundColor Yellow
    $bust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/gh/$repo@main/Ollama-Turbo-RTX.ps1?t=$bust" -OutFile $dst -UseBasicParsing
    $probe = Get-Content $dst -Raw -ErrorAction SilentlyContinue
}
if (-not $probe -or $probe -notmatch 'pendingNvidia') {
    throw "Impossible de telecharger une version a jour de Ollama-Turbo-RTX.ps1"
}

$ErrorActionPreference = "Continue"

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $admin) {
    Write-Host "[*] Ouverture d'une fenetre Administrateur..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dst`"" -Verb RunAs | Out-Null
} else {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    & $dst
}
