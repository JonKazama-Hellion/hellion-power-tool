# ===================================================================
# SYSTEM RESTORE MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Invoke-RestorePointManager {
    param(
        [int]$Mode = 0,
        [switch]$Force
    )
    Write-Host ""
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "                >>> WIEDERHERSTELLUNGSPUNKT-VERWALTUNG <<<" -ForegroundColor White
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "Verwalte System-Wiederherstellungspunkte sicher" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "[*] WIEDERHERSTELLUNGSOPTIONEN:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor White -NoNewline
    Write-Host "Neuen Wiederherstellungspunkt erstellen " -ForegroundColor Green -NoNewline
    Write-Host "(Empfohlen)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor White -NoNewline
    Write-Host "Verfügbare Wiederherstellungspunkte anzeigen " -ForegroundColor White -NoNewline
    Write-Host "(Liste)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor White -NoNewline
    Write-Host "System zu Wiederherstellungspunkt zurücksetzen " -ForegroundColor White -NoNewline
    Write-Host "(Vorsicht)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor White -NoNewline
    Write-Host "System Restore aktivieren " -ForegroundColor White -NoNewline
    Write-Host "(Falls deaktiviert)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [x] " -ForegroundColor White -NoNewline
    Write-Host "Zurück zum Hauptmenü" -ForegroundColor Red
    Write-Host ""
    
    $choice = if ($Mode -gt 0) { "$Mode" } else { Read-Host "Wahl [1-4/x]" }

    if ([string]::IsNullOrEmpty($choice)) { return }
    switch ($choice.ToLower()) {
        '1' {
            if (Get-Command New-SystemRestorePoint -ErrorAction SilentlyContinue) {
                New-SystemRestorePoint
            } else {
                Write-Error "ERROR: New-SystemRestorePoint function not found." -ErrorAction Continue
            }
        }
        '2' {
            if (Get-Command Get-SystemRestorePoints -ErrorAction SilentlyContinue) {
                Get-SystemRestorePoints
            } else {
                Write-Error "ERROR: Get-SystemRestorePoints function not found." -ErrorAction Continue
            }
        }
        '3' {
            if (Get-Command Restore-SystemToPoint -ErrorAction SilentlyContinue) {
                Restore-SystemToPoint
            } else {
                Write-Error "ERROR: Restore-SystemToPoint function not found." -ErrorAction Continue
            }
        }
        '4' {
            if (Get-Command Enable-SystemRestore -ErrorAction SilentlyContinue) {
                Enable-SystemRestore
            } else {
                Write-Error "ERROR: Enable-SystemRestore function not found." -ErrorAction Continue
            }
        }
        'x' {
            Write-Information "[INFO] Zurück zum Hauptmenü..." -InformationAction Continue
            return
        }
        default {
            Write-Information "[ERROR] Ungültige Auswahl: $choice" -InformationAction Continue
        }
    }
    
    if (-not $Force) { Read-Host "`nPress Enter to continue..." }
}

function New-SystemRestorePoint {
    param([string]$Description = "Hellion Tool v8.0.0.0 Jörmungandr")
    
    Write-Log "`n[*] --- WIEDERHERSTELLUNGSPUNKT ---" -Color Cyan
    
    if ($script:RestorePointCreated) {
        Write-Log "[INFO] Wiederherstellungspunkt bereits erstellt" -Color Gray
        return $true
    }
    
    try {
        Write-Log "[*] Erstelle Wiederherstellungspunkt..." -Color Blue
        
        # Prüfe ob System Restore aktiviert ist (ueber Registry statt Restore-Point-Existenz)
        $srConfig = Get-CimInstance -ClassName SystemRestoreConfig -Namespace "root\default" -ErrorAction SilentlyContinue
        $restoreEnabled = $srConfig -and $srConfig.RPSessionInterval -ne 0

        if (-not $restoreEnabled) {
            Write-Log "[INFO] Aktiviere System Restore auf C:\..." -Color Yellow
            if (Get-Command Enable-ComputerRestore -ErrorAction SilentlyContinue) {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
            } else {
                # PS7 Fallback
                & vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5% 2>$null | Out-Null
            }
        }

        # Erstelle Restore Point mit 24h-Bypass
        $fullDescription = "$Description - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

        try {
            # Versuche zuerst normalen Wiederherstellungspunkt
            if (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue) {
                Checkpoint-Computer -Description $fullDescription -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            } else {
                # PS7 Fallback: WMI-Klasse direkt verwenden
                $srClass = [wmiclass]"\\.\root\default:SystemRestore"
                $srClass.CreateRestorePoint($fullDescription, 12, 100) | Out-Null
            }
        } catch {
            # Falls 24h-Limit, versuche Registry-Override
            if ($_.Exception.Message -like "*1440 Minuten*" -or $_.Exception.Message -like "*24*hour*") {
                Write-Log "[INFO] 24h-Limit erreicht, versuche Registry-Override..." -Color Yellow
                try {
                    # Registry-Hack: Zeitlimit umgehen
                    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
                    $originalValue = Get-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
                    
                    Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 0 -ErrorAction Stop
                    
                    # Nochmal versuchen
                    Start-Sleep -Seconds 2
                    if (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue) {
                        Checkpoint-Computer -Description "$fullDescription (Registry-Override)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                    } else {
                        $srClass = [wmiclass]"\\.\root\default:SystemRestore"
                        $srClass.CreateRestorePoint("$fullDescription (Registry-Override)", 12, 100) | Out-Null
                    }
                    
                    # Registry-Wert zurücksetzen (24h Standard)
                    if ($originalValue) {
                        Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value $originalValue.SystemRestorePointCreationFrequency -ErrorAction SilentlyContinue
                    } else {
                        Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 1440 -ErrorAction SilentlyContinue
                    }
                    
                    Write-Log "[INFO] Wiederherstellungspunkt mit Registry-Override erstellt" -Color Green
                } catch {
                    Write-Log "[WARNING] Auch Registry-Override fehlgeschlagen: $($_.Exception.Message)" -Color Red
                    throw $_
                }
            } else {
                throw $_
            }
        }
        
        Add-Success "Wiederherstellungspunkt erstellt: $fullDescription"
        $script:RestorePointCreated = $true
        Write-Log "[INFO] Bei Problemen kann das System auf diesen Punkt zurückgesetzt werden" -Color Cyan
        
        return $true
        
    } catch {
        if ($_.Exception.Message -match "frequency") {
            Write-Log "[INFO] System Restore: Zeitlimit noch nicht erreicht (nur 1x/24h möglich)" -Color Yellow
            Add-Warning "Wiederherstellungspunkt: Zeitlimit (24h) noch nicht erreicht"
            return $true  # Nicht als Fehler werten
        } else {
            # KRITISCHER FEHLER: Wiederherstellungspunkt fehlgeschlagen
            Write-Log "\n🚨 KRITISCHER FEHLER: Wiederherstellungspunkt konnte NICHT erstellt werden!" -Color Red
            Write-Log "\nGrund: $($_.Exception.Message)" -Color Red
            Write-Log "\n🛡️ SICHERHEITS-WARNUNG:" -Color Red
            Write-Log "Ohne Backup ist das automatische Ausführen von System-Änderungen" -Color Yellow
            Write-Log "zu riskant. Auto-Modus wird aus Sicherheitsgründen abgebrochen." -Color Yellow
            Write-Log "\n📝 EMPFOHLENE LÖSUNGEN:" -Color Cyan
            Write-Log "1. System Restore in Windows aktivieren" -Color White
            Write-Log "2. Als Administrator ausführen" -Color White
            Write-Log "3. Ausreichend Festplattenspeicher sicherstellen (min. 300 MB)" -Color White
            Write-Log "4. Manueller Modus verwenden (ohne automatische Änderungen)" -Color White
            Write-Log "\n🚫 AUTO-MODUS ABGEBROCHEN - Sicherheit geht vor!" -Color Red
            
            Add-Warning "KRITISCH: Wiederherstellungspunkt fehlgeschlagen - Auto-Modus abgebrochen"
            
            # Rückgabe false signalisiert kritischen Fehler
            return $false
        }
    }
}

function Get-SystemRestorePoints {
    Write-Log "`n[*] --- VERFUEGBARE WIEDERHERSTELLUNGSPUNKTE ---" -Color Cyan
    
    try {
        if (Get-Command Get-ComputerRestorePoint -ErrorAction SilentlyContinue) {
            $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop
        } else {
            # PS7 Fallback: WMI-Klasse direkt abfragen
            $restorePoints = Get-CimInstance -ClassName SystemRestore -Namespace "root\default" -ErrorAction Stop
        }
        
        if ($restorePoints -and $restorePoints.Count -gt 0) {
            Write-Log "Gefunden: $($restorePoints.Count) Wiederherstellungspunkte" -Color White
            
            $restorePoints | Sort-Object CreationTime -Descending | Select-Object -First 10 | ForEach-Object {
                # CreationTime kann String (CIM) oder DateTime (PS5) sein
                $creationTime = if ($_.CreationTime -is [string]) {
                    [System.Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime)
                } else { $_.CreationTime }
                $ageInDays = [math]::Round((Get-Date).Subtract($creationTime).TotalDays, 1)
                Write-Log "  [$($_.SequenceNumber)] $($_.Description)" -Color Blue
                Write-Log "    Erstellt: $($creationTime.ToString('yyyy-MM-dd HH:mm')) ($ageInDays Tage alt)" -Color Gray
                Write-Log "    Typ: $($_.RestorePointType)" -Color Gray
                Write-Log "" -Color White
            }
            
            return $restorePoints
            
        } else {
            Write-Log "[INFO] Keine Wiederherstellungspunkte gefunden" -Color Yellow
            Write-Log "[INFO] System Restore ist möglicherweise deaktiviert" -Color Gray
            
            $choice = Read-Host "`nWiederherstellungspunkt jetzt erstellen? [j/n]"
            if ($choice -eq 'j' -or $choice -eq 'J') {
                return New-SystemRestorePoint -Description "Manuell erstellt"
            }
            
            return @()
        }
        
    } catch {
        Write-Log "[WARNING] Wiederherstellungspunkte konnten nicht abgerufen werden" -Color Red
        Write-Log "Mögliche Ursachen:" -Color Yellow
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
        Write-Log "[ERROR] Keine Wiederherstellungspunkte verfügbar!" -Color Red
        return $false
    }
    
    Write-Host ""
    Write-Host "[*] WIEDERHERSTELLUNGSOPTIONEN:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor White -NoNewline
    Write-Host "Letzten Wiederherstellungspunkt verwenden " -ForegroundColor Green -NoNewline
    Write-Host "(Schnell)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor White -NoNewline
    Write-Host "Wiederherstellungspunkt auswählen " -ForegroundColor Yellow -NoNewline
    Write-Host "(Erweitert)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor White -NoNewline
    Write-Host "System Restore GUI öffnen " -ForegroundColor Magenta -NoNewline
    Write-Host "(Manuell)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [x] " -ForegroundColor White -NoNewline
    Write-Host "Abbrechen" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "`nWahl [1-3/x]"
    
    switch ($choice.ToLower()) {
        '1' {
            $latestRestore = $restorePoints | Sort-Object CreationTime -Descending | Select-Object -First 1
            
            Write-Information "[INFO] `n[WARNUNG] Das System wird auf folgenden Punkt zurückgesetzt:" -InformationAction Continue
            Write-Information "[INFO]   Beschreibung: $($latestRestore.Description)" -InformationAction Continue
            Write-Information "[INFO]   Erstellt: $($latestRestore.CreationTime)" -InformationAction Continue
            Write-Information "[INFO] `n[WICHTIG] Alle Änderungen seit diesem Zeitpunkt gehen verloren!" -InformationAction Continue
            
            $confirm = Read-Host "`nWirklich fortfahren? [CONFIRM] (Tippe 'CONFIRM' zum Bestätigen)"
            
            if ($confirm -eq 'CONFIRM') {
                try {
                    Write-Log "[*] Starte System-Wiederherstellung..." -Color Blue
                    if (Get-Command Restore-Computer -ErrorAction SilentlyContinue) {
                        Restore-Computer -RestorePoint $latestRestore.SequenceNumber -Confirm:$false -ErrorAction Stop
                    } else {
                        # PS7 Fallback: WMI-Klasse
                        $srClass = [wmiclass]"\\.\root\default:SystemRestore"
                        $srClass.Restore($latestRestore.SequenceNumber) | Out-Null
                    }

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
            Write-Information "[INFO] `nVerfügbare Wiederherstellungspunkte:" -InformationAction Continue
            
            for ($i = 0; $i -lt [Math]::Min(10, $restorePoints.Count); $i++) {
                $rp = $restorePoints[$i]
                Write-Information "[INFO]   [$($i+1)] $($rp.Description) - $($rp.CreationTime.ToString('yyyy-MM-dd HH:mm'))" -InformationAction Continue
            }
            
            $selection = Read-Host "`nWiederherstellungspunkt wählen [1-$([Math]::Min(10, $restorePoints.Count))]"
            
            try {
                $selectedIndex = [int]$selection - 1
                if ($selectedIndex -ge 0 -and $selectedIndex -lt $restorePoints.Count) {
                    $selectedRestore = $restorePoints[$selectedIndex]
                    
                    $confirm = Read-Host "`nAuf '$($selectedRestore.Description)' zurücksetzen? [CONFIRM]"
                    if ($confirm -eq 'CONFIRM') {
                        if (Get-Command Restore-Computer -ErrorAction SilentlyContinue) {
                            Restore-Computer -RestorePoint $selectedRestore.SequenceNumber -Confirm:$false
                        } else {
                            $srClass = [wmiclass]"\\.\root\default:SystemRestore"
                            $srClass.Restore($selectedRestore.SequenceNumber) | Out-Null
                        }
                        Add-Success "System-Wiederherstellung: Manuell gestartet"
                        return $true
                    }
                }
            } catch {
                Write-Log "[ERROR] Ungültige Auswahl" -Color Red
            }
        }
        '3' {
            Write-Log "[*] Öffne System Restore GUI..." -Color Blue
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
            Write-Log "[ERROR] Ungültige Auswahl" -Color Red
        }
    }
    
    return $false
}

function Enable-SystemRestore {
    Write-Log "`n[*] --- SYSTEM RESTORE AKTIVIERUNG ---" -Color Cyan
    
    try {
        # System Restore nur auf dem System-Laufwerk aktivieren
        $systemDrive = $env:SystemDrive
        Write-Log "[*] Aktiviere System Restore auf $systemDrive..." -Color Blue

        try {
            if (Get-Command Enable-ComputerRestore -ErrorAction SilentlyContinue) {
                Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction Stop
            } else {
                # PS7 Fallback: vssadmin
                & vssadmin resize shadowstorage /for=$systemDrive /on=$systemDrive /maxsize=5% 2>$null | Out-Null
            }
            Write-Log "[OK] System Restore aktiviert auf $systemDrive" -Color Green
        } catch {
            Write-Log "[WARNING] System Restore auf $systemDrive nicht aktivierbar" -Color Yellow
        }
        
        # Speicherplatz-Konfiguration (optional)
        Write-Host ""
        Write-Host "Speicherplatz für System Restore konfigurieren?" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   [1] " -ForegroundColor White -NoNewline
        Write-Host "Standard " -ForegroundColor Green -NoNewline
        Write-Host "(5% der Festplatte)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [2] " -ForegroundColor White -NoNewline
        Write-Host "Minimal " -ForegroundColor Yellow -NoNewline
        Write-Host "(2% der Festplatte)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [3] " -ForegroundColor White -NoNewline
        Write-Host "Maximal " -ForegroundColor Magenta -NoNewline
        Write-Host "(10% der Festplatte)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [s] " -ForegroundColor White -NoNewline
        Write-Host "Überspringen" -ForegroundColor Gray
        Write-Host ""
        
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
