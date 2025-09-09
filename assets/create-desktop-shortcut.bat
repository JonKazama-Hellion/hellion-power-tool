@echo off
setlocal enabledelayedexpansion
title Hellion Desktop-Verknuepfung
color 0B

echo ==============================================================================
echo                   HELLION DESKTOP-VERKNUEPFUNG ERSTELLEN
echo ==============================================================================
echo.

echo [*] Erstelle Desktop-Verknuepfung...

REM Desktop-Pfad ermitteln
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_PATH%" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Desktop"
if not exist "%DESKTOP_PATH%" set "DESKTOP_PATH=%PUBLIC%\Desktop"

echo [INFO] Desktop-Pfad: %DESKTOP_PATH%

REM Tool-Pfad ermitteln
set "TOOL_PATH=%~dp0..\START.bat"
set "SHORTCUT_PATH=%DESKTOP_PATH%\Hellion Power Tool.lnk"

echo [*] Erstelle Verknuepfung mit PowerShell...

echo [*] Starte erweiterten Shortcut-Creator...
echo.

REM Rufe PowerShell-Script für erweiterte Icon-Unterstützung auf
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-shortcut.ps1"

if exist "%SHORTCUT_PATH%" (
    echo.
    echo [SUCCESS] Desktop-Verknuepfung erfolgreich erstellt!
    echo [PFAD] %SHORTCUT_PATH%
    echo.
    echo [TIP] Du kannst das Tool jetzt direkt vom Desktop starten
) else (
    echo.
    echo [ERROR] Verknuepfung konnte nicht erstellt werden
    echo [INFO] Versuche manuell oder pruefe Berechtigungen
)

echo.
echo Druecke beliebige Taste um fortzufahren...
pause >nul