# ===================================================================
# DISK MAINTENANCE MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Invoke-CheckDisk {
    Write-Log "`n[*] --- CHECKDISK (CHKDSK) LAUFWERKS-PRUEFUNG ---" -Color Cyan
    Write-Log "Prueft und repariert Dateisystem-Fehler auf Laufwerken" -Color Yellow
    
    # Verfuegbare Laufwerke anzeigen
    Write-Log "`n[*] Verfuegbare Laufwerke:" -Color Blue
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $driveIndex = 1
    
    foreach ($drive in $drives) {
        $driveLetter = $drive.DeviceID
        $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalSpace = [math]::Round($drive.Size / 1GB, 2)
        $usedPercent = [math]::Round((($totalSpace - $freeSpace) / $totalSpace) * 100, 1)
        
        Write-Information "[INFO]   [$driveIndex] $driveLetter ($totalSpace GB, $usedPercent% belegt)" -InformationAction Continue
        $driveIndex++
    }
    
    Write-Information "[INFO] `n[WARNUNG] Checkdisk kann bei Systemplatte einen Neustart erfordern!" -InformationAction Continue
    Write-Information "[INFO] Nur-Lesen-Modus wird zuerst versucht" -InformationAction Continue
    
    $driveChoice = Read-Host "`nLaufwerk waehlen [1-$($drives.Count)] oder [x] zum Abbrechen"
    
    if ($driveChoice -eq 'x' -or $driveChoice -eq 'X') {
        Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
        return $false
    }
    
    try {
        $selectedIndex = [int]$driveChoice - 1
        if ($selectedIndex -lt 0 -or $selectedIndex -ge $drives.Count) {
            throw "Ungueltige Auswahl"
        }
        
        $selectedDrive = $drives[$selectedIndex]
        $driveLetter = $selectedDrive.DeviceID.TrimEnd(':')
        
        Write-Log "[*] Gewaehlt: Laufwerk $driveLetter" -Color Cyan
        
        # Checkdisk-Optionen
        Write-Host ""
        Write-Host "[*] CHECKDISK OPTIONEN:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   [1] " -ForegroundColor White -NoNewline
        Write-Host "Nur pruefen " -ForegroundColor Green -NoNewline
        Write-Host "(Nur-Lesen, empfohlen)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [2] " -ForegroundColor White -NoNewline
        Write-Host "Pruefen und reparieren " -ForegroundColor Yellow -NoNewline
        Write-Host "(/f)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [3] " -ForegroundColor White -NoNewline
        Write-Host "Vollstaendige Pruefung " -ForegroundColor Red -NoNewline
        Write-Host "(/f /r)" -ForegroundColor DarkGray
        Write-Host ""
        
        $modeChoice = Read-Host "`nModus waehlen [1-3]"
        
        $chkdskArgs = ""
        $description = ""
        
        switch ($modeChoice) {
            '1' {
                $chkdskArgs = "${driveLetter}:"
                $description = "Nur-Lesen Pruefung"
            }
            '2' {
                $chkdskArgs = "${driveLetter}: /f"
                $description = "Pruefung und Reparatur"
                Write-Information "[INFO] [WARNUNG] Reparatur-Modus kann Datenverlust verursachen!" -InformationAction Continue
                $confirm = Read-Host "Fortfahren? [j/n]"
                if ($confirm -ne 'j' -and $confirm -ne 'J') {
                    Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
                    return $false
                }
            }
            '3' {
                $chkdskArgs = "${driveLetter}: /f /r"
                $description = "Vollstaendige Pruefung und Reparatur"
                Write-Information "[INFO] [WARNUNG] Vollstaendige Pruefung kann STUNDEN dauern!" -InformationAction Continue
                Write-Information "[INFO] [WARNUNG] Reparatur-Modus kann Datenverlust verursachen!" -InformationAction Continue
                $confirm = Read-Host "Wirklich fortfahren? [j/n]"
                if ($confirm -ne 'j' -and $confirm -ne 'J') {
                    Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
                    return $false
                }
            }
            default {
                Write-Log "[ERROR] Ungueltige Auswahl" -Level "ERROR"
                return $false
            }
        }
        
        Write-Log "[*] Starte Checkdisk: $description" -Color Blue
        Write-Log "[*] Parameter: chkdsk $chkdskArgs" -Color Gray
        
        # Checkdisk ausfuehren
        $chkdskResult = & chkdsk $chkdskArgs.Split(' ') 2>&1 | Out-String
        $chkdskExitCode = $LASTEXITCODE
        
        # Ergebnis auswerten
        if ($chkdskResult -match "errors found" -or $chkdskResult -match "Fehler gefunden") {
            if ($chkdskResult -match "fixed" -or $chkdskResult -match "repariert") {
                Add-Success "Checkdisk: Fehler gefunden und repariert"
                Write-Log "[*] Ein Neustart kann erforderlich sein" -Level "WARNING"
                $script:UpdateRecommendations += "Neustart nach Checkdisk-Reparatur empfohlen"
            } else {
                Add-Warning "Checkdisk: Fehler gefunden - Reparatur-Modus empfohlen"
                $script:UpdateRecommendations += "Checkdisk mit Reparatur-Option ausfuehren"
            }
        } elseif ($chkdskResult -match "no problems found" -or $chkdskResult -match "keine Probleme" -or $chkdskExitCode -eq 0) {
            Add-Success "Checkdisk: Keine Probleme gefunden"
        } elseif ($chkdskResult -match "scheduled" -or $chkdskResult -match "geplant") {
            Add-Success "Checkdisk: Fuer naechsten Neustart geplant"
            Write-Log "[*] Checkdisk wird beim naechsten Neustart ausgefuehrt" -Level "WARNING"
            $script:UpdateRecommendations += "Neustart fuer geplante Checkdisk-Pruefung erforderlich"
        } else {
            # Debug-Info bei unklarem Status
            if ($script:ExplainMode) {
                $resultLength = if ($chkdskResult) { $chkdskResult.Length } else { 0 }
                Write-Log "[DEBUG] Checkdisk Ausgabe: $($chkdskResult.Substring(0, [Math]::Min(300, $resultLength)))" -Level "DEBUG"
                Write-Log "[DEBUG] Exit Code: $chkdskExitCode" -Level "DEBUG"
            }
            Add-Warning "Checkdisk abgeschlossen - Details im Event-Log pruefen"
        }
        
        # Vollstaendige Ausgabe im Debug-Modus anzeigen
        if ($script:ExplainMode) {
            Write-Log "`n[DEBUG] Vollstaendige Checkdisk-Ausgabe:" -Level "DEBUG"
            $chkdskResult.Split("`n") | Select-Object -First 20 | ForEach-Object {
                Write-Log "  $_" -Level "DEBUG"
            }
        }
        
        return $true
        
    } catch {
        Add-Error "Checkdisk fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

# ❌ OBSOLETE FUNCTION - REPLACED BY sfc-simple.ps1
# This function has been replaced by Invoke-SimpleSFC in the sfc-simple.ps1 module
# for better Windows Defender compatibility and simpler architecture.
# Keeping this function commented for reference but it should not be used.
<#
function Invoke-SystemFileChecker {
    Write-Log "`n[*] --- SYSTEM FILE CHECKER (SFC) ---" -Color Cyan
    Write-Log "Prueft und repariert beschaedigte Windows-Systemdateien" -Color Yellow
    
    Write-Information "[INFO] `n[*] SFC OPTIONEN:" -InformationAction Continue
    Write-Information "[INFO]   [1] Schnelle Pruefung (sfc /verifyonly)" -InformationAction Continue
    Write-Information "[INFO]   [2] Pruefung und Reparatur (sfc /scannow)" -InformationAction Continue
    Write-Information "[INFO]   [x] Abbrechen" -InformationAction Continue
    
    $choice = Read-Host "`nWahl [1-2/x]"
    
    if ($choice -eq 'x' -or $choice -eq 'X') {
        Write-Log "[SKIP] SFC abgebrochen" -Color Gray
        return $false
    }
    
    $sfcArgs = ""
    $description = ""
    
    switch ($choice) {
        '1' {
            $sfcArgs = "/verifyonly"
            $description = "Schnelle Systemdatei-Pruefung"
        }
        '2' {
            $sfcArgs = "/scannow"  
            $description = "Vollstaendige Systemdatei-Reparatur"
        }
        default {
            Write-Log "[ERROR] Ungueltige Auswahl" -Level "ERROR"
            return $false
        }
    }
    
    Write-Log "[*] Starte SFC: $description" -Color Blue
    Write-Log "[INFO] Dies kann mehrere Minuten dauern..." -Color Gray
    Write-Information "[INFO] [*] SFC-Progress wird angezeigt sobald verfuegbar..." -InformationAction Continue
    
    try {
        # SFC mit Live-Progress starten - robustere Implementierung
        $job = Start-Job -ScriptBlock {
            param($sfcArgs)
            Write-Output "SFC Job gestartet mit Argumenten: $sfcArgs"
            $result = & sfc.exe $sfcArgs 2>&1
            Write-Output "SFC Job beendet"
            return $result
        } -ArgumentList $sfcArgs
        
        # Warte kurz damit Job startet
        Start-Sleep -Milliseconds 500
        
        # Progress-Monitor waehrend SFC laeuft
        $progressTimer = 0
        $dots = ""
        $jobStarted = $false
        
        while ($job.State -eq "Running" -or ($progressTimer -lt 5 -and -not $jobStarted)) {
            $progressTimer++
            $dots = "." * (($progressTimer % 4) + 1)
            $elapsed = [math]::Round($progressTimer * 2 / 60, 1)
            
            # Prüfe ob Job tatsächlich läuft
            if ($job.State -eq "Running") {
                $jobStarted = $true
                Write-Information "[INFO] [*] SFC arbeitet$dots (${elapsed}min)" -InformationAction Continue
            } else {
                Write-Information "[INFO] [*] SFC startet$dots" -InformationAction Continue
            }
            
            Start-Sleep -Seconds 2
        }
        Write-Information "[INFO] " -InformationAction Continue  # Neue Zeile nach Progress
        
        # Job-Status prüfen
        if ($job.State -eq "Failed") {
            Write-Log "[ERROR] SFC-Job fehlgeschlagen" -Level "ERROR"
            $jobError = Receive-Job -Job $job -ErrorAction SilentlyContinue
            if ($jobError) {
                Write-Log "[ERROR] Job-Fehler: $($jobError -join '; ')" -Level "DEBUG"
            }
            Remove-Job -Job $job -Force
            return $false
        }
        
        # Job-Ergebnis abrufen und verarbeiten
        $sfcResult = Receive-Job -Job $job -Wait -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force
        
        # Output verarbeiten
        if ($sfcResult) {
            if ($script:DebugMode -ge 1) {
                Write-Log "[DEBUG] SFC Raw Output:" -Level "DEBUG"
                # Defender-safe: Use simple for loop instead of pipeline
                if ($sfcResult -and $sfcResult.Count -gt 0) {
                    for ($i = 0; $i -lt $sfcResult.Count; $i++) {
                        if ($sfcResult[$i]) {
                            Write-Log "[DEBUG] $($sfcResult[$i])" -Level "DEBUG"
                        }
                    }
                }
            }
            # Defender-safe: Manual string conversion
            if ($sfcResult -and $sfcResult.Count -gt 0) {
                $sfcOutput = ""
                for ($i = 0; $i -lt $sfcResult.Count; $i++) {
                    $sfcOutput += $sfcResult[$i] + "`n"
                }
            } else {
                $sfcOutput = ""
            }
        } else {
            Write-Log "[WARNING] SFC lieferte keine Ausgabe" -Level "DEBUG"
            $sfcOutput = ""
        }
        
        # Ergebnis auswerten (Job hat keinen ExitCode, analysiere Output)
        $exitCode = 0  # Default success
        
        if ($exitCode -eq 0) {
            if ($sfcOutput -match "did not find any integrity violations" -or $sfcOutput -match "keine Integritaetsverletzungen") {
                Add-Success "SFC: Keine beschaedigten Systemdateien gefunden"
            } else {
                Add-Success "SFC: Reparatur erfolgreich abgeschlossen"
            }
        } elseif ($exitCode -eq 1) {
            Add-Warning "SFC: Beschaedigte Dateien gefunden und repariert"
            $script:UpdateRecommendations += "Neustart nach SFC-Reparatur empfohlen"
        } elseif ($exitCode -eq 2) {
            Add-Error "SFC: Beschaedigte Dateien gefunden - Reparatur fehlgeschlagen"
            $script:UpdateRecommendations += "DISM-Reparatur vor erneutem SFC-Scan erforderlich"
        } else {
            Add-Warning "SFC abgeschlossen - Exit Code: $exitCode"
        }
        
        # Debug-Output
        if ($script:ExplainMode -and $sfcOutput) {
            Write-Log "`n[DEBUG] SFC Output:" -Level "DEBUG"
            # Defender-safe: Manual loop instead of pipeline
            $outputLines = $sfcOutput.Split("`n")
            $maxLines = [Math]::Min(10, $outputLines.Count)
            for ($i = 0; $i -lt $maxLines; $i++) {
                if ($outputLines[$i]) {
                    Write-Log "  $($outputLines[$i])" -Level "DEBUG"
                }
            }
        }
        
        return $exitCode -le 1
        
    } catch {
        Add-Error "SFC-Ausfuehrung fehlgeschlagen" $_.Exception.Message
        return $false
    }
}
#>

function Invoke-DISMRepair {
    Write-Log "`n[*] --- DISM SYSTEM-REPARATUR ---" -Color Cyan
    Write-Log "Repariert das Windows-Image mit DISM (Deployment Image Servicing)" -Color Yellow
    
    Write-Host ""
    Write-Host "[*] DISM OPTIONEN:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor White -NoNewline
    Write-Host "Health-Check " -ForegroundColor Green -NoNewline
    Write-Host "(/CheckHealth)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor White -NoNewline
    Write-Host "Erweiterte Pruefung " -ForegroundColor Yellow -NoNewline
    Write-Host "(/ScanHealth)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor White -NoNewline
    Write-Host "Online-Reparatur " -ForegroundColor Red -NoNewline
    Write-Host "(/RestoreHealth)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [x] " -ForegroundColor White -NoNewline
    Write-Host "Abbrechen" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "`nWahl [1-3/x]"
    
    if ($choice -eq 'x' -or $choice -eq 'X') {
        Write-Log "[SKIP] DISM abgebrochen" -Color Gray
        return $false
    }
    
    $dismArgs = ""
    $description = ""
    
    switch ($choice) {
        '1' {
            $dismArgs = "/Online /Cleanup-Image /CheckHealth"
            $description = "DISM Health-Check"
        }
        '2' {
            $dismArgs = "/Online /Cleanup-Image /ScanHealth"
            $description = "DISM erweiterte Pruefung"
        }
        '3' {
            $dismArgs = "/Online /Cleanup-Image /RestoreHealth"
            $description = "DISM Online-Reparatur"
            Write-Information "[INFO] Online-Reparatur kann 10-30 Minuten dauern!" -InformationAction Continue
        }
        default {
            Write-Log "[ERROR] Ungueltige Auswahl" -Level "ERROR"
            return $false
        }
    }
    
    Write-Log "[*] Starte DISM: $description" -Color Blue
    Write-Log "[INFO] Dies kann mehrere Minuten dauern..." -Color Gray
    
    try {
        # DISM mit nativer Log-Funktion
        $logPath = Join-Path $env:TEMP "dism_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $fullArgs = "$dismArgs /LogPath:$logPath"
        
        $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList $fullArgs -Wait -PassThru -NoNewWindow
        $exitCode = $dismProcess.ExitCode
        
        # Log-Datei auslesen
        $dismOutput = ""
        if (Test-Path $logPath) {
            $dismOutput = Get-Content $logPath -Raw -ErrorAction SilentlyContinue
        }
        
        # Ergebnis auswerten
        if ($exitCode -eq 0) {
            if ($dismOutput -match "No component store corruption detected" -or 
                $dismOutput -match "The component store is repairable" -or
                $dismOutput -match "The restore operation completed successfully") {
                Add-Success "DISM: System-Image ist gesund"
            } else {
                Add-Success "DISM: Reparatur erfolgreich"
            }
        } elseif ($exitCode -eq 1) {
            Add-Warning "DISM: Probleme erkannt - RestoreHealth empfohlen"
        } else {
            Add-Error "DISM: Reparatur fehlgeschlagen (Exit Code: $exitCode)"
        }
        
        # Log-Datei in Debug-Modus anzeigen
        if ($script:ExplainMode -and $dismOutput) {
            Write-Log "`n[DEBUG] DISM Log (erste 15 Zeilen):" -Level "DEBUG"  
            $dismOutput.Split("`n") | Select-Object -First 15 | ForEach-Object {
                if ($_ -match "Error|Warning|Information") {
                    Write-Log "  $_" -Level "DEBUG"
                }
            }
        }
        
        # Log-Datei aufbehalten oder loeschen
        if ($script:DetailedLogging) {
            Write-Log "[INFO] DISM-Log gespeichert: $logPath" -Color Gray
        } else {
            Remove-Item $logPath -Force -ErrorAction SilentlyContinue
        }
        
        return $exitCode -eq 0
        
    } catch {
        Add-Error "DISM-Ausfuehrung fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

function Show-ProgressBar {
    param(
        [int]$PercentComplete,
        [string]$Activity = "Processing",
        [string]$Status = "Please wait..."
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

function Format-ByteSize {
    param([long]$Bytes)
    
    if ($Bytes -gt 1TB) {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    } elseif ($Bytes -gt 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -gt 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)  
    } elseif ($Bytes -gt 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } else {
        return "$Bytes Bytes"
    }
}

function Get-EnhancedDriveInfo {
    Write-Log "`n[*] --- LAUFWERKS-INFORMATION ---" -Color Cyan
    
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        foreach ($drive in $drives) {
            $driveLetter = $drive.DeviceID
            $totalSpace = $drive.Size
            $freeSpace = $drive.FreeSpace
            $usedSpace = $totalSpace - $freeSpace
            $usedPercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)
            
            Write-Log "`n[*] Laufwerk $driveLetter" -Color Blue
            Write-Log "    Gesamt: $(Format-ByteSize $totalSpace)" -Color White
            Write-Log "    Belegt: $(Format-ByteSize $usedSpace) ($usedPercent%)" -Color Yellow
            Write-Log "    Frei:   $(Format-ByteSize $freeSpace)" -Color Green
            
            # Warnung bei wenig freiem Speicher
            if ($usedPercent -gt 90) {
                Write-Log "    [WARNING] Sehr wenig freier Speicher!" -Color Red
            } elseif ($usedPercent -gt 80) {
                Write-Log "    [INFO] Freier Speicher wird knapp" -Color Yellow  
            }
        }
        
    } catch {
        Add-Error "Laufwerks-Information konnte nicht abgerufen werden" $_.Exception.Message
    }
}

# Export functions for dot-sourcing
Write-Verbose "Disk-Maintenance Module loaded: Invoke-CheckDisk, Invoke-DISMRepair, Get-EnhancedDriveInfo, Format-ByteSize, Show-ProgressBar (Invoke-SystemFileChecker obsolete - use sfc-simple.ps1)"
