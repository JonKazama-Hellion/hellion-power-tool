@echo off
:: DEBUG VERSION - Zeigt alle Schritte im Detail
setlocal EnableDelayedExpansion
cls

echo ================================================================
echo           HELLION LAUNCHER v6.5 - DEBUG VERSION
echo ================================================================
echo.

echo [DEBUG] Teste PowerShell-Verfuegbarkeit...
echo.

:: Test 1: PowerShell 7 (pwsh.exe)
echo [TEST 1] Suche PowerShell 7 (pwsh.exe)...
where pwsh >nul 2>&1
if !errorlevel! == 0 (
    echo   [OK] pwsh.exe gefunden im PATH
    echo   Teste Version...
    pwsh -NoProfile -Command "Write-Host 'PowerShell Core Version:' $PSVersionTable.PSVersion.ToString()"
    set "PWSH_AVAILABLE=1"
) else (
    echo   [X] pwsh.exe NICHT gefunden
    set "PWSH_AVAILABLE=0"
)

echo.

:: Test 2: Windows PowerShell (powershell.exe)
echo [TEST 2] Suche Windows PowerShell (powershell.exe)...
where powershell >nul 2>&1
if !errorlevel! == 0 (
    echo   [OK] powershell.exe gefunden im PATH
    echo   Teste Version...
    powershell -NoProfile -Command "Write-Host 'Windows PowerShell Version:' $PSVersionTable.PSVersion.ToString()"
    set "POWERSHELL_AVAILABLE=1"
) else (
    echo   [X] powershell.exe NICHT gefunden
    set "POWERSHELL_AVAILABLE=0"
)

echo.
echo ================================================================
echo ZUSAMMENFASSUNG:
echo   PowerShell 7 (pwsh.exe): !PWSH_AVAILABLE!
echo   Windows PowerShell: !POWERSHELL_AVAILABLE!
echo ================================================================
echo.

:: Entscheidung welche verwendet wird
if !PWSH_AVAILABLE! == 1 (
    echo [ENTSCHEIDUNG] Verwende PowerShell 7 (pwsh.exe)
    set "USE_EXE=pwsh.exe"
) else if !POWERSHELL_AVAILABLE! == 1 (
    echo [ENTSCHEIDUNG] Verwende Windows PowerShell (powershell.exe)
    set "USE_EXE=powershell.exe"
) else (
    echo [FEHLER] Keine PowerShell-Version gefunden!
    pause
    exit /b 1
)

echo.
echo Moechten Sie das Tool mit !USE_EXE! starten? [J/N]
choice /C JN /N >nul
if !errorlevel! == 2 exit /b 0

echo.
echo Starte Hellion Tool mit !USE_EXE!...
echo.

:: Suche Script
set "SCRIPT_PATH="
if exist "%~dp0hellion_tool_v65_monkey.ps1" set "SCRIPT_PATH=%~dp0hellion_tool_v65_monkey.ps1"
if exist "%~dp0hellion_tool_v61.ps1" set "SCRIPT_PATH=%~dp0hellion_tool_v61.ps1"
if exist "%~dp0hellion_tool_v*.ps1" for %%f in ("%~dp0hellion_tool_v*.ps1") do set "SCRIPT_PATH=%%f"

if not defined SCRIPT_PATH (
    echo [FEHLER] Kein PowerShell-Script gefunden!
    pause
    exit /b 1
)

echo Script gefunden: !SCRIPT_PATH!
echo.
echo Starte in 3 Sekunden...
timeout /t 3 /nobreak >nul

!USE_EXE! -NoProfile -ExecutionPolicy Bypass -NoExit -File "!SCRIPT_PATH!"

pause