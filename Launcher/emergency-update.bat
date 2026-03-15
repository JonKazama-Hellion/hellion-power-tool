@echo off
setlocal enabledelayedexpansion
title Hellion Emergency Updater
color 0C

echo.
echo   ================================================================
echo          HELLION EMERGENCY UPDATER v7.2.0.0
echo          Hellion Online Media
echo   ================================================================
echo.
echo   Dieser Notfall-Updater behebt Auto-Update Probleme
echo   fuer Benutzer von v7.1.0 bis v7.1.x
echo.
echo   WICHTIG: NICHT als Administrator ausfuehren!
echo   Normaler Doppelklick genuegt.
echo.

REM ===== SICHERE VERZEICHNIS-ERKENNUNG =====
echo   Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Launchers (100% sicher)
set "LAUNCHER_DIR=%~dp0"
set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"

REM Bestimme Root-Verzeichnis mit mehreren Fallback-Methoden
call :FIND_ROOT_DIRECTORY ROOT_DIR

if "!ROOT_DIR!"=="" (
    echo   [ERROR] Root-Verzeichnis nicht gefunden!
    echo.
    echo   Empfehlung:
    echo   1. Kopiere emergency-update.bat in den Launcher/-Ordner
    echo   2. Starte von dort aus (Doppelklick)
    echo.
    pause
    exit /b 1
)

echo   [OK] Root: !ROOT_DIR!
echo   [OK] Launcher: !LAUNCHER_DIR!

REM Validiere dass alle wichtigen Dateien existieren
set "MAIN_SCRIPT=!ROOT_DIR!\hellion_tool_main.ps1"
set "VERSION_FILE=!ROOT_DIR!\config\version.txt"

if not exist "!MAIN_SCRIPT!" (
    echo   [ERROR] hellion_tool_main.ps1 nicht gefunden!
    echo   Kein vollstaendiges Hellion Power Tool Verzeichnis
    pause
    exit /b 1
)

if not exist "!VERSION_FILE!" (
    echo   [ERROR] config\version.txt nicht gefunden!
    echo   Kein vollstaendiges Hellion Power Tool Verzeichnis
    pause
    exit /b 1
)

echo   [OK] Alle wichtigen Dateien gefunden
echo.

echo   Erstelle Backup der alten update-check.bat...
if exist "update-check.bat" (
    copy "update-check.bat" "update-check.bat.backup" >nul
    echo   [OK] Backup erstellt: update-check.bat.backup
)

echo.
echo   Lade reparierte update-check.bat von GitHub...

REM Erstelle temporaeres Verzeichnis
set "TEMP_DIR=%TEMP%\hellion_emergency_%RANDOM%"
mkdir "%TEMP_DIR%" >nul 2>&1

cd /d "%TEMP_DIR%"

REM Lade nur die reparierte Datei
git clone --depth 1 --no-checkout https://github.com/JonKazama-Hellion/hellion-power-tool.git hellion-fix >nul 2>&1
set "CLONE_RESULT=%errorlevel%"

if %CLONE_RESULT% neq 0 (
    echo   [ERROR] Download fehlgeschlagen!
    echo   Bitte manuell von GitHub herunterladen:
    echo   https://github.com/JonKazama-Hellion/hellion-power-tool/blob/main/Launcher/update-check.bat
    cd /d "%~dp0"
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
    pause
    exit /b 1
)

cd hellion-fix
git checkout HEAD -- Launcher/update-check.bat >nul 2>&1

if exist "Launcher\update-check.bat" (
    echo   [OK] Reparierte Datei geladen!

    REM Kopiere die reparierte Datei zurueck
    copy "Launcher\update-check.bat" "%~dp0update-check.bat" >nul
    if %errorlevel%==0 (
        echo   [OK] update-check.bat erfolgreich repariert!
        echo.
        echo   Vollautomatisches Update-System ist jetzt verfuegbar:
        echo   - Automatisches Backup der aktuellen Version
        echo   - GitHub Download und Installation
        echo   - User-Einstellungen bleiben erhalten
    ) else (
        echo   [ERROR] Kopieren fehlgeschlagen!
    )
) else (
    echo   [ERROR] Reparierte Datei nicht gefunden!
)

REM Cleanup
cd /d "%~dp0"
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo   Teste reparierte update-check.bat...
echo.

REM Wechsle zum sicheren Root-Verzeichnis fuer den Test
cd /d "!ROOT_DIR!"
echo   [OK] Arbeite in: !ROOT_DIR!

REM Fuehre reparierten Update-Check aus
call "Launcher\update-check.bat"

REM Zurueck zum sicheren Launcher-Verzeichnis
cd /d "!LAUNCHER_DIR!"

echo.
echo   ================================================================
echo          EMERGENCY UPDATE FERTIG
echo          Hellion Online Media
echo   ================================================================
echo.
echo   Der Auto-Updater sollte jetzt wieder funktionieren!
echo   Du kannst diesen emergency-update.bat jetzt loeschen.
echo.
pause
goto :EOF

REM ===== ROOT-VERZEICHNIS FINDER (100% SICHER) =====
:FIND_ROOT_DIRECTORY
set "RESULT_VAR=%~1"
set "FOUND_ROOT="

REM Methode 1: Standard-Annahme - Launcher ist in Launcher/-Subdir
set "TEST_ROOT=%LAUNCHER_DIR%\.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_1
if "!IS_VALID_1!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 2: Batch-Parameter %~dp0 verwenden
set "TEST_ROOT=%~dp0.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_2
if "!IS_VALID_2!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 3: Aufwaerts-Suche vom aktuellen Verzeichnis
set "SEARCH_DIR=%CD%"
for /L %%i in (1,1,5) do (
    call :VALIDATE_ROOT_DIR "!SEARCH_DIR!" IS_VALID_3
    if "!IS_VALID_3!"=="YES" (
        set "FOUND_ROOT=!SEARCH_DIR!"
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!SEARCH_DIR!") do set "SEARCH_DIR=%%~dpj"
    set "SEARCH_DIR=!SEARCH_DIR:~0,-1!"
)

REM Methode 4: Suche nach charakteristischen Dateien
set "CHECK_DIR=%CD%"
for /L %%i in (1,1,3) do (
    if exist "!CHECK_DIR!\START.bat" if exist "!CHECK_DIR!\hellion_tool_main.ps1" (
        set "FOUND_ROOT=!CHECK_DIR!"
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!CHECK_DIR!") do set "CHECK_DIR=%%~dpj"
    set "CHECK_DIR=!CHECK_DIR:~0,-1!"
)

goto :FOUND_ROOT_FAILED

:FOUND_ROOT_SUCCESS
for %%i in ("!FOUND_ROOT!") do set "FOUND_ROOT=%%~fi"
set "%RESULT_VAR%=!FOUND_ROOT!"
goto :EOF

:FOUND_ROOT_FAILED
set "%RESULT_VAR%="
goto :EOF

:VALIDATE_ROOT_DIR
set "TEST_DIR=%~1"
set "RESULT_VAR=%~2"

if not exist "!TEST_DIR!" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)

if not exist "!TEST_DIR!\config" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\config\version.txt" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\Launcher" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\modules" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)

set "%RESULT_VAR%=YES"
goto :EOF
