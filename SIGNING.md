# Code signing (Authenticode) — optional

**Recommended for this project right now:** stay **unsigned** + [VirusTotal](SECURITY.md) + open PowerShell source + [`checksums.sha256`](checksums.sha256). That is enough for GitHub / Reddit trust.

Commercial Authenticode is an **extra** (enterprise / SmartScreen), not a launch blocker.

Digital signatures prove **who published** the script and that **bytes were not altered** after signing.

## What removes Windows warnings?

| Certificate type | Trusted Publisher on your PC | SmartScreen for strangers |
|------------------|------------------------------|---------------------------|
| **None** (current public repo) | N/A | May warn on `irm \| iex` / downloaded scripts |
| **Self-signed** (`-CreateSelfSigned`) | Only after you install the `.cer` in Trusted Publisher | **No** — still “Unknown publisher” |
| **Commercial Code Signing (OV)** | Yes, for most users | Much better; reputation builds over time |
| **EV Code Signing** | Yes | Best SmartScreen reputation (USB token / cloud HSM) |

**Bottom line:** self-signing is great for **lab / enterprise** (GPO deploys your cert). For **viral public distribution without warnings**, buy a real **Code Signing** cert (DigiCert, Sectigo, SSL.com, SignPath, etc.) under your legal name / company (**Masterm3u** / Rejean Lessard / groupeplatinium).

## Sign locally (tool in this repo)

```powershell
# Lab / internal only — creates CN=Masterm3u Ollama-Turbo-RTX in CurrentUser\My
.\tools\Sign-Release.ps1 -CreateSelfSigned

# Production — use your purchased cert thumbprint
.\tools\Sign-Release.ps1 -Thumbprint "PASTE_THUMBPRINT_HERE"
```

Verify:

```powershell
Get-AuthenticodeSignature .\Ollama-Turbo-RTX.ps1 | Format-List *
```

`Status` should be **Valid** when the signer cert is trusted on that machine.

## Trust a self-signed cert on one PC (Admin)

```powershell
$cer = ".\Masterm3u-CodeSign.cer"   # exported from the signing cert
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root   # optional for self-signed chain
```

## After every signature

1. File bytes change → update [`checksums.sha256`](checksums.sha256)
2. Re-upload to [VirusTotal](https://www.virustotal.com/gui/home/upload)
3. Update the VirusTotal badge link in the README

## Never commit

- Private keys (`.pfx` / `.p12`)
- Certificate passwords
- Soft-HSM tokens without encryption

Use Windows Certificate Store or a CI secret (GitHub Actions + OV cloud signing) — not the git repo.

## Note on `irm | iex`

Even a signed `.ps1` fetched into memory via `Invoke-Expression` may **not** surface Authenticode the same way as `-File path.ps1`. Prefer the download-then-run path for signature checks:

```powershell
iwr -useb https://raw.githubusercontent.com/Masterm3u/Ollama-Turbo-RTX/main/Ollama-Turbo-RTX.ps1 -OutFile "$env:TEMP\Ollama-Turbo-RTX.ps1"
Get-AuthenticodeSignature "$env:TEMP\Ollama-Turbo-RTX.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\Ollama-Turbo-RTX.ps1"
```
