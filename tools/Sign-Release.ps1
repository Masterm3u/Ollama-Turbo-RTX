#Requires -Version 5.1
<#
.SYNOPSIS
  Signe Ollama-Turbo-RTX.ps1 (et get.ps1) avec Authenticode.

.DESCRIPTION
  - Certificat COMMERCIAL (recommandé grand public / SmartScreen) :
      .\tools\Sign-Release.ps1 -Thumbprint "ABC123..."
  - Certificat auto-signé LOCAL (labo / entreprise où le cert est déployé en Trusted Publisher) :
      .\tools\Sign-Release.ps1 -CreateSelfSigned

  La clé privée / Thumbprint ne doivent JAMAIS être commités dans le dépôt.

.NOTES
  Un certificat auto-signé N'élimine PAS SmartScreen chez les inconnus.
  Pour ça : certificat Code Signing OV/EV (DigiCert, Sectigo, SSL.com, etc.).
#>
param(
    [string]$Thumbprint,
    [switch]$CreateSelfSigned,
    [string]$Subject = "CN=Masterm3u Ollama-Turbo-RTX",
    [string]$TimestampServer = "http://timestamp.digicert.com",
    [string[]]$Files = @(
        (Join-Path $PSScriptRoot "..\Ollama-Turbo-RTX.ps1"),
        (Join-Path $PSScriptRoot "..\get.ps1")
    )
)

$ErrorActionPreference = "Stop"

function Get-SigningCertificate {
    if ($Thumbprint) {
        $cert = Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My -CodeSigningCert -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint -eq ($Thumbprint -replace '\s', '') } |
            Select-Object -First 1
        if (-not $cert) { throw "Aucun certificat Code Signing avec Thumbprint $Thumbprint" }
        return $cert
    }

    if ($CreateSelfSigned) {
        Write-Host "[*] Creation d'un certificat auto-signe (usage local / entreprise seulement)..." -ForegroundColor Yellow
        $cert = New-SelfSignedCertificate `
            -Subject $Subject `
            -Type CodeSigningCert `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable `
            -KeySpec Signature `
            -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddYears(3)
        Write-Host "[OK] Cree : $($cert.Subject)" -ForegroundColor Green
        Write-Host "     Thumbprint : $($cert.Thumbprint)" -ForegroundColor Cyan
        Write-Host "     Pour faire confiance sur CETTE machine (Admin) :" -ForegroundColor DarkGray
        Write-Host "       Export-Certificate -Cert `$cert -FilePath Masterm3u-CodeSign.cer" -ForegroundColor DarkGray
        Write-Host "       Import-Certificate -FilePath Masterm3u-CodeSign.cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher" -ForegroundColor DarkGray
        return $cert
    }

    $existing = Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My -CodeSigningCert -ErrorAction SilentlyContinue |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1
    if ($existing) {
        Write-Host "[*] Certificat trouve : $($existing.Subject) ($($existing.Thumbprint))" -ForegroundColor Cyan
        return $existing
    }

    throw "Aucun certificat Code Signing trouve.`nOptions :`n  1) .\tools\Sign-Release.ps1 -Thumbprint VOTRE_THUMBPRINT`n  2) .\tools\Sign-Release.ps1 -CreateSelfSigned"
}

$cert = Get-SigningCertificate

foreach ($rel in $Files) {
    $path = [System.IO.Path]::GetFullPath($rel)
    if (-not (Test-Path $path)) {
        Write-Warning "Fichier introuvable : $path"
        continue
    }

    Write-Host "[*] Signature Authenticode : $path" -ForegroundColor Cyan
    $sig = Set-AuthenticodeSignature -FilePath $path -Certificate $cert -TimestampServer $TimestampServer -HashAlgorithm SHA256
    if ($sig.Status -ne "Valid" -and $sig.Status -ne "UnknownError") {
        # UnknownError parfois = horodatage indisponible ; on reessaie sans timestamp
        if ($sig.StatusMessage -match "timestamp|horodat") {
            Write-Host "  [!] Timestamp serveur indisponible - signature sans horodatage..." -ForegroundColor Yellow
            $sig = Set-AuthenticodeSignature -FilePath $path -Certificate $cert -HashAlgorithm SHA256
        }
    }

    Write-Host "  Status      : $($sig.Status)" -ForegroundColor $(if ($sig.Status -eq "Valid") { "Green" } else { "Yellow" })
    Write-Host "  Signer      : $($sig.SignerCertificate.Subject)"
    Write-Host "  StatusMsg   : $($sig.StatusMessage)"
}

Write-Host "`n[*] Rafraichir les checksums apres signature (le hash change) :" -ForegroundColor DarkGray
Write-Host '  Get-FileHash .\Ollama-Turbo-RTX.ps1 -Algorithm SHA256' -ForegroundColor DarkGray
Write-Host "  Puis re-uploader sur VirusTotal (nouveau hash)." -ForegroundColor DarkGray
