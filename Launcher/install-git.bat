@echo off
setlocal enabledelayedexpansion
title Git Installation v7.1.5.4
color 0E

echo ==============================================================================
echo                     GIT INSTALLATION MODULE v7.1.5.4
echo                       Robust und zuverlässig
echo ==============================================================================
echo.

echo [*] Erweiterte Git Erkennung...

REM Multi-Level Git Detection (umfassend)
set "GIT_FOUND=0"
set "GIT_PATH_OK=0"
set "GIT_VERSION="
set "GIT_LOCATION="

REM Test 1: PATH-Verfügbarkeit
where git >nul 2>&1
if %errorlevel%==0 (
    set "GIT_FOUND=1"
    set "GIT_PATH_OK=1"
    echo [OK] Git via PATH verfuegbar
    for /f "delims=" %%v in ('git --version 2^>nul') do set "GIT_VERSION=%%v"
    if not "!GIT_VERSION!"=="" (
        echo [INFO] Aktuelle Version: !GIT_VERSION!
    ) else (
        echo [INFO] Version konnte nicht ermittelt werden
    )
    for /f "delims=" %%p in ('where git 2^>nul') do (
        set "GIT_LOCATION=%%p"
        echo [INFO] Pfad: !GIT_LOCATION!
        goto :git_path_found
    )
    :git_path_found
) else (
    echo [INFO] Git nicht im PATH
)

REM Test 2: Standard-Installation (Program Files)
if exist "C:\Program Files\Git\bin\git.exe" (
    set "GIT_FOUND=1"
    set "GIT_LOCATION=C:\Program Files\Git\bin\git.exe"
    echo [OK] Git gefunden: C:\Program Files\Git\
    if "!GIT_PATH_OK!"=="0" (
        echo [INFO] Git installiert aber nicht im PATH
    )
)

REM Test 3: Program Files (x86)
if exist "C:\Program Files (x86)\Git\bin\git.exe" (
    set "GIT_FOUND=1"
    if "!GIT_LOCATION!"=="" set "GIT_LOCATION=C:\Program Files (x86)\Git\bin\git.exe"
    echo [OK] Git gefunden: C:\Program Files (x86)\Git\
    if "!GIT_PATH_OK!"=="0" (
        echo [INFO] Git (x86) installiert aber nicht im PATH
    )
)

REM Test 4: GitHub Desktop Git
if exist "%LOCALAPPDATA%\GitHubDesktop\app-*\resources\app\git\cmd\git.exe" (
    set "GIT_FOUND=1"
    echo [OK] GitHub Desktop Git gefunden
    if "!GIT_PATH_OK!"=="0" (
        echo [INFO] GitHub Desktop Version verfügbar
    )
)

REM Test 5: Git for Windows Portable
for %%d in (C D E F G H) do (
    if exist "%%d:\Git\bin\git.exe" (
        set "GIT_FOUND=1"
        echo [OK] Git Portable gefunden auf: %%d:\Git\
    )
    if exist "%%d:\PortableGit\bin\git.exe" (
        set "GIT_FOUND=1"
        echo [OK] Git Portable gefunden auf: %%d:\PortableGit\
    )
)

REM Test 6: Alternative Pfade
for %%p in ("C:\Git\bin\git.exe" "C:\tools\Git\bin\git.exe" "%USERPROFILE%\Git\bin\git.exe") do (
    if exist %%p (
        set "GIT_FOUND=1"
        echo [OK] Git gefunden in: %%p
    )
)

REM Test 7: Visual Studio Git
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe" (
    set "GIT_FOUND=1"
    echo [OK] Visual Studio Git gefunden
)

echo.
if "!GIT_FOUND!"=="1" (
    if "!GIT_PATH_OK!"=="1" (
        echo [STATUS] Git ist vollständig funktionsfähig
        if not "!GIT_VERSION!"=="" (
            echo [STATUS] !GIT_VERSION!
        )
    ) else (
        echo [STATUS] Git ist installiert aber möglicherweise nicht optimal konfiguriert
        echo [INFO] Git gefunden aber nicht im PATH - möglicherweise Update sinnvoll
    )
    echo.
    echo [FRAGE] Trotzdem neu installieren/updaten?
    echo   [J] Ja, neueste Version installieren (empfohlen)
    echo   [N] Nein, aktuelle Installation beibehalten
    echo   [P] PATH reparieren (Git zur Umgebung hinzufügen)
    echo.
    choice /c JNP /n /m "[J/N/P]: "
    if errorlevel 3 (
        echo.
        echo [PATH-REPAIR] Füge Git zum PATH hinzu...
        if "!GIT_LOCATION!"=="" (
            echo [ERROR] Git-Pfad konnte nicht bestimmt werden
            echo [INFO] Installiere Git neu für automatische PATH-Konfiguration
            goto :start_installation
        ) else (
            for %%i in ("!GIT_LOCATION!") do set "GIT_DIR=%%~dpi"
            set "GIT_DIR=!GIT_DIR:~0,-1!"
            echo [INFO] Git-Verzeichnis: !GIT_DIR!
            echo [INFO] PATH-Reparatur erfordert Administrator-Rechte
            echo [WARNING] Diese Funktion ist experimentell - Installation empfohlen
            pause
            goto :END
        )
    )
    if errorlevel 2 goto :END
) else (
    echo [STATUS] Git ist nicht installiert
    echo [INFO] Installation wird gestartet...
)
echo.

:start_installation
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
    echo [ALTERNATIVE] Manuelle Git Installation:
    echo   - https://git-scm.com/download/win
    echo   - GitHub Desktop: https://desktop.github.com/
    echo.
    goto :END
)

echo [OK] winget ist verfuegbar
echo.

echo [INSTALL] Starte Git Installation...
echo [INFO] Das kann 2-5 Minuten dauern (Git ist groß)...
echo [INFO] Waehle bei Nachfragen: Standard-Einstellungen
echo.

REM Installiere Git mit optimalen Einstellungen
winget install Git.Git --accept-source-agreements --accept-package-agreements --silent

set "INSTALL_RESULT=%errorlevel%"

if %INSTALL_RESULT%==0 (
    echo.
    echo [SUCCESS] Git Installation abgeschlossen!
    echo.
    echo [VERIFICATION] Umfassende Installation-Verifikation...

    REM Warte auf Windows PATH-Update (Git braucht länger)
    timeout /t 5 /nobreak >nul

    set "INSTALL_SUCCESS=0"

    REM Test 1: PATH-Verfügbarkeit nach Installation
    where git >nul 2>&1
    if %errorlevel%==0 (
        echo [OK] Git via PATH verfuegbar
        for /f "delims=" %%v in ('git --version 2^>nul') do echo [OK] Version: %%v
        set "INSTALL_SUCCESS=1"

        REM Teste Git-Funktionalität
        git config --global --get user.name >nul 2>&1
        if %errorlevel%==0 (
            for /f "delims=" %%u in ('git config --global --get user.name 2^>nul') do echo [INFO] Git User: %%u
        ) else (
            echo [INFO] Git noch nicht konfiguriert (normal nach Installation)
        )
    ) else (
        echo [INFO] Git noch nicht im PATH (PATH-Update kann dauern)
    )

    REM Test 2: Standard-Installation prüfen
    if exist "C:\Program Files\Git\bin\git.exe" (
        echo [OK] Git in Standard-Pfad installiert
        set "INSTALL_SUCCESS=1"

        REM Teste direkt über Pfad wenn PATH noch nicht aktualisiert
        if "!INSTALL_SUCCESS!"=="0" (
            echo [TEST] Teste Git direkt über Installationspfad...
            "C:\Program Files\Git\bin\git.exe" --version >nul 2>&1
            if %errorlevel%==0 (
                for /f "delims=" %%v in ('"C:\Program Files\Git\bin\git.exe" --version 2^>nul') do echo [OK] Direkt-Test: %%v
                set "INSTALL_SUCCESS=1"
            )
        )
    )

    REM Test 3: Program Files (x86) prüfen
    if exist "C:\Program Files (x86)\Git\bin\git.exe" (
        echo [OK] Git (x86) installiert
        set "INSTALL_SUCCESS=1"
    )

    echo.
    if "!INSTALL_SUCCESS!"=="1" (
        echo [RESULT] Installation erfolgreich verifiziert!
        echo.
        echo [NAECHSTE SCHRITTE]
        echo 1. Schliesse diese Konsole komplett
        echo 2. Oeffne neue Konsole (wichtig für PATH-Update)
        echo 3. Git wird automatisch erkannt und verwendet
        echo.
        echo [ERSTMALIGE KONFIGURATION] (Optional - kann später gemacht werden):
        echo   git config --global user.name "Dein Name"
        echo   git config --global user.email "deine@email.com"
        echo.
        echo [INFO] Falls Git nicht erkannt wird:
        echo   - Computer neu starten (PATH-Update)
        echo   - Als Administrator einmal ausführen
        echo   - Git Bash verwenden: "C:\Program Files\Git\git-bash.exe"
    ) else (
        echo [WARNING] Installation abgeschlossen aber Verifikation teilweise fehlgeschlagen
        echo [INFO] Git ist möglicherweise installiert aber noch nicht verfügbar
        echo [LOESUNG] Computer neu starten oder neue Konsole öffnen
        echo [MANUELL] Git Bash testen: "C:\Program Files\Git\git-bash.exe"
    )
) else (
    echo.
    echo [ERROR] Installation fehlgeschlagen! (Exit Code: !INSTALL_RESULT!)
    echo.
    echo [DIAGNOSE] Mögliche Ursachen und Lösungen:
    echo   1. [RECHTE] Als Administrator starten (Rechtsklick → "Als Admin ausführen")
    echo   2. [INTERNET] Internetverbindung prüfen (winget benötigt Internet)
    echo   3. [WINGET] Windows Updates installieren (winget aktualisieren)
    echo   4. [FIREWALL] Firewall/Antivirus temporär deaktivieren
    echo   5. [SPEICHER] Mindestens 1GB freien Speicherplatz schaffen
    echo   6. [PROZESS] Andere Git-Prozesse beenden (Task Manager)
    echo.
    echo [ALTERNATIVE] Manuelle Installation:
    echo   - Git for Windows: https://git-scm.com/download/win
    echo   - GitHub Desktop: https://desktop.github.com/
    echo   - Portable Git: https://git-scm.com/download/win (Portable)
    echo.
    echo [EMPFEHLUNG] Bei wiederholten Fehlern:
    echo   - Windows Updates installieren
    echo   - Microsoft Visual C++ Redistributables installieren
    echo   - Windows Defender/Antivirus Ausnahme hinzufügen
)

:END
echo.
echo [INFO] Git wird für GitHub-Operations im Hellion Tool benötigt
echo [INFO] Ohne Git funktionieren Update-Checker und Emergency-Updater nicht
echo.
pause