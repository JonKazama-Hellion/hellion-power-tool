@echo off
setlocal enabledelayedexpansion
title Hellion Desktop-Verknuepfung
color 0A

echo.
echo   ================================================================
echo          HELLION DESKTOP-VERKNUEPFUNG
echo          Hellion Online Media
echo   ================================================================
echo.

echo   Erstelle Desktop-Verknuepfung...

REM Desktop-Pfad ermitteln
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_PATH%" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Desktop"
if not exist "%DESKTOP_PATH%" set "DESKTOP_PATH=%PUBLIC%\Desktop"

echo   Desktop-Pfad: %DESKTOP_PATH%

REM Tool-Pfad ermitteln
set "TOOL_PATH=%~dp0..\START.bat"
set "SHORTCUT_PATH=%DESKTOP_PATH%\Hellion Power Tool.lnk"

echo   Starte Shortcut-Creator...
echo.

REM Rufe PowerShell-Script fuer erweiterte Icon-Unterstuetzung auf
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-shortcut.ps1"

if exist "%SHORTCUT_PATH%" (
    echo.
    echo   [OK] Desktop-Verknuepfung erfolgreich erstellt!
    echo   Pfad: %SHORTCUT_PATH%
    echo.
    echo   Du kannst das Tool jetzt direkt vom Desktop starten
) else (
    echo.
    echo   [ERROR] Verknuepfung konnte nicht erstellt werden
    echo   Versuche manuell oder pruefe Berechtigungen
)

echo.
echo   Beliebige Taste zum Fortfahren...
pause >nul
