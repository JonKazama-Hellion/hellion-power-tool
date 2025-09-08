@echo off
setlocal enabledelayedexpansion
title Hellion Update Checker
color 0C


echo ==============================================================================
echo                    HELLION UPDATE CHECKER MODULE
echo ==============================================================================
echo.

echo [*] Pruefe Update-Status...

REM Lade aktuelle Version
if not exist "config\version.txt" (
    echo [ERROR] version.txt nicht gefunden!
    echo [LÖSUNG] Stelle sicher dass du im richtigen Verzeichnis bist
    goto :END
)

REM Lese lokale Version
set "LINE_NUM=0"
for /f "delims=" %%a in (config\version.txt) do (
    set /a LINE_NUM+=1
    if !LINE_NUM!==1 set "LOCAL_VERSION=%%a"
    if !LINE_NUM!==2 set "LOCAL_CODENAME=%%a"
    if !LINE_NUM!==3 set "LOCAL_DATE=%%a"
)

echo [INFO] Aktuelle Version: %LOCAL_VERSION% "%LOCAL_CODENAME%" (%LOCAL_DATE%)
echo.

REM Prüfe Git Verfügbarkeit
echo [*] Pruefe Git Verfuegbarkeit...

git --version >nul 2>&1
if errorlevel 1 goto :NO_GIT

echo [OK] Git ist verfuegbar
goto :GIT_AVAILABLE

:NO_GIT
echo [INFO] Git ist nicht verfuegbar
echo [INFO] Git wird fuer Update-Check benoetigt
echo.
echo [ANGEBOT] Git jetzt installieren?
echo   [J] Ja, installiere Git (empfohlen)
echo   [N] Nein, ueberspringe Update-Check
echo.
choice /c JN /n /m "Git installieren? [J/N]: "
if errorlevel 2 (
    echo [INFO] Update-Check uebersprungen
    goto :END
)
echo.
echo [INSTALL] Starte Git Installation...
call :INSTALL_GIT
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git Installation fehlgeschlagen
    goto :END
)
echo [SUCCESS] Git ist jetzt verfuegbar!

:GIT_AVAILABLE
echo.

REM Erstelle temporaeres Verzeichnis fuer GitHub Check
set "TEMP_DIR=%TEMP%\hellion_update_check_%RANDOM%"
mkdir "%TEMP_DIR%" >nul 2>&1

echo [*] Lade GitHub Version...
cd /d "%TEMP_DIR%"

git clone --depth 1 https://github.com/JonKazama-Hellion/hellion-power-tool.git hellion-temp >nul 2>&1
set "CLONE_RESULT=%errorlevel%"

if %CLONE_RESULT% neq 0 (
    echo [ERROR] GitHub Version konnte nicht geladen werden
    echo [INFO] Moegliche Ursachen:
    echo   - Keine Internetverbindung
    echo   - Repository nicht erreichbar  
    echo   - Git Authentifizierung erforderlich
    cd /d "%~dp0"
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
    goto :END
)

if not exist "hellion-temp\config\version.txt" (
    echo [ERROR] version.txt nicht im geclonten Repository gefunden
    echo [INFO] Repository-Struktur moeglicherweise geaendert
    cd /d "%~dp0"
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
    goto :END
)

REM Lese GitHub Version
set "GITHUB_VERSION="
set "GITHUB_CODENAME="  
set "GITHUB_DATE="

set /p GITHUB_VERSION=<hellion-temp\config\version.txt
for /f "skip=1 delims=" %%a in (hellion-temp\config\version.txt) do if not defined GITHUB_CODENAME set "GITHUB_CODENAME=%%a"
for /f "skip=2 delims=" %%a in (hellion-temp\config\version.txt) do if not defined GITHUB_DATE set "GITHUB_DATE=%%a"

echo [INFO] GitHub Version: %GITHUB_VERSION% "%GITHUB_CODENAME%" (%GITHUB_DATE%)
echo.

REM Cleanup
cd /d "%~dp0"
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

REM Version Vergleich
echo [*] Vergleiche Versionen...

set "UPDATE_NEEDED=0"
set "UPDATE_REASON="

REM Bekannte Codenamen (chronologisch, älteste zuerst)
set "KNOWN_CODENAMES=Alpha Beta Gamma Delta Epsilon Kazama Beleandis Monkey Moon Moon-Bugfix Fenrir"

REM Prüfe ob GitHub Codename in der bekannten Liste ist
set "GITHUB_KNOWN=0"
echo %KNOWN_CODENAMES% | findstr /C:"%GITHUB_CODENAME%" >nul
if not errorlevel 1 set "GITHUB_KNOWN=1"

if %GITHUB_KNOWN%==0 (
    echo [INFO] Unbekannter GitHub Codename: %GITHUB_CODENAME%
    echo [INFO] Ueberspringe Update-Check - moeglicherweise Entwicklungsversion
    goto :NO_UPDATE
)

REM Intelligenter Version/Datum Check mit Fallback
echo [DEBUG] LOCAL_DATE=%LOCAL_DATE% GITHUB_DATE=%GITHUB_DATE%

REM Handle empty dates gracefully  
if "%LOCAL_DATE%"=="" set "LOCAL_DATE=20250901"
if "%GITHUB_DATE%"=="" set "GITHUB_DATE=20250908"

REM Validate dates are numeric (fix for v7.1.0/7.1.1 compatibility)
set "DATE_COMPARISON_ERROR=0"
echo %LOCAL_DATE%| findstr /R "^[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Lokales Datum ungueltig: '%LOCAL_DATE%' - verwende Fallback
    set "LOCAL_DATE=20250901"
    set "DATE_COMPARISON_ERROR=1"
)

echo %GITHUB_DATE%| findstr /R "^[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 (
    echo [WARNING] GitHub Datum ungueltig: '%GITHUB_DATE%' - verwende Fallback
    set "GITHUB_DATE=20250908"
    set "DATE_COMPARISON_ERROR=1"
)

REM Safe numeric comparison with robust error handling
if %DATE_COMPARISON_ERROR%==0 (
    if %LOCAL_DATE% LSS %GITHUB_DATE% (
        echo [UPDATE] Lokales Datum aelter: %LOCAL_DATE% vs %GITHUB_DATE%
        set "UPDATE_NEEDED=1"
        set "UPDATE_REASON=Datum aelter"
    )
) else (
    echo [INFO] Datum-Vergleich uebersprungen - verwende Version-basierte Entscheidung
)

REM Zusätzlicher Plausibilitäts-Check: Version unterschiedlich UND GitHub neuer
if not "%LOCAL_VERSION%"=="%GITHUB_VERSION%" (
    REM Sichere Datum-Vergleich nur wenn beide Daten gültig sind
    if %DATE_COMPARISON_ERROR%==0 (
        if %LOCAL_DATE% LSS %GITHUB_DATE% (
            echo [UPDATE] Verschiedene Versionen mit neuerem GitHub Datum
            if "%UPDATE_REASON%"=="" (
                set "UPDATE_REASON=Version unterschiedlich, GitHub neuer"
                set "UPDATE_NEEDED=1"
            ) else (
                set "UPDATE_REASON=%UPDATE_REASON%, Version unterschiedlich"
            )
        ) else (
            echo [INFO] Verschiedene Versionen aber lokales Datum neuer oder gleich
            echo [INFO] Vermutlich Entwicklungsversion - kein Update noetig
            goto :NO_UPDATE
        )
    ) else (
        REM Fallback: Bei unterschiedlichen Versionen und ungültigen Daten -> Update empfehlen
        echo [UPDATE] Version unterschiedlich und Datum-Vergleich nicht moeglich
        set "UPDATE_NEEDED=1"
        set "UPDATE_REASON=Version unterschiedlich (Datum unbekannt)"
    )
)

echo.

if "%UPDATE_NEEDED%"=="1" (
    echo ==============================================================================
    echo                            UPDATE VERFUEGBAR!
    echo ==============================================================================
    echo.
    echo [GRUND] %UPDATE_REASON%
    echo.
    echo [EMPFEHLUNG] Lade die neueste Version von GitHub herunter:
    echo   https://github.com/JonKazama-Hellion/hellion-power-tool/releases/latest
    echo.
    echo [HINWEIS] Automatisches Update folgt in einer spaeteren Version
) else (
    echo [OK] Du hast die neueste Version!
)
goto :END

:NO_UPDATE
echo [OK] Kein Update erforderlich - du hast eine aktuelle oder neuere Version!
goto :END

:INSTALL_GIT
echo [*] Pruefe winget Verfuegbarkeit...
where winget >nul 2>&1
if not %errorlevel%==0 (
    echo [ERROR] winget ist nicht verfuegbar!
    echo [INFO] winget wird fuer die Installation benoetigt
    echo.
    echo [LOESUNG] Installiere winget via:
    echo   - Microsoft Store: "App Installer"
    echo   - Oder direkt von GitHub: aka.ms/getwinget
    echo.
    exit /b 1
)

echo [OK] winget ist verfuegbar
echo.
echo [INSTALL] Starte Git Installation...
echo [INFO] Das kann 1-3 Minuten dauern...
echo.

winget install Git.Git --accept-source-agreements --accept-package-agreements

if %errorlevel%==0 (
    echo.
    echo [SUCCESS] Git Installation abgeschlossen!
    echo [INFO] Neustart der Konsole erforderlich
) else (
    echo.
    echo [ERROR] Git Installation fehlgeschlagen!
)
exit /b %errorlevel%

:END
echo.
pause