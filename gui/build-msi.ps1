# Build self-contained exe + WiX MSI installer
# Requires: .NET 8 SDK, WiX CLI (`dotnet tool install -g wix`)
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PATH = "$env:LOCALAPPDATA\dotnet;$env:USERPROFILE\.dotnet\tools;$env:PATH"

Write-Host "==> Publish self-contained exe" -ForegroundColor Cyan
& (Join-Path $root "publish.ps1") -SelfContained

$installer = Join-Path $root "installer"
$wxs = Join-Path $installer "Package.wxs"
$msi = Join-Path $root "dist\OllamaTurboRTX-Setup.msi"

# Bump Version attribute in Package.wxs for this build
$xml = Get-Content $wxs -Raw
$xml = [regex]::Replace($xml, 'Version="[^"]+"', "Version=`"$Version`"")
Set-Content -Path $wxs -Value $xml -Encoding UTF8

Push-Location $installer
try {
    Write-Host "==> Ensure WiX UI extension" -ForegroundColor Cyan
    wix extension add "WixToolset.UI.wixext/5.0.2" 2>$null | Out-Null
    Write-Host "==> Build MSI" -ForegroundColor Cyan
    wix build Package.wxs -ext WixToolset.UI.wixext -arch x64 -out $msi -pdbtype none
} finally {
    Pop-Location
}

if (-not (Test-Path $msi)) { throw "MSI build failed" }
$hash = (Get-FileHash $msi -Algorithm SHA256).Hash.ToLowerInvariant()
$hash | Set-Content -Path "$msi.sha256" -Encoding ascii
$mb = [math]::Round((Get-Item $msi).Length / 1MB, 2)
Write-Host ("OK: {0} ({1} MB)" -f $msi, $mb) -ForegroundColor Green
Write-Host ("SHA256: {0}" -f $hash) -ForegroundColor DarkGray
