@echo off
setlocal enabledelayedexpansion
title Hellion Power Tool v7.2.0.0 "Heimdall"
color 0A

echo.
echo   ================================================================
echo          HELLION POWER TOOL v7.2.0.0 "Heimdall"
echo          Hellion Online Media
echo   ================================================================
echo.

REM ===== SICHERE VERZEICHNIS-ERKENNUNG =====
echo   Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Main-Launchers (100% sicher)
set "MAIN_LAUNCHER_DIR=%~dp0"
set "MAIN_LAUNCHER_DIR=%MAIN_LAUNCHER_DIR:~0,-1%"

REM Direkte Validierung (einfacher als Funktions-Call)
if not exist "!MAIN_LAUNCHER_DIR!\hellion_tool_main.ps1" (
    echo   [ERROR] START.bat ist nicht im Hellion Root-Verzeichnis!
    echo   hellion_tool_main.ps1 nicht gefunden in: !MAIN_LAUNCHER_DIR!
    echo.
    echo   1. Kopiere START.bat in das Hellion Hauptverzeichnis
    echo   2. Stelle sicher dass hellion_tool_main.ps1 im selben Ordner ist
    echo.
    pause
    exit /b 1
)

if not exist "!MAIN_LAUNCHER_DIR!\config\version.txt" (
    echo   [ERROR] config\version.txt nicht gefunden!
    echo   Kein vollstaendiges Hellion Power Tool Verzeichnis
    echo.
    pause
    exit /b 1
)

if not exist "!MAIN_LAUNCHER_DIR!\Launcher" (
    echo   [ERROR] Launcher-Verzeichnis nicht gefunden!
    echo   Kein vollstaendiges Hellion Power Tool Verzeichnis
    echo.
    pause
    exit /b 1
)

echo   [OK] Root: !MAIN_LAUNCHER_DIR!
echo.

REM Debug-Modus waehlen
set "DEBUG_MODE=0"
echo   Modus waehlen:
choice /c 01 /n /m "   [0] Normal  [1] Debug : "
if errorlevel 2 set "DEBUG_MODE=1"

echo.
if "%DEBUG_MODE%"=="1" (
    echo   Modus: Debug
) else (
    echo   Modus: Normal
)

echo.
echo   ----------------------------------------------------------------
echo   --- OPTIONEN ---
echo.
echo   [S] Sofort starten                (Standard)
echo   [L] Advanced Launcher             (Erweiterte Optionen)
echo.
echo   --- INSTALLATION ---
echo.
echo   [D] Desktop-Verknuepfung erstellen
echo   [P] PowerShell 7 installieren
echo   [G] Git installieren
echo.
echo   --- UPDATES ---
echo.
echo   [U] Update-Check
echo   [E] Emergency-Updater
echo.
echo   --- INFO ---
echo.
echo   [H] Hilfe
echo   ----------------------------------------------------------------
echo.
choice /c SLDPGUEH /n /m "   Option waehlen [S/L/D/P/G/U/E/H]: "

if errorlevel 8 goto :HELP
if errorlevel 7 goto :EMERGENCY_UPDATE
if errorlevel 6 goto :UPDATE_CHECK
if errorlevel 5 goto :INSTALL_GIT
if errorlevel 4 goto :INSTALL_PS7
if errorlevel 3 goto :DESKTOP_SHORTCUT
if errorlevel 2 goto :ADVANCED_LAUNCHER
if errorlevel 1 goto :START_TOOL

:START_TOOL
echo.
echo   Starte Hellion Power Tool (Direkt)...
timeout /t 1 /nobreak >nul
call "!MAIN_LAUNCHER_DIR!\launcher\simple-launcher.bat" %DEBUG_MODE% DIRECT
goto :END

:ADVANCED_LAUNCHER
echo.
echo   Starte Advanced Launcher...
timeout /t 1 /nobreak >nul
call "!MAIN_LAUNCHER_DIR!\launcher\simple-launcher.bat" %DEBUG_MODE%
goto :END

:DESKTOP_SHORTCUT
echo.
echo   Erstelle Desktop-Verknuepfung...
if exist "!MAIN_LAUNCHER_DIR!\assets\create-desktop-shortcut.bat" (
    call "!MAIN_LAUNCHER_DIR!\assets\create-desktop-shortcut.bat"
) else (
    echo   [WARNING] create-desktop-shortcut.bat nicht gefunden
    echo   Erstelle manuell eine Verknuepfung zu START.bat
)
echo.
timeout /t 2 /nobreak >nul
goto :START_TOOL

:INSTALL_PS7
echo.
echo   Starte PowerShell 7 Installation...
call "!MAIN_LAUNCHER_DIR!\launcher\install-ps7.bat"
echo.
timeout /t 2 /nobreak >nul
goto :START_TOOL

:INSTALL_GIT
echo.
echo   Starte Git Installation...
call "!MAIN_LAUNCHER_DIR!\launcher\install-git.bat"
echo.
timeout /t 2 /nobreak >nul
goto :START_TOOL

:UPDATE_CHECK
echo.
echo   Starte Update-Check...
call "!MAIN_LAUNCHER_DIR!\launcher\update-check.bat"
echo.
timeout /t 2 /nobreak >nul
goto :START_TOOL

:EMERGENCY_UPDATE
echo.
echo   Starte Emergency-Updater...
call "!MAIN_LAUNCHER_DIR!\launcher\emergency-update.bat"
echo.
timeout /t 2 /nobreak >nul
goto :START_TOOL

:HELP
echo.
echo   ================================================================
echo          HELLION POWER TOOL - HILFE
echo   ================================================================
echo.
echo   --- START ---
echo   [S] Standard-Start        Startet das Tool direkt
echo   [L] Advanced Launcher     Startet mit erweiterten Optionen
echo.
echo   --- INSTALLATION ---
echo   [D] Desktop-Verknuepfung  Shortcut auf Desktop erstellen
echo   [P] PowerShell 7          Installation/Update (empfohlen!)
echo   [G] Git                   Installation/Update (fuer Updates)
echo.
echo   --- UPDATES ---
echo   [U] Update-Check          Prueft auf neue Versionen
echo   [E] Emergency-Updater     Repariert defekte Update-Systeme
echo.
echo   --- EMPFOHLENER WORKFLOW ---
echo   1. PowerShell 7 installieren (Option P)
echo   2. Git installieren (Option G)
echo   3. Desktop-Verknuepfung erstellen (Option D)
echo   4. Update-Check durchfuehren (Option U)
echo   5. Tool starten (Option S oder L)
echo.
echo   --- HINWEISE ---
echo   - PowerShell 7 bietet 2-3x bessere Performance als PS5
echo   - Git wird fuer automatische Updates benoetigt
echo   ================================================================
echo.
pause
cls
goto :RESTART

:RESTART
echo.
echo   ================================================================
echo          HELLION POWER TOOL v7.2.0.0 "Heimdall"
echo          Hellion Online Media
echo   ================================================================
echo.
if "%DEBUG_MODE%"=="1" (
    echo   Modus: Debug
) else (
    echo   Modus: Normal
)
echo.
echo   ----------------------------------------------------------------
echo   --- OPTIONEN ---
echo.
echo   [S] Sofort starten                (Standard)
echo   [L] Advanced Launcher             (Erweiterte Optionen)
echo.
echo   --- INSTALLATION ---
echo.
echo   [D] Desktop-Verknuepfung erstellen
echo   [P] PowerShell 7 installieren
echo   [G] Git installieren
echo.
echo   --- UPDATES ---
echo.
echo   [U] Update-Check
echo   [E] Emergency-Updater
echo.
echo   --- INFO ---
echo.
echo   [H] Hilfe
echo   ----------------------------------------------------------------
echo.
choice /c SLDPGUEH /n /m "   Option waehlen [S/L/D/P/G/U/E/H]: "
goto :HANDLE_CHOICE

:HANDLE_CHOICE
if errorlevel 8 goto :HELP
if errorlevel 7 goto :EMERGENCY_UPDATE
if errorlevel 6 goto :UPDATE_CHECK
if errorlevel 5 goto :INSTALL_GIT
if errorlevel 4 goto :INSTALL_PS7
if errorlevel 3 goto :DESKTOP_SHORTCUT
if errorlevel 2 goto :ADVANCED_LAUNCHER
if errorlevel 1 goto :START_TOOL

:END
REM Auto-close - kein pause mehr dank simple-launcher.bat timeout
goto :EOF
