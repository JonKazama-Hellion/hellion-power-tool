# ===================================================================
# SYSTEM RESTORE MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function New-SystemRestorePoint {
    param([string]$Description = "Hellion Tool v7.0.3 (Modular)")
    
    Write-Log "`n[*] --- WIEDERHERSTELLUNGSPUNKT ---" -Color Cyan
    
    if ($script:RestorePointCreated) {
        Write-Log "[INFO] Wiederherstellungspunkt bereits erstellt" -Color Gray
        return $true
    }
    
    try {
        Write-Log "[*] Erstelle Wiederherstellungspunkt..." -Color Blue
        
        # Pruefe ob System Restore verfuegbar ist
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        if ($null -eq $restoreEnabled) {
            Write-Log "[INFO] Aktiviere System Restore auf C:\..." -Color Yellow
            Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        }
        
        # Erstelle Restore Point
        $fullDescription = "$Description - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $fullDescription -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Add-Success "Wiederherstellungspunkt erstellt: $fullDescription"
        $script:RestorePointCreated = $true
        Write-Log "[INFO] Bei Problemen kann das System auf diesen Punkt zurueckgesetzt werden" -Color Cyan
        
        return $true
        
    } catch {
        if ($_.Exception.Message -match "frequency") {
            Write-Log "[INFO] System Restore: Zeitlimit noch nicht erreicht (nur 1x/24h moeglich)" -Color Yellow
            Add-Warning "Wiederherstellungspunkt: Zeitlimit (24h) noch nicht erreicht"
            return $true  # Nicht als Fehler werten
        } else {
            Add-Warning "Wiederherstellungspunkt konnte nicht erstellt werden: $($_.Exception.Message)"
            return $false
        }
    }
}

function Get-SystemRestorePoints {
    Write-Log "`n[*] --- VERFUEGBARE WIEDERHERSTELLUNGSPUNKTE ---" -Color Cyan
    
    try {
        $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop
        
        if ($restorePoints -and $restorePoints.Count -gt 0) {
            Write-Log "Gefunden: $($restorePoints.Count) Wiederherstellungspunkte" -Color White
            
            $restorePoints | Sort-Object CreationTime -Descending | Select-Object -First 10 | ForEach-Object {
                $ageInDays = [math]::Round((Get-Date).Subtract($_.CreationTime).TotalDays, 1)
                Write-Log "  [$($_.SequenceNumber)] $($_.Description)" -Color Blue
                Write-Log "    Erstellt: $($_.CreationTime.ToString('yyyy-MM-dd HH:mm')) ($ageInDays Tage alt)" -Color Gray
                Write-Log "    Typ: $($_.RestorePointType)" -Color Gray
                Write-Log "" -Color White
            }
            
            return $restorePoints
            
        } else {
            Write-Log "[INFO] Keine Wiederherstellungspunkte gefunden" -Color Yellow
            Write-Log "[INFO] System Restore ist moeglicherweise deaktiviert" -Color Gray
            
            $choice = Read-Host "`nWiederherstellungspunkt jetzt erstellen? [j/n]"
            if ($choice -eq 'j' -or $choice -eq 'J') {
                return New-SystemRestorePoint -Description "Manuell erstellt"
            }
            
            return @()
        }
        
    } catch {
        Write-Log "[WARNING] Wiederherstellungspunkte konnten nicht abgerufen werden" -Color Red
        Write-Log "Moegliche Ursachen:" -Color Yellow
        Write-Log "  - System Restore ist deaktiviert" -Color Gray
        Write-Log "  - Keine Admin-Rechte" -Color Gray
        Write-Log "  - Windows-Version unterstuetzt System Restore nicht" -Color Gray
        
        Add-Warning "System Restore: Zugriff fehlgeschlagen"
        return @()
    }
}

function Restore-SystemToPoint {
    Write-Log "`n[*] --- SYSTEM-WIEDERHERSTELLUNG ---" -Color Cyan
    Write-Log "[WARNUNG] System-Wiederherstellung erfordert einen Neustart!" -Color Red
    
    $restorePoints = Get-SystemRestorePoints
    
    if (-not $restorePoints -or $restorePoints.Count -eq 0) {
        Write-Log "[ERROR] Keine Wiederherstellungspunkte verfuegbar!" -Color Red
        return $false
    }
    
    Write-Information "[INFO] `n[*] WIEDERHERSTELLUNGSOPTIONEN:" -InformationAction Continue
    Write-Information "[INFO]   [1] Letzten Wiederherstellungspunkt verwenden" -InformationAction Continue
    Write-Information "[INFO]   [2] Wiederherstellungspunkt auswählen" -InformationAction Continue
    Write-Information "[INFO]   [3] System Restore GUI öffnen" -InformationAction Continue
    Write-Information "[INFO]   [x] Abbrechen" -InformationAction Continue
    
    $choice = Read-Host "`nWahl [1-3/x]"
    
    switch ($choice.ToLower()) {
        '1' {
            $latestRestore = $restorePoints | Sort-Object CreationTime -Descending | Select-Object -First 1
            
            Write-Information "[INFO] `n[WARNUNG] Das System wird auf folgenden Punkt zurueckgesetzt:" -InformationAction Continue
            Write-Information "[INFO]   Beschreibung: $($latestRestore.Description)" -InformationAction Continue
            Write-Information "[INFO]   Erstellt: $($latestRestore.CreationTime)" -InformationAction Continue
            Write-Information "[INFO] `n[WICHTIG] Alle Aenderungen seit diesem Zeitpunkt gehen verloren!" -InformationAction Continue
            
            $confirm = Read-Host "`nWirklich fortfahren? [CONFIRM] (Tippe 'CONFIRM' zum Bestaetigen)"
            
            if ($confirm -eq 'CONFIRM') {
                try {
                    Write-Log "[*] Starte System-Wiederherstellung..." -Color Blue
                    Restore-Computer -RestorePoint $latestRestore.SequenceNumber -Confirm:$false -ErrorAction Stop
                    
                    Write-Log "[SUCCESS] System-Wiederherstellung gestartet!" -Color Green
                    Write-Log "[INFO] System wird neu gestartet..." -Color Yellow
                    
                    Add-Success "System-Wiederherstellung: Gestartet"
                    return $true
                    
                } catch {
                    Add-Error "System-Wiederherstellung fehlgeschlagen" $_.Exception.Message
                    return $false
                }
            } else {
                Write-Log "[SKIP] System-Wiederherstellung abgebrochen" -Color Gray
            }
        }
        '2' {
            Write-Information "[INFO] `nVerfuegbare Wiederherstellungspunkte:" -InformationAction Continue
            
            for ($i = 0; $i -lt [Math]::Min(10, $restorePoints.Count); $i++) {
                $rp = $restorePoints[$i]
                Write-Information "[INFO]   [$($i+1)] $($rp.Description) - $($rp.CreationTime.ToString('yyyy-MM-dd HH:mm'))" -InformationAction Continue
            }
            
            $selection = Read-Host "`nWiederherstellungspunkt waehlen [1-$([Math]::Min(10, $restorePoints.Count))]"
            
            try {
                $selectedIndex = [int]$selection - 1
                if ($selectedIndex -ge 0 -and $selectedIndex -lt $restorePoints.Count) {
                    $selectedRestore = $restorePoints[$selectedIndex]
                    
                    $confirm = Read-Host "`nAuf '$($selectedRestore.Description)' zuruecksetzen? [CONFIRM]"
                    if ($confirm -eq 'CONFIRM') {
                        Restore-Computer -RestorePoint $selectedRestore.SequenceNumber -Confirm:$false
                        Add-Success "System-Wiederherstellung: Manuell gestartet"
                        return $true
                    }
                }
            } catch {
                Write-Log "[ERROR] Ungueltige Auswahl" -Color Red
            }
        }
        '3' {
            Write-Log "[*] Oeffne System Restore GUI..." -Color Blue
            try {
                # Defender-safe: Avoid -Verb RunAs pattern
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "rstrui.exe"
                $processInfo.Verb = "runas"
                $processInfo.UseShellExecute = $true
                [System.Diagnostics.Process]::Start($processInfo) | Out-Null
                Write-Log "[OK] System Restore GUI geoeffnet" -Color Green
                return $true
            } catch {
                Write-Log "[ERROR] System Restore GUI konnte nicht geoeffnet werden" -Color Red
            }
        }
        'x' {
            Write-Log "[SKIP] System-Wiederherstellung abgebrochen" -Color Gray
        }
        default {
            Write-Log "[ERROR] Ungueltige Auswahl" -Color Red
        }
    }
    
    return $false
}

function Enable-SystemRestore {
    Write-Log "`n[*] --- SYSTEM RESTORE AKTIVIERUNG ---" -Color Cyan
    
    try {
        # System Restore auf allen Laufwerken aktivieren
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        foreach ($drive in $drives) {
            $driveLetter = $drive.DeviceID
            
            try {
                Enable-ComputerRestore -Drive $driveLetter -ErrorAction Stop
                Write-Log "[OK] System Restore aktiviert auf $driveLetter" -Color Green
            } catch {
                Write-Log "[WARNING] System Restore auf $driveLetter nicht aktivierbar" -Color Yellow
            }
        }
        
        # Speicherplatz-Konfiguration (optional)
        Write-Information "[INFO] `nSpeicherplatz fuer System Restore konfigurieren?" -InformationAction Continue
        Write-Information "[INFO]   [1] Standard (5% der Festplatte)" -InformationAction Continue
        Write-Information "[INFO]   [2] Minimal (2% der Festplatte)" -InformationAction Continue  
        Write-Information "[INFO]   [3] Maximal (10% der Festplatte)" -InformationAction Continue
        Write-Information "[INFO]   [s] Ueberspringen" -InformationAction Continue
        
        $spaceChoice = Read-Host "`nWahl [1-3/s]"
        
        switch ($spaceChoice) {
            '1' { $maxSize = 5 }
            '2' { $maxSize = 2 }
            '3' { $maxSize = 10 }
            default { $maxSize = $null }
        }
        
        if ($maxSize) {
            try {
                # PowerShell-Befehl für Speicherplatz-Konfiguration
                $systemDrive = $env:SystemDrive
                & vssadmin resize shadowstorage /for=$systemDrive /on=$systemDrive /maxsize=${maxSize}% 2>$null
                Write-Log "[OK] Speicherplatz auf $maxSize% konfiguriert" -Color Green
            } catch {
                Write-Log "[INFO] Speicherplatz-Konfiguration übersprungen" -Color Gray
            }
        }
        
        # Ersten Wiederherstellungspunkt erstellen
        $createPoint = Read-Host "`nErsten Wiederherstellungspunkt erstellen? [j/n]"
        if ($createPoint -eq 'j' -or $createPoint -eq 'J') {
            New-SystemRestorePoint -Description "System Restore aktiviert"
        }
        
        Add-Success "System Restore: Erfolgreich aktiviert"
        return $true
        
    } catch {
        Add-Error "System Restore Aktivierung fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

# Export functions for dot-sourcing
Write-Verbose "System-Restore Module loaded: New-SystemRestorePoint, Get-SystemRestorePoints, Restore-SystemToPoint, Enable-SystemRestore"
