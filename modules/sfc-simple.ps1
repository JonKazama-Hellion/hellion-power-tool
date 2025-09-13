# =============================================================================
# SFC SIMPLE MODULE - KOMPLETT NEU & DEFENDER-SICHER
# Einfach, robust, ohne Jobs, ohne Pipelines
# =============================================================================

function Invoke-SimpleSFC {
    Write-Log ""
    Write-Log "═══════════════════════════════════════════════════" -Color Cyan
    Write-Log "           🔧 SYSTEM FILE CHECKER" -Color White
    Write-Log "═══════════════════════════════════════════════════" -Color Cyan
    Write-Log "Prüft und repariert beschädigte Windows-Systemdateien" -Color Yellow
    Write-Log ""
    
    Write-Host "[*] SFC OPTIONEN:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor White -NoNewline
    Write-Host "Schnelle Pruefung " -ForegroundColor Green -NoNewline
    Write-Host "(sfc /verifyonly)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor White -NoNewline
    Write-Host "Vollstaendige Reparatur " -ForegroundColor Yellow -NoNewline
    Write-Host "(sfc /scannow)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [x] " -ForegroundColor White -NoNewline
    Write-Host "Abbrechen" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Wahl [1-2/x]"
    
    if ($choice -eq 'x' -or $choice -eq 'X') {
        Write-Information "[INFO] [ABGEBROCHEN] SFC-Scan nicht gestartet" -InformationAction Continue
        return $false
    }
    
    # Admin-Check
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Administrator-Rechte erforderlich für SFC!"
        return $false
    }
    
    # Einfache Parameter ohne komplexe Logik
    $sfcCommand = ""
    $description = ""
    
    if ($choice -eq '1') {
        $sfcCommand = "/verifyonly"
        $description = "Schnelle Pruefung"
    } elseif ($choice -eq '2') {
        $sfcCommand = "/scannow"
        $description = "Vollstaendige Reparatur"
    } else {
        Write-Error "Ungueltige Auswahl: $choice"
        return $false
    }
    
    Write-Log ""
    Write-Log "🔍 Starte SFC: $description" -Color Blue
    Write-Log "⏱️  Geschätzte Dauer: 5-15 Minuten" -Color Yellow
    Write-Log ""
    
    try {
        # Temp-Dateien vorbereiten
        $tempOut = Join-Path $env:TEMP "hellion-sfc-output.txt"
        $tempErr = Join-Path $env:TEMP "hellion-sfc-error.txt"
        
        Write-Log "🔧 Bereite SFC-Scan vor..." -Level "DEBUG"
        Write-Log "   Output-Datei: $tempOut" -Level "DEBUG"
        Write-Log "   Error-Datei: $tempErr" -Level "DEBUG"
        
        # SFC-Prozess starten (nicht-blockierend)
        Write-Log "🚀 Führe 'sfc $sfcCommand' aus..." -Color Cyan
        Write-Log "🔍 Starte SFC-Prozess mit Parametern: $sfcCommand" -Level "DEBUG"
        $startTime = Get-Date
        
        $process = Start-Process -FilePath "sfc.exe" -ArgumentList $sfcCommand -NoNewWindow -PassThru -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
        
        # Ladebalken während Prozess läuft
        Write-Host ""
        Write-Log "📊 Fortschritt:" -Color Cyan
        
        $progressChars = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
        $progressIndex = 0
        $secondsElapsed = 0
        
        while (-not $process.HasExited) {
            $minutes = [math]::Floor($secondsElapsed / 60)
            $seconds = $secondsElapsed % 60
            $timeStr = $minutes.ToString("00") + ":" + $seconds.ToString("00")
            
            $progressBar = ""
            $progressPercent = [math]::Min(($secondsElapsed / 600) * 100, 95)  # Max 95% bis fertig
            $filledBars = [math]::Floor($progressPercent / 5)  # 20 Balken total
            
            for ($i = 0; $i -lt 20; $i++) {
                if ($i -lt $filledBars) { $progressBar += "█" }
                else { $progressBar += "░" }
            }
            
            $percentStr = [math]::Round($progressPercent, 1).ToString() 
            Write-Host "`r   $($progressChars[$progressIndex]) [$progressBar] $percentStr% - $timeStr" -NoNewline -ForegroundColor Green
            
            Start-Sleep -Seconds 1
            $secondsElapsed++
            $progressIndex = ($progressIndex + 1) % $progressChars.Length
        }
        
        # Prozess beendet - 100% anzeigen
        Write-Host "`r   ✅ [████████████████████] 100.0% - Abgeschlossen!    " -ForegroundColor Green
        Write-Host ""
        
        Write-Log "⏳ Warte auf Prozess-Ende und sammle Ergebnisse..." -Level "DEBUG"
        $process.WaitForExit()
        $sfcExitCode = $process.ExitCode
        Write-Log "✅ SFC-Prozess beendet mit Exit-Code: $sfcExitCode" -Level "DEBUG"
        
        # Output lesen (einfach)
        if (Test-Path $tempOut) {
            Write-Log "📄 Lese SFC-Ausgabe..." -Level "DEBUG"
            $sfcOutput = Get-Content $tempOut -ErrorAction SilentlyContinue
            Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
            Write-Log "   Ausgabe-Zeilen gelesen: $($sfcOutput.Count)" -Level "DEBUG"
        }
        
        # Error-Output lesen
        if (Test-Path $tempErr) {
            Write-Log "⚠️  Prüfe SFC-Fehler-Ausgabe..." -Level "DEBUG"
            $sfcError = Get-Content $tempErr -ErrorAction SilentlyContinue
            Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
            if ($sfcError) {
                Write-Log "❌ SFC Error Output gefunden: $($sfcError -join '; ')" -Level "DEBUG"
            } else {
                Write-Log "✅ Keine SFC-Fehler gefunden" -Level "DEBUG"
            }
        }
        
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMinutes, 1)
        
        Write-Log ""
        Write-Log "═══════════════════════════════════════════════════" -Color Cyan
        Write-Log "                 SFC-ERGEBNIS" -Color White
        Write-Log "═══════════════════════════════════════════════════" -Color Cyan
        Write-Log ""
        Write-Log "⏱️  Dauer: ${duration} Minuten" -Color Gray
        
        # Benutzerfreundliche Ergebnis-Interpretation
        $success = $false
        
        switch ($sfcExitCode) {
            0 { 
                Write-Log "✅ System-Dateien: OK" -Color Green
                Write-Log "   Keine Probleme gefunden - System ist gesund!" -Color Green
                $success = $true
            }
            1 { 
                Write-Log "🔧 System-Dateien: REPARIERT" -Color Yellow
                Write-Log "   Fehler wurden gefunden und automatisch repariert" -Color Yellow
                Write-Log "   💡 Empfehlung: Neustart für vollständige Reparatur" -Color Yellow
                $success = $true
            }
            2 { 
                Write-Log "⚠️  System-Dateien: PROBLEME GEFUNDEN" -Color Red
                Write-Log "   Einige Dateien konnten nicht automatisch repariert werden" -Color Red
                Write-Log "   💡 Empfehlung: DISM-Reparatur ausführen, dann SFC wiederholen" -Color Yellow
            }
            3 { 
                Write-Log "❌ SFC-Scan: FEHLGESCHLAGEN" -Color Red
                Write-Log "   Scan konnte nicht ausgeführt werden (Admin-Rechte?)" -Color Red
            }
            default { 
                Write-Log "❓ Unbekannter Exit-Code: $sfcExitCode" -Color Yellow
                Write-Log "   Scan beendet, Status unklar" -Color Yellow
            }
        }
        
        # Debug-Informationen nur im Debug-Modus anzeigen
        Write-Log "💡 SFC-Scan erfolgreich abgeschlossen" -Level "DEBUG"
        Write-Log "   Verarbeitete Ausgabe-Zeilen: $($sfcOutput.Count)" -Level "DEBUG"
        Write-Log "   Exit-Code: $sfcExitCode" -Level "DEBUG"
        
        # Für normale User: Keine verwirrende Ausgabe
        # Für Debug-Modus: Detaillierte SFC-Ausgabe
        if (($null -ne $script:DebugLevel) -and ([int]$script:DebugLevel -ge 1)) {
            if ($sfcOutput -and $sfcOutput.Count -gt 0) {
                Write-Information "[INFO] " -InformationAction Continue
                Write-Information "[INFO] [DEBUG] SFC-Ausgabe zur Analyse:" -InformationAction Continue
                $maxLines = [Math]::Min(10, $sfcOutput.Count)
                for ($i = 0; $i -lt $maxLines; $i++) {
                    if ($sfcOutput[$i] -and $sfcOutput[$i].Trim() -ne "") {
                        Write-Information "[INFO]   $($sfcOutput[$i])" -InformationAction Continue
                    }
                }
                if ($sfcOutput.Count -gt 10) {
                    Write-Information "[INFO] [DEBUG] Weitere $($sfcOutput.Count - 10) Zeilen verfügbar in Log-Datei" -InformationAction Continue
                }
            } else {
                Write-Information "[INFO] [DEBUG] SFC lieferte keine Ausgabe (normal bei /verifyonly ohne Probleme)" -InformationAction Continue
            }
        }
        
        return $success
        
    } catch {
        Write-Information "[INFO] " -InformationAction Continue
        Write-Error "SFC-Ausführung fehlgeschlagen: $($_.Exception.Message)"
        Write-Information "[INFO] Mögliche Lösungen:" -InformationAction Continue
        Write-Information "[INFO]   - Als Administrator ausführen" -InformationAction Continue
        Write-Information "[INFO]   - System neu starten und wiederholen" -InformationAction Continue
        Write-Information "[INFO]   - DISM-Reparatur vor SFC ausführen" -InformationAction Continue
        return $false
    }
}

# Export für das Hauptmodul
Write-Verbose "SFC Simple Module loaded: Invoke-SimpleSFC"
