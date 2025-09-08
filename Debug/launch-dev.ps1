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
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "              HELLION POWER TOOL - DEV LAUNCHER               " -ForegroundColor White  
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Execution Policy: $(Get-ExecutionPolicy)" -ForegroundColor Gray
Write-Host ""

# Admin Rights Check
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[WARNING] Keine Administrator-Rechte erkannt!" -ForegroundColor Yellow
    Write-Host "Einige Funktionen werden moeglicherweise nicht funktionieren." -ForegroundColor Yellow
    
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
    
    Write-Host "`n[INFO] Fortfahren ohne Admin-Rechte..." -ForegroundColor Cyan
} else {
    Write-Host "[OK] Administrator-Rechte verfuegbar" -ForegroundColor Green
}

# Script Path Detection
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptRoot "hellion_tool_main.ps1"
$modulesPath = Join-Path $scriptRoot "modules"

Write-Host "`n[*] DEV-LAUNCHER KONFIGURATION:" -ForegroundColor Cyan
Write-Host "Script Root: $scriptRoot" -ForegroundColor Gray
Write-Host "Main Script: $mainScript" -ForegroundColor Gray
Write-Host "Modules Path: $modulesPath" -ForegroundColor Gray

# File Checks
$checks = @()
$checks += [PSCustomObject]@{ Name = "Main Script"; Path = $mainScript; Exists = (Test-Path $mainScript) }
$checks += [PSCustomObject]@{ Name = "Modules Directory"; Path = $modulesPath; Exists = (Test-Path $modulesPath) }

if (Test-Path $modulesPath) {
    $moduleFiles = Get-ChildItem "$modulesPath\*.ps1" -ErrorAction SilentlyContinue
    $checks += [PSCustomObject]@{ Name = "Module Files"; Path = "$($moduleFiles.Count) files"; Exists = ($moduleFiles.Count -gt 0) }
}

Write-Host "`n[*] FILE CHECKS:" -ForegroundColor Yellow
foreach ($check in $checks) {
    $status = if ($check.Exists) { "[OK]" } else { "[MISSING]" }
    $color = if ($check.Exists) { "Green" } else { "Red" }
    Write-Host "  $status $($check.Name): $($check.Path)" -ForegroundColor $color
}

# Error if main script missing
if (-not (Test-Path $mainScript)) {
    Write-Host "`n[ERROR] Main script not found!" -ForegroundColor Red
    Write-Host "Expected: $mainScript" -ForegroundColor Red
    Read-Host "`nPress Enter to exit"
    exit 1
}

# Debug Mode Selection (if not forced)
if ($ForceDebugLevel -ge 0) {
    $selectedDebugMode = $ForceDebugLevel
    Write-Host "`n[INFO] Debug-Level forced to: $selectedDebugMode" -ForegroundColor Cyan
} elseif ($DevMode) {
    $selectedDebugMode = 2
    Write-Host "`n[DEV] Developer-Mode activated (Debug Level 2)" -ForegroundColor Magenta
} elseif ($DebugMode) {
    $selectedDebugMode = 1
    Write-Host "`n[DEBUG] Debug-Mode activated (Debug Level 1)" -ForegroundColor Yellow
} else {
    # Default to DevMode if this is the dev launcher script
    if ($MyInvocation.MyCommand.Name -eq "launch-dev.ps1") {
        $selectedDebugMode = 2
        Write-Host "`n[DEV] Auto-DevMode activated (launch-dev.ps1 detected)" -ForegroundColor Magenta
    } else {
        Write-Host "`n[*] DEBUG-MODUS WAEHLEN:" -ForegroundColor Yellow
        Write-Host "  [0] Normal-Modus (Standard)" -ForegroundColor Green
        Write-Host "  [1] Debug-Modus (Erweiterte Infos)" -ForegroundColor Cyan  
        Write-Host "  [2] Developer-Modus (Alle Debug-Infos)" -ForegroundColor Red
        Write-Host ""
        
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

Write-Host "`n[*] LAUNCHER KONFIGURATION:" -ForegroundColor Cyan
Write-Host "Debug-Level: $selectedDebugMode ($debugModeText)" -ForegroundColor White
Write-Host "Skip Auto-Mode: $($SkipAutoMode.IsPresent)" -ForegroundColor White
Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Environment Setup
Write-Host "[*] Setting up environment..." -ForegroundColor Blue

# Set execution policy for current process
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Host "[OK] Execution Policy set to Bypass for current process" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Launch confirmation
Write-Host "`n[*] READY TO LAUNCH:" -ForegroundColor Green
Write-Host "Target: Hellion Power Tool (Modular)" -ForegroundColor White
Write-Host "Mode: $debugModeText" -ForegroundColor White

if (-not $SkipAutoMode) {
    $launch = Read-Host "`nTool starten? [j/n]"
    if ($launch -ne 'j' -and $launch -ne 'J') {
        Write-Host "Launch abgebrochen." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`n[*] Launching Hellion Power Tool..." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan

# Set global variables that the main script expects
$global:LauncherDebugMode = $selectedDebugMode
$global:LauncherSkipAutoMode = $SkipAutoMode.IsPresent

try {
    # Execute main script
    & $mainScript
    
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "[*] Tool execution completed." -ForegroundColor Green
    
} catch {
    Write-Host "`n================================================================" -ForegroundColor Red
    Write-Host "[ERROR] Tool execution failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    
    if ($selectedDebugMode -ge 1) {
        Write-Host "`n[DEBUG] Full Error Details:" -ForegroundColor Yellow
        Write-Host $_.Exception.ToString() -ForegroundColor DarkYellow
        Write-Host "`n[DEBUG] Stack Trace:" -ForegroundColor Yellow
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkYellow
    }
}

# Auto-close handling
if ($SkipAutoMode) {
    # Auto-close immediately in skip mode
    Write-Host "`n[*] Launcher finished - auto-closing..." -ForegroundColor Green
    Start-Sleep -Seconds 1
} else {
    # Wait for user input in manual mode
    Read-Host "`nPress Enter to exit"
}