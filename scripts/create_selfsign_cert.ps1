# ClickMate - Create Self-Signed Code Signing Certificate
# Usage: .\create_selfsign_cert.ps1 <cert_path> <password>

param(
    [Parameter(Mandatory=$true)]
    [string]$CertPath,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$ErrorActionPreference = "Stop"

Write-Host "Creating self-signed code signing certificate..."
Write-Host "Output: $CertPath"
Write-Host ""

try {
    # Create certificate
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=ClickMate Developer, O=ClickMate, C=CN" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -CertStoreLocation Cert:\CurrentUser\My `
        -NotAfter (Get-Date).AddYears(5) `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
    
    # Export to PFX
    $secpwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $CertPath -Password $secpwd | Out-Null
    
    Write-Host "[OK] Certificate created successfully"
    Write-Host "Thumbprint: $($cert.Thumbprint)"
    Write-Host "Valid until: $($cert.NotAfter)"
    
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}

