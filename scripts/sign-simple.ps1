# Hellion Power Tool - Einfache Code-Signierung
param(
    [switch]$Force = $false
)

Write-Host "🔐 Hellion Power Tool - Code-Signierung" -ForegroundColor Cyan

# Suche existierendes Zertifikat
$existingCert = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Hellion Power Tool*" }

if ($existingCert -and -not $Force) {
    Write-Host "✅ Existierendes Zertifikat gefunden" -ForegroundColor Green
    $cert = $existingCert
} else {
    Write-Host "🔧 Erstelle neues Self-Signed Zertifikat..." -ForegroundColor Yellow
    
    $cert = New-SelfSignedCertificate `
        -Subject "CN=Hellion Power Tool,O=Open Source Project,C=DE" `
        -Type CodeSigning `
        -KeyUsage DigitalSignature `
        -FriendlyName "Hellion Power Tool Code Signing Certificate" `
        -NotAfter (Get-Date).AddYears(3) `
        -CertStoreLocation "Cert:\CurrentUser\My"
        
    Write-Host "✅ Zertifikat erstellt!" -ForegroundColor Green
}

# Exportiere Zertifikat
try {
    Export-Certificate -Cert $cert -FilePath "hellion-certificate.cer" -Force | Out-Null
    Write-Host "✅ Zertifikat exportiert: hellion-certificate.cer" -ForegroundColor Green
} catch {
    Write-Warning "⚠️ Export fehlgeschlagen: $($_.Exception.Message)"
}

# Signiere alle PowerShell-Dateien
Write-Host "`n✍️ Signiere PowerShell-Dateien..." -ForegroundColor Cyan
$signedCount = 0
$failedCount = 0

Get-ChildItem *.ps1 -Recurse | Where-Object {
    $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\old-versions\*"
} | ForEach-Object {
    try {
        $result = Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert
        if ($result.Status -eq "Valid") {
            Write-Host "✅ $($_.Name)" -ForegroundColor Green
            $signedCount++
        } else {
            Write-Host "❌ $($_.Name) - Status: $($result.Status)" -ForegroundColor Red
            $failedCount++
        }
    } catch {
        Write-Host "❌ $($_.Name) - Fehler: $($_.Exception.Message)" -ForegroundColor Red
        $failedCount++
    }
}

Write-Host "`n📊 ERGEBNIS:" -ForegroundColor Cyan
Write-Host "✅ Erfolgreich signiert: $signedCount" -ForegroundColor Green
Write-Host "❌ Fehlgeschlagen: $failedCount" -ForegroundColor Red

if ($failedCount -eq 0) {
    Write-Host "`n🎉 Alle Dateien erfolgreich signiert!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Einige Dateien konnten nicht signiert werden." -ForegroundColor Yellow
}