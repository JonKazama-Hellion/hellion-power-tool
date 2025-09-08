# =============================================================================
# SFC SIMPLE MODULE - KOMPLETT NEU & DEFENDER-SICHER
# Einfach, robust, ohne Jobs, ohne Pipelines
# =============================================================================

function Invoke-SimpleSFC {
    Write-Host "`n=== SYSTEM FILE CHECKER (EINFACH & SICHER) ===" -ForegroundColor Cyan
    Write-Host "Prueft und repariert beschaedigte Windows-Systemdateien" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "[*] SFC OPTIONEN:" -ForegroundColor Cyan
    Write-Host "  [1] Schnelle Pruefung (sfc /verifyonly)" -ForegroundColor Green
    Write-Host "  [2] Vollstaendige Reparatur (sfc /scannow)" -ForegroundColor Yellow
    Write-Host "  [x] Abbrechen" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Wahl [1-2/x]"
    
    if ($choice -eq 'x' -or $choice -eq 'X') {
        Write-Host "[ABGEBROCHEN] SFC-Scan nicht gestartet" -ForegroundColor Yellow
        return $false
    }
    
    # Admin-Check
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[ERROR] Administrator-Rechte erforderlich für SFC!" -ForegroundColor Red
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
        Write-Host "[ERROR] Ungueltige Auswahl: $choice" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    Write-Host "[*] Starte SFC: $description" -ForegroundColor Blue
    Write-Host "[INFO] Dies kann 5-15 Minuten dauern..." -ForegroundColor Yellow
    Write-Host "[INFO] SFC laeuft im Hintergrund - bitte warten" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # KOMPLETT EINFACH: Direkter SFC-Aufruf ohne Jobs, ohne Pipelines
        Write-Host "[*] Fuehre 'sfc $sfcCommand' aus..." -ForegroundColor Cyan
        
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
                    Write-Host "[DEBUG] SFC Error Output: $($sfcError -join '; ')" -ForegroundColor Gray
                }
            }
            
        } catch {
            throw "SFC-Prozess konnte nicht gestartet werden: $($_.Exception.Message)"
        }
        
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMinutes, 1)
        
        Write-Host ""
        Write-Host "[*] SFC abgeschlossen nach ${duration} Minuten" -ForegroundColor Green
        Write-Host "[*] Exit Code: $sfcExitCode" -ForegroundColor Cyan
        
        # Einfache Ergebnis-Interpretation
        $success = $false
        
        switch ($sfcExitCode) {
            0 { 
                Write-Host "[OK] SFC erfolgreich - Keine Probleme gefunden" -ForegroundColor Green
                $success = $true
            }
            1 { 
                Write-Host "[OK] SFC erfolgreich - Fehler gefunden und repariert" -ForegroundColor Yellow
                Write-Host "[INFO] Neustart empfohlen" -ForegroundColor Yellow
                $success = $true
            }
            2 { 
                Write-Host "[WARNING] SFC unvollständig - Einige Dateien konnten nicht repariert werden" -ForegroundColor Yellow
                Write-Host "[EMPFEHLUNG] DISM-Reparatur durchführen, dann SFC wiederholen" -ForegroundColor Cyan
            }
            3 { 
                Write-Host "[ERROR] SFC konnte nicht ausgeführt werden" -ForegroundColor Red
            }
            default { 
                Write-Host "[INFO] SFC beendet mit Code $sfcExitCode" -ForegroundColor Yellow
            }
        }
        
        # Output anzeigen falls gewünscht
        if ($sfcOutput -and $sfcOutput.Count -gt 0) {
            Write-Host ""
            Write-Host "[*] SFC-Output (erste 5 Zeilen):" -ForegroundColor Blue
            $maxLines = [Math]::Min(5, $sfcOutput.Count)
            for ($i = 0; $i -lt $maxLines; $i++) {
                if ($sfcOutput[$i] -and $sfcOutput[$i].Trim() -ne "") {
                    Write-Host "  $($sfcOutput[$i])" -ForegroundColor White
                }
            }
            if ($sfcOutput.Count -gt 5) {
                Write-Host "  ... und $($sfcOutput.Count - 5) weitere Zeilen" -ForegroundColor Gray
            }
        } else {
            Write-Host ""
            Write-Host "[INFO] SFC lieferte keine Ausgabe (normal bei /verifyonly ohne Probleme)" -ForegroundColor Gray
        }
        
        return $success
        
    } catch {
        Write-Host ""
        Write-Host "[ERROR] SFC-Ausführung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[INFO] Mögliche Lösungen:" -ForegroundColor Yellow
        Write-Host "  - Als Administrator ausführen" -ForegroundColor Gray
        Write-Host "  - System neu starten und wiederholen" -ForegroundColor Gray
        Write-Host "  - DISM-Reparatur vor SFC ausführen" -ForegroundColor Gray
        return $false
    }
}

# Export für das Hauptmodul
Write-Verbose "SFC Simple Module loaded: Invoke-SimpleSFC"