@echo off
REM ===================================================================
REM HELLION POWER TOOL - GUI LAUNCHER
REM Erkennt PowerShell 7 automatisch, startet WPF-Oberflaeche
REM ===================================================================
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "GUI_SCRIPT=%SCRIPT_DIR%src\hellion_gui.ps1"

echo.
echo  Hellion Power Tool - GUI Launcher
echo  ===================================

REM PowerShell 7 suchen
set "PWSH_EXE="

REM 1. PATH pruefen
where pwsh >nul 2>&1
if !errorlevel! == 0 (
    set "PWSH_EXE=pwsh"
    goto :found
)

REM 2. Standard-Installationspfad
if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
    set "PWSH_EXE=C:\Program Files\PowerShell\7\pwsh.exe"
    goto :found
)

REM 3. Fallback: Windows PowerShell 5.1
set "PWSH_EXE=PowerShell"
echo  [HINWEIS] PowerShell 7 nicht gefunden - verwende PS 5.1
echo  [TIPP] Installiere PS7: winget install Microsoft.PowerShell

:found
echo  PowerShell: !PWSH_EXE!
echo.

REM GUI starten (WPF oeffnet eigenes Fenster, Admin-Elevation in hellion_gui.ps1)
start "" /B "!PWSH_EXE!" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%GUI_SCRIPT%" %*

REM BAT-Fenster sofort schliessen
exit
