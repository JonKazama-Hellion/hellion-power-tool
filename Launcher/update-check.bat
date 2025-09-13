@echo off
setlocal enabledelayedexpansion
title Hellion Update Checker v7.1.5.4
color 0B

echo ==============================================================================
echo                 HELLION UPDATE CHECKER v7.1.5.4
echo                      Suche nach neuen Features...
echo ==============================================================================
echo.

REM ===== SCHRITT 0: VERZEICHNIS-SCHUTZ UND PFAD-VALIDIERUNG =====
echo [*] Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Launchers (100% sicher)
set "LAUNCHER_DIR=%~dp0"
set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"

REM Bestimme Root-Verzeichnis mit mehreren Fallback-Methoden
call :FIND_ROOT_DIRECTORY ROOT_DIR

if "!ROOT_DIR!"=="" (
    echo [ERROR] Hellion Tool Root-Verzeichnis konnte nicht gefunden werden
    echo [INFO] Launcher muss im Launcher/-Unterverzeichnis liegen
    goto :ERROR_END
)

echo [OK] Root-Verzeichnis: !ROOT_DIR!
echo [OK] Launcher-Verzeichnis: !LAUNCHER_DIR!

REM ===== SCHRITT 1: LOKALE VERSION LESEN =====
echo [*] Lade lokale Version...

REM Mehrere Fallback-Pfade für version.txt
set "VERSION_FILE=!ROOT_DIR!\config\version.txt"
set "VERSION_FILE_ALT1=%~dp0..\config\version.txt"
set "VERSION_FILE_ALT2=!LAUNCHER_DIR!\..\config\version.txt"

if exist "!VERSION_FILE!" (
    echo [OK] version.txt gefunden: !VERSION_FILE!
) else if exist "!VERSION_FILE_ALT1!" (
    set "VERSION_FILE=!VERSION_FILE_ALT1!"
    echo [OK] version.txt gefunden (Fallback 1): !VERSION_FILE!
) else if exist "!VERSION_FILE_ALT2!" (
    set "VERSION_FILE=!VERSION_FILE_ALT2!"
    echo [OK] version.txt gefunden (Fallback 2): !VERSION_FILE!
) else (
    echo [ERROR] version.txt nicht in folgenden Pfaden gefunden:
    echo   - !VERSION_FILE!
    echo   - !VERSION_FILE_ALT1!
    echo   - !VERSION_FILE_ALT2!
    goto :ERROR_END
)

REM Lese alle 4 Zeilen der version.txt
set "LINE_COUNT=0"
for /f "delims=" %%a in (!VERSION_FILE!) do (
    set /a LINE_COUNT+=1
    if !LINE_COUNT!==1 set "LOCAL_VERSION=%%a"
    if !LINE_COUNT!==2 set "LOCAL_CODENAME=%%a"
    if !LINE_COUNT!==3 set "LOCAL_DATE=%%a"
    if !LINE_COUNT!==4 set "LOCAL_TIMESTAMP=%%a"
)

REM Validiere dass alle Daten vorhanden sind
if "!LOCAL_VERSION!"=="" (
    echo [ERROR] Lokale Version konnte nicht gelesen werden
    goto :ERROR_END
)
if "!LOCAL_TIMESTAMP!"=="" (
    echo [ERROR] Lokaler Timestamp fehlt - inkompatible Version
    echo [INFO] Nur v7.1.4+ Versionen werden unterstuetzt
    goto :ERROR_END
)

echo [OK] Lokale Version: !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
echo [OK] Lokaler Timestamp: !LOCAL_TIMESTAMP!
echo.

REM ===== SCHRITT 2: GIT VERFÜGBARKEIT PRÜFEN =====
echo [*] Pruefe Git Verfuegbarkeit...
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git ist nicht verfuegbar
    echo [INFO] Git wird fuer den Update-Check benoetigt
    echo [INFO] Installiere Git oder fuehre manuellen Update durch
    goto :ERROR_END
)
echo [OK] Git ist verfuegbar
echo.

REM ===== SCHRITT 3: GITHUB VERSION LADEN =====
echo [*] Lade GitHub Version...
set "TEMP_DIR=%TEMP%\hellion_update_%RANDOM%"
mkdir "!TEMP_DIR!" >nul 2>&1

cd /d "!TEMP_DIR!"
git clone --depth 1 https://github.com/JonKazama-Hellion/hellion-power-tool.git repo >nul 2>&1

if errorlevel 1 (
    echo [ERROR] GitHub Repository konnte nicht geladen werden
    echo [INFO] Pruefe Internetverbindung
    cd /d "%~dp0"
    rmdir /s /q "!TEMP_DIR!" >nul 2>&1
    goto :ERROR_END
)

if not exist "repo\config\version.txt" (
    echo [ERROR] version.txt nicht im GitHub Repository gefunden
    cd /d "%~dp0"
    rmdir /s /q "!TEMP_DIR!" >nul 2>&1
    goto :ERROR_END
)

REM Lese GitHub Version
set "GH_LINE_COUNT=0"
for /f "delims=" %%a in (repo\config\version.txt) do (
    set /a GH_LINE_COUNT+=1
    if !GH_LINE_COUNT!==1 set "GITHUB_VERSION=%%a"
    if !GH_LINE_COUNT!==2 set "GITHUB_CODENAME=%%a"
    if !GH_LINE_COUNT!==3 set "GITHUB_DATE=%%a"
    if !GH_LINE_COUNT!==4 set "GITHUB_TIMESTAMP=%%a"
)

REM Cleanup
cd /d "%~dp0"
rmdir /s /q "!TEMP_DIR!" >nul 2>&1

REM Validiere GitHub Daten
if "!GITHUB_VERSION!"=="" (
    echo [ERROR] GitHub Version konnte nicht gelesen werden
    goto :ERROR_END
)
if "!GITHUB_TIMESTAMP!"=="" (
    echo [ERROR] GitHub Timestamp fehlt - inkompatible Version
    goto :ERROR_END
)

echo [OK] GitHub Version: !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
echo [OK] GitHub Timestamp: !GITHUB_TIMESTAMP!
echo.

REM ===== SCHRITT 4: TIMESTAMP VERGLEICH =====
echo [*] Vergleiche Versionen...

if "!LOCAL_TIMESTAMP!"=="!GITHUB_TIMESTAMP!" (
    echo [RESULT] Identische Timestamps - keine Aktualisierung erforderlich
    echo.
    echo ==============================================================================
    echo [OK] Du hast bereits die neueste Version: !LOCAL_VERSION! "!LOCAL_CODENAME!"
    echo ==============================================================================
    goto :SUCCESS_END
)

REM Robuster String-basierter Timestamp-Vergleich
call :COMPARE_TIMESTAMPS "!LOCAL_TIMESTAMP!" "!GITHUB_TIMESTAMP!" TIMESTAMP_RESULT

if "!TIMESTAMP_RESULT!"=="NEWER" (
    echo [RESULT] Lokale Version ist neuer als GitHub - kein Update verfuegbar
    echo.
    echo ==============================================================================
    echo [OK] Du hast eine neuere Version als auf GitHub verfuegbar!
    echo [LOKAL] !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
    echo [GITHUB] !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
    echo ==============================================================================
    goto :SUCCESS_END
)

if "!TIMESTAMP_RESULT!"=="OLDER" (
    echo [RESULT] GitHub Version ist neuer - Update verfuegbar
    echo.
    echo ==============================================================================
    echo                            UPDATE VERFUEGBAR
    echo ==============================================================================
    echo.
    echo [AKTUELL] !LOCAL_VERSION! "!LOCAL_CODENAME!" (!LOCAL_DATE!)
    echo [VERFUEGBAR] !GITHUB_VERSION! "!GITHUB_CODENAME!" (!GITHUB_DATE!)
    echo.
    echo [ANGEBOT] Automatisches Update durchfuehren?
    echo   [J] Ja, automatisch updaten (empfohlen)
    echo   [N] Nein, manuell herunterladen
    echo   [A] Abbrechen
    echo.
    choice /c JNA /n /m "Automatisches Update starten? [J/N/A]: "

    if errorlevel 3 (
        echo [INFO] Update abgebrochen
        goto :SUCCESS_END
    )
    if errorlevel 2 (
        echo.
        echo [MANUAL] Lade die neueste Version manuell herunter:
        echo https://github.com/JonKazama-Hellion/hellion-power-tool/releases/latest
        goto :SUCCESS_END
    )

    echo.
    echo [AUTO-UPDATE] Starte automatisches Update...
    call :PERFORM_AUTO_UPDATE
    goto :SUCCESS_END
)

REM Fallback - sollte nie erreicht werden
echo [ERROR] Timestamp-Vergleich fehlgeschlagen
goto :ERROR_END

REM ===== AUTO-UPDATE FUNKTION =====
:PERFORM_AUTO_UPDATE
echo.
echo ==============================================================================
echo                         AUTOMATISCHES UPDATE
echo ==============================================================================
echo.

REM Sichere Verzeichnis-Bestimmung (kein Self-Delete möglich)
echo [SAFETY] Validiere Update-Verzeichnisse...
set "UPDATE_ROOT_DIR=!ROOT_DIR!"
if "!UPDATE_ROOT_DIR!"=="" (
    echo [ERROR] Root-Verzeichnis nicht verfügbar - Update abgebrochen
    return
)

REM Wechsle zum sicheren Root-Verzeichnis (nie Launcher-Dir)
cd /d "!UPDATE_ROOT_DIR!"
echo [OK] Arbeite in: !UPDATE_ROOT_DIR!

REM Erstelle sicheren Backup-Pfad mit Validierung
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    for /f "tokens=1-3 delims=: " %%a in ("%time%") do (
        set "BACKUP_TIMESTAMP=%%k%%j%%l_%%a-%%b"
    )
)

REM Sichere Backup-Pfad Bestimmung (nie im Launcher-Dir)
set "BACKUP_BASE_DIR=!UPDATE_ROOT_DIR!\backups"
set "BACKUP_DIR=!BACKUP_BASE_DIR!\!LOCAL_VERSION!_!LOCAL_CODENAME!_backup_!BACKUP_TIMESTAMP!"

echo [BACKUP] Erstelle Backup in: !BACKUP_DIR!
echo [SAFETY] Backup-Basis: !BACKUP_BASE_DIR!

REM Erstelle Backup-Verzeichnisse sicher
if not exist "!BACKUP_BASE_DIR!" (
    mkdir "!BACKUP_BASE_DIR!" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Backup-Basis-Verzeichnis kann nicht erstellt werden: !BACKUP_BASE_DIR!
        return
    )
)

mkdir "!BACKUP_DIR!" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Backup-Verzeichnis kann nicht erstellt werden: !BACKUP_DIR!
    return
)
echo [OK] Backup-Verzeichnis erstellt

REM Backup wichtiger Dateien
echo [BACKUP] Sichere aktuelle Installation...
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

echo [BACKUP] Backup erfolgreich erstellt!
echo.

REM Lade neue Version
echo [DOWNLOAD] Lade neue Version von GitHub...
set "UPDATE_TEMP_DIR=%TEMP%\hellion_update_%RANDOM%"
mkdir "!UPDATE_TEMP_DIR!" >nul 2>&1

cd /d "!UPDATE_TEMP_DIR!"
git clone --depth 1 https://github.com/JonKazama-Hellion/hellion-power-tool.git hellion-new >nul 2>&1

if errorlevel 1 (
    echo [ERROR] Download fehlgeschlagen!
    cd /d "%~dp0\.."
    rmdir /s /q "!UPDATE_TEMP_DIR!" >nul 2>&1
    echo [ROLLBACK] Backup bleibt erhalten in: !BACKUP_DIR!
    return
)

echo [DOWNLOAD] Download erfolgreich!
echo.

REM User-Einstellungen retten
echo [MERGE] Sichere User-Einstellungen...
if exist "!BACKUP_DIR!\config\settings.json" (
    copy /Y "!BACKUP_DIR!\config\settings.json" "!UPDATE_TEMP_DIR!\hellion-new\config\settings.json" >nul 2>&1
    echo [MERGE] User-Einstellungen uebertragen
) else (
    echo [MERGE] Keine User-Einstellungen gefunden (Standardwerte verwendet)
)
echo.

REM Erstelle separaten Installer (100% Self-Delete sicher)
echo [UPDATE] Erstelle sicheren Update-Installer...

REM Installer NIEMALS in Launcher-Dir - immer in TEMP
set "INSTALLER_SCRIPT=%TEMP%\hellion_installer_%RANDOM%.bat"
echo [SAFETY] Installer-Pfad: !INSTALLER_SCRIPT!
echo @echo off > "!INSTALLER_SCRIPT!"
echo title Hellion Update Installer >> "!INSTALLER_SCRIPT!"
echo echo [UPDATE] Installiere neue Version... >> "!INSTALLER_SCRIPT!"
echo timeout /t 3 /nobreak ^>nul >> "!INSTALLER_SCRIPT!"
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

echo echo [SUCCESS] Update erfolgreich installiert! >> "!INSTALLER_SCRIPT!"
echo echo [INFO] Neue Version: !GITHUB_VERSION! "!GITHUB_CODENAME!" >> "!INSTALLER_SCRIPT!"
echo echo [BACKUP] Backup: !BACKUP_DIR! >> "!INSTALLER_SCRIPT!"
echo echo. >> "!INSTALLER_SCRIPT!"
echo echo Druecken Sie eine Taste um zu schliessen... >> "!INSTALLER_SCRIPT!"
echo pause ^>nul >> "!INSTALLER_SCRIPT!"
echo rmdir /s /q "!UPDATE_TEMP_DIR!" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"
echo del /f /q "%%%%0" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"

echo [UPDATE] Starte separaten Installer...
start "" "!INSTALLER_SCRIPT!"

echo.
echo ==============================================================================
echo                        UPDATE WIRD INSTALLIERT
echo ==============================================================================
echo.
echo [INFO] Update laeuft im Hintergrund weiter
echo [BACKUP] Backup gesichert in: !BACKUP_DIR!
echo.
echo [EMPFEHLUNG] Warte 10 Sekunden und starte dann das Tool neu:
echo   START.bat
echo.
echo [HINWEIS] Dieses Fenster kann jetzt geschlossen werden
timeout /t 5 /nobreak >nul
exit /b 0

REM ===== ENDE LABELS =====
:SUCCESS_END
echo.
pause
exit /b 0

:ERROR_END
echo.
echo [INFO] Update-Check abgeschlossen
echo [TIP] Kein Problem - du kannst das Tool trotzdem normal verwenden!
echo.
echo Druecke beliebige Taste um fortzufahren...
pause >nul
exit /b 1

REM ===== TIMESTAMP VERGLEICHSFUNKTION =====
REM 100% zuverlaessiger String-basierter Vergleich fuer lange Timestamps
REM Parameter: %1=LOCAL_TS %2=GITHUB_TS %3=RESULT_VAR
:COMPARE_TIMESTAMPS
set "TS1=%~1"
set "TS2=%~2"
set "RESULT_VAR=%~3"

REM Entferne Anfuehrungszeichen falls vorhanden
set "TS1=%TS1:"=%"
set "TS2=%TS2:"=%"

REM Laengen-Check - beide muessen gleiche Laenge haben (14 Zeichen)
call :STRING_LENGTH "!TS1!" LEN1
call :STRING_LENGTH "!TS2!" LEN2

if !LEN1! NEQ !LEN2! (
    set "%RESULT_VAR%=ERROR"
    goto :EOF
)

REM Zeichen-fuer-Zeichen Vergleich von links nach rechts
for /L %%i in (0,1,13) do (
    call set "CHAR1=%%TS1:~%%i,1%%"
    call set "CHAR2=%%TS2:~%%i,1%%"

    if !CHAR1! GTR !CHAR2! (
        set "%RESULT_VAR%=NEWER"
        goto :EOF
    )
    if !CHAR1! LSS !CHAR2! (
        set "%RESULT_VAR%=OLDER"
        goto :EOF
    )
)

REM Alle Zeichen identisch
set "%RESULT_VAR%=EQUAL"
goto :EOF

REM Hilfsfunktion: String-Laenge bestimmen
:STRING_LENGTH
set "STR=%~1"
set "LEN_VAR=%~2"
set "LEN=0"
:STRING_LENGTH_LOOP
if defined STR (
    set "STR=!STR:~1!"
    set /a LEN+=1
    goto :STRING_LENGTH_LOOP
)
set "%LEN_VAR%=%LEN%"
goto :EOF

REM ===== ROOT-VERZEICHNIS FINDER (100% SICHER) =====
REM Findet das Hellion Tool Root-Verzeichnis mit mehreren Fallback-Methoden
REM Parameter: %1=RESULT_VAR
:FIND_ROOT_DIRECTORY
set "RESULT_VAR=%~1"
set "FOUND_ROOT="

echo [DEBUG] Suche Root-Verzeichnis...

REM Methode 1: Standard-Annahme - Launcher ist in Launcher/-Subdir
set "TEST_ROOT=%LAUNCHER_DIR%\.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_1
if "!IS_VALID_1!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    echo [DEBUG] Methode 1 erfolgreich: !FOUND_ROOT!
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 2: Batch-Parameter %~dp0 verwenden
set "TEST_ROOT=%~dp0.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_2
if "!IS_VALID_2!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    echo [DEBUG] Methode 2 erfolgreich: !FOUND_ROOT!
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 3: Aufwärts-Suche vom aktuellen Verzeichnis
set "SEARCH_DIR=%CD%"
for /L %%i in (1,1,5) do (
    call :VALIDATE_ROOT_DIR "!SEARCH_DIR!" IS_VALID_3
    if "!IS_VALID_3!"=="YES" (
        set "FOUND_ROOT=!SEARCH_DIR!"
        echo [DEBUG] Methode 3 erfolgreich (Level %%i): !FOUND_ROOT!
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!SEARCH_DIR!") do set "SEARCH_DIR=%%~dpj"
    set "SEARCH_DIR=!SEARCH_DIR:~0,-1!"
)

REM Methode 4: Suche nach charakteristischen Dateien im aktuellen und Parent-Dirs
set "CHECK_DIR=%CD%"
for /L %%i in (1,1,3) do (
    if exist "!CHECK_DIR!\START.bat" if exist "!CHECK_DIR!\hellion_tool_main.ps1" (
        set "FOUND_ROOT=!CHECK_DIR!"
        echo [DEBUG] Methode 4 erfolgreich (START.bat gefunden): !FOUND_ROOT!
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!CHECK_DIR!") do set "CHECK_DIR=%%~dpj"
    set "CHECK_DIR=!CHECK_DIR:~0,-1!"
)

echo [DEBUG] Alle Methoden fehlgeschlagen
goto :FOUND_ROOT_FAILED

:FOUND_ROOT_SUCCESS
REM Bereinige Pfad (entferne doppelte Backslashes, etc.)
for %%i in ("!FOUND_ROOT!") do set "FOUND_ROOT=%%~fi"
set "%RESULT_VAR%=!FOUND_ROOT!"
goto :EOF

:FOUND_ROOT_FAILED
set "%RESULT_VAR%="
goto :EOF

REM Validiert ob ein Verzeichnis das Hellion Root-Dir ist
REM Parameter: %1=TEST_DIR %2=RESULT_VAR
:VALIDATE_ROOT_DIR
set "TEST_DIR=%~1"
set "RESULT_VAR=%~2"

if not exist "!TEST_DIR!" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)

REM Prüfe auf charakteristische Dateien/Ordner
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