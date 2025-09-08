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
    Defender-safe analysis using Windows Event Logs, Minidump file info, 
    and built-in PowerShell cmdlets. No external tools or risky operations.
    #>
    
    Write-Host "`n=== BLUESCREEN/CRASH ANALYZER ===" -ForegroundColor Cyan
    Write-Host "Analysiere System-Abstuerze und Bluescreens..." -ForegroundColor Yellow
    Write-Host ""
    
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
        Write-Host "[*] Analysiere Windows Event Logs..." -ForegroundColor Green
        
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
                Write-Host "    [OK] $($BugCheckEvents.Count) Bluescreen-Events gefunden" -ForegroundColor Green
            }
        } catch {
            Write-Host "    [INFO] Keine Bugcheck-Events im System Log" -ForegroundColor Yellow
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
                Write-Host "    [OK] $($ShutdownEvents.Count) Unerwartete Abschaltereignisse gefunden" -ForegroundColor Green
            }
        } catch {
            Write-Host "    [INFO] Keine unerwarteten Shutdown-Events gefunden" -ForegroundColor Yellow
        }
        
        # 2. Minidump File Analysis (Nur Metadaten, Defender-Safe)
        Write-Host "`n[*] Analysiere Minidump-Dateien..." -ForegroundColor Green
        
        $MinidumpPath = "C:\Windows\Minidump"
        $MinidumpFiles = @()
        
        if (Test-Path $MinidumpPath) {
            $MinidumpFiles = Get-ChildItem "$MinidumpPath\*.dmp" -ErrorAction SilentlyContinue | 
                Sort-Object CreationTime -Descending | Select-Object -First 10
            
            if ($MinidumpFiles.Count -gt 0) {
                Write-Host "    [OK] $($MinidumpFiles.Count) Minidump-Dateien gefunden" -ForegroundColor Green
                
                # Zeige letzte Crash-Dumps
                Write-Host "`n--- LETZTE CRASH-DUMPS ---" -ForegroundColor Cyan
                $MinidumpFiles | ForEach-Object {
                    $SizeMB = [math]::Round($_.Length / 1MB, 2)
                    Write-Host "    $($_.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')) - $($_.Name) ($SizeMB MB)" -ForegroundColor White
                }
            } else {
                Write-Host "    [INFO] Keine Minidump-Dateien gefunden" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [INFO] Minidump-Ordner existiert nicht" -ForegroundColor Yellow
        }
        
        # 3. Reliability Monitor Data (WMI, Defender-Safe)
        Write-Host "`n[*] Analysiere Windows Reliability History..." -ForegroundColor Green
        
        try {
            $ReliabilityData = Get-WmiObject -Class Win32_ReliabilityRecords -ErrorAction SilentlyContinue |
                Where-Object { $_.SourceName -like "*Bugcheck*" -or $_.EventIdentifier -eq 1001 } |
                Sort-Object TimeGenerated -Descending | Select-Object -First 5
                
            if ($ReliabilityData) {
                Write-Host "    [OK] $($ReliabilityData.Count) Reliability-Eintraege gefunden" -ForegroundColor Green
            }
        } catch {
            Write-Host "    [INFO] Reliability-Daten nicht verfuegbar" -ForegroundColor Yellow
        }
        
        # 4. Analyse-Ausgabe
        Write-Host "`n=== CRASH-ANALYSE ERGEBNISSE ===" -ForegroundColor Cyan
        
        if ($CrashEvents.Count -eq 0 -and $MinidumpFiles.Count -eq 0) {
            Write-Host "[GOOD NEWS] Keine aktuellen System-Abstuerze gefunden!" -ForegroundColor Green
            Write-Host "Ihr System scheint stabil zu laufen." -ForegroundColor Green
            return
        }
        
        # Zeige Event-basierte Crashes
        if ($CrashEvents.Count -gt 0) {
            Write-Host "`n--- EVENT LOG CRASHES ---" -ForegroundColor Yellow
            
            $CrashEvents | Sort-Object Time -Descending | ForEach-Object {
                Write-Host "`n[CRASH] $($_.Time.ToString('yyyy-MM-dd HH:mm:ss')) - $($_.Type)" -ForegroundColor Red
                
                # Extrahiere Stop-Code aus Message
                $Message = $_.Message
                $StopCodeMatch = [regex]::Match($Message, '0x[0-9A-Fa-f]{8}')
                
                if ($StopCodeMatch.Success) {
                    $StopCode = $StopCodeMatch.Value
                    Write-Host "    Stop-Code: $StopCode" -ForegroundColor White
                    
                    # Lookup Stop-Code
                    if ($StopCodes.ContainsKey($StopCode)) {
                        Write-Host "    Bedeutung: $($StopCodes[$StopCode])" -ForegroundColor Cyan
                    }
                    
                    # Lösungsvorschlag
                    if ($Solutions.ContainsKey($StopCode)) {
                        Write-Host "    Loesung: $($Solutions[$StopCode])" -ForegroundColor Green
                    }
                }
                
                # Parameter extrahieren (vereinfacht)
                $ParamMatch = [regex]::Matches($Message, '0x[0-9A-Fa-f]{16}')
                if ($ParamMatch.Count -ge 4) {
                    Write-Host "    Parameter: $($ParamMatch[0].Value), $($ParamMatch[1].Value)" -ForegroundColor Gray
                }
            }
        }
        
        # Häufigkeits-Analyse
        if ($CrashEvents.Count -gt 1) {
            Write-Host "`n--- CRASH-HAEUFIGKEIT ---" -ForegroundColor Yellow
            
            $RecentCrashes = $CrashEvents | Where-Object { $_.Time -gt (Get-Date).AddDays(-7) }
            $TotalCrashes = $CrashEvents.Count
            
            if ($RecentCrashes.Count -gt 0) {
                Write-Host "[WARNING] $($RecentCrashes.Count) von $TotalCrashes Crashes in den letzten 7 Tagen" -ForegroundColor Red
                Write-Host "Empfehlung: Sofortige Hardware-/Treiber-Pruefung erforderlich" -ForegroundColor Yellow
            } else {
                Write-Host "[INFO] $TotalCrashes historische Crashes, keine aktuellen Probleme" -ForegroundColor Green
            }
        }
        
        # Allgemeine Empfehlungen
        Write-Host "`n=== ALLGEMEINE EMPFEHLUNGEN ===" -ForegroundColor Cyan
        Write-Host "[1] Windows Updates installieren" -ForegroundColor White
        Write-Host "[2] Alle Treiber aktualisieren (besonders Grafik/Netzwerk)" -ForegroundColor White
        Write-Host "[3] RAM mit Windows Memory Diagnostic testen" -ForegroundColor White
        Write-Host "[4] Festplatte mit chkdsk /f pruefen" -ForegroundColor White
        Write-Host "[5] Uebertaktung zuruecksetzen (falls vorhanden)" -ForegroundColor White
        Write-Host "[6] Energieeinstellungen auf 'Ausgewogen' setzen" -ForegroundColor White
        
        # Erweiterte Diagnose-Hinweise
        Write-Host "`n=== ERWEITERTE DIAGNOSE ===" -ForegroundColor Cyan
        Write-Host "Fuer detaillierte Minidump-Analyse:" -ForegroundColor Yellow
        Write-Host "- BlueScreenView (nirsoft.net)" -ForegroundColor White
        Write-Host "- WinDbg (Microsoft Debugging Tools)" -ForegroundColor White
        Write-Host "- WhoCrashed (resplendence.com)" -ForegroundColor White
        
    } catch {
        Add-Error "Fehler bei Crash-Analyse: $($_.Exception.Message)"
        Write-Host "[ERROR] Crash-Analyse fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n=== CRASH-ANALYSE ABGESCHLOSSEN ===" -ForegroundColor Cyan
}

# Export function for module system
Export-ModuleMember -Function Get-SystemCrashAnalysis