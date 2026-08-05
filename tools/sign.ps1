# Windows Authenticode signing.
#
# Only the self-hosted 'codecert' runner has the signing token, so this script is
# invoked exclusively from that job in .github/workflows/build.yaml. The
# certificate path comes from CSC_LINK and the token key from BF_CODECERT_KEY,
# matching the convention used by the other Bitfocus projects. Ordinary builds
# (forks, pull requests, non-tag pushes) never call this and stay unsigned.

param (
    [string]$File = $args[0],
    [string]$Description = "Bitfocus Listener Application"
)

if (-not $File) {
    Write-Host "Usage: .\sign.ps1 <File> [-Description <Description>]"
    exit 1
}

$Cert = if ($env:CSC_LINK) { $env:CSC_LINK } else { "c:\actions-runner-bitfocusas\codesign.cer" }

if (-not $env:BF_CODECERT_KEY) {
    Write-Error "BF_CODECERT_KEY is not set; cannot sign $File"
    exit 1
}

$SignTool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe" |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $SignTool) {
    Write-Error "signtool.exe not found in the Windows 10 SDK"
    exit 1
}

Write-Host "Signing $File"

& $SignTool.FullName sign `
/fd SHA256 /td SHA256 `
/tr http://timestamp.digicert.com `
/d "$Description" `
/du "https://bitfocus.io" `
/f "$Cert" `
/csp "eToken Base Cryptographic Provider" `
/k "$env:BF_CODECERT_KEY" `
$File

if ($LASTEXITCODE -ne 0) {
    Write-Error "signtool failed for $File"
    exit $LASTEXITCODE
}
