@echo off
REM ===================================================================
REM DEV-MODE LAUNCHER - Batch Version  
REM Quick launcher for PowerShell 7 or Windows PowerShell
REM ===================================================================

echo ================================================================
echo              HELLION POWER TOOL - QUICK LAUNCHER
echo ================================================================
echo.

REM Check for PowerShell 7 first
where pwsh >nul 2>nul
if %ERRORLEVEL% == 0 (
    echo [INFO] PowerShell 7 detected - using pwsh
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-dev.ps1" -DevMode -SkipAutoMode
) else (
    echo [INFO] PowerShell 7 not found - using Windows PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-dev.ps1" -DevMode -SkipAutoMode
)

REM Script will auto-close when PowerShell script exits