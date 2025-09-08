# =============================================================================
# Hellion Power Tool - Crash/Bluescreen Analyzer Module
# Analyzes Windows crash dumps and event logs to identify crash causes
# DEFENDER-SAFE: Only read-only operations, no system modifications
# =============================================================================

function Get-SystemCrashAnalysis {
    <#
    .SYNOPSIS
    Analyzes system crashes and bluescreens to identify causes and solutions
    .DESCRIPTION
    Enhanced defender-safe analysis using Windows Event Logs, Minidump file info,
    hardware detection, and built-in PowerShell cmdlets. No external tools or risky operations.
    
    Features:
    - Hardware-specific recommendations
    - Automatic log cleanup
    - Interactive error retry options
    #>
    
    Write-Information "[INFO] `n=== BLUESCREEN/CRASH ANALYZER (Enhanced) ===" -InformationAction Continue
    Write-Information "[INFO] Analysiere System-Abstuerze und Bluescreens..." -InformationAction Continue
    Write-Information "[INFO] " -InformationAction Continue
    
    # Hardware-Erkennung für spezifische Empfehlungen
    $HardwareInfo = @{}
    try {
        # GPU-Erkennung
        $GPU = Get-WmiObject -Class Win32_VideoController -ErrorAction SilentlyContinue | 
               Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
        if ($GPU) {
            $HardwareInfo.GPU = @{
                Name = $GPU.Name
                Driver = $GPU.DriverVersion
                Vendor = if ($GPU.Name -like "*NVIDIA*") { "NVIDIA" } 
                        elseif ($GPU.Name -like "*AMD*" -or $GPU.Name -like "*Radeon*") { "AMD" } 
                        elseif ($GPU.Name -like "*Intel*") { "Intel" } 
                        else { "Unknown" }
            }
        }
        
        # CPU-Erkennung
        $CPU = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($CPU) {
            $HardwareInfo.CPU = @{
                Name = $CPU.Name
                Vendor = if ($CPU.Name -like "*Intel*") { "Intel" } 
                        elseif ($CPU.Name -like "*AMD*") { "AMD" } 
                        else { "Unknown" }
            }
        }
        
        # RAM-Info
        $RAM = Get-WmiObject -Class Win32_PhysicalMemory -ErrorAction SilentlyContinue
        if ($RAM) {
            $TotalRAM = ($RAM | Measure-Object -Property Capacity -Sum).Sum / 1GB
            $HardwareInfo.RAM = @{
                TotalGB = [math]::Round($TotalRAM, 1)
                Modules = $RAM.Count
            }
        }
    } catch {
        Write-Information "[INFO] [DEBUG] Hardware-Erkennung teilweise fehlgeschlagen" -InformationAction Continue
    }
    
    # Stop-Code-Datenbank (statisch, defender-safe)
    $StopCodes = @{
        "0x00000001" = "APC_INDEX_MISMATCH"
        "0x00000007" = "INVALID_SOFTWARE_INTERRUPT"
        "0x0000000A" = "IRQL_NOT_LESS_OR_EQUAL - Treiberproblem"
        "0x0000001A" = "MEMORY_MANAGEMENT - RAM/Speicher Problem"
        "0x0000001E" = "KMODE_EXCEPTION_NOT_HANDLED - Kernelfehler"
        "0x00000024" = "NTFS_FILE_SYSTEM - Festplattenproblem"
        "0x0000003B" = "SYSTEM_SERVICE_EXCEPTION - Treiber/Hardware"
        "0x0000003D" = "INTERRUPT_EXCEPTION_NOT_HANDLED - Hardware"
        "0x00000050" = "PAGE_FAULT_IN_NONPAGED_AREA - RAM/Treiber"
        "0x0000007E" = "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED - Treiberproblem"
        "0x0000007F" = "UNEXPECTED_KERNEL_MODE_TRAP - Hardware/Uebertaktung"
        "0x00000116" = "VIDEO_TDR_ERROR - Grafiktreiber-Problem"
        "0x00000124" = "WHEA_UNCORRECTABLE_ERROR - Hardware-Fehler"
        "0x0000009F" = "DRIVER_POWER_STATE_FAILURE - Energieverwaltung"
        "0x000000C2" = "BAD_POOL_CALLER - Treiber/Software Problem"
        "0x000000D1" = "DRIVER_IRQL_NOT_LESS_OR_EQUAL - Treiberfehler"
        "0x000000F4" = "CRITICAL_OBJECT_TERMINATION - Systemdienst"
    }
    
    $Solutions = @{
        "0x0000000A" = "Treiber aktualisieren, RAM testen (MemTest86)"
        "0x0000001A" = "RAM austauschen, Speicher-Diagnose ausfuehren"
        "0x0000003B" = "Grafik-/Netzwerktreiber aktualisieren"
        "0x0000007E" = "Alle Treiber aktualisieren, Hardware pruefen"
        "0x0000007F" = "Uebertaktung zuruecksetzen, Hardware testen"
        "0x00000116" = "Grafiktreiber neu installieren, GPU testen"
        "0x00000124" = "Hardware-Check: CPU, RAM, Mainboard, Netzteil"
        "0x0000009F" = "Energieeinstellungen pruefen, Treiber aktualisieren"
    }
    
    try {
        # 1. Event Log Analysis (100% Defender-Safe)
        Write-Information "[INFO] [*] Analysiere Windows Event Logs..." -InformationAction Continue
        
        $CrashEvents = @()
        
        # System Log - Bugcheck Events (ID 1001)
        try {
            $BugCheckEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                ID = 1001
            } -MaxEvents 10 -ErrorAction SilentlyContinue
            
            if ($BugCheckEvents) {
                $CrashEvents += $BugCheckEvents | ForEach-Object {
                    @{
                        Time = $_.TimeCreated
                        Type = "Bluescreen/Bugcheck"
                        Message = $_.Message
                        Source = "System Event Log"
                    }
                }
                Write-Information "[INFO]     [OK] $($BugCheckEvents.Count) Bluescreen-Events gefunden" -InformationAction Continue
            }
        } catch {
            Write-Information "[INFO]     [INFO] Keine Bugcheck-Events im System Log" -InformationAction Continue
        }
        
        # System Log - Unexpected Shutdown (ID 6008)
        try {
            $ShutdownEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                ID = 6008
            } -MaxEvents 5 -ErrorAction SilentlyContinue
            
            if ($ShutdownEvents) {
                $CrashEvents += $ShutdownEvents | ForEach-Object {
                    @{
                        Time = $_.TimeCreated
                        Type = "Unexpected Shutdown"
                        Message = $_.Message
                        Source = "System Event Log"
                    }
                }
                Write-Information "[INFO]     [OK] $($ShutdownEvents.Count) Unerwartete Abschaltereignisse gefunden" -InformationAction Continue
            }
        } catch {
            Write-Information "[INFO]     [INFO] Keine unerwarteten Shutdown-Events gefunden" -InformationAction Continue
        }
        
        # 2. Minidump File Analysis (Nur Metadaten, Defender-Safe)
        Write-Information "[INFO] `n[*] Analysiere Minidump-Dateien..." -InformationAction Continue
        
        $MinidumpPath = "C:\Windows\Minidump"
        $MinidumpFiles = @()
        
        if (Test-Path $MinidumpPath) {
            $MinidumpFiles = Get-ChildItem "$MinidumpPath\*.dmp" -ErrorAction SilentlyContinue | 
                Sort-Object CreationTime -Descending | Select-Object -First 10
            
            if ($MinidumpFiles.Count -gt 0) {
                Write-Information "[INFO]     [OK] $($MinidumpFiles.Count) Minidump-Dateien gefunden" -InformationAction Continue
                
                # Zeige letzte Crash-Dumps
                Write-Information "[INFO] `n--- LETZTE CRASH-DUMPS ---" -InformationAction Continue
                $MinidumpFiles | ForEach-Object {
                    $SizeMB = [math]::Round($_.Length / 1MB, 2)
                    Write-Information "[INFO]     $($_.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')) - $($_.Name) ($SizeMB MB)" -InformationAction Continue
                }
            } else {
                Write-Information "[INFO]     [INFO] Keine Minidump-Dateien gefunden" -InformationAction Continue
            }
        } else {
            Write-Information "[INFO]     [INFO] Minidump-Ordner existiert nicht" -InformationAction Continue
        }
        
        # 3. Reliability Monitor Data (WMI, Defender-Safe)
        Write-Information "[INFO] `n[*] Analysiere Windows Reliability History..." -InformationAction Continue
        
        try {
            $ReliabilityData = Get-WmiObject -Class Win32_ReliabilityRecords -ErrorAction SilentlyContinue |
                Where-Object { $_.SourceName -like "*Bugcheck*" -or $_.EventIdentifier -eq 1001 } |
                Sort-Object TimeGenerated -Descending | Select-Object -First 5
                
            if ($ReliabilityData) {
                Write-Information "[INFO]     [OK] $($ReliabilityData.Count) Reliability-Eintraege gefunden" -InformationAction Continue
            }
        } catch {
            Write-Information "[INFO]     [INFO] Reliability-Daten nicht verfuegbar" -InformationAction Continue
        }
        
        # 4. Analyse-Ausgabe
        Write-Information "[INFO] `n=== CRASH-ANALYSE ERGEBNISSE ===" -InformationAction Continue
        
        if ($CrashEvents.Count -eq 0 -and $MinidumpFiles.Count -eq 0) {
            Write-Information "[INFO] [GOOD NEWS] Keine aktuellen System-Abstuerze gefunden!" -InformationAction Continue
            Write-Information "[INFO] Ihr System scheint stabil zu laufen." -InformationAction Continue
            return
        }
        
        # Zeige Event-basierte Crashes
        if ($CrashEvents.Count -gt 0) {
            Write-Information "[INFO] `n--- EVENT LOG CRASHES ---" -InformationAction Continue
            
            $CrashEvents | Sort-Object Time -Descending | ForEach-Object {
                Write-Information "[INFO] `n[CRASH] $($_.Time.ToString('yyyy-MM-dd HH:mm:ss')) - $($_.Type)" -InformationAction Continue
                
                # Extrahiere Stop-Code aus Message (verbesserte Regex)
                $Message = $_.Message
                $StopCodeMatch = [regex]::Match($Message, '0x[0-9A-Fa-f]{8,10}')
                
                # Fix für häufigen Parsing-Fehler: 0x000000f7 → 0x0000007F
                if ($StopCodeMatch.Success) {
                    $rawCode = $StopCodeMatch.Value
                    # Normalisiere auf 10 Zeichen (0x + 8 hex digits)
                    if ($rawCode.Length -eq 10) {
                        $StopCodeMatch = [PSCustomObject]@{ Success = $true; Value = $rawCode }
                    } else {
                        # Versuche häufige Patterns zu reparieren
                        $fixedCode = $rawCode -replace '0x0*([0-9A-Fa-f]{1,8})', '0x$1'
                        if ($fixedCode.Length -lt 10) {
                            $hexPart = $fixedCode.Substring(2).PadLeft(8, '0')
                            $fixedCode = "0x$hexPart"
                        }
                        $StopCodeMatch = [PSCustomObject]@{ Success = $true; Value = $fixedCode }
                    }
                }
                
                if ($StopCodeMatch.Success) {
                    $StopCode = $StopCodeMatch.Value
                    Write-Information "[INFO]     Stop-Code: $StopCode" -InformationAction Continue
                    
                    # Lookup Stop-Code
                    if ($StopCodes.ContainsKey($StopCode)) {
                        Write-Information "[INFO]     Bedeutung: $($StopCodes[$StopCode])" -InformationAction Continue
                    }
                    
                    # Hardware-spezifische Lösungsvorschläge
                    if ($Solutions.ContainsKey($StopCode)) {
                        $baseSolution = $Solutions[$StopCode]
                        $enhancedSolution = $baseSolution
                        
                        # GPU-spezifische Empfehlungen
                        if ($StopCode -eq "0x00000116" -and $HardwareInfo.GPU) {
                            $vendor = $HardwareInfo.GPU.Vendor
                            $gpuName = $HardwareInfo.GPU.Name
                            $enhancedSolution = "[$vendor GPU erkannt: $gpuName] - $baseSolution"
                            if ($vendor -eq "NVIDIA") {
                                $enhancedSolution += " | DDU + GeForce Experience verwenden"
                            } elseif ($vendor -eq "AMD") {
                                $enhancedSolution += " | DDU + AMD Software Adrenalin verwenden"
                            }
                        }
                        
                        # CPU-spezifische Empfehlungen  
                        if ($StopCode -eq "0x0000007F" -and $HardwareInfo.CPU) {
                            $cpuVendor = $HardwareInfo.CPU.Vendor
                            $enhancedSolution = "[$cpuVendor CPU erkannt] - $baseSolution"
                            if ($cpuVendor -eq "Intel") {
                                $enhancedSolution += " | Intel Processor Diagnostic Tool verwenden"
                            } elseif ($cpuVendor -eq "AMD") {
                                $enhancedSolution += " | AMD Ryzen Master zuruecksetzen"
                            }
                        }
                        
                        # RAM-spezifische Empfehlungen
                        if ($StopCode -eq "0x0000001A" -and $HardwareInfo.RAM) {
                            $ramSize = $HardwareInfo.RAM.TotalGB
                            $modules = $HardwareInfo.RAM.Modules
                            $enhancedSolution = "[RAM: $ramSize GB, $modules Module] - $baseSolution"
                            if ($modules -gt 1) {
                                $enhancedSolution += " | Teste einzelne RAM-Module"
                            }
                        }
                        
                        Write-Information "[INFO]     Loesung: $enhancedSolution" -InformationAction Continue
                    }
                }
                
                # Parameter extrahieren (vereinfacht)
                $ParamMatch = [regex]::Matches($Message, '0x[0-9A-Fa-f]{16}')
                if ($ParamMatch.Count -ge 4) {
                    Write-Information "[INFO]     Parameter: $($ParamMatch[0].Value), $($ParamMatch[1].Value)" -InformationAction Continue
                }
            }
        }
        
        # Automatische Minidump-Kopie für Analyse
        if ($MinidumpFiles.Count -gt 0) {
            Write-Information "[INFO] `n--- MINIDUMP DESKTOP-KOPIE ---" -InformationAction Continue
            $LatestDump = $MinidumpFiles | Sort-Object CreationTime -Descending | Select-Object -First 1
            
            try {
                $DesktopPath = [Environment]::GetFolderPath("Desktop")
                $StopCodeSuffix = ""
                
                # Versuche Stop-Code aus aktuellstem Event zu extrahieren
                $LatestEvent = $CrashEvents | Sort-Object Time -Descending | Select-Object -First 1
                if ($LatestEvent -and $LatestEvent.Message) {
                    $StopMatch = [regex]::Match($LatestEvent.Message, '0x[0-9A-Fa-f]{8}')
                    if ($StopMatch.Success) {
                        $StopCodeSuffix = "_$($StopMatch.Value.Replace('0x', ''))"
                    }
                }
                
                $DestFileName = "CrashDump_$($LatestDump.CreationTime.ToString('yyyyMMdd_HHmmss'))$StopCodeSuffix.dmp"
                $DestPath = Join-Path $DesktopPath $DestFileName
                
                # Kopiere nur wenn noch nicht vorhanden
                if (-not (Test-Path $DestPath)) {
                    Copy-Item $LatestDump.FullName $DestPath -ErrorAction SilentlyContinue
                    Write-Information "[INFO] [KOPIERT] Neuester Minidump auf Desktop: $DestFileName" -InformationAction Continue
                    Write-Information "[INFO] Kann mit BlueScreenView/WhoCrashed analysiert werden" -InformationAction Continue
                } else {
                    Write-Information "[INFO] Minidump bereits auf Desktop vorhanden: $DestFileName" -InformationAction Continue
                }
            } catch {
                Write-Warning "Minidump-Kopie fehlgeschlagen: $($_.Exception.Message)"
            }
        }
        
        # Häufigkeits-Analyse mit Kritikalitäts-Einstufung
        if ($CrashEvents.Count -gt 1) {
            Write-Information "[INFO] `n--- CRASH-HAEUFIGKEIT ---" -InformationAction Continue
            
            $RecentCrashes = $CrashEvents | Where-Object { $_.Time -gt (Get-Date).AddDays(-7) }
            $TotalCrashes = $CrashEvents.Count
            
            if ($RecentCrashes.Count -gt 5) {
                Write-Information "[INFO] 🚨 [KRITISCH] $($RecentCrashes.Count) von $TotalCrashes Crashes in 7 Tagen - HARDWARE-NOTFALL!" -InformationAction Continue
                Write-Information "[INFO] ⚠️  System ist hochgradig instabil - Sofortige Maßnahmen erforderlich" -InformationAction Continue
                Write-Information "[INFO] 💡 Empfehlung: Computer bis zur Reparatur minimal nutzen" -InformationAction Continue
            } elseif ($RecentCrashes.Count -gt 2) {
                Write-Information "[INFO] [WARNING] $($RecentCrashes.Count) von $TotalCrashes Crashes in den letzten 7 Tagen" -InformationAction Continue
                Write-Information "[INFO] Empfehlung: Sofortige Hardware-/Treiber-Pruefung erforderlich" -InformationAction Continue
            } else {
                Write-Information "[INFO] $TotalCrashes historische Crashes, keine aktuellen Probleme" -InformationAction Continue
            }
        }
        
        # Allgemeine Empfehlungen
        Write-Information "[INFO] `n=== ALLGEMEINE EMPFEHLUNGEN ===" -InformationAction Continue
        Write-Information "[INFO] [1] Windows Updates installieren" -InformationAction Continue
        Write-Information "[INFO] [2] Alle Treiber aktualisieren (besonders Grafik/Netzwerk)" -InformationAction Continue
        Write-Information "[INFO] [3] RAM mit Windows Memory Diagnostic testen" -InformationAction Continue
        Write-Information "[INFO] [4] Festplatte mit chkdsk /f pruefen" -InformationAction Continue
        Write-Information "[INFO] [5] Uebertaktung zuruecksetzen (falls vorhanden)" -InformationAction Continue
        Write-Information "[INFO] [6] Energieeinstellungen auf 'Ausgewogen' setzen" -InformationAction Continue
        
        # Hardware-Zusammenfassung
        if ($HardwareInfo.Count -gt 0) {
            Write-Information "[INFO] `n=== ERKANNTE HARDWARE ===" -InformationAction Continue
            if ($HardwareInfo.CPU) {
                Write-Information "[INFO] CPU: $($HardwareInfo.CPU.Name)" -InformationAction Continue
            }
            if ($HardwareInfo.GPU) {
                Write-Information "[INFO] GPU: $($HardwareInfo.GPU.Name) (Driver: $($HardwareInfo.GPU.Driver))" -InformationAction Continue
            }
            if ($HardwareInfo.RAM) {
                Write-Information "[INFO] RAM: $($HardwareInfo.RAM.TotalGB) GB ($($HardwareInfo.RAM.Modules) Module)" -InformationAction Continue
            }
        }
        
        # Automatische Log-Bereinigung
        Write-Information "[INFO] `n=== LOG-BEREINIGUNG ===" -InformationAction Continue
        try {
            $LogsPath = "$env:SystemRoot\Logs"
            if (Test-Path $LogsPath) {
                $OldLogs = Get-ChildItem "$LogsPath\CBS\*" -File -ErrorAction SilentlyContinue | 
                          Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
                if ($OldLogs) {
                    Write-Information "[INFO] $($OldLogs.Count) alte CBS-Logs gefunden (>30 Tage)" -InformationAction Continue
                    Write-Information "[INFO] Automatische Bereinigung empfohlen: sfc /scannow" -InformationAction Continue
                }
            }
            
            # Temp-Crash-Dumps bereinigen
            $TempCrashPath = "$env:LOCALAPPDATA\CrashDumps"
            if (Test-Path $TempCrashPath) {
                $TempCrashes = Get-ChildItem "$TempCrashPath\*" -File -ErrorAction SilentlyContinue |
                              Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) }
                if ($TempCrashes) {
                    $TempSize = ($TempCrashes | Measure-Object -Property Length -Sum).Sum / 1MB
                    Write-Information "[INFO] [CLEANUP] $($TempCrashes.Count) alte Temp-Crash-Dumps ($([math]::Round($TempSize, 1)) MB)" -InformationAction Continue
                }
            }
        } catch {
            Write-Information "[INFO] [DEBUG] Log-Bereinigung-Check fehlgeschlagen" -InformationAction Continue
        }
        
        # Erweiterte Diagnose-Hinweise
        Write-Information "[INFO] `n=== ERWEITERTE DIAGNOSE ===" -InformationAction Continue
        Write-Information "[INFO] Fuer detaillierte Minidump-Analyse:" -InformationAction Continue
        Write-Information "[INFO] - BlueScreenView (nirsoft.net)" -InformationAction Continue
        Write-Information "[INFO] - WinDbg (Microsoft Debugging Tools)" -InformationAction Continue
        Write-Information "[INFO] - WhoCrashed (resplendence.com)" -InformationAction Continue
        
        # Interaktive Wiederholung bei häufigen Crashes
        if ($CrashEvents.Count -gt 1) {
            $RecentCrashes = $CrashEvents | Where-Object { $_.Time -gt (Get-Date).AddDays(-7) }
            if ($RecentCrashes.Count -gt 2) {
                Write-Information "[INFO] `n=== INTERAKTIVE PROBLEMLOESUNG ===" -InformationAction Continue
                Write-Information "[INFO] Aufgrund haeufiger Crashes werden zusaetzliche Aktionen empfohlen:" -InformationAction Continue
                Write-Information "[INFO] [1] Windows Memory Diagnostic jetzt ausfuehren" -InformationAction Continue
                Write-Information "[INFO] [2] System File Check (SFC) starten" -InformationAction Continue  
                Write-Information "[INFO] [3] DISM Health Check durchfuehren" -InformationAction Continue
                Write-Information "[INFO] [4] Ereignisanzeige oeffnen (eventvwr.msc)" -InformationAction Continue
                Write-Information "[INFO] [x] Ueberspringe zusaetzliche Aktionen" -InformationAction Continue
                
                $actionChoice = Read-Host "`nWahl [1-4/x]"
                switch ($actionChoice) {
                    '1' { 
                        Write-Information "[INFO] `n[INFO] Starte Windows Memory Diagnostic..." -InformationAction Continue
                        try { 
                            Start-Process "mdsched.exe" -ErrorAction SilentlyContinue
                            Write-Information "[OK] Memory Diagnostic gestartet - Neustart erforderlich" -InformationAction Continue
                        } catch {
                            Write-Error "Memory Diagnostic konnte nicht gestartet werden"
                        }
                    }
                    '2' { 
                        Write-Information "[INFO] `n[INFO] System File Check wird in separatem Fenster gestartet..." -InformationAction Continue
                        try {
                            # Defender-safe: Avoid -Verb RunAs pattern
                            try {
                                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                                $processInfo.FileName = "cmd.exe"
                                $processInfo.Arguments = "/k sfc /scannow"
                                $processInfo.Verb = "runas"
                                $processInfo.UseShellExecute = $true
                                [System.Diagnostics.Process]::Start($processInfo) | Out-Null
                            } catch { }
                            Write-Information "[OK] SFC gestartet (Admin-Rechte erforderlich)" -InformationAction Continue
                        } catch {
                            Write-Error "SFC konnte nicht gestartet werden"
                        }
                    }
                    '3' { 
                        Write-Information "[INFO] `n[INFO] DISM Health Check wird gestartet..." -InformationAction Continue
                        try {
                            # Defender-safe: Avoid -Verb RunAs pattern
                            try {
                                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                                $processInfo.FileName = "cmd.exe"
                                $processInfo.Arguments = "/k dism /online /cleanup-image /checkhealth && dism /online /cleanup-image /scanhealth"
                                $processInfo.Verb = "runas"
                                $processInfo.UseShellExecute = $true
                                [System.Diagnostics.Process]::Start($processInfo) | Out-Null
                            } catch { }
                            Write-Information "[OK] DISM Check gestartet (Admin-Rechte erforderlich)" -InformationAction Continue
                        } catch {
                            Write-Error "DISM konnte nicht gestartet werden"
                        }
                    }
                    '4' {
                        Write-Information "[INFO] `n[INFO] Oeffne Ereignisanzeige..." -InformationAction Continue
                        try {
                            Start-Process "eventvwr.msc" -ErrorAction SilentlyContinue
                            Write-Information "[OK] Ereignisanzeige geoeffnet" -InformationAction Continue
                        } catch {
                            Write-Error "Ereignisanzeige konnte nicht geoeffnet werden"
                        }
                    }
                    default { Write-Information "[INFO] Zusaetzliche Aktionen uebersprungen" -InformationAction Continue }
                }
            }
        }
        
    } catch {
        Add-Error "Fehler bei Crash-Analyse: $($_.Exception.Message)"
        Write-Error "Crash-Analyse fehlgeschlagen: $($_.Exception.Message)"
    }
    
    Write-Information "[INFO] `n=== CRASH-ANALYSE ABGESCHLOSSEN ===" -InformationAction Continue
}

# Export function for dot-sourcing
Write-Verbose "Crash-Analyzer Module loaded: Get-SystemCrashAnalysis"
