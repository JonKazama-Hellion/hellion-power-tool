@echo off
setlocal enabledelayedexpansion
title Git Installation v7.2.0.0
color 0E

echo.
echo   ================================================================
echo          GIT INSTALLATION v7.2.0.0
echo          Hellion Online Media
echo   ================================================================
echo.

echo   Erweiterte Git Erkennung...

REM Multi-Level Git Detection (umfassend)
set "GIT_FOUND=0"
set "GIT_PATH_OK=0"
set "GIT_VERSION="
set "GIT_LOCATION="

REM Test 1: PATH-Verfuegbarkeit
where git >nul 2>&1
if %errorlevel%==0 (
    set "GIT_FOUND=1"
    set "GIT_PATH_OK=1"
    echo   [OK] Git via PATH verfuegbar
    for /f "delims=" %%v in ('git --version 2^>nul') do set "GIT_VERSION=%%v"
    if not "!GIT_VERSION!"=="" (
        echo   Version: !GIT_VERSION!
    )
    for /f "delims=" %%p in ('where git 2^>nul') do (
        set "GIT_LOCATION=%%p"
        echo   Pfad: !GIT_LOCATION!
        goto :git_path_found
    )
    :git_path_found
) else (
    echo   Git nicht im PATH
)

REM Test 2: Standard-Installation (Program Files)
if exist "C:\Program Files\Git\bin\git.exe" (
    set "GIT_FOUND=1"
    set "GIT_LOCATION=C:\Program Files\Git\bin\git.exe"
    echo   [OK] Git gefunden: C:\Program Files\Git\
    if "!GIT_PATH_OK!"=="0" (
        echo   Git installiert aber nicht im PATH
    )
)

REM Test 3: Program Files (x86)
if exist "C:\Program Files (x86)\Git\bin\git.exe" (
    set "GIT_FOUND=1"
    if "!GIT_LOCATION!"=="" set "GIT_LOCATION=C:\Program Files (x86)\Git\bin\git.exe"
    echo   [OK] Git gefunden: C:\Program Files (x86)\Git\
)

REM Test 4: GitHub Desktop Git
if exist "%LOCALAPPDATA%\GitHubDesktop\app-*\resources\app\git\cmd\git.exe" (
    set "GIT_FOUND=1"
    echo   [OK] GitHub Desktop Git gefunden
)

REM Test 5: Git for Windows Portable
for %%d in (C D E F G H) do (
    if exist "%%d:\Git\bin\git.exe" (
        set "GIT_FOUND=1"
        echo   [OK] Git Portable: %%d:\Git\
    )
    if exist "%%d:\PortableGit\bin\git.exe" (
        set "GIT_FOUND=1"
        echo   [OK] Git Portable: %%d:\PortableGit\
    )
)

REM Test 6: Alternative Pfade
for %%p in ("C:\Git\bin\git.exe" "C:\tools\Git\bin\git.exe" "%USERPROFILE%\Git\bin\git.exe") do (
    if exist %%p (
        set "GIT_FOUND=1"
        echo   [OK] Git gefunden: %%p
    )
)

REM Test 7: Visual Studio Git
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe" (
    set "GIT_FOUND=1"
    echo   [OK] Visual Studio Git gefunden
)

echo.
if "!GIT_FOUND!"=="1" (
    if "!GIT_PATH_OK!"=="1" (
        echo   Status: Git ist vollstaendig funktionsfaehig
        if not "!GIT_VERSION!"=="" (
            echo   !GIT_VERSION!
        )
    ) else (
        echo   Status: Git installiert aber nicht optimal konfiguriert
        echo   Git gefunden aber nicht im PATH
    )
    echo.
    echo   Trotzdem neu installieren/updaten?
    echo   [J] Ja, neueste Version installieren (empfohlen)
    echo   [N] Nein, aktuelle Installation beibehalten
    echo   [P] PATH reparieren (Git zur Umgebung hinzufuegen)
    echo.
    choice /c JNP /n /m "   Option waehlen [J/N/P]: "
    if errorlevel 3 (
        echo.
        echo   PATH-Reparatur...
        if "!GIT_LOCATION!"=="" (
            echo   [ERROR] Git-Pfad konnte nicht bestimmt werden
            echo   Installiere Git neu fuer automatische PATH-Konfiguration
            goto :start_installation
        ) else (
            for %%i in ("!GIT_LOCATION!") do set "GIT_DIR=%%~dpi"
            set "GIT_DIR=!GIT_DIR:~0,-1!"
            echo   Git-Verzeichnis: !GIT_DIR!
            echo   PATH-Reparatur erfordert Administrator-Rechte
            echo   [WARNING] Diese Funktion ist experimentell - Installation empfohlen
            pause
            goto :END
        )
    )
    if errorlevel 2 goto :END
) else (
    echo   Status: Git ist nicht installiert
    echo   Installation wird gestartet...
)
echo.

:start_installation
echo   Pruefe winget Verfuegbarkeit...
where winget >nul 2>&1
if not %errorlevel%==0 (
    echo   [ERROR] winget ist nicht verfuegbar!
    echo   winget wird fuer die Installation benoetigt
    echo.
    echo   Installiere winget via:
    echo   - Microsoft Store: "App Installer"
    echo   - Oder direkt von GitHub: aka.ms/getwinget
    echo.
    echo   Alternative - Manuelle Git Installation:
    echo   - https://git-scm.com/download/win
    echo   - GitHub Desktop: https://desktop.github.com/
    echo.
    goto :END
)

echo   [OK] winget ist verfuegbar
echo.

echo   Starte Git Installation...
echo   Das kann 2-5 Minuten dauern...
echo   Waehle bei Nachfragen: Standard-Einstellungen
echo.

REM Installiere Git mit optimalen Einstellungen
winget install Git.Git --accept-source-agreements --accept-package-agreements --silent

set "INSTALL_RESULT=%errorlevel%"

if %INSTALL_RESULT%==0 (
    echo.
    echo   [OK] Git Installation abgeschlossen!
    echo.
    echo   Verifikation...

    REM Warte auf Windows PATH-Update
    timeout /t 5 /nobreak >nul

    set "INSTALL_SUCCESS=0"

    REM Test 1: PATH-Verfuegbarkeit nach Installation
    where git >nul 2>&1
    if %errorlevel%==0 (
        echo   [OK] Git via PATH verfuegbar
        for /f "delims=" %%v in ('git --version 2^>nul') do echo   Version: %%v
        set "INSTALL_SUCCESS=1"

        REM Teste Git-Funktionalitaet
        git config --global --get user.name >nul 2>&1
        if %errorlevel%==0 (
            for /f "delims=" %%u in ('git config --global --get user.name 2^>nul') do echo   Git User: %%u
        ) else (
            echo   Git noch nicht konfiguriert (normal nach Installation)
        )
    ) else (
        echo   Git noch nicht im PATH (PATH-Update kann dauern)
    )

    REM Test 2: Standard-Installation pruefen
    if exist "C:\Program Files\Git\bin\git.exe" (
        echo   [OK] Git in Standard-Pfad installiert
        set "INSTALL_SUCCESS=1"

        REM Teste direkt ueber Pfad
        if "!INSTALL_SUCCESS!"=="0" (
            "C:\Program Files\Git\bin\git.exe" --version >nul 2>&1
            if %errorlevel%==0 (
                for /f "delims=" %%v in ('"C:\Program Files\Git\bin\git.exe" --version 2^>nul') do echo   Direkt-Test: %%v
                set "INSTALL_SUCCESS=1"
            )
        )
    )

    REM Test 3: Program Files (x86)
    if exist "C:\Program Files (x86)\Git\bin\git.exe" (
        echo   [OK] Git (x86) installiert
        set "INSTALL_SUCCESS=1"
    )

    echo.
    if "!INSTALL_SUCCESS!"=="1" (
        echo   Installation erfolgreich verifiziert!
        echo.
        echo   Naechste Schritte:
        echo   1. Schliesse diese Konsole komplett
        echo   2. Oeffne neue Konsole (wichtig fuer PATH-Update)
        echo   3. Git wird automatisch erkannt und verwendet
        echo.
        echo   Erstmalige Konfiguration (optional):
        echo     git config --global user.name "Dein Name"
        echo     git config --global user.email "deine@email.com"
        echo.
        echo   Falls Git nicht erkannt wird:
        echo   - Computer neu starten (PATH-Update)
        echo   - Git Bash verwenden: "C:\Program Files\Git\git-bash.exe"
    ) else (
        echo   [WARNING] Verifikation teilweise fehlgeschlagen
        echo   Git ist moeglicherweise installiert aber noch nicht verfuegbar
        echo   Computer neu starten oder neue Konsole oeffnen
    )
) else (
    echo.
    echo   [ERROR] Installation fehlgeschlagen! (Exit Code: !INSTALL_RESULT!)
    echo.
    echo   Moegliche Ursachen:
    echo   1. Als Administrator starten (Rechtsklick)
    echo   2. Internetverbindung pruefen
    echo   3. Windows Updates installieren
    echo   4. Firewall/Antivirus temporaer deaktivieren
    echo   5. Mindestens 1GB freien Speicherplatz schaffen
    echo.
    echo   Alternative - Manuelle Installation:
    echo   - Git for Windows: https://git-scm.com/download/win
    echo   - GitHub Desktop: https://desktop.github.com/
)

:END
echo.
echo   Git wird fuer GitHub-Operations im Hellion Tool benoetigt
echo   Ohne Git funktionieren Update-Checker und Emergency-Updater nicht
echo.
pause
