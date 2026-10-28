# Build single-file OllamaTurboRTX.exe
#   .\publish.ps1                  -> framework-dependent (~0.2 MB, needs .NET 8+ Desktop Runtime)
#   .\publish.ps1 -SelfContained   -> standalone (~60-80 MB, double-click anywhere)
param([switch]$SelfContained)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Join-Path $root "OllamaTurboRTX\OllamaTurboRTX.csproj"
$out  = Join-Path $root "dist"

$dotnet = $null
foreach ($c in @(
    (Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "$env:LOCALAPPDATA\dotnet\dotnet.exe",
    "$env:ProgramFiles\dotnet\dotnet.exe"
)) {
    if ($c -and (Test-Path $c)) { $dotnet = $c; break }
}
if (-not $dotnet) { throw "dotnet SDK not found. Install .NET 8 SDK: https://dot.net/download" }

Write-Host "Using: $dotnet" -ForegroundColor Cyan
$sc = if ($SelfContained) { "true" } else { "false" }
Write-Host ("SelfContained={0}" -f $sc) -ForegroundColor DarkGray

& $dotnet publish $proj -c Release -r win-x64 `
    --self-contained:$SelfContained `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:PublishReadyToRun=true `
    -o $out

$exe = Join-Path $out "OllamaTurboRTX.exe"
if (Test-Path $exe) {
    $hash = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
    $mb = [math]::Round((Get-Item $exe).Length / 1MB, 2)
    Write-Host ""
    Write-Host ("OK: {0} ({1} MB)" -f $exe, $mb) -ForegroundColor Green
    Write-Host ("SHA256: {0}" -f $hash) -ForegroundColor DarkGray
    $hash | Set-Content -Path (Join-Path $out "OllamaTurboRTX.exe.sha256") -Encoding ascii
} else {
    throw "Publish failed - exe missing."
}
