# ===================================================================
# SYSTEM INFORMATION MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Get-DetailedSystemInfo {
    Write-Log "`n[*] --- DETAILLIERTE SYSTEM-INFORMATION ---" -Color Cyan
    
    $systemInfo = @{}
    
    try {
        # Grundlegende System-Info
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $operatingSystem = Get-WmiObject -Class Win32_OperatingSystem
        $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        $memory = Get-WmiObject -Class Win32_PhysicalMemory
        
        $systemInfo.ComputerName = $computerSystem.Name
        $systemInfo.Manufacturer = $computerSystem.Manufacturer
        $systemInfo.Model = $computerSystem.Model
        $systemInfo.TotalRAM = [math]::Round(($memory | Measure-Object Capacity -Sum).Sum / 1GB, 2)
        
        # Betriebssystem
        $systemInfo.OSName = $operatingSystem.Caption
        $systemInfo.OSVersion = $operatingSystem.Version
        $systemInfo.OSBuild = $operatingSystem.BuildNumber
        $systemInfo.OSArchitecture = $operatingSystem.OSArchitecture
        # InstallDate sicher konvertieren
        try {
            if ($operatingSystem.InstallDate) {
                # Versuche WMI ConvertToDateTime Methode
                if ($operatingSystem -is [System.Management.ManagementObject]) {
                    $systemInfo.InstallDate = $operatingSystem.ConvertToDateTime($operatingSystem.InstallDate)
                } else {
                    # Fallback: Manuelle Konvertierung aus WMI DateTime Format
                    $wmidatePattern = '(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})'
                    if ($operatingSystem.InstallDate -match $wmidatePattern) {
                        $systemInfo.InstallDate = Get-Date -Year $matches[1] -Month $matches[2] -Day $matches[3] -Hour $matches[4] -Minute $matches[5] -Second $matches[6]
                    } else {
                        $systemInfo.InstallDate = "Unbekannt"
                    }
                }
            } else {
                $systemInfo.InstallDate = "Unbekannt"
            }
        } catch {
            Write-Log "InstallDate konvertierung fehlgeschlagen: $($_.Exception.Message)" -Level "DEBUG"
            $systemInfo.InstallDate = "Unbekannt"
        }
        
        # Prozessor
        $systemInfo.CPUName = $processor.Name
        $systemInfo.CPUCores = $processor.NumberOfCores
        $systemInfo.CPUThreads = $processor.NumberOfLogicalProcessors
        $systemInfo.CPUSpeed = $processor.MaxClockSpeed
        
        # Anzeige
        Write-Log "`n=== SYSTEM ====" -Color Blue
        Write-Log "Computer: $($systemInfo.ComputerName)" -Color White
        Write-Log "Hersteller: $($systemInfo.Manufacturer)" -Color White
        Write-Log "Modell: $($systemInfo.Model)" -Color White
        
        Write-Log "`n=== BETRIEBSSYSTEM ===" -Color Blue
        Write-Log "OS: $($systemInfo.OSName)" -Color White
        Write-Log "Version: $($systemInfo.OSVersion) (Build $($systemInfo.OSBuild))" -Color White
        Write-Log "Architektur: $($systemInfo.OSArchitecture)" -Color White
        Write-Log "Installation: $($systemInfo.InstallDate.ToString('yyyy-MM-dd'))" -Color White
        
        Write-Log "`n=== HARDWARE ===" -Color Blue
        Write-Log "CPU: $($systemInfo.CPUName)" -Color White
        Write-Log "Kerne: $($systemInfo.CPUCores) (Threads: $($systemInfo.CPUThreads))" -Color White
        Write-Log "Takt: $($systemInfo.CPUSpeed) MHz" -Color White
        Write-Log "RAM: $($systemInfo.TotalRAM) GB" -Color White
        
    } catch {
        Add-Error "System-Information konnte nicht abgerufen werden" $_.Exception.Message
    }
    
    return $systemInfo
}

function Test-SystemCompatibility {
    Write-Log "`n[*] --- SYSTEM-KOMPATIBILITAETS-PRUEFUNG ---" -Color Cyan
    
    $compatible = $true
    $issues = @()
    
    try {
        # Windows-Version pruefen
        $osVersion = [System.Environment]::OSVersion.Version
        if ($osVersion.Major -lt 10) {
            $issues += "Windows 10/11 empfohlen (aktuell: Windows $($osVersion.Major).$($osVersion.Minor))"
            $compatible = $false
        } else {
            Write-Log "[OK] Windows-Version kompatibel" -Color Green
        }
        
        # PowerShell-Version pruefen
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -lt 5) {
            $issues += "PowerShell 5.0+ erforderlich (aktuell: $($psVersion.Major).$($psVersion.Minor))"
            $compatible = $false
        } else {
            Write-Log "[OK] PowerShell-Version kompatibel" -Color Green
        }
        
        # Admin-Rechte pruefen
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $issues += "Administrator-Rechte erforderlich"
            $compatible = $false
        } else {
            Write-Log "[OK] Administrator-Rechte verfuegbar" -Color Green
        }
        
        # Speicherplatz pruefen
        $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "$env:SystemDrive" }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -lt 5) {
            $issues += "Mindestens 5 GB freier Speicher empfohlen (verfuegbar: $freeSpaceGB GB)"
            $compatible = $false
        } else {
            Write-Log "[OK] Ausreichend freier Speicher ($freeSpaceGB GB)" -Color Green
        }
        
        # Antivirus-Status pruefen
        try {
            $antivirusStatus = Test-AntivirusStatus
            if ($antivirusStatus.RealTimeProtectionEnabled) {
                Write-Log "[INFO] Echtzeit-Antivirus aktiv - Langsamere Operationen moeglich" -Color Yellow
            }
        } catch {
            Write-Log "[INFO] Antivirus-Status konnte nicht geprueft werden" -Color Gray
        }
        
    } catch {
        Add-Error "Kompatibilitaets-Pruefung fehlgeschlagen" $_.Exception.Message
        return $false
    }
    
    if ($compatible) {
        Write-Log "`n[OK] System ist vollstaendig kompatibel!" -Color Green
    } else {
        Write-Log "`n[WARNING] Kompatibilitaets-Probleme gefunden:" -Color Red
        foreach ($issue in $issues) {
            Write-Log "  - $issue" -Color Yellow
        }
    }
    
    return $compatible
}

function Test-AntivirusStatus {
    Write-Log "`n[*] --- ANTIVIRUS-STATUS PRUEFUNG ---" -Color Cyan
    
    $antivirusInfo = @{
        ProductName = "Unbekannt"
        RealTimeProtectionEnabled = $false
        UpToDate = $false
        Products = @()
    }
    
    try {
        # Windows Security Center abfragen
        $antivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        
        if ($antivirusProducts) {
            foreach ($product in $antivirusProducts) {
                $productState = $product.productState
                
                # Bit-Manipulation fuer Status-Interpretation
                $realTimeProtection = ($productState -band 0x1000) -ne 0
                $upToDate = ($productState -band 0x10) -eq 0
                
                $productInfo = @{
                    Name = $product.displayName
                    RealTimeProtection = $realTimeProtection
                    UpToDate = $upToDate
                    State = $productState
                }
                
                $antivirusInfo.Products += $productInfo
                
                Write-Log "[*] Antivirus: $($product.displayName)" -Color Blue
                
                if ($realTimeProtection) {
                    Write-Log "    [OK] Echtzeitschutz aktiv" -Color Green
                    $antivirusInfo.RealTimeProtectionEnabled = $true
                } else {
                    Write-Log "    [WARNING] Echtzeitschutz inaktiv" -Color Red
                }
                
                if ($upToDate) {
                    Write-Log "    [OK] Definitionen aktuell" -Color Green
                    $antivirusInfo.UpToDate = $true
                } else {
                    Write-Log "    [WARNING] Definitionen veraltet" -Color Yellow
                }
            }
            
            $antivirusInfo.ProductName = $antivirusProducts[0].displayName
            
        } else {
            # Fallback: Windows Defender pruefen
            try {
                $defenderStatus = Get-MpPreference -ErrorAction SilentlyContinue
                if ($defenderStatus) {
                    Write-Log "[*] Windows Defender gefunden" -Color Blue
                    
                    if ($defenderStatus.DisableRealtimeMonitoring -eq $false) {
                        Write-Log "    [OK] Echtzeitschutz aktiv" -Color Green
                        $antivirusInfo.RealTimeProtectionEnabled = $true
                    } else {
                        Write-Log "    [WARNING] Echtzeitschutz deaktiviert" -Color Red
                    }
                    
                    $antivirusInfo.ProductName = "Windows Defender"
                }
            } catch {
                Write-Log "[INFO] Antivirus-Status konnte nicht ermittelt werden" -Color Gray
            }
        }
        
    } catch {
        Write-Log "[WARNING] Antivirus-Abfrage fehlgeschlagen: $($_.Exception.Message)" -Color Yellow
    }
    
    return $antivirusInfo
}

function Get-DetailedDriverStatus {
    Write-Log "`n[*] --- TREIBER-STATUS ANALYSE ---" -Color Cyan
    
    $driverIssues = @()
    
    try {
        # Problemgeraete aus Device Manager
        $problemDevices = Get-WmiObject -Class Win32_PnPEntity | Where-Object { 
            $_.ConfigManagerErrorCode -ne 0 -and $null -ne $_.ConfigManagerErrorCode 
        }
        
        if ($problemDevices -and $problemDevices.Count -gt 0) {
            Write-Log "[WARNING] Problematische Geraete gefunden:" -Color Red
            
            foreach ($device in $problemDevices) {
                $errorCode = $device.ConfigManagerErrorCode
                $errorDescription = switch ($errorCode) {
                    1 { "Geraet nicht richtig konfiguriert" }
                    10 { "Geraet kann nicht gestartet werden" }
                    22 { "Geraet deaktiviert" }
                    28 { "Treiber nicht installiert" }
                    default { "Unbekannter Fehler (Code: $errorCode)" }
                }
                
                Write-Log "  [!] $($device.Name): $errorDescription" -Color Yellow
                
                $driverIssues += @{
                    DeviceName = $device.Name
                    ErrorCode = $errorCode
                    ErrorDescription = $errorDescription
                    DeviceID = $device.DeviceID
                }
            }
        } else {
            Write-Log "[OK] Keine problematischen Geraete gefunden" -Color Green
        }
        
        # Veraltete Treiber suchen (vereinfacht)
        $drivers = Get-WmiObject -Class Win32_SystemDriver | Where-Object { $_.State -eq "Running" }
        $outdatedDrivers = @()
        
        foreach ($driver in $drivers) {
            try {
                $driverDate = $driver.InstallDate
                if ($driverDate) {
                    $installDate = [Management.ManagementDateTimeConverter]::ToDateTime($driverDate)
                    if ($installDate -lt (Get-Date).AddYears(-3)) {
                        $outdatedDrivers += @{
                            Name = $driver.Name
                            InstallDate = $installDate
                            PathName = $driver.PathName
                        }
                    }
                }
            } catch {
                # Datum nicht parsbar - ignorieren
            }
        }
        
        if ($outdatedDrivers.Count -gt 0) {
            Write-Log "`n[INFO] Sehr alte Treiber gefunden (>3 Jahre):" -Color Yellow
            $outdatedDrivers | Select-Object -First 5 | ForEach-Object {
                Write-Log "  - $($_.Name): $($_.InstallDate.ToString('yyyy-MM-dd'))" -Color Gray
            }
            
            if ($outdatedDrivers.Count -gt 5) {
                Write-Log "  ... und $($outdatedDrivers.Count - 5) weitere" -Color Gray
            }
        }
        
    } catch {
        Add-Error "Treiber-Analyse fehlgeschlagen" $_.Exception.Message
    }
    
    return $driverIssues
}

function New-DetailedSystemReport {
    Write-Log "`n[*] --- DETAILLIERTER SYSTEM-BERICHT ---" -Color Cyan
    
    # Report-Pfad erstellen (mit Fallback wenn LogDirectory nicht verfügbar)
    $reportDir = if ($script:LogDirectory -and (Test-Path $script:LogDirectory)) { 
        $script:LogDirectory 
    } else { 
        "$env:TEMP\HellionPowerTool"
    }
    
    # Verzeichnis erstellen falls es nicht existiert
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportPath = Join-Path $reportDir "system_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    try {
        $report = @"
================================================================
HELLION POWER TOOL - SYSTEM-BERICHT
Generiert am: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
================================================================

"@
        
        # System-Information sammeln
        $systemInfo = Get-DetailedSystemInfo
        $report += "`nSYSTEM-INFORMATION:`n"
        $report += "Computer: $($systemInfo.ComputerName)`n"
        $report += "OS: $($systemInfo.OSName)`n"
        $report += "Version: $($systemInfo.OSVersion)`n"
        $report += "CPU: $($systemInfo.CPUName)`n"
        $report += "RAM: $($systemInfo.TotalRAM) GB`n"
        
        # Antivirus-Status
        $antivirusStatus = Test-AntivirusStatus
        $report += "`nANTIVIRUS-STATUS:`n"
        $report += "Produkt: $($antivirusStatus.ProductName)`n"
        $report += "Echtzeitschutz: $(if($antivirusStatus.RealTimeProtectionEnabled){'Aktiv'}else{'Inaktiv'})`n"
        
        # Treiber-Probleme
        $driverIssues = Get-DetailedDriverStatus
        if ($driverIssues.Count -gt 0) {
            $report += "`nTREIBER-PROBLEME:`n"
            foreach ($issue in $driverIssues) {
                $report += "- $($issue.DeviceName): $($issue.ErrorDescription)`n"
            }
        } else {
            $report += "`nTREIBER-STATUS: Keine Probleme gefunden`n"
        }
        
        # Laufwerks-Information
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $report += "`nLAUFWERKE:`n"
        foreach ($drive in $drives) {
            $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($drive.Size / 1GB, 2)
            $usedPercent = [math]::Round((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100, 1)
            $report += "$($drive.DeviceID) $totalGB GB ($usedPercent% belegt, $freeGB GB frei)`n"
        }
        
        # Aktionen-Log
        if ($script:ActionsPerformed -and $script:ActionsPerformed.Count -gt 0) {
            $report += "`nDURCHGEFUEHRTE AKTIONEN:`n"
            foreach ($action in $script:ActionsPerformed) {
                $report += "- $action`n"
            }
        }
        
        # Fehler und Warnungen
        if ($script:Errors -and $script:Errors.Count -gt 0) {
            $report += "`nFEHLER:`n"
            foreach ($scriptError in $script:Errors) {
                $report += "- $($scriptError.Message)`n"
            }
        }
        
        if ($script:Warnings -and $script:Warnings.Count -gt 0) {
            $report += "`nWARNUNGEN:`n"
            foreach ($warning in $script:Warnings) {
                $report += "- $($warning.Message)`n"
            }
        }
        
        # Bericht speichern
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        
        Write-Log "`n[SUCCESS] System-Bericht erstellt: $reportPath" -Color Green
        Write-Log "[INFO] Bericht-Groesse: $([math]::Round((Get-Item $reportPath).Length / 1KB, 2)) KB" -Color Gray
        
        return $reportPath
        
    } catch {
        Add-Error "System-Bericht konnte nicht erstellt werden" $_.Exception.Message
        return $null
    }
}

function Test-CommandAvailability {
    param([string]$CommandName)
    
    try {
        Get-Command $CommandName -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Export functions for dot-sourcing
Write-Verbose "System-Info Module loaded: Get-DetailedSystemInfo, Test-SystemCompatibility, Test-AntivirusStatus, Get-DetailedDriverStatus, New-DetailedSystemReport, Test-CommandAvailability"