@echo off
setlocal enabledelayedexpansion
title Hellion Emergency Updater
color 0C

echo ==============================================================================
echo                    HELLION EMERGENCY UPDATER v7.1.3
echo                      Repariert Auto-Update Probleme
echo ==============================================================================
echo.
echo [INFO] Dieser Notfall-Updater behebt das Auto-Update Problem
echo [INFO] fuer Benutzer von v7.1.0 und v7.1.1
echo.
echo [IMPORTANT] NICHT als Administrator ausfuehren - normaler Doppelklick!
echo.

REM Prüfe ob im richtigen Verzeichnis
if not exist "..\hellion_tool_main.ps1" (
    echo [ERROR] Nicht im richtigen Verzeichnis!
    echo [INFO] Bitte diese Datei in den /Launcher Ordner kopieren
    echo [INFO] und von dort aus starten.
    echo.
    pause
    exit /b 1
)

REM Prüfe ob config/version.txt existiert
if not exist "..\config\version.txt" (
    echo [ERROR] config\version.txt nicht gefunden!
    echo [INFO] Dies ist kein vollstaendiges Hellion Power Tool Verzeichnis
    echo [INFO] Bitte lade die komplette Version von GitHub herunter.
    echo.
    pause
    exit /b 1
)

echo [*] Erstelle Backup der alten update-check.bat...
if exist "update-check.bat" (
    copy "update-check.bat" "update-check.bat.backup" >nul
    echo [OK] Backup erstellt: update-check.bat.backup
)

echo.
echo [*] Lade reparierte update-check.bat von GitHub...

REM Erstelle temporäres Verzeichnis
set "TEMP_DIR=%TEMP%\hellion_emergency_%RANDOM%"
mkdir "%TEMP_DIR%" >nul 2>&1

cd /d "%TEMP_DIR%"

REM Lade nur die reparierte Datei
git clone --depth 1 --no-checkout https://github.com/JonKazama-Hellion/hellion-power-tool.git hellion-fix >nul 2>&1
set "CLONE_RESULT=%errorlevel%"

if %CLONE_RESULT% neq 0 (
    echo [ERROR] Download fehlgeschlagen!
    echo [INFO] Bitte manuell von GitHub herunterladen:
    echo   https://github.com/JonKazama-Hellion/hellion-power-tool/blob/main/Launcher/update-check.bat
    cd /d "%~dp0"
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
    pause
    exit /b 1
)

cd hellion-fix
git checkout HEAD -- Launcher/update-check.bat >nul 2>&1

if exist "Launcher\update-check.bat" (
    echo [OK] Reparierte Datei geladen!
    
    REM Kopiere die reparierte Datei zurück
    copy "Launcher\update-check.bat" "%~dp0update-check.bat" >nul
    if %errorlevel%==0 (
        echo [SUCCESS] update-check.bat erfolgreich repariert!
        echo.
        echo [BONUS] Vollautomatisches Update-System ist jetzt verfuegbar!
        echo [INFO] Der reparierte Update-Checker kann jetzt automatisch updaten:
        echo   - Automatisches Backup der aktuellen Version  
        echo   - GitHub Download und Installation
        echo   - User-Einstellungen bleiben erhalten
    ) else (
        echo [ERROR] Kopieren fehlgeschlagen!
    )
) else (
    echo [ERROR] Reparierte Datei nicht gefunden!
)

REM Cleanup
cd /d "%~dp0"
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo [*] Teste reparierte update-check.bat...
echo.

REM Wechsle zum Root-Verzeichnis für den Test
cd /d "%~dp0\.."

REM Führe reparierten Update-Check aus (aus dem Root-Verzeichnis)
call "Launcher\update-check.bat"

REM Zurück zum Launcher-Verzeichnis
cd /d "%~dp0"

echo.
echo ==============================================================================
echo                          EMERGENCY UPDATE FERTIG
echo ==============================================================================
echo.
echo [INFO] Der Auto-Updater sollte jetzt wieder funktionieren!
echo [TIP] Du kannst diesen emergency-update.bat jetzt löschen.
echo.
pause