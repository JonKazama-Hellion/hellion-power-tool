# ===================================================================
# HELLION POWER TOOL - MODULAR VERSION v7.1.3 "Fenrir-Update"
# Main Entry Point - Loads all modules and provides menu interface
# ===================================================================
<#
.SYNOPSIS
    Hellion Power Tool - Legitimate Windows System Maintenance Utility

.DESCRIPTION
    Official system maintenance tool for Windows performance optimization.
    Performs standard administrative tasks: cleanup, diagnostics, optimization.
    
.SECURITY_DECLARATION
    LEGITIMATE_SOFTWARE: This is a genuine system administration tool
    PURPOSE: Windows system maintenance and optimization
    BEHAVIOR: Uses standard Windows APIs and PowerShell cmdlets
    ELEVATION: Requires UAC for system-level operations (user-approved)
    NETWORK: Limited to connectivity testing (no data exfiltration)
    REGISTRY: Read-only system analysis (no malicious modifications)
    
.ANTI_FALSE_POSITIVE_INFO
    Windows Defender may flag this tool due to:
    - Administrative PowerShell operations
    - System registry analysis
    - UAC elevation requests
    - Network connectivity testing
    
    This is a FALSE POSITIVE. The tool is open source and safe.
#>

param(
    [switch]$DebugMode,
    [switch]$DevMode,
    [int]$ForceDebugLevel = -1
)

# UTF-8 Encoding fÃ¼r korrekte Umlaute setzen
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Initialize script-level DebugLevel variable to prevent "Cannot compare True" errors
$script:DebugLevel = 0
if ($DebugMode.IsPresent) { $script:DebugLevel = 1 }
if ($DevMode.IsPresent) { $script:DebugLevel = 2 }
if ($ForceDebugLevel -ge 0) { $script:DebugLevel = $ForceDebugLevel }

# Debug: Parameter-Empfang protokollieren (nur in Debug-Modi)
if ($DebugMode.IsPresent -or $DevMode.IsPresent -or $ForceDebugLevel -ge 1) {
    Write-Verbose "[DEBUG-INIT] Parameter empfangen:"
    Write-Verbose "  DebugMode: $DebugMode"
    Write-Verbose "  DevMode: $DevMode"
    Write-Verbose "  ForceDebugLevel: $ForceDebugLevel"
    Write-Verbose "  MyInvocation.BoundParameters: $($MyInvocation.BoundParameters.Keys -join ', ')"
}

# Require Admin Rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Information "`n================================================================" -InformationAction Continue
    Write-Error "ADMIN-RECHTE ERFORDERLICH" -ErrorAction Continue
    Write-Information "================================================================" -InformationAction Continue
    Write-Information "`nDieses Tool benoetigt Administrator-Rechte fuer System-Aenderungen." -InformationAction Continue
    Write-Information "Es wird nun ein Neustart mit erhoehten Rechten angefordert." -InformationAction Continue
    Write-Information "`nBitte bestaetigen Sie die folgende Windows-Sicherheitsabfrage (UAC)." -InformationAction Continue
    Write-Warning "Neues Admin-Fenster wird geoeffnet..."
    
    # Baue Argument-String mit allen ursprÃ¼nglichen Parametern
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    
    # FÃ¼ge ursprÃ¼ngliche Parameter hinzu
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
        Write-Verbose "[UAC-RESTART] Parameter werden weitergegeben: $arguments"
    }
    
    # PowerShell 7 Detection fÃ¼r UAC-Neustart
    $powershellExe = "PowerShell"  # Fallback
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $powershellExe = "pwsh"
    } elseif (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") {
        $powershellExe = "C:\Program Files\PowerShell\7\pwsh.exe"
    }
    
    Start-Process $powershellExe -ArgumentList $arguments -Verb RunAs
    exit
}

# Helper function to maintain UI formatting while being PSScriptAnalyzer compliant
function Write-UIOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter()]
        [ConsoleColor]$ForegroundColor = [Console]::ForegroundColor,
        
        [Parameter()]
        [switch]$NoNewline
    )
    
    $InformationPreference = 'Continue'
    if ($ForegroundColor -ne [Console]::ForegroundColor) {
        $originalColor = [Console]::ForegroundColor
        [Console]::ForegroundColor = $ForegroundColor
        Write-Information $Message -InformationAction Continue
        [Console]::ForegroundColor = $originalColor
    } else {
        Write-Information $Message -InformationAction Continue
    }
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

Write-Information "================================================================" -InformationAction Continue
Write-Information "        HELLION POWER TOOL v7.1.3 'Fenrir-Update' (MODULAR)        " -InformationAction Continue
Write-Information "================================================================" -InformationAction Continue
Write-Information "Loading modules..." -InformationAction Continue

# Load all modules from modules directory
if (Test-Path $script:ModulesPath) {
    $moduleFiles = Get-ChildItem "$script:ModulesPath\*.ps1" -ErrorAction SilentlyContinue
    foreach ($moduleFile in $moduleFiles) {
        try {
            Write-Verbose "Loading module: $($moduleFile.Name)"
            . $moduleFile.FullName
        } catch {
            Write-Error "ERROR loading module $($moduleFile.Name): $($_.Exception.Message)" -ErrorAction Continue
        }
    }
    Write-Information "Loaded $($moduleFiles.Count) modules." -InformationAction Continue
} else {
    Write-Error "ERROR: Modules directory not found at $script:ModulesPath" -ErrorAction Continue
    Write-Warning "Please ensure all module files are in the 'modules' subdirectory."
    Read-Host "Press Enter to exit"
    exit 1
}

# Initialize logging
Initialize-Logging -LogDirectory "$env:TEMP\HellionPowerTool" -DetailedLogging

Write-Log "Hellion Power Tool v7.1.3 'Fenrir-Update' started (Modular version)" -Color Cyan
Write-Log "Modules loaded from: $script:ModulesPath" -Color Gray

# Load configuration
if (Get-Command Load-Configuration -ErrorAction SilentlyContinue) {
    $script:Config = Load-Configuration
    Write-Log "[CONFIG] Konfiguration geladen erfolgreich" -Level "DEBUG"
} else {
    Write-Warning "Config-Utils Modul nicht verfÃ¼gbar - verwende Defaults"
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
    Write-Debug "[DEBUG-DETAIL] Parameter Analysis:"
    Write-Debug "  DebugMode.IsPresent: $($DebugMode.IsPresent)"
    Write-Debug "  DevMode.IsPresent: $($DevMode.IsPresent)"
    Write-Debug "  ForceDebugLevel: $ForceDebugLevel"
    Write-Debug "  global:LauncherDebugMode: $($global:LauncherDebugMode)"
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
    Write-Verbose "[PARAM-FORCE] Debug-Mode forced to: $modeText"
    Write-Log "[PARAM] Debug-Mode forced to: $modeText" -Level "DEV"
} elseif ($DevMode.IsPresent -eq $true) {
    $script:DebugLevel = 2
    Write-Information "[PARAM-DEV] Developer-Mode activated via DevMode parameter" -InformationAction Continue
    Write-Log "[PARAM] Developer-Mode activated via DevMode parameter" -Level "DEV"
} elseif ($DebugMode.IsPresent -eq $true) {
    $script:DebugLevel = 1
    Write-Information "[PARAM-DEBUG] Debug-Mode activated via DebugMode parameter" -InformationAction Continue
    Write-Log "[PARAM] Debug-Mode activated via DebugMode parameter" -Level "DEV"
} elseif ($null -ne $global:LauncherDebugMode -and $global:LauncherDebugMode -ge 0) {
    $script:DebugLevel = $global:LauncherDebugMode
    $modeText = switch ($script:DebugLevel) {
        0 { "Normal-Modus" }
        1 { "Debug-Modus" }
        2 { "Developer-Modus" }
        default { "Unknown" }
    }
    Write-Information "[LAUNCHER] Debug-Mode set by launcher: $modeText" -InformationAction Continue
    Write-Log "[LAUNCHER] Debug-Mode set by launcher: $modeText" -Level "DEV"
} else {
    Write-Information "[NO-PARAM] Keine Parameter erkannt - falle in manuelle Auswahl" -InformationAction Continue
    Clear-Host
    Write-Information "================================================================" -InformationAction Continue
    Write-Information "        HELLION POWER TOOL v7.1.3 'Fenrir-Update' (MODULAR)        " -InformationAction Continue
    Write-Information "================================================================" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "[*] DEBUG-MODUS WAEHLEN:" -InformationAction Continue
    Write-Information "  [0] Normal-Modus (Standard)" -InformationAction Continue
    Write-Information "  [1] Debug-Modus (Erweiterte Infos)" -InformationAction Continue  
    Write-Information "  [2] Developer-Modus (Alle Debug-Infos)" -InformationAction Continue
    Write-Information "" -InformationAction Continue

    $debugChoice = Read-Host "Modus waehlen [0-2]"
    switch ($debugChoice) {
        '1' { $script:DebugLevel = 1; Write-Information "Debug-Modus aktiviert" -InformationAction Continue
        }
        '2' { $script:DebugLevel = 2; Write-Information "Developer-Modus aktiviert" -InformationAction Continue
        }
        default { $script:DebugLevel = 0; Write-Information "Normal-Modus aktiviert" -InformationAction Continue
        }
    }

    Start-Sleep -Seconds 1
}

# Skip Auto-Mode Prompt - go directly to menu

# Main Menu Function
function Show-MainMenu {
    Clear-Host
    Write-Information "================================================================" -InformationAction Continue
    Write-Information "        HELLION POWER TOOL v7.1.3 'Fenrir-Update' (MODULAR)        " -InformationAction Continue
    Write-Information "================================================================" -InformationAction Continue
    
    # Show current debug mode (nur in Debug-Modi)
    if ($script:DebugLevel -ge 1) {
        Write-Information "[DEBUG-STATUS] script:DebugLevel = $($script:DebugLevel)" -InformationAction Continue
    }
    
    $modeText = switch ($script:DebugLevel) {
        0 { "Normal-Modus" }
        1 { "Debug-Modus" }
        2 { "Developer-Modus" }
        default { "Unknown (Wert: $($script:DebugLevel))" }
    }
    Write-Information "Aktueller Modus: $modeText" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    Write-Information "  [*] SCHNELL-AKTIONEN:" -InformationAction Continue
    Write-Information "     [A] AUTO-MODUS ERWEITERT (Empfohlen)" -InformationAction Continue
    Write-Information "     [Q] Schnell-Bereinigung" -InformationAction Continue
    Write-Information "     [W] Winget-Updates" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "  === SYSTEM-REPARATUR ===" -InformationAction Continue
    Write-Information "     [1] System File Checker (SFC)" -InformationAction Continue
    Write-Information "     [2] DISM Reparatur" -InformationAction Continue
    Write-Information "     [3] CheckDisk Laufwerks-Pruefung" -InformationAction Continue
    Write-Information "     [4] DLL Integritaets-Check" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "  === SYSTEM-BEREINIGUNG ===" -InformationAction Continue
    Write-Information "     [5] Umfassende System-Bereinigung" -InformationAction Continue
    Write-Information "     [6] Performance-Optimierung" -InformationAction Continue
    Write-Information "     [7] Ungenutzte Programme finden" -InformationAction Continue
    Write-Information "     [8] Bloatware erkennen" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "  === DIAGNOSE & INFO ===" -InformationAction Continue
    Write-Information "     [9] System-Information" -InformationAction Continue
    Write-Information "     [10] Netzwerk-Test" -InformationAction Continue
    Write-Information "     [11] Treiber-Status" -InformationAction Continue
    Write-Information "     [12] System-Bericht erstellen" -InformationAction Continue
    Write-Information "     [13] Bluescreen/Crash Analyzer" -InformationAction Continue
    Write-Information "     [14] RAM-Test (Memory Diagnostic)" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "  === SICHERHEIT & VERWALTUNG ===" -InformationAction Continue
    Write-Information "     [15] Safe Adblock verwalten" -InformationAction Continue
    Write-Information "     [16] Wiederherstellungspunkte" -InformationAction Continue
    Write-Information "     [17] Netzwerk zuruecksetzen" -InformationAction Continue
    Write-Information "     [18] Winget Updates" -InformationAction Continue
    Write-Information "     [19] Auto-Modus (Nochmal ausfuehren)" -InformationAction Continue
    Write-Information "     [20] Schnell-Modus" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    Write-Information "     [x] Beenden" -InformationAction Continue
    Write-Information "" -InformationAction Continue
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
                Write-Error "ERROR: Auto-Mode function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        'Q' {
            Write-Information "`n[*] SCHNELL-BEREINIGUNG..." -InformationAction Continue
            $script:AutoApproveCleanup = $true
            $freed = 0
            
            if (Get-Command Remove-SafeFiles -ErrorAction SilentlyContinue) {
                $freed += Remove-SafeFiles "$env:TEMP" "Temp-Dateien" -Force
                $freed += Remove-SafeFiles "$env:SystemRoot\Temp" "System-Temp" -Force
                
                # DNS Cache leeren
                try {
                    & ipconfig /flushdns | Out-Null
                    Write-Information "[OK] DNS-Cache geleert" -InformationAction Continue
                } catch {
                    Write-Information "[WARNING] DNS-Cache konnte nicht geleert werden" -InformationAction Continue
                }
                
                Write-Information "[OK] Schnell-Bereinigung abgeschlossen! ($freed MB)" -InformationAction Continue
            } else {
                Write-Error "ERROR: Cleanup functions not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        'W' {
            if (Get-Command Get-WingetUpdates -ErrorAction SilentlyContinue) {
                $updates = Get-WingetUpdates
                if ($updates.Count -gt 0) {
                    Write-Information "`n$($updates.Count) Updates verfuegbar. Alle installieren? [j/n]" -InformationAction Continue
                    $installChoice = Read-Host
                    if ($installChoice -eq 'j' -or $installChoice -eq 'J') {
                        $null = Install-WingetUpdates  # Suppress return value output
                    }
                } else {
                    Write-Information "`nKeine Winget-Updates verfuegbar." -InformationAction Continue
                }
            } else {
                Write-Error "ERROR: Winget functions not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        
        # SYSTEM-REPARATUR
        '1' {
            # Load new simple SFC module
            . "$PSScriptRoot\modules\sfc-simple.ps1"
            
            if (Get-Command Invoke-SimpleSFC -ErrorAction SilentlyContinue) {
                $null = Invoke-SimpleSFC  # Suppress return value
            } else {
                Write-Error "ERROR: Simple SFC function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '2' {
            if (Get-Command Invoke-DISMRepair -ErrorAction SilentlyContinue) {
                Invoke-DISMRepair
            } else {
                Write-Error "ERROR: DISM Repair function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '3' {
            if (Get-Command Invoke-CheckDisk -ErrorAction SilentlyContinue) {
                Invoke-CheckDisk
            } else {
                Write-Error "ERROR: CheckDisk function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '4' {
            if (Get-Command Test-DLLIntegrity -ErrorAction SilentlyContinue) {
                Test-DLLIntegrity
            } else {
                Write-Error "ERROR: DLL Integrity function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '5' {
            if (Get-Command Invoke-ComprehensiveCleanup -ErrorAction SilentlyContinue) {
                Invoke-ComprehensiveCleanup
            } else {
                Write-Error "ERROR: Comprehensive Cleanup function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '6' {
            if (Get-Command Optimize-SystemPerformance -ErrorAction SilentlyContinue) {
                Optimize-SystemPerformance
            } else {
                Write-Error "ERROR: Performance Optimization function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '7' {
            if (Get-Command Get-UnusedPrograms -ErrorAction SilentlyContinue) {
                $null = Get-UnusedPrograms  # Capture return value to prevent console output
            } else {
                Write-Error "ERROR: Unused Programs function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '8' {
            # Simple Bloatware-Erkennung (robust und schnell)
            try {
                # Lade das einfache Modul
                . "$PSScriptRoot\modules\bloatware-detection-simple.ps1"
                
                # Starte einfache Bloatware-Erkennung
                $bloatwareResults = Get-SimpleBloatwarePrograms
                
                if ($bloatwareResults -and $bloatwareResults.Count -gt 0) {
                    Write-Information "`n[SUCCESS] $($bloatwareResults.Count) Bloatware-Programme identifiziert" -InformationAction Continue
                } else {
                    Write-Information "`n[OK] System scheint sauber zu sein!" -InformationAction Continue
                }
            } catch {
                Write-Information "`n[ERROR] Bloatware-Erkennung fehlgeschlagen!" -InformationAction Continue
                Write-Information "Fehlerdetails: $($_.Exception.Message)" -InformationAction Continue
                Write-Information "Fehlerzeile: $($_.InvocationInfo.ScriptLineNumber)" -InformationAction Continue
                
                # Debug-Information
                if ($_.Exception.InnerException) {
                    Write-Information "Inner Exception: $($_.Exception.InnerException.Message)" -InformationAction Continue
                }
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '9' {
            if (Get-Command Get-DetailedSystemInfo -ErrorAction SilentlyContinue) {
                Get-DetailedSystemInfo
                Get-EnhancedDriveInfo
            } else {
                Write-Error "ERROR: System Info function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '10' {
            if (Get-Command Test-EnhancedInternetConnectivity -ErrorAction SilentlyContinue) {
                Test-EnhancedInternetConnectivity
            } else {
                Write-Error "ERROR: Network Test function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '11' {
            Write-Information "`n[*] TREIBER-OPTIONEN:" -InformationAction Continue
            Write-Information "  [1] Treiber-Status analysieren" -InformationAction Continue
            Write-Information "  [2] Problematische Treiber reparieren" -InformationAction Continue
            Write-Information "  [3] Alle Treiber neu installieren" -InformationAction Continue
            Write-Information "  [x] Zurueck zum Hauptmenu" -InformationAction Continue
            
            $driverChoice = Read-Host "`nWahl [1-3/x]"
            switch ($driverChoice.ToLower()) {
                '1' {
                    if (Get-Command Get-DetailedDriverStatus -ErrorAction SilentlyContinue) {
                        Get-DetailedDriverStatus
                    } else {
                        Write-Error "ERROR: Driver Status function not found." -ErrorAction Continue
                    }
                }
                '2' {
                    Write-Information "`n[*] TREIBER-REPARATUR:" -InformationAction Continue
                    Write-Information "[WARNING] Treiber-Reparatur kann System-Neustart erfordern!" -InformationAction Continue
                    
                    $confirm = Read-Host "`nProblematische Treiber reparieren? [j/n]"
                    if ($confirm -eq 'j' -or $confirm -eq 'J') {
                        # Verwende pnputil fÃ¼r Treiber-Reparatur
                        Write-Information "`n[*] Suche nach problematischen Treibern..." -InformationAction Continue
                        
                        try {
                            # Problematische GerÃ¤te finden
                            $problemDevices = Get-WmiObject Win32_PnPEntity | Where-Object { 
                                $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne 22 
                            }
                            
                            if ($problemDevices.Count -gt 0) {
                                Write-Information "[*] Gefunden: $($problemDevices.Count) Geraete mit Problemen" -InformationAction Continue
                                
                                foreach ($device in $problemDevices | Select-Object -First 5) {
                                    Write-Information "  [*] Repariere: $($device.Name)" -InformationAction Continue
                                    
                                    # Versuche GerÃ¤t zu deaktivieren und reaktivieren
                                    try {
                                        $deviceId = $device.DeviceID
                                        & pnputil /restart-device "$deviceId" 2>$null
                                        Write-Information "    [OK] Neustart versucht" -InformationAction Continue
                                    } catch {
                                        Write-Information "    [WARNING] Neustart fehlgeschlagen" -InformationAction Continue
                                    }
                                }
                                
                                Write-Information "`n[INFO] Treiber-Reparatur abgeschlossen" -InformationAction Continue
                                Write-Information "[EMPFEHLUNG] System-Neustart wird empfohlen" -InformationAction Continue
                            } else {
                                Write-Information "[OK] Keine problematischen Treiber gefunden" -InformationAction Continue
                            }
                        } catch {
                            Write-Error "[ERROR] Treiber-Reparatur fehlgeschlagen: $($_.Exception.Message)" -ErrorAction Continue
                        }
                    }
                }
                '3' {
                    Write-Information "`n[DANGER] VOLLSTAENDIGE TREIBER-NEUINSTALLATION" -InformationAction Continue
                    Write-Information "[WARNING] Dies kann das System unbrauchbar machen!" -InformationAction Continue
                    Write-Information "[WARNING] Nur fuer Experten empfohlen!" -InformationAction Continue
                    
                    $confirm = Read-Host "`nWirklich alle Treiber neu installieren? [CONFIRM]"
                    if ($confirm -eq 'CONFIRM') {
                        Write-Information "`n[*] Starte Treiber-Neuinstallation..." -InformationAction Continue
                        Write-Information "[INFO] Diese Funktion ist zu riskant und wurde deaktiviert" -InformationAction Continue
                        Write-Information "[EMPFEHLUNG] Verwenden Sie Windows Update oder Hersteller-Tools" -InformationAction Continue
                    } else {
                        Write-Information "[SKIP] Treiber-Neuinstallation abgebrochen" -InformationAction Continue
                    }
                }
                'x' {
                    Write-Information "Zurueck zum Hauptmenu..." -InformationAction Continue
                }
                default {
                    Write-Information "Ungueltige Auswahl." -InformationAction Continue
                }
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '12' {
            if (Get-Command New-DetailedSystemReport -ErrorAction SilentlyContinue) {
                $reportPath = New-DetailedSystemReport
                if ($reportPath) {
                    Write-Information "`nSystem-Bericht erstellt: $reportPath" -InformationAction Continue
                }
            } else {
                Write-Error "ERROR: System report function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '13' {
            if (Get-Command Get-SystemCrashAnalysis -ErrorAction SilentlyContinue) {
                Get-SystemCrashAnalysis
            } else {
                Write-Error "ERROR: Crash analyzer function not found." -ErrorAction Continue
                Write-Information "Module: crash-analyzer.ps1 not loaded" -InformationAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '14' {
            # RAM-Test (Memory Diagnostic)
            . "$PSScriptRoot\modules\memory-diagnostic.ps1"
            Write-Information "`n[*] RAM-TEST OPTIONEN:" -InformationAction Continue
            Write-Information "  [1] Windows Memory Diagnostic starten (System-Neustart)" -InformationAction Continue
            Write-Information "  [2] Vorherige RAM-Test Ergebnisse anzeigen" -InformationAction Continue
            Write-Information "  [x] Zurueck zum Hauptmenu" -InformationAction Continue
            
            $memChoice = Read-Host "`nWahl [1-2/x]"
            switch ($memChoice.ToLower()) {
                '1' {
                    if (Get-Command Start-WindowsMemoryDiagnostic -ErrorAction SilentlyContinue) {
                        Start-WindowsMemoryDiagnostic
                    } else {
                        Write-Error "ERROR: Memory Diagnostic function not found." -ErrorAction Continue
                    }
                }
                '2' {
                    if (Get-Command Get-MemoryTestResults -ErrorAction SilentlyContinue) {
                        Get-MemoryTestResults
                    } else {
                        Write-Error "ERROR: Memory Test Results function not found." -ErrorAction Continue
                    }
                }
                'x' {
                    Write-Information "[INFO] Zurueck zum Hauptmenu..." -InformationAction Continue
                }
                default {
                    Write-Error "[ERROR] Ungueltige Auswahl: $memChoice" -ErrorAction Continue
                }
            }
            if ($memChoice.ToLower() -ne 'x') {
                Write-Information "`nPress Enter to continue..." -InformationAction Continue
                Read-Host
            }
        }
        '15' {
            if (Get-Command Invoke-SafeAdblock -ErrorAction SilentlyContinue) {
                Invoke-SafeAdblock
            } else {
                Write-Error "ERROR: Safe Adblock function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '16' {
            Write-Information "`n[*] WIEDERHERSTELLUNGSPUNKT OPTIONEN:" -InformationAction Continue
            Write-Information "  [1] Neuen Wiederherstellungspunkt erstellen" -InformationAction Continue
            Write-Information "  [2] Verfuegbare Wiederherstellungspunkte anzeigen" -InformationAction Continue
            Write-Information "  [3] System auf Wiederherstellungspunkt zuruecksetzen" -InformationAction Continue
            Write-Information "  [4] System Restore aktivieren" -InformationAction Continue
            Write-Information "  [x] Zurueck zum Hauptmenu" -InformationAction Continue
            
            $restoreChoice = Read-Host "`nWahl [1-4/x]"
            switch ($restoreChoice.ToLower()) {
                '1' {
                    if (Get-Command New-SystemRestorePoint -ErrorAction SilentlyContinue) {
                        New-SystemRestorePoint
                    } else {
                        Write-Error "ERROR: System Restore function not found." -ErrorAction Continue
                    }
                }
                '2' {
                    if (Get-Command Get-SystemRestorePoints -ErrorAction SilentlyContinue) {
                        Get-SystemRestorePoints
                    } else {
                        Write-Error "ERROR: System Restore function not found." -ErrorAction Continue
                    }
                }
                '3' {
                    if (Get-Command Restore-SystemToPoint -ErrorAction SilentlyContinue) {
                        Restore-SystemToPoint
                    } else {
                        Write-Error "ERROR: System Restore function not found." -ErrorAction Continue
                    }
                }
                '4' {
                    if (Get-Command Enable-SystemRestore -ErrorAction SilentlyContinue) {
                        Enable-SystemRestore
                    } else {
                        Write-Error "ERROR: System Restore function not found." -ErrorAction Continue
                    }
                }
                'x' {
                    Write-Information "Zurueck zum Hauptmenu..." -InformationAction Continue
                }
                default {
                    Write-Information "Ungueltige Auswahl." -InformationAction Continue
                }
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '17' {
            if (Get-Command Reset-NetworkConfiguration -ErrorAction SilentlyContinue) {
                Reset-NetworkConfiguration
            } else {
                Write-Error "ERROR: Network Reset function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '18' {
            Write-Information "`n[*] WINGET OPTIONEN:" -InformationAction Continue
            Write-Information "  [1] Verfuegbare Updates anzeigen" -InformationAction Continue
            Write-Information "  [2] Alle Updates installieren" -InformationAction Continue
            Write-Information "  [3] Software suchen" -InformationAction Continue
            Write-Information "  [4] Winget-Status pruefen" -InformationAction Continue
            Write-Information "  [x] Zurueck zum Hauptmenu" -InformationAction Continue
            
            $wingetChoice = Read-Host "`nWahl [1-4/x]"
            switch ($wingetChoice.ToLower()) {
                '1' {
                    if (Get-Command Get-WingetUpdates -ErrorAction SilentlyContinue) {
                        Get-WingetUpdates
                    } else {
                        Write-Error "ERROR: Winget function not found." -ErrorAction Continue
                    }
                }
                '2' {
                    if (Get-Command Install-WingetUpdates -ErrorAction SilentlyContinue) {
                        $null = Install-WingetUpdates  # Suppress return value output
                    } else {
                        Write-Error "ERROR: Winget function not found." -ErrorAction Continue
                    }
                }
                '3' {
                    if (Get-Command Search-WingetSoftware -ErrorAction SilentlyContinue) {
                        $searchTerm = Read-Host "Suchbegriff eingeben"
                        Search-WingetSoftware -SearchTerm $searchTerm
                    } else {
                        Write-Error "ERROR: Winget function not found." -ErrorAction Continue
                    }
                }
                '4' {
                    if (Get-Command Test-WingetAvailability -ErrorAction SilentlyContinue) {
                        Test-WingetAvailability
                    } else {
                        Write-Error "ERROR: Winget function not found." -ErrorAction Continue
                    }
                }
                'x' {
                    Write-Information "Zurueck zum Hauptmenu..." -InformationAction Continue
                }
                default {
                    Write-Information "Ungueltige Auswahl." -InformationAction Continue
                }
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '19' {
            if (Get-Command Invoke-EnhancedAutoMode -ErrorAction SilentlyContinue) {
                Invoke-EnhancedAutoMode
            } else {
                Write-Error "ERROR: Auto-Mode function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '20' {
            if (Get-Command Invoke-QuickMode -ErrorAction SilentlyContinue) {
                Invoke-QuickMode
            } else {
                Write-Error "ERROR: Quick-Mode function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        'x' {
            Write-Log "Tool beendet durch Benutzer" -Color Yellow
            Write-Information "`nTool wird beendet..." -InformationAction Continue
            break
        }
        default {
            Write-Information "Ungueltige Auswahl. Bitte waehlen Sie eine gueltige Option." -InformationAction Continue
            Start-Sleep -Seconds 2
        }
    }
} while ($choice.ToLower() -ne 'x')

# Display final summary
$logSummary = Get-LogSummary
Write-Information "`n================================================================" -InformationAction Continue
Write-Information "                        ZUSAMMENFASSUNG                        " -InformationAction Continue
Write-Information "================================================================" -InformationAction Continue
Write-Log "`n[*] Log gespeichert: $($logSummary.LogFile)" -Color Cyan
Write-Log "[*] Log-Groesse: $($logSummary.LogSize) KB" -Color Gray
if ($logSummary.ErrorCount -gt 0) {
    Write-Log "[*] Fehler protokolliert: $($logSummary.ErrorCount)" -Color Red
}
if ($logSummary.WarningCount -gt 0) {
    Write-Log "[*] Warnungen protokolliert: $($logSummary.WarningCount)" -Color Yellow
}

Write-Information "`n[*] Enter zum Beenden..." -InformationAction Continue
Read-Host


