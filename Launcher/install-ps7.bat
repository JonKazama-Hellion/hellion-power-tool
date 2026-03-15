@echo off
setlocal enabledelayedexpansion
title PowerShell 7 Installation v7.2.0.0
color 0D

echo.
echo   ================================================================
echo          POWERSHELL 7 INSTALLATION v7.2.0.0
echo          Hellion Online Media
echo   ================================================================
echo.

echo   Erweiterte PowerShell 7 Erkennung...

REM Multi-Level PS7 Detection (umfassend)
set "PS7_FOUND=0"
set "PS7_PATH_OK=0"
set "PS7_VERSION="

REM Test 1: PATH-Verfuegbarkeit
where pwsh >nul 2>&1
if %errorlevel%==0 (
    set "PS7_FOUND=1"
    set "PS7_PATH_OK=1"
    echo   [OK] PowerShell 7 via PATH verfuegbar
    for /f "delims=" %%v in ('pwsh --version 2^>nul') do set "PS7_VERSION=%%v"
    if not "!PS7_VERSION!"=="" (
        echo   Version: !PS7_VERSION!
    )
) else (
    echo   PowerShell 7 nicht im PATH
)

REM Test 2: Standard-Installation (Program Files)
if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
    set "PS7_FOUND=1"
    echo   [OK] PowerShell 7 gefunden: C:\Program Files\PowerShell\7\
    if "!PS7_PATH_OK!"=="0" (
        echo   Installiert aber nicht im PATH
    )
) else (
    echo   Nicht in Standard-Installation
)

REM Test 3: Microsoft Store Installation (per-user)
if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
    set "PS7_FOUND=1"
    echo   [OK] PowerShell 7 Store-Installation gefunden
) else (
    echo   Store-Version nicht gefunden
)

REM Test 4: Alternative Pfade
for %%p in ("C:\Program Files\PowerShell\pwsh.exe" "C:\PowerShell\7\pwsh.exe") do (
    if exist %%p (
        set "PS7_FOUND=1"
        echo   [OK] PowerShell 7 gefunden: %%p
    )
)

echo.
if "!PS7_FOUND!"=="1" (
    if "!PS7_PATH_OK!"=="1" (
        echo   Status: PowerShell 7 ist vollstaendig funktionsfaehig
    ) else (
        echo   Status: PowerShell 7 installiert aber nicht optimal konfiguriert
    )
    echo   Trotzdem neu installieren/updaten?
    choice /c JN /n /m "   [J/N]: "
    if errorlevel 2 goto :END
) else (
    echo   Status: PowerShell 7 ist nicht installiert
    echo   Installation wird gestartet...
)
echo.

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
    goto :END
)

echo   [OK] winget ist verfuegbar
echo.

echo   Starte PowerShell 7 Installation...
echo   Das kann 1-3 Minuten dauern...
echo.

winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements

if %errorlevel%==0 (
    echo.
    echo   [OK] PowerShell 7 Installation abgeschlossen!
    echo.
    echo   Verifikation...

    REM Warte kurz auf Windows PATH-Update
    timeout /t 2 /nobreak >nul

    REM Test 1: PATH-Verfuegbarkeit nach Installation
    where pwsh >nul 2>&1
    if %errorlevel%==0 (
        echo   [OK] PowerShell 7 via PATH verfuegbar
        for /f "delims=" %%v in ('pwsh --version 2^>nul') do echo   Version: %%v
        set "INSTALL_SUCCESS=1"
    ) else (
        echo   PowerShell 7 noch nicht im PATH (normal nach Installation)
        set "INSTALL_SUCCESS=0"
    )

    REM Test 2: Standard-Installation pruefen
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo   [OK] PowerShell 7 in Standard-Pfad installiert
        set "INSTALL_SUCCESS=1"
    )

    REM Test 3: Store-Installation pruefen
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
        echo   [OK] PowerShell 7 Store-Version installiert
        set "INSTALL_SUCCESS=1"
    )

    echo.
    if "!INSTALL_SUCCESS!"=="1" (
        echo   Installation erfolgreich verifiziert!
        echo.
        echo   Naechste Schritte:
        echo   1. Schliesse diese Konsole komplett
        echo   2. Starte START.bat neu (wichtig fuer PATH-Update)
        echo   3. PowerShell 7 wird automatisch erkannt und verwendet
        echo.
        echo   Falls PowerShell 7 nicht erkannt wird:
        echo   - Computer neu starten (PATH-Update)
        echo   - Als Administrator einmal ausfuehren
    ) else (
        echo   [WARNING] Verifikation teilweise fehlgeschlagen
        echo   PowerShell 7 ist moeglicherweise installiert aber noch nicht verfuegbar
        echo   Computer neu starten oder als Administrator nochmal versuchen
    )
) else (
    echo.
    echo   [ERROR] Installation fehlgeschlagen! (Exit Code: %errorlevel%)
    echo.
    echo   Moegliche Ursachen:
    echo   1. Als Administrator starten (Rechtsklick)
    echo   2. Internetverbindung pruefen
    echo   3. Windows Updates installieren
    echo   4. Firewall/Antivirus temporaer deaktivieren
    echo   5. Microsoft Store oeffnen und Updates installieren
    echo.
    echo   Alternative - Manuelle Installation:
    echo   - GitHub: https://github.com/PowerShell/PowerShell/releases/latest
    echo   - Microsoft Store: "PowerShell" suchen und installieren
)

:END
echo.
pause
