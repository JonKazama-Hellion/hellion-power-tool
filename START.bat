@echo off
setlocal enabledelayedexpansion
title Hellion Power Tool v7.1.5.4 "Baldur"
color 0B

echo ==============================================================================
echo                HELLION POWER TOOL v7.1.5.4 "Baldur"
echo                        Main Launcher - Robust
echo ==============================================================================
echo.

REM ===== SICHERE VERZEICHNIS-ERKENNUNG =====
echo [*] Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Main-Launchers (100% sicher)
set "MAIN_LAUNCHER_DIR=%~dp0"
set "MAIN_LAUNCHER_DIR=%MAIN_LAUNCHER_DIR:~0,-1%"

REM Direkte Validierung (einfacher als Funktions-Call)
if not exist "!MAIN_LAUNCHER_DIR!\hellion_tool_main.ps1" (
    echo [ERROR] START.bat ist nicht im Hellion Root-Verzeichnis!
    echo [INFO] hellion_tool_main.ps1 nicht gefunden in: !MAIN_LAUNCHER_DIR!
    echo.
    echo [LOESUNG]
    echo 1. Kopiere START.bat in das Hellion Hauptverzeichnis
    echo 2. Stelle sicher dass hellion_tool_main.ps1 im selben Ordner ist
    echo.
    pause
    exit /b 1
)

if not exist "!MAIN_LAUNCHER_DIR!\config\version.txt" (
    echo [ERROR] config\version.txt nicht gefunden!
    echo [INFO] Dies ist kein vollstaendiges Hellion Power Tool Verzeichnis
    echo.
    pause
    exit /b 1
)

if not exist "!MAIN_LAUNCHER_DIR!\Launcher" (
    echo [ERROR] Launcher-Verzeichnis nicht gefunden!
    echo [INFO] Dies ist kein vollstaendiges Hellion Power Tool Verzeichnis
    echo.
    pause
    exit /b 1
)

echo [OK] Root-Verzeichnis validiert: !MAIN_LAUNCHER_DIR!
echo.

REM Debug-Modus wählen
set "DEBUG_MODE=0"
echo [*] Waehle Debug-Level:
choice /c 01 /n /m "Debug-Level [0=Normal, 1=Debug]: "
if errorlevel 2 set "DEBUG_MODE=1"

echo.
if "%DEBUG_MODE%"=="1" (
    echo [DEBUG] Debug-Modus aktiviert
) else (
    echo [INFO] Normal-Modus aktiviert
)

echo.
echo === ERWEITERTE OPTIONEN ===
echo [S] Sofort starten (Standard)
echo [L] Advanced Launcher (Erweiterte Optionen)
echo [D] Desktop-Verknuepfung erstellen
echo [P] PowerShell 7 installieren/updaten
echo [G] Git installieren/updaten
echo [U] Update-Check durchfuehren
echo [E] Emergency-Updater
echo [H] Hilfe und Informationen
echo.
choice /c SLDPGUEH /n /m "Waehle eine Option [S/L/D/P/G/U/E/H]: "

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
echo [*] Starte Hellion Power Tool (Direkt)...
timeout /t 1 /nobreak >nul
call "!MAIN_LAUNCHER_DIR!\launcher\simple-launcher.bat" %DEBUG_MODE% DIRECT
goto :END

:ADVANCED_LAUNCHER
echo.
echo [*] Starte Advanced Launcher (Mit Menu-Optionen)...
timeout /t 1 /nobreak >nul
call "!MAIN_LAUNCHER_DIR!\launcher\simple-launcher.bat" %DEBUG_MODE%
goto :END

:DESKTOP_SHORTCUT
echo.
echo [*] Erstelle Desktop-Verknuepfung...
if exist "!MAIN_LAUNCHER_DIR!\assets\create-desktop-shortcut.bat" (
    call "!MAIN_LAUNCHER_DIR!\assets\create-desktop-shortcut.bat"
) else (
    echo [WARNING] create-desktop-shortcut.bat nicht gefunden
    echo [INFO] Erstelle manuell eine Verknuepfung zu START.bat
)
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:INSTALL_PS7
echo.
echo [*] Starte PowerShell 7 Installation...
call "!MAIN_LAUNCHER_DIR!\launcher\install-ps7.bat"
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:INSTALL_GIT
echo.
echo [*] Starte Git Installation...
call "!MAIN_LAUNCHER_DIR!\launcher\install-git.bat"
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:UPDATE_CHECK
echo.
echo [*] Starte Update-Check...
call "!MAIN_LAUNCHER_DIR!\launcher\update-check.bat"
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:EMERGENCY_UPDATE
echo.
echo [*] Starte Emergency-Updater...
call "!MAIN_LAUNCHER_DIR!\launcher\emergency-update.bat"
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:HELP
echo.
echo === HELLION POWER TOOL HILFE v7.1.5.4 ===
echo.
echo HAUPTOPTIONEN:
echo [S] Standard-Start - Startet das Tool direkt (schnell)
echo [L] Advanced Launcher - Startet mit erweiterten Menu-Optionen
echo [D] Desktop-Verknuepfung - Erstellt Shortcut auf Desktop
echo [H] Diese Hilfe anzeigen
echo.
echo INSTALLATIONS-OPTIONEN:
echo [P] PowerShell 7 - Installiert/Aktualisiert PowerShell 7 (empfohlen!)
echo [G] Git - Installiert/Aktualisiert Git (fuer Updates erforderlich!)
echo.
echo UPDATE-OPTIONEN:
echo [U] Update-Check - Prueft auf neue Versionen
echo [E] Emergency-Updater - Repariert defekte Update-Systeme
echo.
echo EMPFOHLENER WORKFLOW:
echo 1. PowerShell 7 installieren (Option P) - Bessere Performance
echo 2. Git installieren (Option G) - Fuer automatische Updates
echo 3. Desktop-Verknuepfung erstellen (Option D) - Einfacher Zugriff
echo 4. Update-Check durchfuehren (Option U) - Neueste Version
echo 5. Tool starten (Option S oder L)
echo.
echo HINWEISE:
echo - PowerShell 7 bietet 2-3x bessere Performance als PS5!
echo - Git wird fuer Update-Checker und Emergency-Updater benoetigt
echo - Advanced Launcher bietet Installations-Menu direkt im Tool
echo.
pause
cls
goto :RESTART

:RESTART
echo ==============================================================================
echo                HELLION POWER TOOL v7.1.5.4 "Baldur"
echo                        Main Launcher - Robust
echo ==============================================================================
echo.
if "%DEBUG_MODE%"=="1" (
    echo [DEBUG] Debug-Modus aktiviert
) else (
    echo [INFO] Normal-Modus aktiviert
)
echo.
echo === ERWEITERTE OPTIONEN ===
echo [S] Sofort starten (Standard)
echo [L] Advanced Launcher (Erweiterte Optionen)
echo [D] Desktop-Verknuepfung erstellen
echo [P] PowerShell 7 installieren/updaten
echo [G] Git installieren/updaten
echo [U] Update-Check durchfuehren
echo [E] Emergency-Updater
echo [H] Hilfe und Informationen
echo.
choice /c SLDPGUEH /n /m "Waehle eine Option [S/L/D/P/G/U/E/H]: "
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

