# Hellion Power Tool - Lokale Code-Signierung
# Dieses Script signiert alle PowerShell-Dateien mit einem Self-Signed Zertifikat

param(
    [switch]$Force = $false,
    [switch]$TestOnly = $false
)

Write-Information "[INFO] Hellion Power Tool - Lokale Code-Signierung" -InformationAction Continue
Write-Information "[INFO] ================================================" -InformationAction Continue

# 1. Prüfe ob bereits ein Hellion-Zertifikat existiert
Write-Information "[INFO] Suche nach existierendem Hellion-Zertifikat..." -InformationAction Continue
$existingCert = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Hellion Power Tool*" }

if ($existingCert -and -not $Force) {
    Write-Information "[OK] Existierendes Zertifikat gefunden:" -InformationAction Continue
    Write-Information "[OK]    Subject: $($existingCert.Subject)" -InformationAction Continue
    Write-Information "[OK]    Thumbprint: $($existingCert.Thumbprint)" -InformationAction Continue
    Write-Information "[OK]    Gültig bis: $($existingCert.NotAfter)" -InformationAction Continue
    
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
    Write-Information "[INFO] Erstelle neues Self-Signed Zertifikat..." -InformationAction Continue
    
    try {
        $cert = New-SelfSignedCertificate `
            -Subject "CN=Hellion Power Tool,O=Open Source Project,C=DE" `
            -Type CodeSigning `
            -KeyUsage DigitalSignature `
            -FriendlyName "Hellion Power Tool Code Signing Certificate" `
            -NotAfter (Get-Date).AddYears(3) `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable
            
        Write-Information "[OK] Zertifikat erfolgreich erstellt!" -InformationAction Continue
        Write-Information "[OK]    Subject: $($cert.Subject)" -InformationAction Continue
        Write-Information "[OK]    Thumbprint: $($cert.Thumbprint)" -InformationAction Continue
        Write-Information "[OK]    Gültig bis: $($cert.NotAfter)" -InformationAction Continue
    } catch {
        Write-Error "❌ Fehler beim Erstellen des Zertifikats: $($_.Exception.Message)"
        exit 1
    }
}

# 3. Exportiere Zertifikat für User-Verifikation
Write-Information "[INFO] Exportiere Zertifikat für Benutzer..." -InformationAction Continue
try {
    $certPath = Join-Path $PSScriptRoot "..\hellion-certificate.cer"
    Export-Certificate -Cert $cert -FilePath $certPath -Force | Out-Null
    Write-Information "[OK] Zertifikat exportiert: $certPath" -InformationAction Continue
} catch {
    Write-Warning "⚠️ Zertifikat-Export fehlgeschlagen: $($_.Exception.Message)"
}

if ($TestOnly) {
    Write-Information "[WARN] Test-Modus: Zertifikat erstellt, aber keine Dateien signiert." -InformationAction Continue
    Write-Information "[TIP] Verwende '-TestOnly:$false' um tatsächlich zu signieren." -InformationAction Continue
    exit 0
}

# 4. Finde alle PowerShell-Dateien
Write-Information "[INFO] Suche PowerShell-Dateien zum Signieren..." -InformationAction Continue
$rootPath = Split-Path $PSScriptRoot -Parent
$psFiles = Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    # Ausschlüsse
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\old-versions\*" -and
    $_.FullName -notlike "*\backup\*"
}

Write-Information "[INFO] Gefundene Dateien: $($psFiles.Count)" -InformationAction Continue
$psFiles | ForEach-Object {
    $relativePath = $_.FullName.Replace($rootPath, "").TrimStart('\')
    Write-Information "[INFO]    - $relativePath" -InformationAction Continue
}

if ($psFiles.Count -eq 0) {
    Write-Error "Keine PowerShell-Dateien gefunden!"
    exit 1
}

# 5. Signiere alle Dateien
Write-Information "[INFO] Beginne Signierung..." -InformationAction Continue
$signedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($file in $psFiles) {
    $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
    
    try {
        # Prüfe ob bereits signiert
        $existingSignature = Get-AuthenticodeSignature $file.FullName
        if ($existingSignature.Status -eq "Valid" -and -not $Force) {
            Write-Information "[SKIP] Übersprungen (bereits signiert): $relativePath" -InformationAction Continue
            $skippedCount++
            continue
        }
        
        # Signiere Datei
        $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert
        
        if ($result.Status -eq "Valid") {
            Write-Information "[OK] Signiert: $relativePath" -InformationAction Continue
            $signedCount++
        } else {
            Write-Warning "Signierung fehlgeschlagen: $relativePath - Status: $($result.Status)"
            $failedCount++
        }
    } catch {
        Write-Warning "Fehler bei $relativePath`: $($_.Exception.Message)"
        $failedCount++
    }
}

# 6. Zusammenfassung
Write-Information "[INFO] SIGNIERUNG ABGESCHLOSSEN" -InformationAction Continue
Write-Information "[INFO] =========================" -InformationAction Continue
Write-Information "[OK] Erfolgreich signiert: $signedCount" -InformationAction Continue
Write-Information "[SKIP] Übersprungen: $skippedCount" -InformationAction Continue
Write-Information "[FAIL] Fehlgeschlagen: $failedCount" -InformationAction Continue
Write-Information "[INFO] Gesamt verarbeitet: $($psFiles.Count)" -InformationAction Continue

if ($failedCount -eq 0) {
    Write-Information "[OK] Alle Dateien erfolgreich verarbeitet!" -InformationAction Continue
} else {
    Write-Warning "Einige Dateien konnten nicht signiert werden."
}

# 7. Verifikation
Write-Information "[INFO] Verifikation der Signaturen..." -InformationAction Continue
$validCount = 0
Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\old-versions\*"
} | ForEach-Object {
    $signature = Get-AuthenticodeSignature $_.FullName
    $relativePath = $_.FullName.Replace($rootPath, "").TrimStart('\')
    
    switch ($signature.Status) {
        "Valid" {
            Write-Information "[OK] $relativePath" -InformationAction Continue
            $validCount++
        }
        "NotSigned" {
            Write-Information "[WARN] $relativePath (nicht signiert)" -InformationAction Continue
        }
        default {
            Write-Warning "$relativePath ($($signature.Status))"
        }
    }
}

Write-Information "[RESULT] ENDERGEBNIS: $validCount von $($psFiles.Count) Dateien haben gültige Signaturen" -InformationAction Continue

# 8. Nächste Schritte
Write-Information "[INFO] NÄCHSTE SCHRITTE:" -InformationAction Continue
Write-Information "[TIP] 1. Teste das Tool: .\launcher\simple-launcher.bat" -InformationAction Continue
Write-Information "[TIP] 2. Prüfe Signatur: Get-AuthenticodeSignature .\hellion_tool_main.ps1" -InformationAction Continue 
Write-Information "[TIP] 3. Erstelle Release: GitHub Actions Workflow ausführen" -InformationAction Continue
Write-Information "[TIP] 4. Installiere Zertifikat (optional): Doppelklick auf hellion-certificate.cer" -InformationAction Continue

Write-Information "[OK] Lokale Code-Signierung abgeschlossen!" -InformationAction Continue