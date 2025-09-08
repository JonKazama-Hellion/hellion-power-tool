# Hellion Power Tool - Signatur-Test
# Dieses Script testet die Signaturen aller PowerShell-Dateien

Write-Host "🔍 Hellion Power Tool - Signatur-Verifikation" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$rootPath = Split-Path $PSScriptRoot -Parent
$totalFiles = 0
$signedFiles = 0
$validSigned = 0
$invalidSigned = 0

Write-Host "`n📂 Analysiere Verzeichnis: $rootPath"

# Sammle alle PowerShell-Dateien
$psFiles = Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\old-versions\*" -and 
    $_.FullName -notlike "*\backup\*"
}

Write-Host "📊 Gefundene PowerShell-Dateien: $($psFiles.Count)"

if ($psFiles.Count -eq 0) {
    Write-Host "❌ Keine PowerShell-Dateien gefunden!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 SIGNATUR-ANALYSE:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

foreach ($file in $psFiles) {
    $totalFiles++
    $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
    
    try {
        $signature = Get-AuthenticodeSignature $file.FullName
        
        switch ($signature.Status) {
            "Valid" {
                Write-Host "✅ $relativePath" -ForegroundColor Green
                Write-Host "   └─ Signer: $($signature.SignerCertificate.Subject.Split(',')[0])" -ForegroundColor DarkGreen
                $signedFiles++
                $validSigned++
            }
            "NotSigned" {
                Write-Host "⚪ $relativePath (nicht signiert)" -ForegroundColor Gray
            }
            "HashMismatch" {
                Write-Host "❌ $relativePath (Hash-Fehler - Datei verändert nach Signierung?)" -ForegroundColor Red
                $signedFiles++
                $invalidSigned++
            }
            "UnknownError" {
                Write-Host "❌ $relativePath (unbekannter Fehler)" -ForegroundColor Red
                $signedFiles++
                $invalidSigned++
            }
            default {
                Write-Host "⚠️ $relativePath (Status: $($signature.Status))" -ForegroundColor Yellow
                $signedFiles++
                $invalidSigned++
            }
        }
    } catch {
        Write-Host "❌ $relativePath (Fehler beim Lesen der Signatur)" -ForegroundColor Red
    }
}

# Zusammenfassung
Write-Host "`n📊 ZUSAMMENFASSUNG:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "📄 Dateien gesamt: $totalFiles"
Write-Host "✅ Gültig signiert: $validSigned" -ForegroundColor Green
Write-Host "❌ Ungültig signiert: $invalidSigned" -ForegroundColor Red
Write-Host "⚪ Nicht signiert: $($totalFiles - $signedFiles)" -ForegroundColor Gray

$signedPercentage = if ($totalFiles -gt 0) { [math]::Round(($validSigned / $totalFiles) * 100, 1) } else { 0 }
Write-Host "🎯 Signierungsgrad: $signedPercentage%" -ForegroundColor Cyan

# Empfehlungen
Write-Host "`n💡 EMPFEHLUNGEN:" -ForegroundColor Yellow
if ($validSigned -eq $totalFiles) {
    Write-Host "🎉 Perfekt! Alle Dateien sind gültig signiert." -ForegroundColor Green
    Write-Host "✅ Ready for Release!"
} elseif ($validSigned -eq 0) {
    Write-Host "🔧 Noch keine Dateien signiert." -ForegroundColor Yellow
    Write-Host "▶️ Führe aus: .\scripts\sign-local.ps1"
} else {
    Write-Host "⚠️ Nur teilweise signiert ($signedPercentage%)." -ForegroundColor Yellow
    Write-Host "▶️ Führe aus: .\scripts\sign-local.ps1 -Force"
}

if ($invalidSigned -gt 0) {
    Write-Host "⚠️ Ungültige Signaturen gefunden!" -ForegroundColor Red
    Write-Host "▶️ Führe aus: .\scripts\sign-local.ps1 -Force"
}

# Zertifikat-Info
Write-Host "`n🔐 ZERTIFIKAT-INFO:" -ForegroundColor Cyan
$hellionCerts = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Hellion Power Tool*" }
if ($hellionCerts) {
    foreach ($cert in $hellionCerts) {
        Write-Host "📜 Hellion Zertifikat gefunden:"
        Write-Host "   Subject: $($cert.Subject)"
        Write-Host "   Thumbprint: $($cert.Thumbprint)"
        Write-Host "   Gültig bis: $($cert.NotAfter)"
        
        $daysLeft = ($cert.NotAfter - (Get-Date)).Days
        if ($daysLeft -lt 30) {
            Write-Host "   ⚠️ Läuft in $daysLeft Tagen ab!" -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ Noch $daysLeft Tage gültig" -ForegroundColor Green
        }
    }
} else {
    Write-Host "⚪ Kein Hellion-Zertifikat im lokalen Store gefunden."
    Write-Host "▶️ Erstelle Zertifikat: .\scripts\sign-local.ps1 -TestOnly"
}

Write-Host "`n✅ Signatur-Test abgeschlossen!" -ForegroundColor Green