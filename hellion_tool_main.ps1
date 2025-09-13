# ===================================================================
# HELLION POWER TOOL - MODULAR VERSION v7.1.5.3 "Baldur"
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
    
    try {
        Start-Process $powershellExe -ArgumentList $arguments -Verb RunAs
        exit
    } catch {
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host "ADMINISTRATOR-RECHTE WURDEN ABGELEHNT" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Das Tool kann ohne Administrator-Rechte nicht ausgefuehrt werden." -ForegroundColor White
        Write-Host ""
        Write-Host "MOEGLICHE GRUENDE:" -ForegroundColor Cyan
        Write-Host "  • Sie haben die Windows UAC-Abfrage abgebrochen" -ForegroundColor Gray
        Write-Host "  • Sie haben 'Nein' bei der Sicherheitsabfrage geklickt" -ForegroundColor Gray
        Write-Host "  • UAC ist deaktiviert aber Sie sind kein Administrator" -ForegroundColor Gray
        Write-Host ""
        Write-Host "LOESUNG:" -ForegroundColor Green
        Write-Host "  1. Tool erneut starten" -ForegroundColor White
        Write-Host "  2. Bei der UAC-Abfrage auf 'Ja' klicken" -ForegroundColor White
        Write-Host "  3. Oder: Rechtsklick auf START.bat -> Als Administrator ausfuehren" -ForegroundColor White
        Write-Host ""
        Write-Host "[INFO] Tool wird beendet. Druecke eine beliebige Taste..." -ForegroundColor Yellow
        
        try { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null } catch { Read-Host }
        exit 1
    }
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
Write-Information "        HELLION POWER TOOL v7.1.5.3 'Baldur' (MODULAR)        " -InformationAction Continue
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

Write-Log "Hellion Power Tool v7.1.5.3 'Baldur' started (Modular version)" -Color Cyan
Write-Log "Modules loaded from: $script:ModulesPath" -Color Gray

# Load configuration
if (Get-Command Import-Configuration -ErrorAction SilentlyContinue) {
    $script:Config = Import-Configuration
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
    Write-Information "        HELLION POWER TOOL v7.1.5.3 'Baldur' (MODULAR)        " -InformationAction Continue
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
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "        HELLION POWER TOOL v7.1.5.3 'Baldur' (MODULAR)        " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    
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
    
    # 🚀 HAUPT-AKTIONEN (Empfohlen für alle User)
    Write-UIOutput "🚀 HAUPT-AKTIONEN" -ForegroundColor Cyan
    Write-Information "   [A] Auto-Modus Erweitert     (Empfohlen - Alles automatisch)" -InformationAction Continue
    Write-Information "   [Q] Schnell-Bereinigung      (5 Min - Grundreinigung)" -InformationAction Continue
    Write-Information "   [1] System-Reparatur         (SFC + DISM + CheckDisk)" -InformationAction Continue
    Write-Information "   [2] Performance-Boost        (Bereinigung + Optimierung)" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    # 🔧 DIAGNOSE & PROBLEMLÖSUNG
    Write-UIOutput "🔧 DIAGNOSE & PROBLEMLÖSUNG" -ForegroundColor Yellow  
    Write-Information "   [3] System-Information        (Hardware + Software Überblick)" -InformationAction Continue
    Write-Information "   [4] Netzwerk-Test             (Internet + DNS + Speed)" -InformationAction Continue
    Write-Information "   [5] Treiber-Diagnose          (ENE.SYS + Hardware-Probleme)" -InformationAction Continue
    Write-Information "   [6] Bluescreen-Analyse        (Crash-Logs + Ursachen)" -InformationAction Continue
    Write-Information "   [7] RAM-Test                  (Memory Diagnostic)" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    # 🛡️ SICHERHEIT & VERWALTUNG  
    Write-UIOutput "🛡️ SICHERHEIT & VERWALTUNG" -ForegroundColor Green
    Write-Information "   [8] Wiederherstellungspunkte  (Backup + Restore)" -InformationAction Continue
    Write-Information "   [9] Bloatware-Erkennung       (Unnötige Software finden)" -InformationAction Continue
    Write-Information "   [W] Winget-Updates            (Software aktualisieren)" -InformationAction Continue
    Write-Information "   [R] Netzwerk zurücksetzen     (Bei Internet-Problemen)" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    # 📊 ERWEITERTE FUNKTIONEN
    Write-UIOutput "📊 ERWEITERTE FUNKTIONEN" -ForegroundColor Magenta
    Write-Information "   [E] System-Bericht erstellen  (Detaillierte Analyse)" -InformationAction Continue
    Write-Information "   [S] Safe Adblock verwalten    (Werbeblocker-Tools)" -InformationAction Continue
    Write-Information "   [D] DLL-Integritäts-Check     (System-Dateien prüfen)" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    Write-UIOutput "[X] BEENDEN" -ForegroundColor Red
    Write-Information "" -InformationAction Continue
}


# DEBUG: Module Syntax & Function Check (nur in Debug-Modus)
if (($null -ne $script:DebugLevel) -and ([int]$script:DebugLevel -ge 1)) {
    Write-Information "" -InformationAction Continue
    Write-Information "[DEBUG] Starting module validation..." -InformationAction Continue
    Write-Host "🔍 MODUL-VALIDIERUNG" -ForegroundColor Cyan
    Write-Host "────────────────────────" -ForegroundColor DarkGray
    
    $validationErrors = 0
    $validationWarnings = 0
    
    # Syntax-Check aller Module
    if (Test-Path $script:ModulesPath) {
        $moduleFiles = Get-ChildItem "$script:ModulesPath\*.ps1" -ErrorAction SilentlyContinue
        
        foreach ($moduleFile in $moduleFiles) {
            Write-Host "📄 Prüfe: " -ForegroundColor White -NoNewline
            Write-Host "$($moduleFile.Name)" -ForegroundColor Gray -NoNewline
            
            try {
                # Basis Syntax-Check durch Parsing
                $tokens = @()
                $parseErrors = @()
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $moduleFile.FullName -Raw), [ref]$parseErrors)
                
                if ($parseErrors.Count -gt 0) {
                    Write-Host " - ❌ " -ForegroundColor Red -NoNewline
                    Write-Host "SYNTAX-FEHLER" -ForegroundColor Red
                    foreach ($error in $parseErrors) {
                        Write-Host "    🔍 Zeile $($error.Token.StartLine): $($error.Message)" -ForegroundColor DarkRed
                    }
                    $validationErrors++
                    continue
                }
                
                # Content für weitere Analysen laden
                $content = Get-Content $moduleFile.FullName -Raw
                
                # Erweiterte Deep-Validation (nur in Debug-Modi)
                $deepValidation = @{
                    Functions = @()
                    Issues = @()
                    Warnings = @()
                    Score = 0
                }
                
                try {
                    # 1. Funktions-Extraktion und Parameter-Analyse
                    $functionPattern = '(?s)function\s+([A-Za-z0-9-_]+)\s*\{.*?^}'
                    $functionMatches = [regex]::Matches($content, 'function\s+([A-Za-z0-9-_]+)')
                    
                    foreach ($match in $functionMatches) {
                        $funcName = $match.Groups[1].Value
                        $deepValidation.Functions += $funcName
                        
                        # Parameter-Check für jede Funktion
                        $paramPattern = "function\s+$funcName\s*\{[^}]*param\s*\("
                        if ($content -match $paramPattern) {
                            $deepValidation.Score += 10  # Bonus für Parameter-Dokumentation
                        }
                    }
                    
                    # 2. Error-Handling Qualität prüfen
                    $tryCatchCount = ([regex]::Matches($content, 'try\s*\{')).Count
                    $errorActionCount = ([regex]::Matches($content, '-ErrorAction\s+\w+')).Count
                    
                    if ($tryCatchCount -eq 0 -and $deepValidation.Functions.Count -gt 0) {
                        $deepValidation.Warnings += "Keine Try-Catch Blöcke gefunden"
                    } else {
                        $deepValidation.Score += ($tryCatchCount * 5)
                    }
                    
                    # 3. Cmdlet-Dependency Check
                    $commonCmdlets = @('Get-Process', 'Start-Process', 'Get-ChildItem', 'Remove-Item', 'Test-Path', 'Write-Error', 'Write-Warning')
                    $usedCmdlets = @()
                    foreach ($cmdlet in $commonCmdlets) {
                        if ($content -match [regex]::Escape($cmdlet)) {
                            $usedCmdlets += $cmdlet
                        }
                    }
                    
                    # 4. Return-Statement Analyse
                    $returnCount = ([regex]::Matches($content, 'return\s+')).Count
                    if ($returnCount -eq 0 -and $deepValidation.Functions.Count -gt 0) {
                        $deepValidation.Warnings += "Keine Return-Statements gefunden"
                    }
                    
                    # 5. Write-Log Usage Check (für User-Friendly Output)
                    $writeLogCount = ([regex]::Matches($content, 'Write-Log\s+')).Count
                    if ($writeLogCount -gt 0) {
                        $deepValidation.Score += 15  # Bonus für User-Friendly Logging
                    }
                    
                    # 6. Erweiterte Problematische Patterns & Anti-False-Positive Checks
                    $problematicPatterns = @(
                        @{Pattern = '\$\w+\.\w+:'; Issue = "Variable-Syntax Problem (Doppelpunkt nach Eigenschaft)"; Severity = "High"},
                        @{Pattern = 'Invoke-Expression'; Issue = "Unsichere Invoke-Expression verwendet"; Severity = "High"},
                        @{Pattern = 'catch\s*\{\s*\}'; Issue = "Leere Catch-Blöcke gefunden"; Severity = "Medium"},
                        @{Pattern = 'Start-Sleep\s+\d{4,}'; Issue = "Sehr lange Sleep-Zeit gefunden (>1000ms)"; Severity = "Medium"},
                        @{Pattern = 'Write-Host.*-NoNewline.*Write-Host'; Issue = "Potentielle Ausgabe-Formatierung-Problem"; Severity = "Low"},
                        @{Pattern = 'Get-WmiObject'; Issue = "Veraltetes WMI - Consider Get-CimInstance"; Severity = "Low"},
                        @{Pattern = '\$LASTEXITCODE'; Issue = "Exit-Code wird verwendet - gut für Robustheit"; Severity = "Positive"},
                        @{Pattern = '-ErrorAction\s+(SilentlyContinue|Stop)'; Issue = "Explizite Error-Action - gut"; Severity = "Positive"}
                    )
                    
                    foreach ($pattern in $problematicPatterns) {
                        $matches = [regex]::Matches($content, $pattern.Pattern)
                        if ($matches.Count -gt 0) {
                            if ($pattern.Severity -eq "Positive") {
                                $deepValidation.Score += ($matches.Count * 3)
                                # Positive Patterns nicht als Issues anzeigen
                            } else {
                                $deepValidation.Issues += "$($pattern.Issue) ($($matches.Count)x gefunden)"
                                if ($pattern.Severity -eq "High") { $validationErrors++ }
                                elseif ($pattern.Severity -eq "Medium") { $validationWarnings++ }
                            }
                        }
                    }
                    
                    # 7. AV-spezifische False-Positive Checks
                    $avRiskyPatterns = @{
                        "Universal" = @(
                            @{Pattern = 'Remove-Item.*-Recurse.*-Force'; Risk = "Aggressive Datei-Löschung"; Severity = "High"},
                            @{Pattern = 'Start-Process.*-WindowStyle\s+Hidden'; Risk = "Hidden Process Start"; Severity = "High"},
                            @{Pattern = 'Invoke-WebRequest|Invoke-RestMethod'; Risk = "Netzwerk-Download"; Severity = "Medium"},
                            @{Pattern = 'Add-Type.*System\.Windows\.Forms'; Risk = "GUI-Manipulation"; Severity = "Medium"},
                            @{Pattern = 'Registry::.*HKLM'; Risk = "Registry-Zugriff"; Severity = "Medium"},
                            @{Pattern = '\[System\.IO\.File\]::'; Risk = "Direkte Datei-Manipulation"; Severity = "Low"}
                        )
                        "Bitdefender" = @(
                            @{Pattern = 'Get-Process.*Stop-Process'; Risk = "Prozess-Manipulation (Bitdefender-sensitiv)"; Severity = "High"},
                            @{Pattern = 'Set-Service.*-Status\s+(Stop|Disabled)'; Risk = "Service-Manipulation (Bitdefender-kritisch)"; Severity = "High"},
                            @{Pattern = 'New-Object.*System\.Net\.WebClient'; Risk = "WebClient-Download (Bitdefender-Verdacht)"; Severity = "High"},
                            @{Pattern = 'powershell.*-EncodedCommand'; Risk = "Encoded Commands (Bitdefender-Malware-Signature)"; Severity = "Critical"},
                            @{Pattern = '\$env:TEMP.*\.exe'; Risk = "Temp-EXE-Erstellung (Bitdefender-Heuristik)"; Severity = "High"}
                        )
                        "Avast" = @(
                            @{Pattern = 'Invoke-Expression.*\$\('; Risk = "Dynamic Code Execution (Avast-Heuristik)"; Severity = "High"},
                            @{Pattern = 'Start-Job.*ScriptBlock'; Risk = "Background ScriptBlock (Avast-Verdacht)"; Severity = "Medium"},
                            @{Pattern = 'Copy-Item.*-Destination.*System32'; Risk = "System32-Manipulation (Avast-kritisch)"; Severity = "Critical"},
                            @{Pattern = '\[Convert\]::FromBase64String'; Risk = "Base64-Decoding (Avast-Malware-Pattern)"; Severity = "High"},
                            @{Pattern = 'HKCU.*\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'; Risk = "Autostart-Manipulation (Avast-sensitiv)"; Severity = "High"}
                        )
                        "AVG" = @(
                            @{Pattern = 'Get-WmiObject.*Win32_Process.*Create'; Risk = "WMI-Process-Start (AVG-Heuristik)"; Severity = "High"},
                            @{Pattern = 'New-Object.*-Com.*Shell.Application'; Risk = "COM-Shell-Zugriff (AVG-Verdacht)"; Severity = "Medium"},
                            @{Pattern = 'Set-ExecutionPolicy.*Bypass'; Risk = "ExecutionPolicy-Bypass (AVG-kritisch)"; Severity = "High"},
                            @{Pattern = '\$PSHome.*powershell\.exe'; Risk = "PowerShell-Rekursion (AVG-Signature)"; Severity = "Medium"}
                        )
                        "Norton" = @(
                            @{Pattern = 'Compress-Archive.*\.zip'; Risk = "Archive-Erstellung (Norton-Packer-Detection)"; Severity = "Medium"},
                            @{Pattern = 'Get-Content.*\| Out-File.*\.bat'; Risk = "Batch-File-Generierung (Norton-Script-Virus)"; Severity = "High"},
                            @{Pattern = 'New-Object.*System\.Security\.Principal\.WindowsPrincipal'; Risk = "Elevation-Check (Norton-UAC-Bypass-Signature)"; Severity = "Medium"}
                        )
                        "McAfee" = @(
                            @{Pattern = 'Start-Process.*cmd\.exe.*\/c'; Risk = "CMD-Execution (McAfee-Shell-Injection)"; Severity = "High"},
                            @{Pattern = '\[System\.Text\.Encoding\].*GetBytes'; Risk = "Encoding-Manipulation (McAfee-Obfuscation)"; Severity = "Medium"},
                            @{Pattern = 'Get-Random.*-Minimum.*-Maximum'; Risk = "Random-Generierung (McAfee-Polymorphic-Signature)"; Severity = "Low"}
                        )
                        "Kaspersky" = @(
                            @{Pattern = 'Test-NetConnection.*-Port\s+\d+'; Risk = "Port-Scanning (Kaspersky-Network-Heuristik)"; Severity = "Medium"},
                            @{Pattern = 'Get-Credential.*-Message'; Risk = "Credential-Harvesting (Kaspersky-Phishing)"; Severity = "High"},
                            @{Pattern = '\[System\.Diagnostics\.Process\]::Start'; Risk = "Process-Start (Kaspersky-Injection-Pattern)"; Severity = "Medium"}
                        )
                    }
                    
                    $detectedRisks = @{
                        Universal = @()
                        Specific = @()
                    }
                    
                    # Universal-Patterns für alle AVs prüfen
                    foreach ($pattern in $avRiskyPatterns["Universal"]) {
                        $matches = [regex]::Matches($content, $pattern.Pattern)
                        if ($matches.Count -gt 0) {
                            $detectedRisks.Universal += @{
                                Risk = $pattern.Risk
                                Severity = $pattern.Severity
                                Count = $matches.Count
                            }
                        }
                    }
                    
                    # Spezifische AV-Patterns prüfen
                    foreach ($avName in @("Bitdefender", "Avast", "AVG", "Norton", "McAfee", "Kaspersky")) {
                        if ($avRiskyPatterns.ContainsKey($avName)) {
                            foreach ($pattern in $avRiskyPatterns[$avName]) {
                                $matches = [regex]::Matches($content, $pattern.Pattern)
                                if ($matches.Count -gt 0) {
                                    $detectedRisks.Specific += @{
                                        AV = $avName
                                        Risk = $pattern.Risk
                                        Severity = $pattern.Severity
                                        Count = $matches.Count
                                    }
                                }
                            }
                        }
                    }
                    
                    # Risiko-Bewertung hinzufügen
                    if ($detectedRisks.Universal.Count -gt 0 -or $detectedRisks.Specific.Count -gt 0) {
                        $criticalRisks = ($detectedRisks.Universal + $detectedRisks.Specific) | Where-Object { $_.Severity -eq "Critical" }
                        $highRisks = ($detectedRisks.Universal + $detectedRisks.Specific) | Where-Object { $_.Severity -eq "High" }
                        
                        if ($criticalRisks.Count -gt 0) {
                            $deepValidation.Warnings += "KRITISCHES AV-Risiko: $($criticalRisks.Count) Pattern"
                        }
                        if ($highRisks.Count -gt 0) {
                            $deepValidation.Warnings += "HOHES AV-Risiko: $($highRisks.Count) Pattern"
                        }
                        
                        # Store für spätere detaillierte Ausgabe
                        $deepValidation.AVRisks = $detectedRisks
                    }
                    
                    # 8. Performance & Resource Check
                    $performanceIssues = @()
                    if ($content -match 'Get-ChildItem.*-Recurse.*\\') {
                        $performanceIssues += "Rekursive Datei-Suche (kann langsam sein)"
                    }
                    if ($content -match 'foreach.*Get-') {
                        $performanceIssues += "Cmdlet in Loop (Performance-Impact)"
                    }
                    if ([regex]::Matches($content, 'Start-Job').Count -gt 2) {
                        $performanceIssues += "Viele Background-Jobs (Ressourcen-intensiv)"
                        $deepValidation.Score += 10  # Bonus für Parallelisierung
                    }
                    
                    if ($performanceIssues.Count -gt 0) {
                        $deepValidation.Warnings += "Performance-Hinweise: $($performanceIssues -join ', ')"
                    }
                    
                    # 9. Security & Best Practice Check + Hardcoded Credentials Detection
                    $securityProfile = @{
                        Score = 0
                        HardcodedSecrets = @()
                        SecurityIssues = @()
                        BestPractices = @()
                    }
                    
                    # Best Practice Scoring
                    if ($content -match 'param\s*\([^)]*\[.*\]') {
                        $securityProfile.Score += 5
                        $securityProfile.BestPractices += "Type-sichere Parameter"
                    }
                    if ($content -match '\[CmdletBinding\(\)\]') {
                        $securityProfile.Score += 10
                        $securityProfile.BestPractices += "Advanced Function"
                    }
                    if ($content -match 'ValidateSet\(') {
                        $securityProfile.Score += 5
                        $securityProfile.BestPractices += "Input Validation"
                    }
                    if ($content -match '-WhatIf') {
                        $securityProfile.Score += 15
                        $securityProfile.BestPractices += "Safe execution support"
                    }
                    
                    # 14. Hardcoded Credentials & Secrets Detection
                    $secretPatterns = @(
                        @{Pattern = 'password\s*=\s*"[\w\d]{3,}"'; Type = "Hardcoded Password (Double Quote)"; Risk = "High"},
                        @{Pattern = "password\s*=\s*'[\w\d]{3,}'"; Type = "Hardcoded Password (Single Quote)"; Risk = "High"},
                        @{Pattern = 'apikey\s*=\s*"[\w\d]{10,}"'; Type = "API Key (Double Quote)"; Risk = "Critical"},
                        @{Pattern = "apikey\s*=\s*'[\w\d]{10,}'"; Type = "API Key (Single Quote)"; Risk = "Critical"},
                        @{Pattern = 'token\s*=\s*"[\w\d]{10,}"'; Type = "Authentication Token (Double Quote)"; Risk = "Critical"},
                        @{Pattern = "token\s*=\s*'[\w\d]{10,}'"; Type = "Authentication Token (Single Quote)"; Risk = "Critical"},
                        @{Pattern = 'secret\s*=\s*"[\w\d]{8,}"'; Type = "Secret Value"; Risk = "High"},
                        @{Pattern = '\$cred\s*=\s*New-Object.*Password'; Type = "PSCredential Password"; Risk = "High"},
                        @{Pattern = 'ConvertTo-SecureString\s+-String\s+"[\w\d]{3,}"'; Type = "Plain-Text in SecureString"; Risk = "Medium"},
                        @{Pattern = '-Password\s+"[\w\d]{3,}"'; Type = "Parameter Password"; Risk = "High"},
                        @{Pattern = 'mysql://.*:.*@'; Type = "MySQL Connection String"; Risk = "Critical"},
                        @{Pattern = 'postgres://.*:.*@'; Type = "PostgreSQL Connection String"; Risk = "Critical"},
                        @{Pattern = '"pk_[a-zA-Z0-9]{10,}"'; Type = "Stripe API Key"; Risk = "Critical"},
                        @{Pattern = '"sk_[a-zA-Z0-9]{10,}"'; Type = "Stripe Secret Key"; Risk = "Critical"},
                        @{Pattern = '"AKIA[0-9A-Z]{16}"'; Type = "AWS Access Key"; Risk = "Critical"},
                        @{Pattern = '"github_pat_[a-zA-Z0-9]{22}"'; Type = "GitHub Personal Access Token"; Risk = "Critical"},
                        @{Pattern = 'admin.*=.*"[\w\d]{3,}"'; Type = "Admin Account Credential"; Risk = "Critical"},
                        @{Pattern = 'administrator.*=.*"[\w\d]{3,}"'; Type = "Administrator Credential"; Risk = "Critical"},
                        @{Pattern = 'smtp.*password.*"[\w\d]{3,}"'; Type = "SMTP Password"; Risk = "Medium"},
                        @{Pattern = 'ftp://[^:]+:[^@]+@'; Type = "FTP Credential"; Risk = "Medium"}
                    )
                    
                    foreach ($secretPattern in $secretPatterns) {
                        $matches = [regex]::Matches($content, $secretPattern.Pattern, 'IgnoreCase')
                        if ($matches.Count -gt 0) {
                            foreach ($match in $matches) {
                                # Whitelist für bekannte sichere Patterns
                                $isWhitelisted = $false
                                $whitelistPatterns = @(
                                    'example\.com', 'localhost', '127\.0\.0\.1',  # Test-Domains
                                    'placeholder', 'your_password_here', 'enter_password',  # Platzhalter
                                    '\$\w+', 'Get-Content', 'Read-Host',  # Variablen oder sichere Eingabe
                                    'ConvertFrom-SecureString.*AsPlainText',  # Sichere Entschlüsselung
                                    'WindowsPrincipal.*WindowsIdentity.*Administrator',  # Windows API Admin-Check
                                    'Security\.Principal\..*Administrator',  # Windows Security Principal API
                                    'IsInRole.*Administrator'  # Windows Role-Check API
                                )
                                
                                foreach ($whitelist in $whitelistPatterns) {
                                    if ($match.Value -match $whitelist) {
                                        $isWhitelisted = $true
                                        break
                                    }
                                }
                                
                                if (-not $isWhitelisted) {
                                    $securityProfile.HardcodedSecrets += @{
                                        Type = $secretPattern.Type
                                        Risk = $secretPattern.Risk
                                        Context = $match.Value.Substring(0, [Math]::Min(50, $match.Value.Length)) + "..."
                                        Line = ($content.Substring(0, $match.Index) -split "`n").Count
                                    }
                                }
                            }
                        }
                    }
                    
                    # Weitere Sicherheits-Checks
                    $additionalSecurityChecks = @(
                        @{Pattern = 'Invoke-Expression.*\$\w+'; Issue = "Dynamic Code Execution mit Variablen"; Risk = "High"},
                        @{Pattern = 'Start-Process.*-Verb RunAs.*-WindowStyle Hidden'; Issue = "Versteckte Admin-Ausführung"; Risk = "High"},
                        @{Pattern = 'Add-Type.*DllImport'; Issue = "Native Code Import"; Risk = "Medium"},
                        @{Pattern = '\[System\.Reflection\.Assembly\]::Load'; Issue = "Assembly Loading"; Risk = "Medium"},
                        @{Pattern = 'New-Object.*-Com.*WScript\.Shell'; Issue = "WScript COM Object"; Risk = "Medium"},
                        @{Pattern = '\[Convert\]::FromBase64String.*IEX'; Issue = "Base64 + Invoke-Expression"; Risk = "Critical"},
                        @{Pattern = 'powershell.*-ep bypass.*-w hidden'; Issue = "Policy Bypass + Hidden Window"; Risk = "Critical"},
                        @{Pattern = 'Registry::.*CurrentVersion\\Run'; Issue = "Autostart Registry Manipulation"; Risk = "High"}
                    )
                    
                    foreach ($secCheck in $additionalSecurityChecks) {
                        $matches = [regex]::Matches($content, $secCheck.Pattern, 'IgnoreCase')
                        if ($matches.Count -gt 0) {
                            $securityProfile.SecurityIssues += @{
                                Issue = $secCheck.Issue
                                Risk = $secCheck.Risk
                                Count = $matches.Count
                            }
                        }
                    }
                    
                    $deepValidation.Score += $securityProfile.Score
                    $deepValidation.SecurityProfile = $securityProfile
                    
                    # 10. Code-Complexity Analyse
                    $complexity = @{
                        Functions = $deepValidation.Functions.Count
                        IfStatements = ([regex]::Matches($content, '\bif\s*\(')).Count
                        SwitchStatements = ([regex]::Matches($content, '\bswitch\s*\(')).Count
                        Loops = ([regex]::Matches($content, '\b(for|foreach|while)\s*\(')).Count
                        TryCatch = $tryCatchCount
                    }
                    
                    $complexityScore = ($complexity.IfStatements * 1) + ($complexity.SwitchStatements * 2) + 
                                     ($complexity.Loops * 2) + ($complexity.TryCatch * 5)
                    
                    if ($complexityScore -gt 50) {
                        $deepValidation.Warnings += "Hohe Code-Komplexität ($complexityScore Punkte)"
                    } elseif ($complexityScore -gt 20) {
                        $deepValidation.Score += 5  # Moderate Komplexität ist gut
                    }
                    
                    # Ergebnis-Ausgabe
                    if ($deepValidation.Functions.Count -gt 0) {
                        $qualityColor = if ($deepValidation.Score -ge 30) { "Green" } 
                                       elseif ($deepValidation.Score -ge 15) { "Yellow" } 
                                       else { "Red" }
                        
                        Write-Host " - ✅ " -ForegroundColor Green -NoNewline
                        Write-Host "$($deepValidation.Functions.Count) Funktionen " -ForegroundColor Green -NoNewline
                        Write-Host "(Qualität: $($deepValidation.Score))" -ForegroundColor $qualityColor
                        
                        Write-Host "    📋 Funktionen: " -ForegroundColor DarkGray -NoNewline
                        Write-Host "$($deepValidation.Functions -join ', ')" -ForegroundColor Gray
                        
                        if ($usedCmdlets.Count -gt 0) {
                            Write-Host "    🔧 Cmdlets: " -ForegroundColor DarkGray -NoNewline
                            Write-Host "$($usedCmdlets -join ', ')" -ForegroundColor Gray
                        }
                        
                        # Code-Complexity Info (nur bei hoher Komplexität)
                        if ($complexityScore -gt 20) {
                            Write-Host "    📊 Komplexität: " -ForegroundColor Magenta -NoNewline
                            Write-Host "$complexityScore Punkte " -ForegroundColor Magenta -NoNewline
                            Write-Host "($($complexity.IfStatements) If, $($complexity.Loops) Loops, $($complexity.TryCatch) Try-Catch)" -ForegroundColor DarkGray
                        }
                        
                        # AV-Risiken detailliert anzeigen
                        if ($deepValidation.AVRisks.Universal.Count -gt 0 -or $deepValidation.AVRisks.Specific.Count -gt 0) {
                            Write-Host ""
                            Write-Host "    🛡️ ANTIVIRUS-RISIKO-ANALYSE:" -ForegroundColor Red
                            
                            # Universal-Risiken (alle AVs)
                            if ($deepValidation.AVRisks.Universal.Count -gt 0) {
                                Write-Host "    ┌─ Universal-Risiken (alle AV-Produkte):" -ForegroundColor Yellow
                                foreach ($risk in $deepValidation.AVRisks.Universal) {
                                    $severityColor = switch ($risk.Severity) {
                                        "Critical" { "Red" }
                                        "High" { "Yellow" }
                                        "Medium" { "Cyan" }
                                        default { "Gray" }
                                    }
                                    Write-Host "    │  • " -ForegroundColor DarkGray -NoNewline
                                    Write-Host "$($risk.Risk) " -ForegroundColor $severityColor -NoNewline
                                    Write-Host "($($risk.Count)x, $($risk.Severity))" -ForegroundColor DarkGray
                                }
                            }
                            
                            # AV-spezifische Risiken
                            if ($deepValidation.AVRisks.Specific.Count -gt 0) {
                                Write-Host "    ├─ AV-spezifische Risiken:" -ForegroundColor Yellow
                                $groupedByAV = $deepValidation.AVRisks.Specific | Group-Object AV
                                foreach ($avGroup in $groupedByAV) {
                                    $criticalCount = ($avGroup.Group | Where-Object { $_.Severity -eq "Critical" }).Count
                                    $highCount = ($avGroup.Group | Where-Object { $_.Severity -eq "High" }).Count
                                    
                                    $avColor = if ($criticalCount -gt 0) { "Red" }
                                              elseif ($highCount -gt 2) { "Yellow" }
                                              else { "Cyan" }
                                    
                                    Write-Host "    │  🔸 " -ForegroundColor $avColor -NoNewline
                                    Write-Host "$($avGroup.Name): " -ForegroundColor $avColor -NoNewline
                                    Write-Host "$($avGroup.Group.Count) Risiko-Pattern" -ForegroundColor DarkGray
                                    
                                    foreach ($risk in ($avGroup.Group | Sort-Object Severity)) {
                                        $severitySymbol = switch ($risk.Severity) {
                                            "Critical" { "🔥" }
                                            "High" { "⚠️" }
                                            "Medium" { "💡" }
                                            default { "ℹ️" }
                                        }
                                        $severityColor = switch ($risk.Severity) {
                                            "Critical" { "Red" }
                                            "High" { "Yellow" }
                                            "Medium" { "Cyan" }
                                            default { "Gray" }
                                        }
                                        Write-Host "    │     $severitySymbol " -ForegroundColor $severityColor -NoNewline
                                        Write-Host "$($risk.Risk) " -ForegroundColor $severityColor -NoNewline
                                        Write-Host "($($risk.Count)x)" -ForegroundColor DarkGray
                                    }
                                }
                            }
                            
                            # Risiko-Empfehlung
                            $totalCritical = ($deepValidation.AVRisks.Universal + $deepValidation.AVRisks.Specific) | Where-Object { $_.Severity -eq "Critical" }
                            $totalHigh = ($deepValidation.AVRisks.Universal + $deepValidation.AVRisks.Specific) | Where-Object { $_.Severity -eq "High" }
                            
                            if ($totalCritical.Count -gt 0) {
                                Write-Host "    └─ 🚨 " -ForegroundColor Red -NoNewline
                                Write-Host "KRITISCHES RISIKO - AV-Scanner werden sehr wahrscheinlich anschlagen!" -ForegroundColor Red
                                Write-Host "       💡 Empfehlung: Code-Patterns überarbeiten oder AV-Whitelist konfigurieren" -ForegroundColor Yellow
                            } elseif ($totalHigh.Count -gt 2) {
                                Write-Host "    └─ ⚠️ " -ForegroundColor Yellow -NoNewline
                                Write-Host "HOHES RISIKO - AV-Scanner könnten anschlagen" -ForegroundColor Yellow
                                Write-Host "       💡 Empfehlung: Defender-Whitelist für Tool-Ordner erstellen" -ForegroundColor Cyan
                            } else {
                                Write-Host "    └─ ✅ " -ForegroundColor Green -NoNewline
                                Write-Host "MODERATES RISIKO - Tool sollte meist problemlos laufen" -ForegroundColor Green
                            }
                            Write-Host ""
                        }
                        
                        # Defender-Risiken anzeigen (für Kompatibilität)
                        if ($defenderRisks.Count -gt 0) {
                            Write-Host "    🛡️ Legacy Defender-Risiko: " -ForegroundColor Red -NoNewline
                            Write-Host "$($defenderRisks.Count) Pattern gefunden" -ForegroundColor Red
                        }
                        
                        # Issues anzeigen (mit Severity-Farben)
                        foreach ($issue in $deepValidation.Issues) {
                            $issueColor = if ($issue -match "Variable-Syntax|Invoke-Expression") { "Red" }
                                         elseif ($issue -match "Exception-Handling|Sleep-Zeit") { "Yellow" }
                                         else { "Cyan" }
                            Write-Host "    ⚠️ Problem: " -ForegroundColor $issueColor -NoNewline
                            Write-Host "$issue" -ForegroundColor $issueColor
                        }
                        
                        # Security-Profile anzeigen
                        if ($deepValidation.SecurityProfile) {
                            $secProfile = $deepValidation.SecurityProfile
                            
                            # Hardcoded Secrets anzeigen
                            if ($secProfile.HardcodedSecrets.Count -gt 0) {
                                Write-Host ""
                                Write-Host "    🚨 SICHERHEITS-WARNUNG: HARDCODED CREDENTIALS GEFUNDEN!" -ForegroundColor Red
                                foreach ($secret in $secProfile.HardcodedSecrets) {
                                    $riskColor = switch ($secret.Risk) {
                                        "Critical" { "Red" }
                                        "High" { "Yellow" }
                                        "Medium" { "Cyan" }
                                        default { "Gray" }
                                    }
                                    Write-Host "    │  🔐 " -ForegroundColor $riskColor -NoNewline
                                    Write-Host "$($secret.Type) " -ForegroundColor $riskColor -NoNewline
                                    Write-Host "(Zeile $($secret.Line), $($secret.Risk) Risiko)" -ForegroundColor DarkGray
                                    Write-Host "    │     📝 Context: " -ForegroundColor Gray -NoNewline
                                    Write-Host "$($secret.Context)" -ForegroundColor DarkGray
                                }
                                Write-Host "    └─ 💡 Empfehlung: Credentials in sichere Speicher (SecureString, Credential-Manager) verschieben" -ForegroundColor Yellow
                                Write-Host ""
                            }
                            
                            # Security Issues anzeigen
                            if ($secProfile.SecurityIssues.Count -gt 0) {
                                Write-Host "    🛡️ SICHERHEITS-CHECKS:" -ForegroundColor Yellow
                                foreach ($secIssue in $secProfile.SecurityIssues) {
                                    $riskColor = switch ($secIssue.Risk) {
                                        "Critical" { "Red" }
                                        "High" { "Yellow" }
                                        "Medium" { "Cyan" }
                                        default { "Gray" }
                                    }
                                    $riskSymbol = switch ($secIssue.Risk) {
                                        "Critical" { "🔥" }
                                        "High" { "⚠️" }
                                        "Medium" { "💡" }
                                        default { "ℹ️" }
                                    }
                                    Write-Host "    │  $riskSymbol " -ForegroundColor $riskColor -NoNewline
                                    Write-Host "$($secIssue.Issue) " -ForegroundColor $riskColor -NoNewline
                                    Write-Host "($($secIssue.Count)x gefunden)" -ForegroundColor DarkGray
                                }
                            }
                            
                            # Best Practices anzeigen (nur bei Debug Level 2+)
                            if ($secProfile.BestPractices.Count -gt 0 -and $script:DebugLevel -ge 2) {
                                Write-Host "    ✨ Security Best Practices: " -ForegroundColor Green -NoNewline
                                Write-Host "$($secProfile.BestPractices -join ', ')" -ForegroundColor Gray
                            }
                        }
                        
                        # Warnungen anzeigen (gruppiert)
                        foreach ($warning in $deepValidation.Warnings) {
                            $warningColor = if ($warning -match "Defender-False-Positive") { "Red" }
                                           elseif ($warning -match "Performance|Komplexität") { "Yellow" }
                                           else { "Cyan" }
                            Write-Host "    💡 Hinweis: " -ForegroundColor $warningColor -NoNewline
                            Write-Host "$warning" -ForegroundColor $warningColor
                        }
                        
                    } else {
                        Write-Host " - ⚠️ " -ForegroundColor Yellow -NoNewline
                        Write-Host "Keine Funktionen gefunden" -ForegroundColor Yellow
                        $validationWarnings++
                    }
                    
                } catch {
                    Write-Host " - ❌ " -ForegroundColor Red -NoNewline
                    Write-Host "Deep-Analyse fehlgeschlagen" -ForegroundColor Red
                    Write-Host "    🔍 Grund: $($_.Exception.Message)" -ForegroundColor DarkRed
                    $validationErrors++
                }
            } catch {
                Write-Host " - ❌ " -ForegroundColor Red -NoNewline
                Write-Host "KRITISCHER SYNTAX-FEHLER" -ForegroundColor Red
                Write-Host "    🔍 Modul kann nicht geladen werden: $($_.Exception.Message)" -ForegroundColor DarkRed
                $validationErrors++
            }
        }
        
        # Erweiterte Validierungs-Zusammenfassung
        Write-Host ""
        Write-Host "📊 DEEP-VALIDIERUNGS-ERGEBNIS" -ForegroundColor Cyan
        Write-Host "────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "📄 Module geprüft: " -ForegroundColor White -NoNewline
        Write-Host "$($moduleFiles.Count)" -ForegroundColor White
        
        if ($validationErrors -eq 0 -and $validationWarnings -eq 0) {
            Write-Host "✅ Status: " -ForegroundColor Green -NoNewline
            Write-Host "ALLE MODULE OPTIMAL" -ForegroundColor Green
            Write-Host "💡 Empfehlung: " -ForegroundColor Blue -NoNewline
            Write-Host "Tool ist bereit für den produktiven Einsatz" -ForegroundColor Gray
        } else {
            $overallStatus = if ($validationErrors -gt 0) { "KRITISCH" } elseif ($validationWarnings -gt 5) { "BEDENKLICH" } else { "AKZEPTABEL" }
            $statusColor = if ($validationErrors -gt 0) { "Red" } elseif ($validationWarnings -gt 5) { "Yellow" } else { "Cyan" }
            
            Write-Host "⚠️ Status: " -ForegroundColor $statusColor -NoNewline
            Write-Host "$overallStatus" -ForegroundColor $statusColor
            
            if ($validationErrors -gt 0) {
                Write-Host "❌ Kritische Fehler: " -ForegroundColor Red -NoNewline
                Write-Host "$validationErrors Module" -ForegroundColor Red
                Write-Host "💡 Empfehlung: " -ForegroundColor Blue -NoNewline
                Write-Host "Fehler beheben bevor Tool verwendet wird" -ForegroundColor Red
            }
            
            if ($validationWarnings -gt 0) {
                Write-Host "⚠️ Warnungen: " -ForegroundColor Yellow -NoNewline
                Write-Host "$validationWarnings Issues" -ForegroundColor Yellow
                Write-Host "💡 Empfehlung: " -ForegroundColor Blue -NoNewline
                if ($validationWarnings -gt 5) {
                    Write-Host "Warnungen überprüfen - eventuell Funktionalität eingeschränkt" -ForegroundColor Yellow
                } else {
                    Write-Host "Tool funktionsfähig, Optimierungen möglich" -ForegroundColor Cyan
                }
            }
            
            # Detaillierte Handlungsempfehlungen
            Write-Host ""
            Write-Host "🔧 HANDLUNGSEMPFEHLUNGEN:" -ForegroundColor Magenta
            if ($validationErrors -gt 0) {
                Write-Host "  1. Syntax-Fehler in betroffenen Modulen korrigieren" -ForegroundColor White
                Write-Host "  2. Module mit Try-Catch Blöcken absichern" -ForegroundColor White
                Write-Host "  3. Problematische Variable-Syntax beheben" -ForegroundColor White
            }
            if ($validationWarnings -gt 3) {
                Write-Host "  4. Return-Statements zu Funktionen hinzufügen" -ForegroundColor Gray
                Write-Host "  5. Error-Handling mit -ErrorAction verbessern" -ForegroundColor Gray
                Write-Host "  6. Write-Log für benutzerfreundliche Ausgaben nutzen" -ForegroundColor Gray
            }
        }
        
        # Kernfunktionen-Check
        Write-Host ""
        Write-Host "🔧 KERNFUNKTIONEN-CHECK" -ForegroundColor Cyan
        Write-Host "────────────────────────" -ForegroundColor DarkGray
        
        $coreModules = @(
            @{Name="sfc-simple.ps1"; Function="Invoke-SimpleSFC"},
            @{Name="system-cleanup.ps1"; Function="Invoke-ComprehensiveCleanup"},
            @{Name="disk-maintenance.ps1"; Function="Invoke-CheckDisk"},
            @{Name="network-tools.ps1"; Function="Test-EnhancedInternetConnectivity"},
            @{Name="logging-utils.ps1"; Function="Write-Log"}
        )
        
        foreach ($coreModule in $coreModules) {
            Write-Host "🔍 $($coreModule.Function): " -ForegroundColor White -NoNewline
            if (Get-Command $coreModule.Function -ErrorAction SilentlyContinue) {
                Write-Host "✅ Verfügbar" -ForegroundColor Green
            } else {
                Write-Host "❌ Nicht gefunden" -ForegroundColor Red
                $validationErrors++
            }
        }
        
        # 11. System-Environment Checks (zusätzlich zu Modul-Checks)
        Write-Host ""
        Write-Host "🔧 SYSTEM-ENVIRONMENT-CHECK" -ForegroundColor Cyan
        Write-Host "─────────────────────────────" -ForegroundColor DarkGray
        
        # PowerShell Version Check
        $psVersion = $PSVersionTable.PSVersion
        Write-Host "🔹 PowerShell: " -ForegroundColor White -NoNewline
        if ($psVersion.Major -ge 7) {
            Write-Host "v$psVersion ✅ Modern" -ForegroundColor Green
        } elseif ($psVersion.Major -eq 5 -and $psVersion.Minor -eq 1) {
            Write-Host "v$psVersion ⚠️ Legacy (funktional)" -ForegroundColor Yellow
        } else {
            Write-Host "v$psVersion ❌ Veraltet" -ForegroundColor Red
            $validationWarnings++
        }
        
        # Execution Policy Check
        $execPolicy = Get-ExecutionPolicy
        Write-Host "🔹 Execution Policy: " -ForegroundColor White -NoNewline
        if ($execPolicy -in @('Unrestricted', 'RemoteSigned', 'Bypass')) {
            Write-Host "$execPolicy ✅" -ForegroundColor Green
        } else {
            Write-Host "$execPolicy ⚠️ Restriktiv" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # Admin Rights Check
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        Write-Host "🔹 Administrator: " -ForegroundColor White -NoNewline
        if ($isAdmin) {
            Write-Host "✅ Verfügbar" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Nicht verfügbar (einige Features limitiert)" -ForegroundColor Yellow
        }
        
        # Umfassende Antiviren-Erkennung
        Write-Host "🔹 Antiviren-Schutz: " -ForegroundColor White -NoNewline
        
        $antivirusInfo = @{
            Product = "Unbekannt"
            Status = "Unbekannt"
            DefenderActive = $false
            ThirdPartyAV = $null
        }
        
        # 1. Windows Defender Status prüfen
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($defenderStatus) {
                $antivirusInfo.DefenderActive = $defenderStatus.RealTimeProtectionEnabled
                if ($defenderStatus.RealTimeProtectionEnabled) {
                    $antivirusInfo.Product = "Windows Defender"
                    $antivirusInfo.Status = "Aktiv"
                }
            }
        } catch {
            # Defender-Cmdlets nicht verfügbar
        }
        
        # 2. Dritt-Anbieter Antiviren über WMI/Registry suchen (falls Defender inaktiv)
        if (-not $antivirusInfo.DefenderActive) {
            $detectedAV = @()
            
            # Bekannte Antiviren-Programme (Registry-Einträge)
            $avPrograms = @(
                @{Name="Bitdefender"; Registry="HKLM:\SOFTWARE\Bitdefender"; Process="bdagent.exe"},
                @{Name="Avast"; Registry="HKLM:\SOFTWARE\AVAST Software\Avast"; Process="avastui.exe"},
                @{Name="AVG"; Registry="HKLM:\SOFTWARE\AVG"; Process="avgui.exe"},
                @{Name="Kaspersky"; Registry="HKLM:\SOFTWARE\Kaspersky Lab"; Process="avp.exe"},
                @{Name="Norton"; Registry="HKLM:\SOFTWARE\Norton"; Process="norton.exe"},
                @{Name="McAfee"; Registry="HKLM:\SOFTWARE\McAfee"; Process="mcshield.exe"},
                @{Name="ESET"; Registry="HKLM:\SOFTWARE\ESET"; Process="egui.exe"},
                @{Name="Malwarebytes"; Registry="HKLM:\SOFTWARE\Malwarebytes"; Process="mbam.exe"},
                @{Name="Trend Micro"; Registry="HKLM:\SOFTWARE\TrendMicro"; Process="uiwinmgr.exe"},
                @{Name="F-Secure"; Registry="HKLM:\SOFTWARE\F-Secure"; Process="fshoster32.exe"},
                @{Name="Sophos"; Registry="HKLM:\SOFTWARE\Sophos"; Process="sophosui.exe"},
                @{Name="G Data"; Registry="HKLM:\SOFTWARE\G Data"; Process="gdsc.exe"}
            )
            
            foreach ($av in $avPrograms) {
                try {
                    # Registry-Check
                    $regExists = Test-Path $av.Registry -ErrorAction SilentlyContinue
                    
                    # Process-Check 
                    $processExists = Get-Process -Name $av.Process.Replace('.exe', '') -ErrorAction SilentlyContinue
                    
                    if ($regExists -or $processExists) {
                        $detectedAV += @{
                            Name = $av.Name
                            Registry = $regExists
                            Process = ($processExists -ne $null)
                            Status = if ($processExists) { "Aktiv" } else { "Installiert" }
                        }
                    }
                } catch {
                    # Fehler bei AV-Erkennung ignorieren
                }
            }
            
            # WMI Security Center abfragen (Windows 10+)
            try {
                $securityCenter = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
                foreach ($av in $securityCenter) {
                    if ($av.displayName -notmatch "Windows Defender") {
                        $avState = switch ($av.productState) {
                            397568 { "Aktiv, Up-to-date" }
                            397584 { "Aktiv, Out-of-date" }
                            393472 { "Inaktiv, Up-to-date" }
                            393488 { "Inaktiv, Out-of-date" }
                            default { "Status: $($av.productState)" }
                        }
                        
                        $detectedAV += @{
                            Name = $av.displayName
                            Registry = $true
                            Process = ($avState -match "Aktiv")
                            Status = $avState
                        }
                    }
                }
            } catch {
                # WMI Security Center nicht verfügbar (ältere Windows-Versionen)
            }
            
            # Ergebnisse verarbeiten
            if ($detectedAV.Count -gt 0) {
                $antivirusInfo.ThirdPartyAV = $detectedAV
                $activeAV = $detectedAV | Where-Object { $_.Status -match "Aktiv" }
                
                if ($activeAV) {
                    $antivirusInfo.Product = $activeAV[0].Name
                    $antivirusInfo.Status = "Aktiv"
                } else {
                    $antivirusInfo.Product = "$($detectedAV[0].Name) (Installiert)"
                    $antivirusInfo.Status = "Installiert"
                }
            }
        }
        
        # Antiviren-Status ausgeben
        if ($antivirusInfo.DefenderActive) {
            Write-Host "✅ Windows Defender (False-Positives möglich)" -ForegroundColor Yellow
        } elseif ($antivirusInfo.ThirdPartyAV -and $antivirusInfo.ThirdPartyAV.Count -gt 0) {
            $activeThirdParty = $antivirusInfo.ThirdPartyAV | Where-Object { $_.Status -match "Aktiv" }
            if ($activeThirdParty) {
                Write-Host "✅ $($activeThirdParty[0].Name) (Dritt-Anbieter)" -ForegroundColor Green
                if ($activeThirdParty.Count -gt 1) {
                    Write-Host "    📋 Weitere: $($activeThirdParty[1..($activeThirdParty.Count-1)].Name -join ', ')" -ForegroundColor Gray
                }
                
                # Warnung bei bekannten "aggressiven" AVs
                $aggressiveAVs = @("Avast", "AVG", "McAfee", "Norton")
                if ($activeThirdParty[0].Name -in $aggressiveAVs) {
                    Write-Host "    ⚠️ Hinweis: Dieses AV kann aggressive False-Positives erzeugen" -ForegroundColor Yellow
                }
            } else {
                $installedAV = $antivirusInfo.ThirdPartyAV[0].Name
                Write-Host "⚠️ $installedAV installiert, aber inaktiv" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Kein Antiviren-Schutz erkannt!" -ForegroundColor Red
            Write-Host "    💡 Empfehlung: Windows Defender aktivieren oder AV installieren" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # 12. Performance Profiling & Resource Monitoring
        Write-Host ""
        Write-Host "⚡ PERFORMANCE & RESOURCE MONITORING" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray
        
        $resourceProfile = @{
            CPU = @{ Usage = 0; Cores = 0; Architecture = "" }
            Memory = @{ TotalGB = 0; AvailableGB = 0; UsagePercent = 0 }
            Disk = @{ SystemDrive = ""; FreeSpaceGB = 0; UsagePercent = 0 }
            Network = @{ Connected = $false; Speed = 0 }
            PowerShell = @{ LoadTime = 0; ModuleCount = 0 }
        }
        
        # CPU-Informationen
        try {
            $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
            if ($cpuInfo) {
                $resourceProfile.CPU.Cores = $cpuInfo.NumberOfCores
                $resourceProfile.CPU.Architecture = $cpuInfo.Architecture
                
                # CPU-Usage über Performance Counter (robustere Methode mit Lokalisierung)
                try {
                    # Versuche verschiedene Counter-Namen (EN/DE)
                    $cpuCounters = @(
                        "\Processor(_Total)\% Processor Time",  # Englisch
                        "\Prozessor(_Total)\Prozessorzeit (%)"  # Deutsch
                    )
                    
                    $cpuUsage = $null
                    foreach ($counterPath in $cpuCounters) {
                        try {
                            # Erste Messung
                            $cpu1 = Get-Counter $counterPath -ErrorAction SilentlyContinue
                            if ($cpu1) {
                                Start-Sleep -Milliseconds 500
                                # Zweite Messung nach kurzer Pause
                                $cpu2 = Get-Counter $counterPath -ErrorAction SilentlyContinue
                                
                                if ($cpu2 -and $cpu2.CounterSamples) {
                                    $cpuUsage = [math]::Round($cpu2.CounterSamples[0].CookedValue, 1)
                                    break
                                }
                            }
                        } catch {
                            continue  # Versuche nächsten Counter
                        }
                    }
                    
                    if ($cpuUsage) {
                        $resourceProfile.CPU.Usage = $cpuUsage
                    } else {
                        throw "Performance Counter nicht verfügbar"
                    }
                } catch {
                    # Fallback: WMI-basierte CPU-Last (langsamer aber zuverlässiger)
                    try {
                        $cpuLoad = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
                        if ($cpuLoad.Average) {
                            $resourceProfile.CPU.Usage = [math]::Round($cpuLoad.Average, 1)
                        }
                    } catch {
                        # Letzter Fallback: Geschätzte CPU-Last über Prozesse
                        $processes = Get-Process | Where-Object { $_.CPU -gt 0 } | Sort-Object CPU -Descending | Select-Object -First 10
                        if ($processes) {
                            $estimatedUsage = ($processes | Measure-Object CPU -Sum).Sum / $resourceProfile.CPU.Cores / 10
                            $resourceProfile.CPU.Usage = [math]::Min([math]::Round($estimatedUsage, 1), 100)
                        }
                    }
                }
            }
            
            Write-Host "🔹 CPU: " -ForegroundColor White -NoNewline
            if ($resourceProfile.CPU.Cores -gt 0) {
                $cpuColor = if ($resourceProfile.CPU.Usage -lt 80) { "Green" } elseif ($resourceProfile.CPU.Usage -lt 95) { "Yellow" } else { "Red" }
                Write-Host "$($resourceProfile.CPU.Cores) Kerne " -ForegroundColor Green -NoNewline
                Write-Host "($($resourceProfile.CPU.Usage)% Last)" -ForegroundColor $cpuColor
            } else {
                Write-Host "⚠️ Info nicht verfügbar" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "🔹 CPU: ❌ Fehler beim Abrufen der CPU-Informationen" -ForegroundColor Red
            $validationWarnings++
        }
        
        # Memory-Informationen
        try {
            $memInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
            $memAvailable = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
            
            if ($memInfo -and $memAvailable) {
                $resourceProfile.Memory.TotalGB = [math]::Round($memInfo.TotalPhysicalMemory / 1GB, 1)
                $resourceProfile.Memory.AvailableGB = [math]::Round($memAvailable.FreePhysicalMemory * 1KB / 1GB, 1)
                $resourceProfile.Memory.UsagePercent = [math]::Round(($resourceProfile.Memory.TotalGB - $resourceProfile.Memory.AvailableGB) / $resourceProfile.Memory.TotalGB * 100, 1)
            }
            
            Write-Host "🔹 Arbeitsspeicher: " -ForegroundColor White -NoNewline
            if ($resourceProfile.Memory.TotalGB -gt 0) {
                $memColor = if ($resourceProfile.Memory.UsagePercent -lt 80) { "Green" } elseif ($resourceProfile.Memory.UsagePercent -lt 95) { "Yellow" } else { "Red" }
                Write-Host "$($resourceProfile.Memory.TotalGB) GB Total " -ForegroundColor Green -NoNewline
                Write-Host "($($resourceProfile.Memory.AvailableGB) GB frei, $($resourceProfile.Memory.UsagePercent)% genutzt)" -ForegroundColor $memColor
                
                # Low-Memory Warnung
                if ($resourceProfile.Memory.AvailableGB -lt 1) {
                    Write-Host "    ⚠️ Warnung: Wenig verfügbarer Speicher - Tool kann langsamer laufen" -ForegroundColor Red
                    $validationWarnings++
                } elseif ($resourceProfile.Memory.TotalGB -lt 4) {
                    Write-Host "    💡 Hinweis: System-Upgrade auf min. 8GB RAM empfohlen" -ForegroundColor Yellow
                }
            } else {
                Write-Host "⚠️ Info nicht verfügbar" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "🔹 Arbeitsspeicher: ❌ Fehler beim Abrufen der Memory-Informationen" -ForegroundColor Red
            $validationWarnings++
        }
        
        # Disk-Informationen
        try {
            $systemDrive = $env:SystemDrive
            $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue
            
            if ($diskInfo) {
                $resourceProfile.Disk.SystemDrive = $systemDrive
                $resourceProfile.Disk.FreeSpaceGB = [math]::Round($diskInfo.FreeSpace / 1GB, 1)
                $totalSpaceGB = [math]::Round($diskInfo.Size / 1GB, 1)
                $resourceProfile.Disk.UsagePercent = [math]::Round(($totalSpaceGB - $resourceProfile.Disk.FreeSpaceGB) / $totalSpaceGB * 100, 1)
            }
            
            Write-Host "🔹 Festplatte ($systemDrive): " -ForegroundColor White -NoNewline
            if ($resourceProfile.Disk.FreeSpaceGB -gt 0) {
                $diskColor = if ($resourceProfile.Disk.FreeSpaceGB -gt 10) { "Green" } elseif ($resourceProfile.Disk.FreeSpaceGB -gt 2) { "Yellow" } else { "Red" }
                Write-Host "$($resourceProfile.Disk.FreeSpaceGB) GB frei " -ForegroundColor $diskColor -NoNewline
                Write-Host "($($resourceProfile.Disk.UsagePercent)% belegt)" -ForegroundColor $diskColor
                
                # Low-Disk-Space Warnung
                if ($resourceProfile.Disk.FreeSpaceGB -lt 2) {
                    Write-Host "    🚨 KRITISCH: Wenig Festplattenspeicher - Tool könnte fehlschlagen!" -ForegroundColor Red
                    $validationErrors++
                } elseif ($resourceProfile.Disk.FreeSpaceGB -lt 5) {
                    Write-Host "    ⚠️ Warnung: Wenig Festplattenspeicher - Cleanup empfohlen" -ForegroundColor Yellow
                    $validationWarnings++
                }
            } else {
                Write-Host "⚠️ Info nicht verfügbar" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "🔹 Festplatte: ❌ Fehler beim Abrufen der Disk-Informationen" -ForegroundColor Red
            $validationWarnings++
        }
        
        # PowerShell Performance Metrics
        try {
            $moduleCount = (Get-Module).Count
            $loadedSnapins = if (Get-Command Get-PSSnapin -ErrorAction SilentlyContinue) { (Get-PSSnapin -ErrorAction SilentlyContinue).Count } else { 0 }
            
            # PowerShell-Version und Performance-Info
            $psVersion = $PSVersionTable.PSVersion
            $hostInfo = Get-Host
            
            # Speicher-Usage von PowerShell-Prozess
            $psProcess = Get-Process -Id $PID -ErrorAction SilentlyContinue
            $psMemoryMB = if ($psProcess) { [math]::Round($psProcess.WorkingSet64 / 1MB, 1) } else { 0 }
            
            # Ausführungszeit-Test (einfacher Performance-Test)
            $perfTestStart = Get-Date
            1..1000 | ForEach-Object { $_ * 2 } | Out-Null
            $perfTestEnd = Get-Date
            $perfTestTime = [math]::Round(($perfTestEnd - $perfTestStart).TotalMilliseconds, 0)
            
            Write-Host "🔹 PowerShell Performance: " -ForegroundColor White -NoNewline
            Write-Host "v$($psVersion.Major).$($psVersion.Minor) " -ForegroundColor Green -NoNewline
            Write-Host "($moduleCount Module" -ForegroundColor Gray -NoNewline
            if ($loadedSnapins -gt 0) {
                Write-Host ", $loadedSnapins Snapins" -ForegroundColor Gray -NoNewline
            }
            Write-Host ")" -ForegroundColor Gray
            
            # Performance-Details
            Write-Host "    📊 Arbeitsspeicher: " -ForegroundColor DarkGray -NoNewline
            Write-Host "$psMemoryMB MB " -ForegroundColor Gray -NoNewline
            Write-Host "│ Performance-Test: " -ForegroundColor DarkGray -NoNewline
            
            $perfColor = if ($perfTestTime -lt 50) { "Green" } elseif ($perfTestTime -lt 150) { "Yellow" } else { "Red" }
            Write-Host "${perfTestTime}ms" -ForegroundColor $perfColor
            
            # Performance-Warnungen
            if ($moduleCount -gt 50) {
                Write-Host "    💡 Hinweis: Viele Module geladen ($moduleCount) - könnte Performance beeinträchtigen" -ForegroundColor Yellow
            }
            if ($psMemoryMB -gt 500) {
                Write-Host "    💡 Hinweis: Hoher Speicherverbrauch (${psMemoryMB}MB) - Session-Neustart erwägen" -ForegroundColor Yellow
            }
            if ($perfTestTime -gt 100) {
                Write-Host "    ⚠️ Warnung: Langsame PowerShell-Performance (${perfTestTime}ms) - System überlastet?" -ForegroundColor Yellow
            }
            
            # Temp-Verzeichnis Check
            $tempDir = $env:TEMP
            $tempSpace = 0
            if (Test-Path $tempDir) {
                try {
                    $tempItems = Get-ChildItem $tempDir -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
                    if ($tempItems.Sum) {
                        $tempSpace = [math]::Round($tempItems.Sum / 1MB, 1)
                    }
                } catch {
                    # Temp-Größe nicht ermittelbar
                }
            }
            
            Write-Host "🔹 Temp-Verzeichnis: " -ForegroundColor White -NoNewline
            if ($tempSpace -gt 0) {
                $tempColor = if ($tempSpace -lt 500) { "Green" } elseif ($tempSpace -lt 2000) { "Yellow" } else { "Red" }
                Write-Host "$tempSpace MB belegt" -ForegroundColor $tempColor
                if ($tempSpace -gt 1000) {
                    Write-Host "    💡 Hinweis: Temp-Bereinigung könnte Performance verbessern" -ForegroundColor Yellow
                }
            } else {
                Write-Host "✅ Verfügbar ($tempDir)" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "🔹 PowerShell: ❌ Performance-Analyse fehlgeschlagen" -ForegroundColor Red
            if ($script:DebugLevel -ge 1) {
                Write-Host "    🔍 Fehlerdetails: $($_.Exception.Message)" -ForegroundColor DarkRed
            }
            $validationWarnings++
        }
        
        # Critical System Dependencies
        $criticalCmdlets = @('Get-WmiObject', 'Get-CimInstance', 'Start-Job', 'Invoke-WebRequest')
        $missingCmdlets = @()
        foreach ($cmdlet in $criticalCmdlets) {
            if (-not (Get-Command $cmdlet -ErrorAction SilentlyContinue)) {
                $missingCmdlets += $cmdlet
            }
        }
        
        Write-Host "🔹 System-Cmdlets: " -ForegroundColor White -NoNewline
        if ($missingCmdlets.Count -eq 0) {
            Write-Host "✅ Alle verfügbar" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Fehlend: $($missingCmdlets -join ', ')" -ForegroundColor Red
            $validationErrors++
        }
        
        # 13. Network Connectivity Pre-checks
        Write-Host ""
        Write-Host "🌐 NETZWERK-KONNEKTIVITÄT" -ForegroundColor Cyan
        Write-Host "──────────────────────────" -ForegroundColor DarkGray
        
        $networkProfile = @{
            LocalConnectivity = $false
            InternetConnectivity = $false
            DNSResolution = $false
            DownloadSpeed = 0
            PublicDNS = @()
        }
        
        # 1. Lokale Netzwerk-Konnektivität
        try {
            $localNetwork = Test-NetConnection -ComputerName "127.0.0.1" -Port 80 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null; $localNetwork = $?
            $networkProfile.LocalConnectivity = $localNetwork
            
            Write-Host "🔹 Lokale Konnektivität: " -ForegroundColor White -NoNewline
            if ($localNetwork) {
                Write-Host "✅ Verfügbar" -ForegroundColor Green
            } else {
                Write-Host "❌ Nicht verfügbar" -ForegroundColor Red
                $validationWarnings++
            }
        } catch {
            Write-Host "🔹 Lokale Konnektivität: ⚠️ Test fehlgeschlagen" -ForegroundColor Yellow
        }
        
        # 2. Internet-Konnektivität (schneller Test)
        $internetHosts = @(
            @{Name="Google DNS"; Host="8.8.8.8"; Port=53},
            @{Name="Cloudflare DNS"; Host="1.1.1.1"; Port=53},
            @{Name="Microsoft"; Host="outlook.com"; Port=443}
        )
        
        $connectedHosts = @()
        foreach ($testHost in $internetHosts) {
            try {
                $connection = Test-NetConnection -ComputerName $testHost.Host -Port $testHost.Port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null; $connection = $?
                if ($connection) {
                    $connectedHosts += $testHost.Name
                }
            } catch {
                # Verbindung fehlgeschlagen
            }
        }
        
        Write-Host "🔹 Internet-Konnektivität: " -ForegroundColor White -NoNewline
        if ($connectedHosts.Count -gt 0) {
            $networkProfile.InternetConnectivity = $true
            Write-Host "✅ $($connectedHosts.Count)/$($internetHosts.Count) Hosts erreichbar" -ForegroundColor Green
            if ($connectedHosts.Count -lt $internetHosts.Count) {
                Write-Host "    📋 Erreichbar: $($connectedHosts -join ', ')" -ForegroundColor Gray
            }
        } else {
            Write-Host "❌ Keine Internet-Verbindung" -ForegroundColor Red
            Write-Host "    💡 Warnung: Update-Check und Download-Features nicht verfügbar" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # 3. DNS-Resolution Test
        $dnsTests = @("github.com", "microsoft.com", "google.com")
        $resolvedHosts = @()
        
        foreach ($dnsHost in $dnsTests) {
            try {
                $dnsResult = Resolve-DnsName -Name $dnsHost -Type A -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if ($dnsResult) {
                    $resolvedHosts += $dnsHost
                }
            } catch {
                # DNS-Resolution fehlgeschlagen
            }
        }
        
        Write-Host "🔹 DNS-Resolution: " -ForegroundColor White -NoNewline
        if ($resolvedHosts.Count -gt 0) {
            $networkProfile.DNSResolution = $true
            Write-Host "✅ $($resolvedHosts.Count)/$($dnsTests.Count) Domains aufgelöst" -ForegroundColor Green
        } else {
            Write-Host "❌ DNS-Problems erkannt" -ForegroundColor Red
            Write-Host "    💡 Empfehlung: DNS-Settings prüfen (8.8.8.8, 1.1.1.1)" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # 4. Download-Performance Test (nur bei Internet-Verbindung)
        if ($networkProfile.InternetConnectivity) {
            Write-Host "🔹 Download-Performance: " -ForegroundColor White -NoNewline
            try {
                # Kleinen Test-Download für Performance-Messung (GitHub API - schnell)
                $testUrl = "https://api.github.com/zen"
                $startTime = Get-Date
                $testContent = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
                $endTime = Get-Date
                $downloadTime = ($endTime - $startTime).TotalMilliseconds
                
                if ($testContent -and $downloadTime -gt 0) {
                    $downloadColor = if ($downloadTime -lt 1000) { "Green" } elseif ($downloadTime -lt 3000) { "Yellow" } else { "Red" }
                    Write-Host "✅ ${downloadTime}ms Response-Zeit" -ForegroundColor $downloadColor
                    
                    if ($downloadTime -gt 5000) {
                        Write-Host "    ⚠️ Warnung: Langsame Internetverbindung - Updates könnten Zeit brauchen" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "❌ Test fehlgeschlagen" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Nicht testbar ($($_.Exception.Message -replace '^[^:]+: ',''))" -ForegroundColor Red
            }
        }
        
        # 5. Public DNS Server Check
        $publicDNS = @("8.8.8.8", "1.1.1.1", "9.9.9.9")
        $workingDNS = @()
        
        foreach ($dnsServer in $publicDNS) {
            try {
                $dnsTest = Test-NetConnection -ComputerName $dnsServer -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null; $dnsTest = $?
                if ($dnsTest) {
                    $workingDNS += $dnsServer
                }
            } catch {
                # DNS Server nicht erreichbar
            }
        }
        
        Write-Host "🔹 Public DNS Server: " -ForegroundColor White -NoNewline
        if ($workingDNS.Count -gt 0) {
            Write-Host "✅ $($workingDNS.Count) verfügbar " -ForegroundColor Green -NoNewline
            Write-Host "($($workingDNS -join ', '))" -ForegroundColor Gray
            $networkProfile.PublicDNS = $workingDNS
        } else {
            Write-Host "❌ Keine erreichbar" -ForegroundColor Red
            Write-Host "    💡 Empfehlung: Netzwerk-/Firewall-Einstellungen prüfen" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # 6. Firewall/Proxy Detection
        Write-Host "🔹 Netzwerk-Restriktionen: " -ForegroundColor White -NoNewline
        
        # Simple Firewall/Proxy Detection durch Port-Tests
        $restrictedPorts = @()
        $testPorts = @(80, 443, 53)
        foreach ($port in $testPorts) {
            try {
                $portTest = Test-NetConnection -ComputerName "8.8.8.8" -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null; $portTest = $?
                if (-not $portTest) {
                    $restrictedPorts += $port
                }
            } catch {
                $restrictedPorts += $port
            }
        }
        
        if ($restrictedPorts.Count -eq 0) {
            Write-Host "✅ Keine erkannt" -ForegroundColor Green
        } elseif ($restrictedPorts.Count -lt 2) {
            Write-Host "⚠️ Moderate Einschränkungen " -ForegroundColor Yellow -NoNewline
            Write-Host "(Port $($restrictedPorts -join ', ') blockiert)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Starke Restriktionen " -ForegroundColor Red -NoNewline
            Write-Host "(Ports $($restrictedPorts -join ', ') blockiert)" -ForegroundColor Gray
            Write-Host "    💡 Hinweis: Corporate Firewall oder Proxy aktiv" -ForegroundColor Yellow
            $validationWarnings++
        }
        
        # Disk Space Check für Temp-Verzeichnis
        try {
            $tempDrive = (Get-Item $env:TEMP).PSDrive
            $freeSpaceGB = [math]::Round($tempDrive.Free / 1GB, 2)
            Write-Host "🔹 Temp-Speicher: " -ForegroundColor White -NoNewline
            if ($freeSpaceGB -gt 5) {
                Write-Host "${freeSpaceGB} GB ✅" -ForegroundColor Green
            } elseif ($freeSpaceGB -gt 1) {
                Write-Host "${freeSpaceGB} GB ⚠️ Knapp" -ForegroundColor Yellow
            } else {
                Write-Host "${freeSpaceGB} GB ❌ Kritisch" -ForegroundColor Red
                $validationWarnings++
            }
        } catch {
            Write-Host "🔹 Temp-Speicher: " -ForegroundColor White -NoNewline
            Write-Host "⚠️ Status unbekannt" -ForegroundColor Yellow
        }
    }
    
    Write-Information "" -InformationAction Continue
    Write-Information "[DEBUG] Module validation completed. Errors: $validationErrors, Warnings: $validationWarnings" -InformationAction Continue
    Write-Host "Falls Fehler oder Warnungen angezeigt wurden, können Sie diese jetzt analysieren." -ForegroundColor Yellow
    Read-Host "Drücken Sie Enter um fortzufahren zum Hauptmenü"
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
        
        # SYSTEM-REPARATUR (SFC + DISM + CheckDisk)
        '1' {
            Write-Host ""
            Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "           🛠️ SYSTEM-REPARATUR TOOLS" -ForegroundColor White
            Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Wählen Sie das gewünschte Reparatur-Tool" -ForegroundColor Yellow
            Write-Host ""
            
            Write-Host "🛠️ REPARATUR-OPTIONEN:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "   [1] " -ForegroundColor White -NoNewline
            Write-Host "SFC-Scan " -ForegroundColor Green -NoNewline
            Write-Host "(System File Checker)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "   [2] " -ForegroundColor White -NoNewline
            Write-Host "CheckDisk " -ForegroundColor Yellow -NoNewline
            Write-Host "(Dateisystem-Prüfung)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "   [3] " -ForegroundColor White -NoNewline
            Write-Host "DISM-Reparatur " -ForegroundColor Magenta -NoNewline
            Write-Host "(Image-Wiederherstellung)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "   [4] " -ForegroundColor White -NoNewline
            Write-Host "Alle nacheinander " -ForegroundColor Red -NoNewline
            Write-Host "(SFC → CheckDisk → DISM)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "   [x] " -ForegroundColor White -NoNewline
            Write-Host "Zurück zum Hauptmenü" -ForegroundColor Red
            Write-Host ""
            
            $repairChoice = Read-Host "Wahl [1-4/x]"
            
            switch ($repairChoice.ToLower()) {
                '1' {
                    # SFC-Scan
                    . "$PSScriptRoot\modules\sfc-simple.ps1"
                    if (Get-Command Invoke-SimpleSFC -ErrorAction SilentlyContinue) {
                        $null = Invoke-SimpleSFC
                    } else {
                        Write-Error "ERROR: SFC-Modul nicht gefunden." -ErrorAction Continue
                    }
                }
                '2' {
                    # CheckDisk
                    . "$PSScriptRoot\modules\disk-maintenance.ps1"
                    if (Get-Command Invoke-CheckDisk -ErrorAction SilentlyContinue) {
                        $null = Invoke-CheckDisk
                    } else {
                        Write-Error "ERROR: CheckDisk-Modul nicht gefunden." -ErrorAction Continue
                    }
                }
                '3' {
                    # DISM-Reparatur
                    . "$PSScriptRoot\modules\disk-maintenance.ps1"
                    if (Get-Command Invoke-DISMRepair -ErrorAction SilentlyContinue) {
                        $null = Invoke-DISMRepair
                    } else {
                        Write-Host ""
                        Write-Host "⚠️ DISM-Automatik nicht verfügbar" -ForegroundColor Yellow
                        Write-Host "💡 Führen Sie manuell aus:" -ForegroundColor Cyan
                        Write-Host "   dism /online /cleanup-image /restorehealth" -ForegroundColor Gray
                        Write-Host ""
                    }
                }
                '4' {
                    # Alle nacheinander
                    Write-Host ""
                    Write-Host "🔄 VOLLSTÄNDIGE SYSTEM-REPARATUR" -ForegroundColor Cyan
                    Write-Host "Führt alle Tools in optimaler Reihenfolge aus" -ForegroundColor Yellow
                    Write-Host ""
                    
                    $overallSuccess = $true
                    
                    # 1. SFC-Scan
                    Write-Host "🔧 SCHRITT 1/3: SFC-SCAN" -ForegroundColor Cyan
                    . "$PSScriptRoot\modules\sfc-simple.ps1"
                    if (Get-Command Invoke-SimpleSFC -ErrorAction SilentlyContinue) {
                        $sfcResult = Invoke-SimpleSFC
                        if (-not $sfcResult) { $overallSuccess = $false }
                    }
                    
                    Start-Sleep -Seconds 2
                    
                    # 2. CheckDisk
                    Write-Host ""
                    Write-Host "🔧 SCHRITT 2/3: CHECKDISK" -ForegroundColor Cyan
                    . "$PSScriptRoot\modules\disk-maintenance.ps1"
                    if (Get-Command Invoke-CheckDisk -ErrorAction SilentlyContinue) {
                        $chkResult = Invoke-CheckDisk
                        if (-not $chkResult) { $overallSuccess = $false }
                    }
                    
                    Start-Sleep -Seconds 2
                    
                    # 3. DISM
                    Write-Host ""
                    Write-Host "🔧 SCHRITT 3/3: DISM" -ForegroundColor Cyan
                    if (Get-Command Invoke-DISMRepair -ErrorAction SilentlyContinue) {
                        $dismResult = Invoke-DISMRepair
                        if (-not $dismResult) { $overallSuccess = $false }
                    } else {
                        Write-Host "⚠️ DISM-Tool nicht verfügbar" -ForegroundColor Yellow
                    }
                    
                    # Gesamtergebnis
                    Write-Host ""
                    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
                    if ($overallSuccess) {
                        Write-Host "✅ Vollständige System-Reparatur abgeschlossen!" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️ System-Reparatur mit Problemen abgeschlossen" -ForegroundColor Yellow
                    }
                    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
                }
                'x' {
                    Write-Host "↩️ Zurück zum Hauptmenü" -ForegroundColor Gray
                    break
                }
                default {
                    Write-Host "❌ Ungültige Auswahl: $repairChoice" -ForegroundColor Red
                }
            }
            
            if ($repairChoice -ne 'x') {
                Write-Information "`nPress Enter to continue..." -InformationAction Continue
                Read-Host
            }
        }
        '2' {
            # Performance-Boost (Bereinigung + Optimierung)
            if (Get-Command Invoke-ComprehensiveCleanup -ErrorAction SilentlyContinue) {
                Invoke-ComprehensiveCleanup
                if (Get-Command Optimize-SystemPerformance -ErrorAction SilentlyContinue) {
                    Optimize-SystemPerformance
                }
            } else {
                Write-Error "ERROR: Performance-Boost functions not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '3' {
            # System-Information (Hardware + Software Überblick)
            if (Get-Command Get-DetailedSystemInfo -ErrorAction SilentlyContinue) {
                Get-DetailedSystemInfo
                if (Get-Command Get-EnhancedDriveInfo -ErrorAction SilentlyContinue) {
                    Get-EnhancedDriveInfo
                }
            } else {
                Write-Error "ERROR: System-Information functions not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '4' {
            # Netzwerk-Test (Internet + DNS + Speed)
            if (Get-Command Test-EnhancedInternetConnectivity -ErrorAction SilentlyContinue) {
                $null = Test-EnhancedInternetConnectivity
            } else {
                Write-Error "ERROR: Netzwerk-Test function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '5' {
            # Treiber-Diagnose (ENE.SYS + Hardware-Probleme)
            if (Get-Command Start-DriverDiagnostic -ErrorAction SilentlyContinue) {
                Start-DriverDiagnostic
            } else {
                Write-Error "ERROR: Treiber-Diagnose function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '6' {
            # Bluescreen-Analyse (Crash-Logs + Ursachen)
            if (Get-Command Get-SystemCrashAnalysis -ErrorAction SilentlyContinue) {
                Get-SystemCrashAnalysis
            } else {
                Write-Error "ERROR: Bluescreen-Analyse function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '7' {
            # RAM-Test (Memory Diagnostic)
            if (Get-Command Start-WindowsMemoryDiagnostic -ErrorAction SilentlyContinue) {
                Start-WindowsMemoryDiagnostic
            } else {
                Write-Error "ERROR: RAM-Test function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '8' {
            # Wiederherstellungspunkte verwalten
            try {
                # Lade das System-Restore Modul
                . "$PSScriptRoot\modules\system-restore.ps1"
                
                # Starte Wiederherstellungspunkt-Verwaltung
                Invoke-RestorePointManager
                
            } catch {
                Write-Information "`n[ERROR] Wiederherstellungspunkt-Verwaltung fehlgeschlagen!" -InformationAction Continue
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
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '10' {
            if (Get-Command Test-EnhancedInternetConnectivity -ErrorAction SilentlyContinue) {
                $null = Test-EnhancedInternetConnectivity
            } else {
                Write-Error "ERROR: Network Test function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        '11' {
            # Load driver diagnostic module
            . "$PSScriptRoot\modules\driver-diagnostic.ps1"
            
            if (Get-Command Start-DriverDiagnostic -ErrorAction SilentlyContinue) {
                Start-DriverDiagnostic
            } else {
                Write-Error "ERROR: Driver Diagnostic module not found." -ErrorAction Continue
                Write-Information "Bitte stelle sicher dass modules/driver-diagnostic.ps1 geladen ist." -InformationAction Continue
            }
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
        'E' {
            # System-Bericht erstellen (Detaillierte Analyse)
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
        'S' {
            # Safe Adblock verwalten (Werbeblocker-Tools)
            if (Get-Command Invoke-SafeAdblock -ErrorAction SilentlyContinue) {
                Invoke-SafeAdblock
            } else {
                Write-Error "ERROR: Safe Adblock function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        'D' {
            # DLL-Integritäts-Check (System-Dateien prüfen)
            if (Get-Command Test-DLLIntegrity -ErrorAction SilentlyContinue) {
                Test-DLLIntegrity
            } else {
                Write-Error "ERROR: DLL Integrity function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
        }
        'R' {
            # Netzwerk zurücksetzen (Bei Internet-Problemen)
            if (Get-Command Reset-NetworkConfiguration -ErrorAction SilentlyContinue) {
                Reset-NetworkConfiguration
            } else {
                Write-Error "ERROR: Network Reset function not found." -ErrorAction Continue
            }
            Write-Information "`nPress Enter to continue..." -InformationAction Continue
            Read-Host
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


