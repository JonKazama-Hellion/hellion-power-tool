@echo off
setlocal enabledelayedexpansion
title Hellion Update Checker v7.2.0.0
color 0A

echo.
echo   ================================================================
echo          HELLION UPDATE CHECKER v7.2.0.0
echo          Hellion Online Media
echo   ================================================================
echo.

REM ===== SCHRITT 0: VERZEICHNIS-SCHUTZ UND PFAD-VALIDIERUNG =====
echo   Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Launchers (100% sicher)
set "LAUNCHER_DIR=%~dp0"
set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"

REM Bestimme Root-Verzeichnis mit mehreren Fallback-Methoden
call :FIND_ROOT_DIRECTORY ROOT_DIR

if "!ROOT_DIR!"=="" (
    echo   [ERROR] Root-Verzeichnis nicht gefunden!
    echo   Launcher muss im Launcher/-Unterverzeichnis liegen
    goto :ERROR_END
)

echo   [OK] Root: !ROOT_DIR!
echo   [OK] Launcher: !LAUNCHER_DIR!

REM ===== SCHRITT 1: LOKALE VERSION LESEN =====
echo   Lade lokale Version...

REM Mehrere Fallback-Pfade fuer version.txt
set "VERSION_FILE=!ROOT_DIR!\config\version.txt"
set "VERSION_FILE_ALT1=%~dp0..\config\version.txt"
set "VERSION_FILE_ALT2=!LAUNCHER_DIR!\..\config\version.txt"

if exist "!VERSION_FILE!" (
    echo   [OK] version.txt gefunden
) else if exist "!VERSION_FILE_ALT1!" (
    set "VERSION_FILE=!VERSION_FILE_ALT1!"
    echo   [OK] version.txt gefunden (Fallback 1)
) else if exist "!VERSION_FILE_ALT2!" (
    set "VERSION_FILE=!VERSION_FILE_ALT2!"
    echo   [OK] version.txt gefunden (Fallback 2)
) else (
    echo   [ERROR] version.txt nicht gefunden!
    goto :ERROR_END
)

REM Lese alle 4 Zeilen der version.txt (usebackq fuer Pfade mit Leerzeichen)
set "LINE_COUNT=0"
for /f "usebackq delims=" %%a in ("!VERSION_FILE!") do (
    set /a LINE_COUNT+=1
    if !LINE_COUNT!==1 set "LOCAL_VERSION=%%a"
    if !LINE_COUNT!==2 set "LOCAL_CODENAME=%%a"
    if !LINE_COUNT!==3 set "LOCAL_DATE=%%a"
    if !LINE_COUNT!==4 set "LOCAL_TIMESTAMP=%%a"
)

REM Validiere dass alle Daten vorhanden sind
if "!LOCAL_VERSION!"=="" (
    echo   [ERROR] Lokale Version konnte nicht gelesen werden
    goto :ERROR_END
)
if "!LOCAL_TIMESTAMP!"=="" (
    echo   [ERROR] Lokaler Timestamp fehlt - inkompatible Version
    echo   Nur v7.1.4+ Versionen werden unterstuetzt
    goto :ERROR_END
)

echo   [OK] Lokal: !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
echo.

REM ===== SCHRITT 2: GIT VERFUEGBARKEIT PRUEFEN =====
echo   Pruefe Git Verfuegbarkeit...
git --version >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Git ist nicht verfuegbar
    echo   Git wird fuer den Update-Check benoetigt
    goto :ERROR_END
)
echo   [OK] Git ist verfuegbar
echo.

REM ===== SCHRITT 3: GITHUB VERSION LADEN =====
echo   Lade GitHub Version...
echo   Verbinde mit GitHub Repository...
set "TEMP_DIR=%TEMP%\hellion_update_%RANDOM%"
mkdir "!TEMP_DIR!" >nul 2>&1

cd /d "!TEMP_DIR!"

REM Git clone mit sichtbarem Fehler-Output
git clone --depth 1 https://github.com/JonKazama-Hellion/hellion-power-tool.git repo 2>&1 | findstr /i "error fatal" >nul 2>&1
REM Pruefe ob clone erfolgreich war anhand der Dateien
if not exist "repo\config\version.txt" (
    echo   [ERROR] GitHub Repository konnte nicht geladen werden
    echo   Pruefe Internetverbindung und Repository-URL
    cd /d "!LAUNCHER_DIR!"
    rmdir /s /q "!TEMP_DIR!" >nul 2>&1
    goto :ERROR_END
)

echo   [OK] Repository erfolgreich geladen

REM Lese GitHub Version
set "GH_LINE_COUNT=0"
for /f "usebackq delims=" %%a in ("repo\config\version.txt") do (
    set /a GH_LINE_COUNT+=1
    if !GH_LINE_COUNT!==1 set "GITHUB_VERSION=%%a"
    if !GH_LINE_COUNT!==2 set "GITHUB_CODENAME=%%a"
    if !GH_LINE_COUNT!==3 set "GITHUB_DATE=%%a"
    if !GH_LINE_COUNT!==4 set "GITHUB_TIMESTAMP=%%a"
)

REM Cleanup
cd /d "!LAUNCHER_DIR!"
rmdir /s /q "!TEMP_DIR!" >nul 2>&1

REM Validiere GitHub Daten
if "!GITHUB_VERSION!"=="" (
    echo   [ERROR] GitHub Version konnte nicht gelesen werden
    goto :ERROR_END
)
if "!GITHUB_TIMESTAMP!"=="" (
    echo   [ERROR] GitHub Timestamp fehlt - inkompatible Version
    goto :ERROR_END
)

echo   [OK] GitHub: !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
echo.

REM ===== SCHRITT 4: VERSIONS-VERGLEICH =====
echo   Vergleiche Versionen...

REM Erster Check: Versions-String direkt vergleichen
if "!LOCAL_VERSION!"=="!GITHUB_VERSION!" (
    if "!LOCAL_TIMESTAMP!"=="!GITHUB_TIMESTAMP!" (
        echo.
        echo   ================================================================
        echo   [OK] Neueste Version: !LOCAL_VERSION! "!LOCAL_CODENAME!"
        echo   ================================================================
        goto :SUCCESS_END
    )
    REM Gleiche Version aber anderer Timestamp
    echo   Gleiche Version aber anderer Build-Timestamp erkannt
)

REM Zweiter Check: Wenn Versionen unterschiedlich, ist ein Update da
if NOT "!LOCAL_VERSION!"=="!GITHUB_VERSION!" (
    echo.
    echo   ================================================================
    echo                        UPDATE VERFUEGBAR
    echo   ================================================================
    echo.
    echo   Aktuell:     !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
    echo   Verfuegbar:  !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
    echo.
    goto :OFFER_UPDATE
)

REM Dritter Check: Timestamp-Vergleich
call :COMPARE_TIMESTAMPS "!LOCAL_TIMESTAMP!" "!GITHUB_TIMESTAMP!" TIMESTAMP_RESULT

if "!TIMESTAMP_RESULT!"=="NEWER" (
    echo.
    echo   ================================================================
    echo   [OK] Lokale Version ist neuer als GitHub!
    echo   Lokal:   !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
    echo   GitHub:  !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
    echo   ================================================================
    goto :SUCCESS_END
)

if "!TIMESTAMP_RESULT!"=="OLDER" (
    echo.
    echo   ================================================================
    echo                         HOTFIX VERFUEGBAR
    echo   ================================================================
    echo.
    echo   Aktuell:     !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
    echo   Verfuegbar:  !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
    echo.
    goto :OFFER_UPDATE
)

if "!TIMESTAMP_RESULT!"=="EQUAL" (
    echo.
    echo   ================================================================
    echo   [OK] Neueste Version: !LOCAL_VERSION! "!LOCAL_CODENAME!"
    echo   ================================================================
    goto :SUCCESS_END
)

REM Fallback bei Vergleichsfehler
echo   [WARNING] Timestamp-Vergleich ergab: !TIMESTAMP_RESULT!
echo   Versionen manuell pruefen:
echo   Lokal:   !LOCAL_VERSION! "!LOCAL_CODENAME!" Timestamp: !LOCAL_TIMESTAMP!
echo   GitHub:  !GITHUB_VERSION! "!GITHUB_CODENAME!" Timestamp: !GITHUB_TIMESTAMP!
goto :SUCCESS_END

REM ===== UPDATE ANBIETEN =====
:OFFER_UPDATE
echo   Automatisches Update durchfuehren?
echo   [J] Ja, automatisch updaten (empfohlen)
echo   [N] Nein, manuell herunterladen
echo   [A] Abbrechen
echo.
choice /c JNA /n /m "   Option waehlen [J/N/A]: "

if errorlevel 3 (
    echo   Update abgebrochen
    goto :SUCCESS_END
)
if errorlevel 2 (
    echo.
    echo   Lade die neueste Version manuell herunter:
    echo   https://github.com/JonKazama-Hellion/hellion-power-tool/releases/latest
    goto :SUCCESS_END
)

echo.
echo   Starte automatisches Update...
call :PERFORM_AUTO_UPDATE
goto :SUCCESS_END

REM ===== AUTO-UPDATE FUNKTION =====
:PERFORM_AUTO_UPDATE
echo.
echo   ================================================================
echo                      AUTOMATISCHES UPDATE
echo   ================================================================
echo.

REM Sichere Verzeichnis-Bestimmung
echo   Validiere Update-Verzeichnisse...
set "UPDATE_ROOT_DIR=!ROOT_DIR!"
if "!UPDATE_ROOT_DIR!"=="" (
    echo   [ERROR] Root-Verzeichnis nicht verfuegbar - Update abgebrochen
    goto :EOF
)

REM Wechsle zum sicheren Root-Verzeichnis
cd /d "!UPDATE_ROOT_DIR!"
echo   [OK] Arbeite in: !UPDATE_ROOT_DIR!

REM Erstelle sicheren Backup-Pfad mit Validierung
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    for /f "tokens=1-3 delims=: " %%a in ("%time%") do (
        set "BACKUP_TIMESTAMP=%%k%%j%%l_%%a-%%b"
    )
)

REM Sichere Backup-Pfad Bestimmung
set "BACKUP_BASE_DIR=!UPDATE_ROOT_DIR!\backups"
set "BACKUP_DIR=!BACKUP_BASE_DIR!\!LOCAL_VERSION!_!LOCAL_CODENAME!_backup_!BACKUP_TIMESTAMP!"

echo   Erstelle Backup in: !BACKUP_DIR!

REM Erstelle Backup-Verzeichnisse sicher
if not exist "!BACKUP_BASE_DIR!" (
    mkdir "!BACKUP_BASE_DIR!" >nul 2>&1
    if errorlevel 1 (
        echo   [ERROR] Backup-Verzeichnis kann nicht erstellt werden
        goto :EOF
    )
)

mkdir "!BACKUP_DIR!" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Backup-Verzeichnis kann nicht erstellt werden
    goto :EOF
)
echo   [OK] Backup-Verzeichnis erstellt

REM Backup wichtiger Dateien
echo   Sichere aktuelle Installation...
xcopy /E /I /Q /Y "config" "!BACKUP_DIR!\config\" >nul 2>&1
xcopy /E /I /Q /Y "modules" "!BACKUP_DIR!\modules\" >nul 2>&1
xcopy /E /I /Q /Y "Launcher" "!BACKUP_DIR!\Launcher\" >nul 2>&1
xcopy /E /I /Q /Y "scripts" "!BACKUP_DIR!\scripts\" >nul 2>&1
xcopy /E /I /Q /Y "Debug" "!BACKUP_DIR!\Debug\" >nul 2>&1
xcopy /E /I /Q /Y "docs" "!BACKUP_DIR!\docs\" >nul 2>&1
copy /Y "hellion_tool_main.ps1" "!BACKUP_DIR!\" >nul 2>&1
copy /Y "START.bat" "!BACKUP_DIR!\" >nul 2>&1
copy /Y "README.md" "!BACKUP_DIR!\" >nul 2>&1
copy /Y "SECURITY.md" "!BACKUP_DIR!\" >nul 2>&1
copy /Y "LICENSE" "!BACKUP_DIR!\" >nul 2>&1

echo   [OK] Backup erfolgreich erstellt
echo.

REM Lade neue Version
echo   Lade neue Version von GitHub...
set "UPDATE_TEMP_DIR=%TEMP%\hellion_update_%RANDOM%"
mkdir "!UPDATE_TEMP_DIR!" >nul 2>&1

cd /d "!UPDATE_TEMP_DIR!"
echo   Clone Repository...
git clone --depth 1 https://github.com/JonKazama-Hellion/hellion-power-tool.git hellion-new

if not exist "hellion-new\hellion_tool_main.ps1" (
    echo   [ERROR] Download fehlgeschlagen!
    cd /d "!UPDATE_ROOT_DIR!"
    rmdir /s /q "!UPDATE_TEMP_DIR!" >nul 2>&1
    echo   Backup bleibt erhalten in: !BACKUP_DIR!
    goto :EOF
)

echo   [OK] Download erfolgreich
echo.

REM User-Einstellungen retten
echo   Sichere User-Einstellungen...
if exist "!BACKUP_DIR!\config\settings.json" (
    copy /Y "!BACKUP_DIR!\config\settings.json" "!UPDATE_TEMP_DIR!\hellion-new\config\settings.json" >nul 2>&1
    echo   [OK] User-Einstellungen uebertragen
) else (
    echo   Keine User-Einstellungen gefunden (Standardwerte)
)
echo.

REM Erstelle separaten Installer (100% Self-Delete sicher)
echo   Erstelle sicheren Update-Installer...

REM Installer NIEMALS in Launcher-Dir - immer in TEMP
set "INSTALLER_SCRIPT=%TEMP%\hellion_installer_%RANDOM%.bat"
echo @echo off > "!INSTALLER_SCRIPT!"
echo title Hellion Update Installer >> "!INSTALLER_SCRIPT!"
echo echo   Installiere neue Version... >> "!INSTALLER_SCRIPT!"
echo echo   Warte bis Parent-Prozesse beendet sind (10 Sekunden)... >> "!INSTALLER_SCRIPT!"
echo timeout /t 10 /nobreak ^>nul >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo REM Wechsle in sicheres Root-Verzeichnis >> "!INSTALLER_SCRIPT!"
echo cd /d "!UPDATE_ROOT_DIR!" >> "!INSTALLER_SCRIPT!"
echo if errorlevel 1 echo [ERROR] Kann nicht in Root-Dir wechseln ^&^& pause ^&^& exit /b 1 >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo REM Loesche alte Dateien (behalte backups) >> "!INSTALLER_SCRIPT!"
echo for /f %%%%i in ('dir /b /a-d 2^^^>nul ^^^| findstr /v /i "backup"') do del /f /q "%%%%i" ^^^>nul 2^^^>^^^&1 >> "!INSTALLER_SCRIPT!"
echo for /f %%%%i in ('dir /b /ad 2^^^>nul ^^^| findstr /v /i "backup"') do rmdir /s /q "%%%%i" ^^^>nul 2^^^>^^^&1 >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo REM Kopiere neue Version mit absolutem Pfad >> "!INSTALLER_SCRIPT!"
echo xcopy /E /I /Q /Y "!UPDATE_TEMP_DIR!\hellion-new\*" "!UPDATE_ROOT_DIR!" ^^^>nul 2^^^>^^^&1 >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo echo   [OK] Update erfolgreich installiert! >> "!INSTALLER_SCRIPT!"
echo echo   Neue Version: !GITHUB_VERSION! "!GITHUB_CODENAME!" >> "!INSTALLER_SCRIPT!"
echo echo   Backup: !BACKUP_DIR! >> "!INSTALLER_SCRIPT!"
echo echo. >> "!INSTALLER_SCRIPT!"
echo echo   Beliebige Taste zum Schliessen... >> "!INSTALLER_SCRIPT!"
echo pause ^>nul >> "!INSTALLER_SCRIPT!"
echo rmdir /s /q "!UPDATE_TEMP_DIR!" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"
echo del /f /q "%%%%0" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"

echo   Starte separaten Installer...
start "" "!INSTALLER_SCRIPT!"

echo.
echo   ================================================================
echo                     UPDATE WIRD INSTALLIERT
echo   ================================================================
echo.
echo   Update laeuft im Hintergrund weiter
echo   Backup gesichert in: !BACKUP_DIR!
echo.
echo   Warte 10 Sekunden und starte dann das Tool neu:
echo   START.bat
echo.
echo   Dieses Fenster kann jetzt geschlossen werden
timeout /t 5 /nobreak >nul
exit /b 0

REM ===== ENDE LABELS =====
:SUCCESS_END
echo.
pause
exit /b 0

:ERROR_END
echo.
echo   Update-Check abgeschlossen
echo   Kein Problem - du kannst das Tool trotzdem normal verwenden!
echo.
echo   Beliebige Taste zum Fortfahren...
pause >nul
exit /b 1

REM ===== TIMESTAMP VERGLEICHSFUNKTION =====
:COMPARE_TIMESTAMPS
set "TS1=%~1"
set "TS2=%~2"
set "CT_RESULT_VAR=%~3"

set "TS1=%TS1:"=%"
set "TS2=%TS2:"=%"

call :STRING_LENGTH "!TS1!" LEN1
call :STRING_LENGTH "!TS2!" LEN2

if !LEN1! NEQ !LEN2! (
    set "%CT_RESULT_VAR%=ERROR"
    goto :EOF
)

set /a MAX_IDX=!LEN1!-1

for /L %%i in (0,1,!MAX_IDX!) do (
    call set "CHAR1=%%TS1:~%%i,1%%"
    call set "CHAR2=%%TS2:~%%i,1%%"

    if !CHAR1! GTR !CHAR2! (
        set "%CT_RESULT_VAR%=NEWER"
        goto :EOF
    )
    if !CHAR1! LSS !CHAR2! (
        set "%CT_RESULT_VAR%=OLDER"
        goto :EOF
    )
)

set "%CT_RESULT_VAR%=EQUAL"
goto :EOF

:STRING_LENGTH
set "STR=%~1"
set "SL_LEN_VAR=%~2"
set "SL_LEN=0"
:STRING_LENGTH_LOOP
if defined STR (
    set "STR=!STR:~1!"
    set /a SL_LEN+=1
    goto :STRING_LENGTH_LOOP
)
set "%SL_LEN_VAR%=%SL_LEN%"
goto :EOF

REM ===== ROOT-VERZEICHNIS FINDER (100% SICHER) =====
:FIND_ROOT_DIRECTORY
set "FRD_RESULT_VAR=%~1"
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
set "%FRD_RESULT_VAR%=!FOUND_ROOT!"
goto :EOF

:FOUND_ROOT_FAILED
set "%FRD_RESULT_VAR%="
goto :EOF

:VALIDATE_ROOT_DIR
set "VRD_TEST_DIR=%~1"
set "VRD_RESULT_VAR=%~2"

if not exist "!VRD_TEST_DIR!" (
    set "%VRD_RESULT_VAR%=NO"
    goto :EOF
)

if not exist "!VRD_TEST_DIR!\config" (
    set "%VRD_RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!VRD_TEST_DIR!\config\version.txt" (
    set "%VRD_RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!VRD_TEST_DIR!\Launcher" (
    set "%VRD_RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!VRD_TEST_DIR!\modules" (
    set "%VRD_RESULT_VAR%=NO"
    goto :EOF
)

set "%VRD_RESULT_VAR%=YES"
goto :EOF
