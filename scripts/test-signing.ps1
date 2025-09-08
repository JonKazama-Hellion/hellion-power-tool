# Hellion Power Tool - Signatur-Test
# Dieses Script testet die Signaturen aller PowerShell-Dateien

Write-Information "[INFO] Hellion Power Tool - Signatur-Verifikation" -InformationAction Continue
Write-Information "[INFO] =============================================" -InformationAction Continue

$rootPath = Split-Path $PSScriptRoot -Parent
$totalFiles = 0
$signedFiles = 0
$validSigned = 0
$invalidSigned = 0

Write-Information "[INFO] Analysiere Verzeichnis: $rootPath" -InformationAction Continue

# Sammle alle PowerShell-Dateien
$psFiles = Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\old-versions\*" -and 
    $_.FullName -notlike "*\backup\*"
}

Write-Information "[INFO] Gefundene PowerShell-Dateien: $($psFiles.Count)" -InformationAction Continue

if ($psFiles.Count -eq 0) {
    Write-Error "Keine PowerShell-Dateien gefunden!"
    exit 1
}

Write-Information "[INFO] SIGNATUR-ANALYSE:" -InformationAction Continue
Write-Information "[INFO] ===================" -InformationAction Continue

foreach ($file in $psFiles) {
    $totalFiles++
    $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
    
    try {
        $signature = Get-AuthenticodeSignature $file.FullName
        
        switch ($signature.Status) {
            "Valid" {
                Write-Information "[OK] $relativePath" -InformationAction Continue
                Write-Information "[OK]    Signer: $($signature.SignerCertificate.Subject.Split(',')[0])" -InformationAction Continue
                $signedFiles++
                $validSigned++
            }
            "NotSigned" {
                Write-Information "[WARN] $relativePath (nicht signiert)" -InformationAction Continue
            }
            "HashMismatch" {
                Write-Warning "$relativePath (Hash-Fehler - Datei verändert nach Signierung?)"
                $signedFiles++
                $invalidSigned++
            }
            "UnknownError" {
                Write-Warning "$relativePath (unbekannter Fehler)"
                $signedFiles++
                $invalidSigned++
            }
            default {
                Write-Warning "$relativePath (Status: $($signature.Status))"
                $signedFiles++
                $invalidSigned++
            }
        }
    } catch {
        Write-Warning "$relativePath (Fehler beim Lesen der Signatur)"
    }
}

# Zusammenfassung
Write-Information "[INFO] ZUSAMMENFASSUNG:" -InformationAction Continue
Write-Information "[INFO] ==================" -InformationAction Continue
Write-Information "[INFO] Dateien gesamt: $totalFiles" -InformationAction Continue
Write-Information "[OK] Gültig signiert: $validSigned" -InformationAction Continue
Write-Information "[FAIL] Ungültig signiert: $invalidSigned" -InformationAction Continue
Write-Information "[WARN] Nicht signiert: $($totalFiles - $signedFiles)" -InformationAction Continue

$signedPercentage = if ($totalFiles -gt 0) { [math]::Round(($validSigned / $totalFiles) * 100, 1) } else { 0 }
Write-Information "[INFO] Signierungsgrad: $signedPercentage%" -InformationAction Continue

# Empfehlungen
Write-Information "[INFO] EMPFEHLUNGEN:" -InformationAction Continue
if ($validSigned -eq $totalFiles) {
    Write-Information "[OK] Perfekt! Alle Dateien sind gültig signiert." -InformationAction Continue
    Write-Information "[OK] Ready for Release!" -InformationAction Continue
} elseif ($validSigned -eq 0) {
    Write-Information "[WARN] Noch keine Dateien signiert." -InformationAction Continue
    Write-Information "[TIP] Führe aus: .\scripts\sign-local.ps1" -InformationAction Continue
} else {
    Write-Information "[WARN] Nur teilweise signiert ($signedPercentage%)." -InformationAction Continue
    Write-Information "[TIP] Führe aus: .\scripts\sign-local.ps1 -Force" -InformationAction Continue
}

if ($invalidSigned -gt 0) {
    Write-Warning "Ungültige Signaturen gefunden!"
    Write-Information "[TIP] Führe aus: .\scripts\sign-local.ps1 -Force" -InformationAction Continue
}

# Zertifikat-Info
Write-Information "[INFO] ZERTIFIKAT-INFO:" -InformationAction Continue
$hellionCerts = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Hellion Power Tool*" }
if ($hellionCerts) {
    foreach ($cert in $hellionCerts) {
        Write-Information "[INFO] Hellion Zertifikat gefunden:" -InformationAction Continue
        Write-Information "[INFO]    Subject: $($cert.Subject)" -InformationAction Continue
        Write-Information "[INFO]    Thumbprint: $($cert.Thumbprint)" -InformationAction Continue
        Write-Information "[INFO]    Gültig bis: $($cert.NotAfter)" -InformationAction Continue
        
        $daysLeft = ($cert.NotAfter - (Get-Date)).Days
        if ($daysLeft -lt 30) {
            Write-Warning "Läuft in $daysLeft Tagen ab!"
        } else {
            Write-Information "[OK]    Noch $daysLeft Tage gültig" -InformationAction Continue
        }
    }
} else {
    Write-Information "[WARN] Kein Hellion-Zertifikat im lokalen Store gefunden." -InformationAction Continue
    Write-Information "[TIP] Erstelle Zertifikat: .\scripts\sign-local.ps1 -TestOnly" -InformationAction Continue
}

Write-Information "[OK] Signatur-Test abgeschlossen!" -InformationAction Continue