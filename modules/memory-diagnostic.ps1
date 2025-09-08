# =============================================================================
# WINDOWS MEMORY DIAGNOSTIC MODULE - ROBUST & DEFENDER-SAFE
# Sicherer RAM-Test mit Wiederherstellungspunkt
# =============================================================================

function Start-WindowsMemoryDiagnostic {
    Write-Information "[INFO] === WINDOWS SPEICHER-DIAGNOSE ===" -InformationAction Continue
    Write-Information "[INFO] Überprüft RAM auf Hardwarefehler mittels Windows-eigenem Tool" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    # WICHTIGE WARNUNGEN
    Write-Warning "WICHTIGE HINWEISE:"
    Write-Warning "   • System wird automatisch NEU GESTARTET"
    Write-Warning "   • RAM-Test läuft VOR Windows-Start (ca. 10-20 Minuten)"
    Write-Warning "   • Alle offenen Programme werden beendet"
    Write-Information "[INFO]    • Test-Ergebnisse nach Neustart im Ereignisprotokoll" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    # Admin-Check
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Administrator-Rechte erforderlich für Speicher-Test!"
        return $false
    }
    
    # Prüfe ob mdsched.exe verfügbar ist
    $mdsched = Get-Command "mdsched.exe" -ErrorAction SilentlyContinue
    if (-not $mdsched) {
        Write-Error "Windows Memory Diagnostic nicht gefunden!"
        Write-Information "[INFO] Normalerweise unter C:\Windows\System32\mdsched.exe" -InformationAction Continue
        return $false
    }
    
    Write-Information "[OK] Windows Memory Diagnostic gefunden: $($mdsched.Source)" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    # Erste Bestätigung
    Write-Information "[INFO] 🔄 RAM-TEST DURCHFÜHREN?" -InformationAction Continue
    Write-Information "[INFO]    [J] Ja - Starte RAM-Test (System wird neu gestartet)" -InformationAction Continue
    Write-Information "[INFO]    [N] Nein - Zurück zum Hauptmenü" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    $choice1 = Read-Host "RAM-Test starten? [J/N]"
    if ($choice1 -notmatch "^[JjYy]") {
        Write-Information "[INFO] [ABGEBROCHEN] RAM-Test nicht gestartet" -InformationAction Continue
        return $false
    }
    
    # Wiederherstellungspunkt erstellen
    Write-Information "[INFO] " -InformationAction Continue
    Write-Information "[INFO] 💾 WIEDERHERSTELLUNGSPUNKT ERSTELLEN?" -InformationAction Continue
    Write-Information "[INFO]    Empfohlen als Sicherheitsmaßnahme vor System-Tests" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    $choice2 = Read-Host "Wiederherstellungspunkt erstellen? [J/N]"
    if ($choice2 -match "^[JjYy]") {
        Write-Information "[INFO] " -InformationAction Continue
        Write-Information "[INFO] [*] Erstelle Wiederherstellungspunkt..." -InformationAction Continue
        
        try {
            # Prüfe ob System Restore aktiviert ist
            $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
            if ($null -eq $restoreEnabled) {
                Write-Warning "Systemwiederherstellung scheint deaktiviert zu sein"
                Write-Information "[INFO] Wiederherstellungspunkt kann nicht erstellt werden" -InformationAction Continue
            } else {
                # Erstelle Wiederherstellungspunkt
                $restoreDescription = "Hellion Tool - Vor RAM-Test $(Get-Date -Format 'dd.MM.yyyy HH:mm')"
                Checkpoint-Computer -Description $restoreDescription -RestorePointType "MODIFY_SETTINGS"
                Write-Information "[OK] Wiederherstellungspunkt erstellt: $restoreDescription" -InformationAction Continue
            }
        } catch {
            Write-Warning "Wiederherstellungspunkt konnte nicht erstellt werden: $($_.Exception.Message)"
            Write-Information "[INFO] RAM-Test kann trotzdem sicher durchgeführt werden" -InformationAction Continue
        }
    }
    
    # Letzte Warnung und Bestätigung
    Write-Information "[INFO] " -InformationAction Continue
    Write-Information "[INFO] ⚠️  LETZTE BESTÄTIGUNG:" -InformationAction Continue
    Write-Information "[INFO]    • ALLE OFFENEN PROGRAMME SPEICHERN UND SCHLIESSEN!" -InformationAction Continue
    Write-Information "[INFO]    • System startet in ca. 5 Sekunden automatisch neu" -InformationAction Continue
    Write-Information "[INFO]    • RAM-Test läuft beim Systemstart (10-20 Minuten)" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    $finalChoice = Read-Host "WIRKLICH JETZT NEU STARTEN? [J/N]"
    if ($finalChoice -notmatch "^[JjYy]") {
        Write-Information "[INFO] [ABGEBROCHEN] RAM-Test nicht gestartet" -InformationAction Continue
        return $false
    }
    
    # RAM-Test starten
    Write-Information "[INFO] " -InformationAction Continue
    Write-Information "[INFO] [*] Starte Windows Memory Diagnostic..." -InformationAction Continue
    Write-Information "[INFO] [*] System wird in 5 Sekunden neu gestartet..." -InformationAction Continue
    
    # Countdown
    for ($i = 5; $i -gt 0; $i--) {
        Write-Information "[INFO]    Neustart in $i Sekunden..." -InformationAction Continue
        [System.Threading.Thread]::Sleep(1000)  # Defender-safe delay
    }
    
    try {
        # Starte Memory Diagnostic (automatischer Neustart)
        Write-Information "[INFO] " -InformationAction Continue
        Write-Information "[INFO] [STARTING] Windows Memory Diagnostic wird gestartet..." -InformationAction Continue
        
        # mdsched.exe startet automatisch den Neustart-Prozess
        Start-Process "mdsched.exe" -ErrorAction Stop
        
        Write-Information "[OK] Memory Diagnostic gestartet - System startet automatisch neu" -InformationAction Continue
        Write-Information "[INFO] " -InformationAction Continue
        Write-Information "[INFO] 📋 NACH DEM RAM-TEST:" -InformationAction Continue
        Write-Information "[INFO]    • Windows startet normal" -InformationAction Continue
        Write-Information "[INFO]    • Ergebnisse im Ereignisprotokoll (eventvwr.msc)" -InformationAction Continue
        Write-Information "[INFO]    • Pfad: Windows-Protokolle → System → Quelle 'MemoryDiagnostics-Results'" -InformationAction Continue
        Write-Information "[INFO] " -InformationAction Continue
        Write-Information "[INFO] 🔍 ERGEBNISSE INTERPRETIEREN:" -InformationAction Continue
        Write-Information "[INFO]    • Keine Fehler = RAM ist OK" -InformationAction Continue
        Write-Information "[INFO]    • Fehler gefunden = RAM-Modul defekt" -InformationAction Continue
        Write-Information "[INFO]    • Bei Fehlern: RAM-Module einzeln testen/ersetzen" -InformationAction Continue
        
        return $true
        
    } catch {
        Write-Error "Memory Diagnostic konnte nicht gestartet werden: $($_.Exception.Message)"
        Write-Information "[INFO] Versuche manuell: Windows-Taste + R → 'mdsched.exe'" -InformationAction Continue
        return $false
    }
}

function Get-MemoryTestResults {
    Write-Information "[INFO] `n=== SPEICHER-TEST ERGEBNISSE ===" -InformationAction Continue
    Write-Information "[INFO] Zeigt Ergebnisse des letzten RAM-Tests" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    try {
        # Suche nach Memory Diagnostic Einträgen im Ereignisprotokoll
        $memoryEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
        } -MaxEvents 5 -ErrorAction SilentlyContinue
        
        if ($memoryEvents) {
            Write-Information "[OK] Speicher-Test Ergebnisse gefunden:" -InformationAction Continue
            Write-Information "[INFO] " -InformationAction Continue
            
            foreach ($event in $memoryEvents) {
                Write-Information "[INFO] 🕐 Datum: $($event.TimeCreated.ToString('dd.MM.yyyy HH:mm:ss'))" -InformationAction Continue
                Write-Information "[INFO] 📝 Nachricht:" -InformationAction Continue
                Write-Information "[INFO]    $($event.Message)" -InformationAction Continue
                Write-Information "[INFO] " -InformationAction Continue
                
                # Interpretiere Ergebnis
                if ($event.Message -match "no memory errors" -or $event.Message -match "keine.*fehler") {
                    Write-Information "[INFO] ✅ ERGEBNIS: RAM ist in Ordnung (keine Fehler)" -InformationAction Continue
                } elseif ($event.Message -match "error" -or $event.Message -match "fehler") {
                    Write-Information "[INFO] ❌ ERGEBNIS: RAM-Fehler erkannt - Hardware-Problem!" -InformationAction Continue
                    Write-Information "[INFO]    → Empfehlung: RAM-Module einzeln testen/ersetzen" -InformationAction Continue
                } else {
                    Write-Information "[INFO] ℹ️  ERGEBNIS: Test abgeschlossen - siehe Details oben" -InformationAction Continue
                }
                Write-Information "[INFO] " -InformationAction Continue
            }
        } else {
            Write-Information "[INFO] Keine aktuellen Speicher-Test Ergebnisse gefunden" -InformationAction Continue
            Write-Information "[INFO] [TIPP] Führe erst einen RAM-Test durch (Option vorher)" -InformationAction Continue
        }
        
        Write-Information "[INFO] 🔍 MANUELLER ZUGRIFF:" -InformationAction Continue
        Write-Information "[INFO]    Windows-Taste + R → 'eventvwr.msc'" -InformationAction Continue
        Write-Information "[INFO]    → Windows-Protokolle → System" -InformationAction Continue
        Write-Information "[INFO]    → Filter: Quelle = 'MemoryDiagnostics-Results'" -InformationAction Continue
        
    } catch {
        Write-Error "Ereignisprotokoll konnte nicht gelesen werden: $($_.Exception.Message)"
        Write-Information "[INFO] [LÖSUNG] Manuell prüfen: eventvwr.msc → System → MemoryDiagnostics-Results" -InformationAction Continue
    }
}

# Export-Funktionen für das Hauptmenü
Write-Verbose "Memory Diagnostic Module loaded: Start-WindowsMemoryDiagnostic, Get-MemoryTestResults"
