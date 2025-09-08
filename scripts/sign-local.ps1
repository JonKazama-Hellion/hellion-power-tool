# Hellion Power Tool - Lokale Code-Signierung
# Dieses Script signiert alle PowerShell-Dateien mit einem Self-Signed Zertifikat

param(
    [switch]$Force = $false,
    [switch]$TestOnly = $false
)

Write-Host "🔐 Hellion Power Tool - Lokale Code-Signierung" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Prüfe ob bereits ein Hellion-Zertifikat existiert
Write-Host "`n🔍 Suche nach existierendem Hellion-Zertifikat..."
$existingCert = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Hellion Power Tool*" }

if ($existingCert -and -not $Force) {
    Write-Host "✅ Existierendes Zertifikat gefunden:" -ForegroundColor Green
    Write-Host "   Subject: $($existingCert.Subject)"
    Write-Host "   Thumbprint: $($existingCert.Thumbprint)"
    Write-Host "   Gültig bis: $($existingCert.NotAfter)"
    
    $useExisting = Read-Host "`nVorhandenes Zertifikat verwenden? (J/N)"
    if ($useExisting -eq "J" -or $useExisting -eq "j" -or $useExisting -eq "Y" -or $useExisting -eq "y") {
        $cert = $existingCert
    } else {
        $cert = $null
    }
} else {
    $cert = $null
}

# 2. Erstelle neues Zertifikat falls nötig
if (-not $cert) {
    Write-Host "`n🔧 Erstelle neues Self-Signed Zertifikat..."
    
    try {
        $cert = New-SelfSignedCertificate `
            -Subject "CN=Hellion Power Tool,O=Open Source Project,C=DE" `
            -Type CodeSigning `
            -KeyUsage DigitalSignature `
            -FriendlyName "Hellion Power Tool Code Signing Certificate" `
            -NotAfter (Get-Date).AddYears(3) `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable
            
        Write-Host "✅ Zertifikat erfolgreich erstellt!" -ForegroundColor Green
        Write-Host "   Subject: $($cert.Subject)"
        Write-Host "   Thumbprint: $($cert.Thumbprint)"
        Write-Host "   Gültig bis: $($cert.NotAfter)"
    } catch {
        Write-Error "❌ Fehler beim Erstellen des Zertifikats: $($_.Exception.Message)"
        exit 1
    }
}

# 3. Exportiere Zertifikat für User-Verifikation
Write-Host "`n📄 Exportiere Zertifikat für Benutzer..."
try {
    $certPath = Join-Path $PSScriptRoot "..\hellion-certificate.cer"
    Export-Certificate -Cert $cert -FilePath $certPath -Force | Out-Null
    Write-Host "✅ Zertifikat exportiert: $certPath" -ForegroundColor Green
} catch {
    Write-Warning "⚠️ Zertifikat-Export fehlgeschlagen: $($_.Exception.Message)"
}

if ($TestOnly) {
    Write-Host "`n✅ Test-Modus: Zertifikat erstellt, aber keine Dateien signiert." -ForegroundColor Yellow
    Write-Host "Verwende '-TestOnly:$false' um tatsächlich zu signieren." -ForegroundColor Yellow
    exit 0
}

# 4. Finde alle PowerShell-Dateien
Write-Host "`n🔍 Suche PowerShell-Dateien zum Signieren..."
$rootPath = Split-Path $PSScriptRoot -Parent
$psFiles = Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    # Ausschlüsse
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\old-versions\*" -and
    $_.FullName -notlike "*\backup\*"
}

Write-Host "📊 Gefundene Dateien: $($psFiles.Count)" -ForegroundColor Cyan
$psFiles | ForEach-Object {
    $relativePath = $_.FullName.Replace($rootPath, "").TrimStart('\')
    Write-Host "   - $relativePath"
}

if ($psFiles.Count -eq 0) {
    Write-Host "❌ Keine PowerShell-Dateien gefunden!" -ForegroundColor Red
    exit 1
}

# 5. Signiere alle Dateien
Write-Host "`n✍️ Beginne Signierung..."
$signedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($file in $psFiles) {
    $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
    
    try {
        # Prüfe ob bereits signiert
        $existingSignature = Get-AuthenticodeSignature $file.FullName
        if ($existingSignature.Status -eq "Valid" -and -not $Force) {
            Write-Host "⏭️ Übersprungen (bereits signiert): $relativePath" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        # Signiere Datei
        $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert
        
        if ($result.Status -eq "Valid") {
            Write-Host "✅ Signiert: $relativePath" -ForegroundColor Green
            $signedCount++
        } else {
            Write-Host "❌ Signierung fehlgeschlagen: $relativePath - Status: $($result.Status)" -ForegroundColor Red
            $failedCount++
        }
    } catch {
        Write-Host "❌ Fehler bei $relativePath`: $($_.Exception.Message)" -ForegroundColor Red
        $failedCount++
    }
}

# 6. Zusammenfassung
Write-Host "`n📊 SIGNIERUNG ABGESCHLOSSEN" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "✅ Erfolgreich signiert: $signedCount" -ForegroundColor Green
Write-Host "⏭️ Übersprungen: $skippedCount" -ForegroundColor Yellow
Write-Host "❌ Fehlgeschlagen: $failedCount" -ForegroundColor Red
Write-Host "📄 Gesamt verarbeitet: $($psFiles.Count)"

if ($failedCount -eq 0) {
    Write-Host "`n🎉 Alle Dateien erfolgreich verarbeitet!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Einige Dateien konnten nicht signiert werden." -ForegroundColor Yellow
}

# 7. Verifikation
Write-Host "`n🔍 Verifikation der Signaturen..."
$validCount = 0
Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\old-versions\*"
} | ForEach-Object {
    $signature = Get-AuthenticodeSignature $_.FullName
    $relativePath = $_.FullName.Replace($rootPath, "").TrimStart('\')
    
    switch ($signature.Status) {
        "Valid" {
            Write-Host "✅ $relativePath" -ForegroundColor Green
            $validCount++
        }
        "NotSigned" {
            Write-Host "⚪ $relativePath (nicht signiert)" -ForegroundColor Gray
        }
        default {
            Write-Host "❌ $relativePath ($($signature.Status))" -ForegroundColor Red
        }
    }
}

Write-Host "`n🎯 ENDERGEBNIS: $validCount von $($psFiles.Count) Dateien haben gültige Signaturen" -ForegroundColor Cyan

# 8. Nächste Schritte
Write-Host "`n🚀 NÄCHSTE SCHRITTE:" -ForegroundColor Cyan
Write-Host "1. Teste das Tool: .\launcher\simple-launcher.bat"
Write-Host "2. Prüfe Signatur: Get-AuthenticodeSignature .\hellion_tool_main.ps1" 
Write-Host "3. Erstelle Release: GitHub Actions Workflow ausführen"
Write-Host "4. Installiere Zertifikat (optional): Doppelklick auf hellion-certificate.cer"

Write-Host "`n✅ Lokale Code-Signierung abgeschlossen!" -ForegroundColor Green