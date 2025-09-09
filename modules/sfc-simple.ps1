# =============================================================================
# SFC SIMPLE MODULE - KOMPLETT NEU & DEFENDER-SICHER
# Einfach, robust, ohne Jobs, ohne Pipelines
# =============================================================================

function Invoke-SimpleSFC {
    Write-Host ""
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "                >>> SYSTEM FILE CHECKER (SICHER) <<<" -ForegroundColor White
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "Prueft und repariert beschaedigte Windows-Systemdateien" -ForegroundColor Yellow
    Write-Host ""
    
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
    
    Write-Information "[INFO] " -InformationAction Continue
    Write-Information "[INFO] [*] Starte SFC: $description" -InformationAction Continue
    Write-Information "[INFO] Dies kann 5-15 Minuten dauern..." -InformationAction Continue
    Write-Information "[INFO] SFC laeuft im Hintergrund - bitte warten" -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    try {
        # KOMPLETT EINFACH: Direkter SFC-Aufruf ohne Jobs, ohne Pipelines
        Write-Information "[INFO] [*] Fuehre 'sfc $sfcCommand' aus..." -InformationAction Continue
        
        $startTime = Get-Date
        $sfcExitCode = 0
        $sfcOutput = @()
        
        # Simpelster Aufruf möglich - kein Job, kein Pipeline, nur direkter Call
        # Temp-Dateien in korrektem Temp-Ordner
        $tempOut = Join-Path $env:TEMP "hellion-sfc-output.txt"
        $tempErr = Join-Path $env:TEMP "hellion-sfc-error.txt"
        
        try {
            $process = Start-Process -FilePath "sfc.exe" -ArgumentList $sfcCommand -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
            $sfcExitCode = $process.ExitCode
            
            # Output lesen (einfach)
            if (Test-Path $tempOut) {
                $sfcOutput = Get-Content $tempOut -ErrorAction SilentlyContinue
                Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
            }
            
            # Error-Output lesen
            if (Test-Path $tempErr) {
                $sfcError = Get-Content $tempErr -ErrorAction SilentlyContinue
                Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
                if ($sfcError) {
                    Write-Information "[INFO] [DEBUG] SFC Error Output: $($sfcError -join '; ')" -InformationAction Continue
                }
            }
            
        } catch {
            throw "SFC-Prozess konnte nicht gestartet werden: $($_.Exception.Message)"
        }
        
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMinutes, 1)
        
        Write-Information "[INFO] " -InformationAction Continue
        Write-Information "[INFO] [*] SFC abgeschlossen nach ${duration} Minuten" -InformationAction Continue
        Write-Information "[INFO] [*] Exit Code: $sfcExitCode" -InformationAction Continue
        
        # Einfache Ergebnis-Interpretation
        $success = $false
        
        switch ($sfcExitCode) {
            0 { 
                Write-Information "[OK] SFC erfolgreich - Keine Probleme gefunden" -InformationAction Continue
                $success = $true
            }
            1 { 
                Write-Information "[INFO] [OK] SFC erfolgreich - Fehler gefunden und repariert" -InformationAction Continue
                Write-Information "[INFO] Neustart empfohlen" -InformationAction Continue
                $success = $true
            }
            2 { 
                Write-Warning "SFC unvollständig - Einige Dateien konnten nicht repariert werden"
                Write-Information "[INFO] [EMPFEHLUNG] DISM-Reparatur durchführen, dann SFC wiederholen" -InformationAction Continue
            }
            3 { 
                Write-Error "SFC konnte nicht ausgeführt werden"
            }
            default { 
                Write-Information "[INFO] SFC beendet mit Code $sfcExitCode" -InformationAction Continue
            }
        }
        
        # Output anzeigen falls gewünscht
        if ($sfcOutput -and $sfcOutput.Count -gt 0) {
            Write-Information "[INFO] " -InformationAction Continue
            Write-Information "[INFO] [*] SFC-Output (erste 5 Zeilen):" -InformationAction Continue
            $maxLines = [Math]::Min(5, $sfcOutput.Count)
            for ($i = 0; $i -lt $maxLines; $i++) {
                if ($sfcOutput[$i] -and $sfcOutput[$i].Trim() -ne "") {
                    Write-Information "[INFO]   $($sfcOutput[$i])" -InformationAction Continue
                }
            }
            if ($sfcOutput.Count -gt 5) {
                Write-Information "[INFO]   ... und $($sfcOutput.Count - 5) weitere Zeilen" -InformationAction Continue
            }
        } else {
            Write-Information "[INFO] " -InformationAction Continue
            Write-Information "[INFO] SFC lieferte keine Ausgabe (normal bei /verifyonly ohne Probleme)" -InformationAction Continue
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
