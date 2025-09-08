# ===================================================================
# DEV-MODE LAUNCHER - PowerShell 7 Compatible
# Hellion Power Tool - Modular Version
# Quick launcher for development and testing
# ===================================================================

param(
    [switch]$DevMode,
    [switch]$DebugMode,
    [switch]$SkipAutoMode,
    [int]$ForceDebugLevel = -1
)

# PowerShell Version Check
$psVersion = $PSVersionTable.PSVersion.Major
Write-Information "[INFO] ================================================================" -InformationAction Continue
Write-Information "[INFO]               HELLION POWER TOOL - DEV LAUNCHER               " -InformationAction Continue  
Write-Information "[INFO] ================================================================" -InformationAction Continue
Write-Information "[INFO] PowerShell Version: $($PSVersionTable.PSVersion)" -InformationAction Continue
Write-Information "[INFO] Execution Policy: $(Get-ExecutionPolicy)" -InformationAction Continue
Write-Information "[INFO] " -InformationAction Continue

# Admin Rights Check
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Keine Administrator-Rechte erkannt!"
    Write-Information "[INFO] Einige Funktionen werden moeglicherweise nicht funktionieren." -InformationAction Continue
    
    $elevate = Read-Host "`nMit Admin-Rechten neu starten? [j/n]"
    if ($elevate -eq 'j' -or $elevate -eq 'J') {
        if ($psVersion -ge 7) {
            # PowerShell 7
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            Start-Process pwsh -ArgumentList $arguments -Verb RunAs
        } else {
            # Windows PowerShell
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            Start-Process powershell -ArgumentList $arguments -Verb RunAs
        }
        exit
    }
    
    Write-Information "[INFO] `n[INFO] Fortfahren ohne Admin-Rechte..." -InformationAction Continue
} else {
    Write-Information "[OK] Administrator-Rechte verfuegbar" -InformationAction Continue
}

# Script Path Detection
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptRoot "hellion_tool_main.ps1"
$modulesPath = Join-Path $scriptRoot "modules"

Write-Information "[INFO] `n[*] DEV-LAUNCHER KONFIGURATION:" -InformationAction Continue
Write-Information "[INFO] Script Root: $scriptRoot" -InformationAction Continue
Write-Information "[INFO] Main Script: $mainScript" -InformationAction Continue
Write-Information "[INFO] Modules Path: $modulesPath" -InformationAction Continue

# File Checks
$checks = @()
$checks += [PSCustomObject]@{ Name = "Main Script"; Path = $mainScript; Exists = (Test-Path $mainScript) }
$checks += [PSCustomObject]@{ Name = "Modules Directory"; Path = $modulesPath; Exists = (Test-Path $modulesPath) }

if (Test-Path $modulesPath) {
    $moduleFiles = Get-ChildItem "$modulesPath\*.ps1" -ErrorAction SilentlyContinue
    $checks += [PSCustomObject]@{ Name = "Module Files"; Path = "$($moduleFiles.Count) files"; Exists = ($moduleFiles.Count -gt 0) }
}

Write-Information "[INFO] `n[*] FILE CHECKS:" -InformationAction Continue
foreach ($check in $checks) {
    $status = if ($check.Exists) { "[OK]" } else { "[MISSING]" }
    $color = if ($check.Exists) { "Green" } else { "Red" }
    Write-Information "[INFO]   $status $($check.Name): $($check.Path)" -InformationAction Continue
}

# Error if main script missing
if (-not (Test-Path $mainScript)) {
    Write-Error "`n[ERROR] Main script not found!"
    Write-Information "[INFO] Expected: $mainScript" -InformationAction Continue
    Read-Host "`nPress Enter to exit"
    exit 1
}

# Debug Mode Selection (if not forced)
if ($ForceDebugLevel -ge 0) {
    $selectedDebugMode = $ForceDebugLevel
    Write-Information "[INFO] `n[INFO] Debug-Level forced to: $selectedDebugMode" -InformationAction Continue
} elseif ($DevMode) {
    $selectedDebugMode = 2
    Write-Information "[INFO] `n[DEV] Developer-Mode activated (Debug Level 2)" -InformationAction Continue
} elseif ($DebugMode) {
    $selectedDebugMode = 1
    Write-Information "[INFO] `n[DEBUG] Debug-Mode activated (Debug Level 1)" -InformationAction Continue
} else {
    # Default to DevMode if this is the dev launcher script
    if ($MyInvocation.MyCommand.Name -eq "launch-dev.ps1") {
        $selectedDebugMode = 2
        Write-Information "[INFO] `n[DEV] Auto-DevMode activated (launch-dev.ps1 detected)" -InformationAction Continue
    } else {
        Write-Information "[INFO] `n[*] DEBUG-MODUS WAEHLEN:" -InformationAction Continue
        Write-Information "[INFO]   [0] Normal-Modus (Standard)" -InformationAction Continue
        Write-Information "[INFO]   [1] Debug-Modus (Erweiterte Infos)" -InformationAction Continue  
        Write-Information "[INFO]   [2] Developer-Modus (Alle Debug-Infos)" -InformationAction Continue
        Write-Information "[INFO] " -InformationAction Continue
        
        do {
            $debugInput = Read-Host "Debug-Level [0-2]"
            $selectedDebugMode = [int]$debugInput
        } while ($selectedDebugMode -lt 0 -or $selectedDebugMode -gt 2)
    }
}

$debugModeText = switch ($selectedDebugMode) {
    0 { "Normal-Modus" }
    1 { "Debug-Modus" }  
    2 { "Developer-Modus"  }
    default { "Unknown" }
}

Write-Information "[INFO] `n[*] LAUNCHER KONFIGURATION:" -InformationAction Continue
Write-Information "[INFO] Debug-Level: $selectedDebugMode ($debugModeText)" -InformationAction Continue
Write-Information "[INFO] Skip Auto-Mode: $($SkipAutoMode.IsPresent)" -InformationAction Continue
Write-Information "[INFO] PowerShell: $($PSVersionTable.PSVersion)" -InformationAction Continue
Write-Information "[INFO] " -InformationAction Continue

# Environment Setup
Write-Information "[INFO] [*] Setting up environment..." -InformationAction Continue

# Set execution policy for current process
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Information "[OK] Execution Policy set to Bypass for current process" -InformationAction Continue
} catch {
    Write-Warning "Could not set execution policy: $($_.Exception.Message)"
}

# Launch confirmation
Write-Information "[INFO] `n[*] READY TO LAUNCH:" -InformationAction Continue
Write-Information "[INFO] Target: Hellion Power Tool (Modular)" -InformationAction Continue
Write-Information "[INFO] Mode: $debugModeText" -InformationAction Continue

if (-not $SkipAutoMode) {
    $launch = Read-Host "`nTool starten? [j/n]"
    if ($launch -ne 'j' -and $launch -ne 'J') {
        Write-Information "[INFO] Launch abgebrochen." -InformationAction Continue
        exit 0
    }
}

Write-Information "[INFO] `n[*] Launching Hellion Power Tool..." -InformationAction Continue
Write-Information "[INFO] ================================================================" -InformationAction Continue

# Set global variables that the main script expects
$global:LauncherDebugMode = $selectedDebugMode
$global:LauncherSkipAutoMode = $SkipAutoMode.IsPresent

try {
    # Execute main script
    & $mainScript
    
    Write-Information "[INFO] `n================================================================" -InformationAction Continue
    Write-Information "[INFO] [*] Tool execution completed." -InformationAction Continue
    
} catch {
    Write-Information "[INFO] `n================================================================" -InformationAction Continue
    Write-Error "Tool execution failed!"
    Write-Error "Error: $($_.Exception.Message)"
    Write-Information "[INFO] Line: $($_.InvocationInfo.ScriptLineNumber)" -InformationAction Continue
    
    if ($selectedDebugMode -ge 1) {
        Write-Information "[INFO] `n[DEBUG] Full Error Details:" -InformationAction Continue
        Write-Information "[DEBUG] $($_.Exception.ToString())" -InformationAction Continue
        Write-Information "[INFO] `n[DEBUG] Stack Trace:" -InformationAction Continue
        Write-Information "[DEBUG] $($_.ScriptStackTrace)" -InformationAction Continue
    }
}

# Auto-close handling
if ($SkipAutoMode) {
    # Auto-close immediately in skip mode
    Write-Information "[INFO] `n[*] Launcher finished - auto-closing..." -InformationAction Continue
    Start-Sleep -Seconds 1
} else {
    # Wait for user input in manual mode
    Read-Host "`nPress Enter to exit"
}
