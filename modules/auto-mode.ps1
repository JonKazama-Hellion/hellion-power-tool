# ===================================================================
# AUTO MODE MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Invoke-EnhancedAutoMode {
    Write-Log "`n[*] --- ERWEITERTER AUTO-MODUS ---" -Color Green
    Write-Log "Fuehrt alle empfohlenen Optimierungen automatisch durch" -Color Yellow
    
    $script:AutoApproveCleanup = $true
    $autoStartTime = Get-Date
    $autoResults = @{
        TotalActions = 0
        SuccessfulActions = 0
        FailedActions = 0
        FreedSpaceMB = 0
        Duration = 0
        ActionsPerformed = @()
    }
    
    Write-Information "[INFO] `n[*] AUTO-MODUS OPTIONEN:" -InformationAction Continue
    Write-Information "[INFO]   [1] Basis-Optimierung (Sicher)" -InformationAction Continue
    Write-Information "[INFO]   [2] Erweiterte Optimierung (Empfohlen)" -InformationAction Continue
    Write-Information "[INFO]   [3] Vollstaendige Optimierung (Alles)" -InformationAction Continue
    Write-Information "[INFO]   [x] Abbrechen" -InformationAction Continue
    
    $autoMode = Read-Host "`nWahl [1-3/x]"
    
    if ($autoMode -eq 'x' -or $autoMode -eq 'X') {
        Write-Log "[SKIP] Auto-Modus abgebrochen" -Color Gray
        return $false
    }
    
    # Wiederherstellungspunkt erstellen
    Write-Log "`n=== VORBEREITUNG ===" -Color Cyan
    if (Get-Command New-SystemRestorePoint -ErrorAction SilentlyContinue) {
        $restoreResult = New-SystemRestorePoint -Description "Auto-Modus (vor Optimierung)"
        if ($restoreResult) {
            $autoResults.ActionsPerformed += "Wiederherstellungspunkt erstellt"
            $autoResults.SuccessfulActions++
        }
    }
    
    # Basis-Aktionen (alle Modi)
    $autoResults.TotalActions++
    Write-Log "`n=== BASIS-OPTIMIERUNGEN ===" -Color Green
    
    # System File Checker
    if (Get-Command Invoke-SystemFileChecker -ErrorAction SilentlyContinue) {
        Write-Log "[*] Fuehre System File Checker aus..." -Color Blue
        try {
            # Automatischer SFC-Scan ohne Benutzerinteraktion
            $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
            if ($sfcProcess.ExitCode -eq 0) {
                $autoResults.ActionsPerformed += "SFC-Scan erfolgreich"
                $autoResults.SuccessfulActions++
            } else {
                $autoResults.ActionsPerformed += "SFC-Scan mit Warnungen"
                $autoResults.FailedActions++
            }
        } catch {
            $autoResults.ActionsPerformed += "SFC-Scan fehlgeschlagen"
            $autoResults.FailedActions++
        }
        $autoResults.TotalActions++
    }
    
    # System-Bereinigung
    if (Get-Command Invoke-ComprehensiveCleanup -ErrorAction SilentlyContinue) {
        Write-Log "[*] Fuehre System-Bereinigung aus..." -Color Blue
        $script:TotalFreedSpace = 0
        $cleanupResult = Invoke-ComprehensiveCleanup
        if ($cleanupResult) {
            $autoResults.FreedSpaceMB += $script:TotalFreedSpace
            $autoResults.ActionsPerformed += "System-Bereinigung ($($script:TotalFreedSpace) MB)"
            $autoResults.SuccessfulActions++
        } else {
            $autoResults.ActionsPerformed += "System-Bereinigung fehlgeschlagen"
            $autoResults.FailedActions++
        }
        $autoResults.TotalActions++
    }
    
    # Erweiterte Aktionen (Modus 2 und 3)
    if ($autoMode -ge 2) {
        Write-Log "`n=== ERWEITERTE OPTIMIERUNGEN ===" -Color Yellow
        
        # Performance-Optimierung
        if (Get-Command Optimize-SystemPerformance -ErrorAction SilentlyContinue) {
            Write-Log "[*] Fuehre Performance-Optimierung aus..." -Color Blue
            $perfResult = Optimize-SystemPerformance
            if ($perfResult) {
                $autoResults.ActionsPerformed += "Performance-Optimierung"
                $autoResults.SuccessfulActions++
            } else {
                $autoResults.ActionsPerformed += "Performance-Optimierung fehlgeschlagen"
                $autoResults.FailedActions++
            }
            $autoResults.TotalActions++
        }
        
        # DISM Health-Check
        if (Get-Command Invoke-DISMRepair -ErrorAction SilentlyContinue) {
            Write-Log "[*] Fuehre DISM Health-Check aus..." -Color Blue
            try {
                $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -Wait -PassThru -NoNewWindow
                if ($dismProcess.ExitCode -eq 0) {
                    $autoResults.ActionsPerformed += "DISM Health-Check erfolgreich"
                    $autoResults.SuccessfulActions++
                } else {
                    $autoResults.ActionsPerformed += "DISM Health-Check mit Warnungen"
                    $autoResults.FailedActions++
                }
            } catch {
                $autoResults.ActionsPerformed += "DISM Health-Check fehlgeschlagen"
                $autoResults.FailedActions++
            }
            $autoResults.TotalActions++
        }
        
        # DLL-Integrity Check
        if (Get-Command Test-DLLIntegrity -ErrorAction SilentlyContinue) {
            Write-Log "[*] Fuehre DLL-Integritaets-Check aus..." -Color Blue
            $dllResult = Test-DLLIntegrity
            if ($dllResult) {
                $autoResults.ActionsPerformed += "DLL-Integritaets-Check erfolgreich"
                $autoResults.SuccessfulActions++
            } else {
                $autoResults.ActionsPerformed += "DLL-Integritaets-Check: Probleme gefunden"
                $autoResults.FailedActions++
            }
            $autoResults.TotalActions++
        }
    }
    
    # Vollstaendige Optimierung (nur Modus 3)
    if ($autoMode -eq 3) {
        Write-Log "`n=== VOLLSTAENDIGE OPTIMIERUNG ===" -Color Red
        
        # Netzwerk-Test
        if (Get-Command Test-EnhancedInternetConnectivity -ErrorAction SilentlyContinue) {
            Write-Log "[*] Fuehre Netzwerk-Test aus..." -Color Blue
            $networkResult = Test-EnhancedInternetConnectivity
            if ($networkResult.Overall) {
                $autoResults.ActionsPerformed += "Netzwerk-Test erfolgreich"
                $autoResults.SuccessfulActions++
            } else {
                $autoResults.ActionsPerformed += "Netzwerk-Test: Probleme erkannt"
                $autoResults.FailedActions++
            }
            $autoResults.TotalActions++
        }
        
        # Safe Adblock (automatisch aktivieren)
        if (Get-Command Invoke-SafeAdblock -ErrorAction SilentlyContinue) {
            Write-Log "[*] Aktiviere Safe Adblock..." -Color Blue
            try {
                # Automatische Adblock-Aktivierung ohne Benutzerinteraktion
                $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
                $backupPath = "$env:SystemRoot\System32\drivers\etc\hosts.hellion.backup"
                
                if (-not (Test-Path $backupPath)) {
                    Copy-Item $hostsPath $backupPath -Force
                }
                
                # Vereinfachte Adblock-Domains hinzufügen
                $commonTrackers = @(
                    "doubleclick.net", "googleadservices.com", "googlesyndication.com",
                    "google-analytics.com", "facebook.com/tr", "scorecardresearch.com"
                )
                
                $hostsContent = Get-Content $hostsPath
                $addedCount = 0
                
                foreach ($domain in $commonTrackers) {
                    $domainBlocked = $hostsContent | Where-Object { $_ -match "127\.0\.0\.1\s+$([regex]::Escape($domain))" }
                    if (-not $domainBlocked) {
                        "127.0.0.1 $domain" | Add-Content -Path $hostsPath -Encoding UTF8
                        $addedCount++
                    }
                }
                
                if ($addedCount -gt 0) {
                    & ipconfig /flushdns | Out-Null
                    $autoResults.ActionsPerformed += "Safe Adblock: $addedCount Domains blockiert"
                    $autoResults.SuccessfulActions++
                } else {
                    $autoResults.ActionsPerformed += "Safe Adblock: Bereits aktiv"
                    $autoResults.SuccessfulActions++
                }
            } catch {
                $autoResults.ActionsPerformed += "Safe Adblock fehlgeschlagen"
                $autoResults.FailedActions++
            }
            $autoResults.TotalActions++
        }
        
        # Winget Updates prüfen
        if (Get-Command Get-WingetUpdates -ErrorAction SilentlyContinue) {
            Write-Log "[*] Pruefe Winget Updates..." -Color Blue
            $updates = Get-WingetUpdates
            if ($updates.Count -gt 0) {
                $autoResults.ActionsPerformed += "Winget: $($updates.Count) Updates verfuegbar"
                $autoResults.SuccessfulActions++
            } else {
                $autoResults.ActionsPerformed += "Winget: Alle Programme aktuell"
                $autoResults.SuccessfulActions++
            }
            $autoResults.TotalActions++
        }
    }
    
    # Auto-Modus Zusammenfassung
    $autoEndTime = Get-Date
    $autoResults.Duration = [math]::Round(($autoEndTime - $autoStartTime).TotalMinutes, 2)
    
    Write-Log "`n=== AUTO-MODUS ABGESCHLOSSEN ===" -Color Green
    Write-Log "Dauer: $($autoResults.Duration) Minuten" -Color White
    Write-Log "Aktionen gesamt: $($autoResults.TotalActions)" -Color White
    Write-Log "Erfolgreich: $($autoResults.SuccessfulActions)" -Color Green
    Write-Log "Fehlgeschlagen: $($autoResults.FailedActions)" -Color Red
    if ($autoResults.FreedSpaceMB -gt 0) {
        Write-Log "Freigegebener Speicher: $($autoResults.FreedSpaceMB) MB" -Color Cyan
    }
    
    Write-Log "`nDurchgefuehrte Aktionen:" -Color Yellow
    foreach ($action in $autoResults.ActionsPerformed) {
        Write-Log "  - $action" -Color White
    }
    
    # Empfehlungen nach Auto-Modus
    Write-Log "`n=== EMPFEHLUNGEN ===" -Color Cyan
    if ($autoResults.FailedActions -gt 0) {
        Write-Log "- Einzelne fehlgeschlagene Aktionen manuell wiederholen" -Color Yellow
    }
    if ($autoResults.FreedSpaceMB -gt 500) {
        Write-Log "- Neustart empfohlen nach umfangreicher Bereinigung" -Color Yellow
    }
    Write-Log "- Regelmaessige Ausfuehrung (1x Woche) empfohlen" -Color Green
    
    # Erfolgsrate berechnen
    $successRate = if ($autoResults.TotalActions -gt 0) { 
        [math]::Round(($autoResults.SuccessfulActions / $autoResults.TotalActions) * 100, 0)
    } else { 0 }
    
    if ($successRate -ge 90) {
        Add-Success "Auto-Modus: $successRate% erfolgreich - Excellent!"
    } elseif ($successRate -ge 70) {
        Add-Success "Auto-Modus: $successRate% erfolgreich - Good"  
    } else {
        Add-Warning "Auto-Modus: $successRate% erfolgreich - Needs attention"
    }
    
    $script:ActionsPerformed += "Auto-Modus ($successRate% erfolgreich)"
    return $autoResults
}

function Invoke-QuickMode {
    Write-Log "`n[*] --- SCHNELL-MODUS ---" -Color Green
    Write-Log "Fuehrt nur die wichtigsten Optimierungen durch (< 5 Minuten)" -Color Yellow
    
    $quickStartTime = Get-Date
    $quickResults = @{
        ActionsPerformed = @()
        SuccessCount = 0
        TotalCount = 0
    }
    
    # Wiederherstellungspunkt (optional)
    $createRestore = Read-Host "`nWiederherstellungspunkt erstellen? [j/n] (empfohlen)"
    if ($createRestore -eq 'j' -or $createRestore -eq 'J') {
        if (Get-Command New-SystemRestorePoint -ErrorAction SilentlyContinue) {
            New-SystemRestorePoint -Description "Schnell-Modus"
        }
    }
    
    Write-Log "`n[*] Fuehre Schnell-Optimierungen durch..." -Color Blue
    
    # 1. Temp-Dateien bereinigen (nur Basis)
    $quickResults.TotalCount++
    try {
        $tempPaths = @("$env:TEMP", "$env:SystemRoot\Temp", "$env:LOCALAPPDATA\Temp")
        $totalFreed = 0
        
        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                $sizeBefore = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
                              Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                
                Get-ChildItem $tempPath -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
                $totalFreed += [math]::Round($sizeBefore / 1MB, 2)
            }
        }
        
        $quickResults.ActionsPerformed += "Temp-Bereinigung: $totalFreed MB"
        $quickResults.SuccessCount++
        Write-Log "  [OK] Temp-Bereinigung: $totalFreed MB" -Color Green
        
    } catch {
        $quickResults.ActionsPerformed += "Temp-Bereinigung: Fehlgeschlagen"
        Write-Log "  [ERROR] Temp-Bereinigung fehlgeschlagen" -Color Red
    }
    
    # 2. DNS-Cache leeren
    $quickResults.TotalCount++
    try {
        & ipconfig /flushdns | Out-Null
        $quickResults.ActionsPerformed += "DNS-Cache geleert"
        $quickResults.SuccessCount++
        Write-Log "  [OK] DNS-Cache geleert" -Color Green
    } catch {
        $quickResults.ActionsPerformed += "DNS-Cache: Fehlgeschlagen"
        Write-Log "  [ERROR] DNS-Cache leeren fehlgeschlagen" -Color Red
    }
    
    # 3. Prefetch bereinigen
    $quickResults.TotalCount++
    try {
        $prefetchPath = "$env:SystemRoot\Prefetch"
        if (Test-Path $prefetchPath) {
            $prefetchFiles = Get-ChildItem $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue
            $removedCount = 0
            
            foreach ($file in $prefetchFiles) {
                try {
                    Remove-Item $file.FullName -Force -ErrorAction Stop
                    $removedCount++
                } catch {
                    # Einzelne Dateien können gesperrt sein - ignorieren
                }
            }
            
            $quickResults.ActionsPerformed += "Prefetch: $removedCount Dateien"
            $quickResults.SuccessCount++
            Write-Log "  [OK] Prefetch bereinigt: $removedCount Dateien" -Color Green
        }
    } catch {
        $quickResults.ActionsPerformed += "Prefetch: Fehlgeschlagen"
        Write-Log "  [ERROR] Prefetch-Bereinigung fehlgeschlagen" -Color Red
    }
    
    # Schnell-Modus Zusammenfassung
    $quickEndTime = Get-Date
    $quickDuration = [math]::Round(($quickEndTime - $quickStartTime).TotalMinutes, 2)
    $quickSuccessRate = [math]::Round(($quickResults.SuccessCount / $quickResults.TotalCount) * 100, 0)
    
    Write-Log "`n[SUCCESS] Schnell-Modus abgeschlossen!" -Color Green
    Write-Log "Dauer: $quickDuration Minuten" -Color White
    Write-Log "Erfolgsrate: $quickSuccessRate% ($($quickResults.SuccessCount)/$($quickResults.TotalCount))" -Color Cyan
    
    Write-Log "`nDurchgefuehrte Aktionen:" -Color Yellow
    foreach ($action in $quickResults.ActionsPerformed) {
        Write-Log "  - $action" -Color White
    }
    
    Add-Success "Schnell-Modus: $quickSuccessRate% erfolgreich"
    return $quickResults
}

# Export functions for dot-sourcing
Write-Verbose "Auto-Mode Module loaded: Invoke-EnhancedAutoMode, Invoke-QuickMode"
