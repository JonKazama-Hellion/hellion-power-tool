@echo off
setlocal enabledelayedexpansion
title Hellion Update Checker v7.1.4.3
color 0C

echo ==============================================================================
echo                    HELLION UPDATE CHECKER v7.1.4.3
echo ==============================================================================
echo.

REM ===== SCHRITT 1: LOKALE VERSION LESEN =====
echo [*] Lade lokale Version...
set "VERSION_FILE=%~dp0..\config\version.txt"

if not exist "!VERSION_FILE!" (
    echo [ERROR] version.txt nicht gefunden: !VERSION_FILE!
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
) else (
    echo [RESULT] Unterschiedliche Timestamps - Update verfuegbar
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

REM ===== AUTO-UPDATE FUNKTION =====
:PERFORM_AUTO_UPDATE
echo.
echo ==============================================================================
echo                         AUTOMATISCHES UPDATE
echo ==============================================================================
echo.

REM Wechsle zum Root-Verzeichnis
cd /d "%~dp0\.."

REM Erstelle Backup mit Timestamp
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    for /f "tokens=1-3 delims=: " %%a in ("%time%") do (
        set "BACKUP_TIMESTAMP=%%k%%j%%l_%%a-%%b"
    )
)
set "BACKUP_DIR=backups\!LOCAL_VERSION!_!LOCAL_CODENAME!_backup_!BACKUP_TIMESTAMP!"

echo [BACKUP] Erstelle Backup in: !BACKUP_DIR!
mkdir "!BACKUP_DIR!" >nul 2>&1

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

REM Erstelle separaten Installer
cd /d "%~dp0\.."
echo [UPDATE] Erstelle Update-Installer...

set "INSTALLER_SCRIPT=%TEMP%\hellion_installer_%RANDOM%.bat"
echo @echo off > "!INSTALLER_SCRIPT!"
echo title Hellion Update Installer >> "!INSTALLER_SCRIPT!"
echo echo [UPDATE] Installiere neue Version... >> "!INSTALLER_SCRIPT!"
echo timeout /t 3 /nobreak ^>nul >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo REM Loesche alte Dateien (behalte backups) >> "!INSTALLER_SCRIPT!"
echo for /f %%%%i in ('dir /b /a-d 2^^^>nul ^^^| findstr /v /i "backup"') do del /f /q "%%%%i" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"
echo for /f %%%%i in ('dir /b /ad 2^^^>nul ^^^| findstr /v /i "backup"') do rmdir /s /q "%%%%i" ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"
echo. >> "!INSTALLER_SCRIPT!"

echo REM Kopiere neue Version >> "!INSTALLER_SCRIPT!"
echo xcopy /E /I /Q /Y "!UPDATE_TEMP_DIR!\hellion-new\*" "." ^>nul 2^>^&1 >> "!INSTALLER_SCRIPT!"
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
echo [ERROR] Update-Check konnte nicht durchgefuehrt werden
pause
exit /b 1