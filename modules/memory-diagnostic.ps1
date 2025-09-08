# =============================================================================
# WINDOWS MEMORY DIAGNOSTIC MODULE - ROBUST & DEFENDER-SAFE
# Sicherer RAM-Test mit Wiederherstellungspunkt
# =============================================================================

function Start-WindowsMemoryDiagnostic {
    Write-Host "`n=== WINDOWS SPEICHER-DIAGNOSE ===" -ForegroundColor Cyan
    Write-Host "Überprüft RAM auf Hardwarefehler mittels Windows-eigenem Tool" -ForegroundColor Gray
    Write-Host ""
    
    # WICHTIGE WARNUNGEN
    Write-Host "⚠️  WICHTIGE HINWEISE:" -ForegroundColor Yellow
    Write-Host "   • System wird automatisch NEU GESTARTET" -ForegroundColor Red
    Write-Host "   • RAM-Test läuft VOR Windows-Start (ca. 10-20 Minuten)" -ForegroundColor Yellow
    Write-Host "   • Alle offenen Programme werden beendet" -ForegroundColor Yellow
    Write-Host "   • Test-Ergebnisse nach Neustart im Ereignisprotokoll" -ForegroundColor Cyan
    Write-Host ""
    
    # Admin-Check
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[ERROR] Administrator-Rechte erforderlich für Speicher-Test!" -ForegroundColor Red
        return $false
    }
    
    # Prüfe ob mdsched.exe verfügbar ist
    $mdsched = Get-Command "mdsched.exe" -ErrorAction SilentlyContinue
    if (-not $mdsched) {
        Write-Host "[ERROR] Windows Memory Diagnostic nicht gefunden!" -ForegroundColor Red
        Write-Host "[INFO] Normalerweise unter C:\Windows\System32\mdsched.exe" -ForegroundColor Gray
        return $false
    }
    
    Write-Host "[OK] Windows Memory Diagnostic gefunden: $($mdsched.Source)" -ForegroundColor Green
    Write-Host ""
    
    # Erste Bestätigung
    Write-Host "🔄 RAM-TEST DURCHFÜHREN?" -ForegroundColor Cyan
    Write-Host "   [J] Ja - Starte RAM-Test (System wird neu gestartet)" -ForegroundColor Green
    Write-Host "   [N] Nein - Zurück zum Hauptmenü" -ForegroundColor Gray
    Write-Host ""
    
    $choice1 = Read-Host "RAM-Test starten? [J/N]"
    if ($choice1 -notmatch "^[JjYy]") {
        Write-Host "[ABGEBROCHEN] RAM-Test nicht gestartet" -ForegroundColor Yellow
        return $false
    }
    
    # Wiederherstellungspunkt erstellen
    Write-Host ""
    Write-Host "💾 WIEDERHERSTELLUNGSPUNKT ERSTELLEN?" -ForegroundColor Cyan
    Write-Host "   Empfohlen als Sicherheitsmaßnahme vor System-Tests" -ForegroundColor Yellow
    Write-Host ""
    
    $choice2 = Read-Host "Wiederherstellungspunkt erstellen? [J/N]"
    if ($choice2 -match "^[JjYy]") {
        Write-Host ""
        Write-Host "[*] Erstelle Wiederherstellungspunkt..." -ForegroundColor Blue
        
        try {
            # Prüfe ob System Restore aktiviert ist
            $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
            if ($null -eq $restoreEnabled) {
                Write-Host "[WARNING] Systemwiederherstellung scheint deaktiviert zu sein" -ForegroundColor Yellow
                Write-Host "[INFO] Wiederherstellungspunkt kann nicht erstellt werden" -ForegroundColor Gray
            } else {
                # Erstelle Wiederherstellungspunkt
                $restoreDescription = "Hellion Tool - Vor RAM-Test $(Get-Date -Format 'dd.MM.yyyy HH:mm')"
                Checkpoint-Computer -Description $restoreDescription -RestorePointType "MODIFY_SETTINGS"
                Write-Host "[OK] Wiederherstellungspunkt erstellt: $restoreDescription" -ForegroundColor Green
            }
        } catch {
            Write-Host "[WARNING] Wiederherstellungspunkt konnte nicht erstellt werden: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "[INFO] RAM-Test kann trotzdem sicher durchgeführt werden" -ForegroundColor Gray
        }
    }
    
    # Letzte Warnung und Bestätigung
    Write-Host ""
    Write-Host "⚠️  LETZTE BESTÄTIGUNG:" -ForegroundColor Red
    Write-Host "   • ALLE OFFENEN PROGRAMME SPEICHERN UND SCHLIESSEN!" -ForegroundColor Red
    Write-Host "   • System startet in ca. 5 Sekunden automatisch neu" -ForegroundColor Yellow
    Write-Host "   • RAM-Test läuft beim Systemstart (10-20 Minuten)" -ForegroundColor Yellow
    Write-Host ""
    
    $finalChoice = Read-Host "WIRKLICH JETZT NEU STARTEN? [J/N]"
    if ($finalChoice -notmatch "^[JjYy]") {
        Write-Host "[ABGEBROCHEN] RAM-Test nicht gestartet" -ForegroundColor Yellow
        return $false
    }
    
    # RAM-Test starten
    Write-Host ""
    Write-Host "[*] Starte Windows Memory Diagnostic..." -ForegroundColor Blue
    Write-Host "[*] System wird in 5 Sekunden neu gestartet..." -ForegroundColor Yellow
    
    # Countdown
    for ($i = 5; $i -gt 0; $i--) {
        Write-Host "   Neustart in $i Sekunden..." -ForegroundColor Red
        [System.Threading.Thread]::Sleep(1000)  # Defender-safe delay
    }
    
    try {
        # Starte Memory Diagnostic (automatischer Neustart)
        Write-Host ""
        Write-Host "[STARTING] Windows Memory Diagnostic wird gestartet..." -ForegroundColor Green
        
        # mdsched.exe startet automatisch den Neustart-Prozess
        Start-Process "mdsched.exe" -ErrorAction Stop
        
        Write-Host "[OK] Memory Diagnostic gestartet - System startet automatisch neu" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 NACH DEM RAM-TEST:" -ForegroundColor Cyan
        Write-Host "   • Windows startet normal" -ForegroundColor Gray
        Write-Host "   • Ergebnisse im Ereignisprotokoll (eventvwr.msc)" -ForegroundColor Gray
        Write-Host "   • Pfad: Windows-Protokolle → System → Quelle 'MemoryDiagnostics-Results'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🔍 ERGEBNISSE INTERPRETIEREN:" -ForegroundColor Cyan
        Write-Host "   • Keine Fehler = RAM ist OK" -ForegroundColor Green
        Write-Host "   • Fehler gefunden = RAM-Modul defekt" -ForegroundColor Red
        Write-Host "   • Bei Fehlern: RAM-Module einzeln testen/ersetzen" -ForegroundColor Yellow
        
        return $true
        
    } catch {
        Write-Host "[ERROR] Memory Diagnostic konnte nicht gestartet werden: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[INFO] Versuche manuell: Windows-Taste + R → 'mdsched.exe'" -ForegroundColor Gray
        return $false
    }
}

function Get-MemoryTestResults {
    Write-Host "`n=== SPEICHER-TEST ERGEBNISSE ===" -ForegroundColor Cyan
    Write-Host "Zeigt Ergebnisse des letzten RAM-Tests" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Suche nach Memory Diagnostic Einträgen im Ereignisprotokoll
        $memoryEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
        } -MaxEvents 5 -ErrorAction SilentlyContinue
        
        if ($memoryEvents) {
            Write-Host "[OK] Speicher-Test Ergebnisse gefunden:" -ForegroundColor Green
            Write-Host ""
            
            foreach ($event in $memoryEvents) {
                Write-Host "🕐 Datum: $($event.TimeCreated.ToString('dd.MM.yyyy HH:mm:ss'))" -ForegroundColor Cyan
                Write-Host "📝 Nachricht:" -ForegroundColor Yellow
                Write-Host "   $($event.Message)" -ForegroundColor White
                Write-Host ""
                
                # Interpretiere Ergebnis
                if ($event.Message -match "no memory errors" -or $event.Message -match "keine.*fehler") {
                    Write-Host "✅ ERGEBNIS: RAM ist in Ordnung (keine Fehler)" -ForegroundColor Green
                } elseif ($event.Message -match "error" -or $event.Message -match "fehler") {
                    Write-Host "❌ ERGEBNIS: RAM-Fehler erkannt - Hardware-Problem!" -ForegroundColor Red
                    Write-Host "   → Empfehlung: RAM-Module einzeln testen/ersetzen" -ForegroundColor Yellow
                } else {
                    Write-Host "ℹ️  ERGEBNIS: Test abgeschlossen - siehe Details oben" -ForegroundColor Blue
                }
                Write-Host ""
            }
        } else {
            Write-Host "[INFO] Keine aktuellen Speicher-Test Ergebnisse gefunden" -ForegroundColor Yellow
            Write-Host "[TIPP] Führe erst einen RAM-Test durch (Option vorher)" -ForegroundColor Gray
        }
        
        Write-Host "🔍 MANUELLER ZUGRIFF:" -ForegroundColor Cyan
        Write-Host "   Windows-Taste + R → 'eventvwr.msc'" -ForegroundColor Gray
        Write-Host "   → Windows-Protokolle → System" -ForegroundColor Gray
        Write-Host "   → Filter: Quelle = 'MemoryDiagnostics-Results'" -ForegroundColor Gray
        
    } catch {
        Write-Host "[ERROR] Ereignisprotokoll konnte nicht gelesen werden: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[LÖSUNG] Manuell prüfen: eventvwr.msc → System → MemoryDiagnostics-Results" -ForegroundColor Yellow
    }
}

# Export-Funktionen für das Hauptmenü
Write-Verbose "Memory Diagnostic Module loaded: Start-WindowsMemoryDiagnostic, Get-MemoryTestResults"