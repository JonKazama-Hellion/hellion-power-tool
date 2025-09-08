# ===================================================================
# HELLION POWER TOOL - MODULAR VERSION v7.1.0.a "Fenrir"
# Main Entry Point - Loads all modules and provides menu interface
# ===================================================================

param(
    [switch]$DebugMode,
    [switch]$DevMode,
    [int]$ForceDebugLevel = -1
)

# UTF-8 Encoding für korrekte Umlaute setzen
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Debug: Parameter-Empfang protokollieren (nur in Debug-Modi)
if ($DebugMode.IsPresent -or $DevMode.IsPresent -or $ForceDebugLevel -ge 1) {
    Write-Host "[DEBUG-INIT] Parameter empfangen:" -ForegroundColor Magenta
    Write-Host "  DebugMode: $DebugMode" -ForegroundColor Gray
    Write-Host "  DevMode: $DevMode" -ForegroundColor Gray
    Write-Host "  ForceDebugLevel: $ForceDebugLevel" -ForegroundColor Gray
    Write-Host "  MyInvocation.BoundParameters: $($MyInvocation.BoundParameters.Keys -join ', ')" -ForegroundColor Gray
}

# Require Admin Rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n================================================================"
    Write-Host "                    ADMIN-RECHTE ERFORDERLICH                   " -ForegroundColor Red
    Write-Host "================================================================"
    Write-Host "`nDieses Tool benoetigt Administrator-Rechte fuer System-Aenderungen."
    Write-Host "Es wird nun ein Neustart mit erhoehten Rechten angefordert."
    Write-Host "`nBitte bestaetigen Sie die folgende Windows-Sicherheitsabfrage (UAC)."
    Write-Host "`nNeues Admin-Fenster wird geoeffnet..." -ForegroundColor Yellow
    
    # Baue Argument-String mit allen ursprünglichen Parametern
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    
    # Füge ursprüngliche Parameter hinzu
    if ($DebugMode.IsPresent) {
        $arguments += " -DebugMode"
    }
    if ($DevMode.IsPresent) {
        $arguments += " -DevMode"
    }
    if ($ForceDebugLevel -ge 0) {
        $arguments += " -ForceDebugLevel $ForceDebugLevel"
    }
    
    # Debug-Info nur bei Debug-Modi anzeigen
    if ($DebugMode.IsPresent -or $DevMode.IsPresent -or $ForceDebugLevel -ge 1) {
        Write-Host "[UAC-RESTART] Parameter werden weitergegeben: $arguments" -ForegroundColor Cyan
    }
    
    # PowerShell 7 Detection für UAC-Neustart
    $powershellExe = "PowerShell"  # Fallback
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $powershellExe = "pwsh"
    } elseif (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") {
        $powershellExe = "C:\Program Files\PowerShell\7\pwsh.exe"
    }
    
    Start-Process $powershellExe -ArgumentList $arguments -Verb RunAs
    exit
}

# Initialize script variables
$script:LogBuffer = @()
$script:Errors = @()
$script:Warnings = @()
$script:SuccessActions = @()
$script:ActionsPerformed = @()

# Get script root directory
$script:RootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ModulesPath = Join-Path $script:RootPath "modules"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           HELLION POWER TOOL v7.1.0.a "Fenrir" (MODULAR)             " -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Loading modules..." -ForegroundColor Yellow

# Load all modules from modules directory
if (Test-Path $script:ModulesPath) {
    $moduleFiles = Get-ChildItem "$script:ModulesPath\*.ps1" -ErrorAction SilentlyContinue
    foreach ($moduleFile in $moduleFiles) {
        try {
            Write-Host "Loading module: $($moduleFile.Name)" -ForegroundColor Gray
            . $moduleFile.FullName
        } catch {
            Write-Host "ERROR loading module $($moduleFile.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "Loaded $($moduleFiles.Count) modules." -ForegroundColor Green
} else {
    Write-Host "ERROR: Modules directory not found at $script:ModulesPath" -ForegroundColor Red
    Write-Host "Please ensure all module files are in the 'modules' subdirectory." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Initialize logging
Initialize-Logging -LogDirectory "$env:TEMP\HellionPowerTool" -DetailedLogging

Write-Log "Hellion Power Tool v7.1.0.a 'Fenrir' started (Modular version)" -Color Cyan
Write-Log "Modules loaded from: $script:ModulesPath" -Color Gray

# Load configuration
if (Get-Command Load-Configuration -ErrorAction SilentlyContinue) {
    $script:Config = Load-Configuration
    Write-Log "[CONFIG] Konfiguration geladen erfolgreich" -Level "DEBUG"
} else {
    Write-Log "[WARNING] Config-Utils Modul nicht verfügbar - verwende Defaults" -Color Yellow
}

# Initialize additional script variables
$script:AutoApproveCleanup = $false
$script:TotalFreedSpace = 0
$script:AVSafeMode = $true
$script:AVDelayMs = 50
$script:UpdateRecommendations = @()
$script:ExplainMode = $false
$script:DebugLevel = 0  # 0=Normal, 1=Debug, 2=Verbose

# Debug: Zeige detaillierte Parameter-Info (nur in Developer-Modus)
if ($DevMode.IsPresent -or $ForceDebugLevel -ge 2) {
    Write-Host "[DEBUG-DETAIL] Parameter Analysis:" -ForegroundColor Magenta
    Write-Host "  DebugMode.IsPresent: $($DebugMode.IsPresent)" -ForegroundColor Gray
    Write-Host "  DevMode.IsPresent: $($DevMode.IsPresent)" -ForegroundColor Gray
    Write-Host "  ForceDebugLevel: $ForceDebugLevel" -ForegroundColor Gray
    Write-Host "  global:LauncherDebugMode: $($global:LauncherDebugMode)" -ForegroundColor Gray
}

# Debug Mode Selection (can be overridden by launcher or parameters)
if ($ForceDebugLevel -ge 0) {
    $script:DebugLevel = $ForceDebugLevel
    $modeText = switch ($script:DebugLevel) {
        0 { "Normal-Modus" }
        1 { "Debug-Modus" }
        2 { "Developer-Modus" }
        default { "Unknown" }
    }
    Write-Host "[PARAM-FORCE] Debug-Mode forced to: $modeText" -ForegroundColor Magenta
    Write-Log "[PARAM] Debug-Mode forced to: $modeText" -Level "DEV"
} elseif ($DevMode.IsPresent -eq $true) {
    $script:DebugLevel = 2
    Write-Host "[PARAM-DEV] Developer-Mode activated via DevMode parameter" -ForegroundColor Green
    Write-Log "[PARAM] Developer-Mode activated via DevMode parameter" -Level "DEV"
} elseif ($DebugMode.IsPresent -eq $true) {
    $script:DebugLevel = 1
    Write-Host "[PARAM-DEBUG] Debug-Mode activated via DebugMode parameter" -ForegroundColor Green
    Write-Log "[PARAM] Debug-Mode activated via DebugMode parameter" -Level "DEV"
} elseif ($null -ne $global:LauncherDebugMode -and $global:LauncherDebugMode -ge 0) {
    $script:DebugLevel = $global:LauncherDebugMode
    $modeText = switch ($script:DebugLevel) {
        0 { "Normal-Modus" }
        1 { "Debug-Modus" }
        2 { "Developer-Modus" }
        default { "Unknown" }
    }
    Write-Host "[LAUNCHER] Debug-Mode set by launcher: $modeText" -ForegroundColor Cyan
    Write-Log "[LAUNCHER] Debug-Mode set by launcher: $modeText" -Level "DEV"
} else {
    Write-Host "[NO-PARAM] Keine Parameter erkannt - falle in manuelle Auswahl" -ForegroundColor Yellow
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           HELLION POWER TOOL v7.1.0.a "Fenrir" (MODULAR)             " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[*] DEBUG-MODUS WAEHLEN:" -ForegroundColor Yellow
    Write-Host "  [0] Normal-Modus (Standard)" -ForegroundColor Green
    Write-Host "  [1] Debug-Modus (Erweiterte Infos)" -ForegroundColor Cyan  
    Write-Host "  [2] Developer-Modus (Alle Debug-Infos)" -ForegroundColor Red
    Write-Host ""

    $debugChoice = Read-Host "Modus waehlen [0-2]"
    switch ($debugChoice) {
        '1' { $script:DebugLevel = 1; Write-Host "Debug-Modus aktiviert" -ForegroundColor Cyan }
        '2' { $script:DebugLevel = 2; Write-Host "Developer-Modus aktiviert" -ForegroundColor Red }
        default { $script:DebugLevel = 0; Write-Host "Normal-Modus aktiviert" -ForegroundColor Green }
    }

    Start-Sleep -Seconds 1
}

# Skip Auto-Mode Prompt - go directly to menu

# Main Menu Function
function Show-MainMenu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           HELLION POWER TOOL v7.1.0.a "Fenrir" (MODULAR)             " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    
    # Show current debug mode (nur in Debug-Modi)
    if ($script:DebugLevel -ge 1) {
        Write-Host "[DEBUG-STATUS] script:DebugLevel = $($script:DebugLevel)" -ForegroundColor Magenta
    }
    
    $modeText = switch ($script:DebugLevel) {
        0 { "Normal-Modus" }
        1 { "Debug-Modus" }
        2 { "Developer-Modus" }
        default { "Unknown (Wert: $($script:DebugLevel))" }
    }
    Write-Host "Aktueller Modus: $modeText" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  [*] SCHNELL-AKTIONEN:" -ForegroundColor Green
    Write-Host "     [A] AUTO-MODUS ERWEITERT (Empfohlen)" -ForegroundColor Green
    Write-Host "     [Q] Schnell-Bereinigung" -ForegroundColor Cyan
    Write-Host "     [W] Winget-Updates" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  === SYSTEM-REPARATUR ===" -ForegroundColor Yellow
    Write-Host "     [1] System File Checker (SFC)" -ForegroundColor Cyan
    Write-Host "     [2] DISM Reparatur" -ForegroundColor Cyan
    Write-Host "     [3] CheckDisk Laufwerks-Pruefung" -ForegroundColor Cyan
    Write-Host "     [4] DLL Integritaets-Check" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  === SYSTEM-BEREINIGUNG ===" -ForegroundColor Yellow
    Write-Host "     [5] Umfassende System-Bereinigung" -ForegroundColor Cyan
    Write-Host "     [6] Performance-Optimierung" -ForegroundColor Cyan
    Write-Host "     [7] Ungenutzte Programme finden" -ForegroundColor Cyan
    Write-Host "     [8] Bloatware erkennen" -ForegroundColor Red
    Write-Host ""
    Write-Host "  === DIAGNOSE & INFO ===" -ForegroundColor Blue
    Write-Host "     [9] System-Information" -ForegroundColor Cyan
    Write-Host "     [10] Netzwerk-Test" -ForegroundColor Cyan
    Write-Host "     [11] Treiber-Status" -ForegroundColor Cyan
    Write-Host "     [12] System-Bericht erstellen" -ForegroundColor Cyan
    Write-Host "     [13] Bluescreen/Crash Analyzer" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  === SICHERHEIT & VERWALTUNG ===" -ForegroundColor Magenta
    Write-Host "     [14] Safe Adblock verwalten" -ForegroundColor Cyan
    Write-Host "     [15] Wiederherstellungspunkte" -ForegroundColor Cyan
    Write-Host "     [16] Netzwerk zuruecksetzen" -ForegroundColor Cyan
    Write-Host "     [17] Winget Updates" -ForegroundColor Cyan
    Write-Host "     [18] Auto-Modus (Nochmal ausfuehren)" -ForegroundColor Green
    Write-Host "     [19] Schnell-Modus" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "     [x] Beenden" -ForegroundColor Red
    Write-Host ""
}

# Main execution loop
do {
    Show-MainMenu
    $choice = Read-Host "Ihre Wahl"
    
    switch ($choice.ToUpper()) {
        # SCHNELL-AKTIONEN
        'A' {
            if (Get-Command Invoke-EnhancedAutoMode -ErrorAction SilentlyContinue) {
                Invoke-EnhancedAutoMode
            } else {
                Write-Host "ERROR: Auto-Mode function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        'Q' {
            Write-Host "`n[*] SCHNELL-BEREINIGUNG..." -ForegroundColor Cyan
            $script:AutoApproveCleanup = $true
            $freed = 0
            
            if (Get-Command Remove-SafeFiles -ErrorAction SilentlyContinue) {
                $freed += Remove-SafeFiles "$env:TEMP" "Temp-Dateien" -Force
                $freed += Remove-SafeFiles "$env:SystemRoot\Temp" "System-Temp" -Force
                
                # DNS Cache leeren
                try {
                    & ipconfig /flushdns | Out-Null
                    Write-Host "[OK] DNS-Cache geleert" -ForegroundColor Green
                } catch {
                    Write-Host "[WARNING] DNS-Cache konnte nicht geleert werden" -ForegroundColor Yellow
                }
                
                Write-Host "[OK] Schnell-Bereinigung abgeschlossen! ($freed MB)" -ForegroundColor Green
            } else {
                Write-Host "ERROR: Cleanup functions not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        'W' {
            if (Get-Command Get-WingetUpdates -ErrorAction SilentlyContinue) {
                $updates = Get-WingetUpdates
                if ($updates.Count -gt 0) {
                    Write-Host "`n$($updates.Count) Updates verfuegbar. Alle installieren? [j/n]" -ForegroundColor Yellow
                    $installChoice = Read-Host
                    if ($installChoice -eq 'j' -or $installChoice -eq 'J') {
                        Install-WingetUpdates
                    }
                } else {
                    Write-Host "`nKeine Winget-Updates verfuegbar." -ForegroundColor Green
                }
            } else {
                Write-Host "ERROR: Winget functions not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
        # SYSTEM-REPARATUR
        '1' {
            if (Get-Command Invoke-SystemFileChecker -ErrorAction SilentlyContinue) {
                Invoke-SystemFileChecker
            } else {
                Write-Host "ERROR: System File Checker function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '2' {
            if (Get-Command Invoke-DISMRepair -ErrorAction SilentlyContinue) {
                Invoke-DISMRepair
            } else {
                Write-Host "ERROR: DISM Repair function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '3' {
            if (Get-Command Invoke-CheckDisk -ErrorAction SilentlyContinue) {
                Invoke-CheckDisk
            } else {
                Write-Host "ERROR: CheckDisk function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '4' {
            if (Get-Command Test-DLLIntegrity -ErrorAction SilentlyContinue) {
                Test-DLLIntegrity
            } else {
                Write-Host "ERROR: DLL Integrity function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '5' {
            if (Get-Command Invoke-ComprehensiveCleanup -ErrorAction SilentlyContinue) {
                Invoke-ComprehensiveCleanup
            } else {
                Write-Host "ERROR: Comprehensive Cleanup function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '6' {
            if (Get-Command Optimize-SystemPerformance -ErrorAction SilentlyContinue) {
                Optimize-SystemPerformance
            } else {
                Write-Host "ERROR: Performance Optimization function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '7' {
            if (Get-Command Get-UnusedPrograms -ErrorAction SilentlyContinue) {
                $null = Get-UnusedPrograms  # Capture return value to prevent console output
            } else {
                Write-Host "ERROR: Unused Programs function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '8' {
            # Direkte Bloatware-Erkennung (vereinfacht)
            if (Get-Command Get-BloatwarePrograms -ErrorAction SilentlyContinue) {
                $bloatwareResults = Get-BloatwarePrograms
                if ($bloatwareResults.Count -gt 0) {
                    Write-Host "`n[SUCCESS] $($bloatwareResults.Count) Bloatware-Programme identifiziert" -ForegroundColor Green
                }
            } else {
                Write-Host "ERROR: Bloatware Detection function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '9' {
            if (Get-Command Get-DetailedSystemInfo -ErrorAction SilentlyContinue) {
                Get-DetailedSystemInfo
                Get-EnhancedDriveInfo
            } else {
                Write-Host "ERROR: System Info function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '10' {
            if (Get-Command Test-EnhancedInternetConnectivity -ErrorAction SilentlyContinue) {
                Test-EnhancedInternetConnectivity
            } else {
                Write-Host "ERROR: Network Test function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '11' {
            Write-Host "`n[*] TREIBER-OPTIONEN:" -ForegroundColor Cyan
            Write-Host "  [1] Treiber-Status analysieren" -ForegroundColor Green
            Write-Host "  [2] Problematische Treiber reparieren" -ForegroundColor Yellow
            Write-Host "  [3] Alle Treiber neu installieren" -ForegroundColor Red
            Write-Host "  [x] Zurueck zum Hauptmenu" -ForegroundColor Gray
            
            $driverChoice = Read-Host "`nWahl [1-3/x]"
            switch ($driverChoice.ToLower()) {
                '1' {
                    if (Get-Command Get-DetailedDriverStatus -ErrorAction SilentlyContinue) {
                        Get-DetailedDriverStatus
                    } else {
                        Write-Host "ERROR: Driver Status function not found." -ForegroundColor Red
                    }
                }
                '2' {
                    Write-Host "`n[*] TREIBER-REPARATUR:" -ForegroundColor Yellow
                    Write-Host "[WARNING] Treiber-Reparatur kann System-Neustart erfordern!" -ForegroundColor Red
                    
                    $confirm = Read-Host "`nProblematische Treiber reparieren? [j/n]"
                    if ($confirm -eq 'j' -or $confirm -eq 'J') {
                        # Verwende pnputil für Treiber-Reparatur
                        Write-Host "`n[*] Suche nach problematischen Treibern..." -ForegroundColor Blue
                        
                        try {
                            # Problematische Geräte finden
                            $problemDevices = Get-WmiObject Win32_PnPEntity | Where-Object { 
                                $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne 22 
                            }
                            
                            if ($problemDevices.Count -gt 0) {
                                Write-Host "[*] Gefunden: $($problemDevices.Count) Geraete mit Problemen" -ForegroundColor Yellow
                                
                                foreach ($device in $problemDevices | Select-Object -First 5) {
                                    Write-Host "  [*] Repariere: $($device.Name)" -ForegroundColor Cyan
                                    
                                    # Versuche Gerät zu deaktivieren und reaktivieren
                                    try {
                                        $deviceId = $device.DeviceID
                                        & pnputil /restart-device "$deviceId" 2>$null
                                        Write-Host "    [OK] Neustart versucht" -ForegroundColor Green
                                    } catch {
                                        Write-Host "    [WARNING] Neustart fehlgeschlagen" -ForegroundColor Yellow
                                    }
                                }
                                
                                Write-Host "`n[INFO] Treiber-Reparatur abgeschlossen" -ForegroundColor Green
                                Write-Host "[EMPFEHLUNG] System-Neustart wird empfohlen" -ForegroundColor Yellow
                            } else {
                                Write-Host "[OK] Keine problematischen Treiber gefunden" -ForegroundColor Green
                            }
                        } catch {
                            Write-Host "[ERROR] Treiber-Reparatur fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
                '3' {
                    Write-Host "`n[DANGER] VOLLSTAENDIGE TREIBER-NEUINSTALLATION" -ForegroundColor Red
                    Write-Host "[WARNING] Dies kann das System unbrauchbar machen!" -ForegroundColor Red
                    Write-Host "[WARNING] Nur fuer Experten empfohlen!" -ForegroundColor Red
                    
                    $confirm = Read-Host "`nWirklich alle Treiber neu installieren? [CONFIRM]"
                    if ($confirm -eq 'CONFIRM') {
                        Write-Host "`n[*] Starte Treiber-Neuinstallation..." -ForegroundColor Red
                        Write-Host "[INFO] Diese Funktion ist zu riskant und wurde deaktiviert" -ForegroundColor Yellow
                        Write-Host "[EMPFEHLUNG] Verwenden Sie Windows Update oder Hersteller-Tools" -ForegroundColor Green
                    } else {
                        Write-Host "[SKIP] Treiber-Neuinstallation abgebrochen" -ForegroundColor Gray
                    }
                }
                'x' {
                    Write-Host "Zurueck zum Hauptmenu..." -ForegroundColor Gray
                }
                default {
                    Write-Host "Ungueltige Auswahl." -ForegroundColor Red
                }
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '12' {
            if (Get-Command New-DetailedSystemReport -ErrorAction SilentlyContinue) {
                $reportPath = New-DetailedSystemReport
                if ($reportPath) {
                    Write-Host "`nSystem-Bericht erstellt: $reportPath" -ForegroundColor Green
                }
            } else {
                Write-Host "ERROR: System report function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '13' {
            if (Get-Command Get-SystemCrashAnalysis -ErrorAction SilentlyContinue) {
                Get-SystemCrashAnalysis
            } else {
                Write-Host "ERROR: Crash analyzer function not found." -ForegroundColor Red
                Write-Host "Module: crash-analyzer.ps1 not loaded" -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '14' {
            if (Get-Command Invoke-SafeAdblock -ErrorAction SilentlyContinue) {
                Invoke-SafeAdblock
            } else {
                Write-Host "ERROR: Safe Adblock function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '15' {
            Write-Host "`n[*] WIEDERHERSTELLUNGSPUNKT OPTIONEN:" -ForegroundColor Cyan
            Write-Host "  [1] Neuen Wiederherstellungspunkt erstellen" -ForegroundColor Green
            Write-Host "  [2] Verfuegbare Wiederherstellungspunkte anzeigen" -ForegroundColor Blue
            Write-Host "  [3] System auf Wiederherstellungspunkt zuruecksetzen" -ForegroundColor Yellow
            Write-Host "  [4] System Restore aktivieren" -ForegroundColor Magenta
            Write-Host "  [x] Zurueck zum Hauptmenu" -ForegroundColor Gray
            
            $restoreChoice = Read-Host "`nWahl [1-4/x]"
            switch ($restoreChoice.ToLower()) {
                '1' {
                    if (Get-Command New-SystemRestorePoint -ErrorAction SilentlyContinue) {
                        New-SystemRestorePoint
                    } else {
                        Write-Host "ERROR: System Restore function not found." -ForegroundColor Red
                    }
                }
                '2' {
                    if (Get-Command Get-SystemRestorePoints -ErrorAction SilentlyContinue) {
                        Get-SystemRestorePoints
                    } else {
                        Write-Host "ERROR: System Restore function not found." -ForegroundColor Red
                    }
                }
                '3' {
                    if (Get-Command Restore-SystemToPoint -ErrorAction SilentlyContinue) {
                        Restore-SystemToPoint
                    } else {
                        Write-Host "ERROR: System Restore function not found." -ForegroundColor Red
                    }
                }
                '4' {
                    if (Get-Command Enable-SystemRestore -ErrorAction SilentlyContinue) {
                        Enable-SystemRestore
                    } else {
                        Write-Host "ERROR: System Restore function not found." -ForegroundColor Red
                    }
                }
                'x' {
                    Write-Host "Zurueck zum Hauptmenu..." -ForegroundColor Gray
                }
                default {
                    Write-Host "Ungueltige Auswahl." -ForegroundColor Red
                }
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '16' {
            if (Get-Command Reset-NetworkConfiguration -ErrorAction SilentlyContinue) {
                Reset-NetworkConfiguration
            } else {
                Write-Host "ERROR: Network Reset function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '17' {
            Write-Host "`n[*] WINGET OPTIONEN:" -ForegroundColor Cyan
            Write-Host "  [1] Verfuegbare Updates anzeigen" -ForegroundColor Green
            Write-Host "  [2] Alle Updates installieren" -ForegroundColor Yellow
            Write-Host "  [3] Software suchen" -ForegroundColor Blue
            Write-Host "  [4] Winget-Status pruefen" -ForegroundColor Magenta
            Write-Host "  [x] Zurueck zum Hauptmenu" -ForegroundColor Gray
            
            $wingetChoice = Read-Host "`nWahl [1-4/x]"
            switch ($wingetChoice.ToLower()) {
                '1' {
                    if (Get-Command Get-WingetUpdates -ErrorAction SilentlyContinue) {
                        Get-WingetUpdates
                    } else {
                        Write-Host "ERROR: Winget function not found." -ForegroundColor Red
                    }
                }
                '2' {
                    if (Get-Command Install-WingetUpdates -ErrorAction SilentlyContinue) {
                        Install-WingetUpdates
                    } else {
                        Write-Host "ERROR: Winget function not found." -ForegroundColor Red
                    }
                }
                '3' {
                    if (Get-Command Search-WingetSoftware -ErrorAction SilentlyContinue) {
                        $searchTerm = Read-Host "Suchbegriff eingeben"
                        Search-WingetSoftware -SearchTerm $searchTerm
                    } else {
                        Write-Host "ERROR: Winget function not found." -ForegroundColor Red
                    }
                }
                '4' {
                    if (Get-Command Test-WingetAvailability -ErrorAction SilentlyContinue) {
                        Test-WingetAvailability
                    } else {
                        Write-Host "ERROR: Winget function not found." -ForegroundColor Red
                    }
                }
                'x' {
                    Write-Host "Zurueck zum Hauptmenu..." -ForegroundColor Gray
                }
                default {
                    Write-Host "Ungueltige Auswahl." -ForegroundColor Red
                }
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '18' {
            if (Get-Command Invoke-EnhancedAutoMode -ErrorAction SilentlyContinue) {
                Invoke-EnhancedAutoMode
            } else {
                Write-Host "ERROR: Auto-Mode function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        '19' {
            if (Get-Command Invoke-QuickMode -ErrorAction SilentlyContinue) {
                Invoke-QuickMode
            } else {
                Write-Host "ERROR: Quick-Mode function not found." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        'x' {
            Write-Log "Tool beendet durch Benutzer" -Color Yellow
            Write-Host "`nTool wird beendet..." -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "Ungueltige Auswahl. Bitte waehlen Sie eine gueltige Option." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice.ToLower() -ne 'x')

# Display final summary
$logSummary = Get-LogSummary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "                        ZUSAMMENFASSUNG                        " -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Log "`n[*] Log gespeichert: $($logSummary.LogFile)" -Color Cyan
Write-Log "[*] Log-Groesse: $($logSummary.LogSize) KB" -Color Gray
if ($logSummary.ErrorCount -gt 0) {
    Write-Log "[*] Fehler protokolliert: $($logSummary.ErrorCount)" -Color Red
}
if ($logSummary.WarningCount -gt 0) {
    Write-Log "[*] Warnungen protokolliert: $($logSummary.WarningCount)" -Color Yellow
}

Write-Host "`n[*] Enter zum Beenden..." -ForegroundColor Yellow
Read-Host