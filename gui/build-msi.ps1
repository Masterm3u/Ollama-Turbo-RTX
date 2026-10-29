# Build self-contained app EXE + WiX MSI + branded Setup.exe (llama icon)
# Requires: .NET 8 SDK, WiX CLI (`dotnet tool install -g wix`)
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PATH = "$env:LOCALAPPDATA\dotnet;$env:USERPROFILE\.dotnet\tools;$env:PATH"

$dotnet = $null
foreach ($c in @(
    (Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "$env:LOCALAPPDATA\dotnet\dotnet.exe",
    "$env:ProgramFiles\dotnet\dotnet.exe"
)) {
    if ($c -and (Test-Path $c)) { $dotnet = $c; break }
}
if (-not $dotnet) { throw "dotnet SDK not found" }

Write-Host "==> Publish self-contained app exe" -ForegroundColor Cyan
& (Join-Path $root "publish.ps1") -SelfContained

$installer = Join-Path $root "installer"
$wxs = Join-Path $installer "Package.wxs"
$dist = Join-Path $root "dist"
$msi = Join-Path $dist "OllamaTurboRTX-Setup.msi"

# Bump Version attribute in Package.wxs for this build
$xml = Get-Content $wxs -Raw
$xml = [regex]::Replace($xml, 'Version="[^"]+"', "Version=`"$Version`"")
# Strip UTF-8 BOM if Set-Content added one previously (breaks wix)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($wxs, $xml, $utf8NoBom)

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
$msiHash = (Get-FileHash $msi -Algorithm SHA256).Hash.ToLowerInvariant()
$msiHash | Set-Content -Path "$msi.sha256" -Encoding ascii
$msiMb = [math]::Round((Get-Item $msi).Length / 1MB, 2)
Write-Host ("OK: {0} ({1} MB)" -f $msi, $msiMb) -ForegroundColor Green
Write-Host ("SHA256: {0}" -f $msiHash) -ForegroundColor DarkGray

# Branded Setup.exe (Explorer shows racing-llama icon; .msi always uses Windows default)
Write-Host "==> Build branded Setup.exe bootstrapper" -ForegroundColor Cyan
$launcher = Join-Path $root "setup-launcher"
$payloadDir = Join-Path $launcher "Payload"
New-Item -ItemType Directory -Force -Path $payloadDir | Out-Null
Copy-Item -Force $msi (Join-Path $payloadDir "OllamaTurboRTX-Setup.msi")

$csproj = Join-Path $launcher "SetupLauncher.csproj"
# Keep launcher assembly version in sync
$projXml = Get-Content $csproj -Raw
$projXml = [regex]::Replace($projXml, '<Version>[^<]+</Version>', "<Version>$Version</Version>")
[System.IO.File]::WriteAllText($csproj, $projXml, $utf8NoBom)

& $dotnet publish $csproj -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o $dist

$setupExe = Join-Path $dist "OllamaTurboRTX-Setup.exe"
if (-not (Test-Path $setupExe)) { throw "Setup.exe publish failed" }
$setupHash = (Get-FileHash $setupExe -Algorithm SHA256).Hash.ToLowerInvariant()
$setupHash | Set-Content -Path "$setupExe.sha256" -Encoding ascii
$setupMb = [math]::Round((Get-Item $setupExe).Length / 1MB, 2)
Write-Host ("OK: {0} ({1} MB) - use this for the llama icon in Explorer" -f $setupExe, $setupMb) -ForegroundColor Green
Write-Host ("SHA256: {0}" -f $setupHash) -ForegroundColor DarkGray
