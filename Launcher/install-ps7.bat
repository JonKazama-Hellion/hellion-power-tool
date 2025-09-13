@echo off
setlocal enabledelayedexpansion
title PowerShell 7 Installation v7.1.5.4
color 0D

echo ==============================================================================
echo                  POWERSHELL 7 INSTALLATION MODULE v7.1.5.4
echo                       Robust und zuverlässig
echo ==============================================================================
echo.

echo [*] Erweiterte PowerShell 7 Erkennung...

REM Multi-Level PS7 Detection (umfassend)
set "PS7_FOUND=0"
set "PS7_PATH_OK=0"
set "PS7_VERSION="

REM Test 1: PATH-Verfügbarkeit
where pwsh >nul 2>&1
if %errorlevel%==0 (
    set "PS7_FOUND=1"
    set "PS7_PATH_OK=1"
    echo [OK] PowerShell 7 via PATH verfuegbar
    for /f "delims=" %%v in ('pwsh --version 2^>nul') do set "PS7_VERSION=%%v"
    if not "!PS7_VERSION!"=="" (
        echo [INFO] Aktuelle Version: !PS7_VERSION!
    ) else (
        echo [INFO] Version konnte nicht ermittelt werden
    )
) else (
    echo [INFO] PowerShell 7 nicht im PATH
)

REM Test 2: Standard-Installation (Program Files)
if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
    set "PS7_FOUND=1"
    echo [OK] PowerShell 7 gefunden: C:\Program Files\PowerShell\7\
    if "!PS7_PATH_OK!"=="0" (
        echo [INFO] PowerShell 7 installiert aber nicht im PATH
    )
) else (
    echo [INFO] PowerShell 7 nicht in Standard-Installation
)

REM Test 3: Microsoft Store Installation (per-user)
if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
    set "PS7_FOUND=1"
    echo [OK] PowerShell 7 Store-Installation gefunden
    if "!PS7_PATH_OK!"=="0" (
        echo [INFO] Store-Version verfügbar
    )
) else (
    echo [INFO] PowerShell 7 Store-Version nicht gefunden
)

REM Test 4: Alternative Pfade
for %%p in ("C:\Program Files\PowerShell\pwsh.exe" "C:\PowerShell\7\pwsh.exe") do (
    if exist %%p (
        set "PS7_FOUND=1"
        echo [OK] PowerShell 7 gefunden in: %%p
    )
)

echo.
if "!PS7_FOUND!"=="1" (
    if "!PS7_PATH_OK!"=="1" (
        echo [STATUS] PowerShell 7 ist vollständig funktionsfähig
    ) else (
        echo [STATUS] PowerShell 7 ist installiert aber möglicherweise nicht optimal konfiguriert
    )
    echo [FRAGE] Trotzdem neu installieren/updaten?
    choice /c JN /n /m "[J/N]: "
    if errorlevel 2 goto :END
) else (
    echo [STATUS] PowerShell 7 ist nicht installiert
    echo [INFO] Installation wird gestartet...
)
echo.

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
    goto :END
)

echo [OK] winget ist verfuegbar
echo.

echo [INSTALL] Starte PowerShell 7 Installation...
echo [INFO] Das kann 1-3 Minuten dauern...
echo.

winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements

if %errorlevel%==0 (
    echo.
    echo [SUCCESS] PowerShell 7 Installation abgeschlossen!
    echo.
    echo [VERIFICATION] Umfassende Installation-Verifikation...

    REM Warte kurz auf Windows PATH-Update
    timeout /t 2 /nobreak >nul

    REM Test 1: PATH-Verfügbarkeit nach Installation
    where pwsh >nul 2>&1
    if %errorlevel%==0 (
        echo [OK] PowerShell 7 via PATH verfuegbar
        for /f "delims=" %%v in ('pwsh --version 2^>nul') do echo [OK] Version: %%v
        set "INSTALL_SUCCESS=1"
    ) else (
        echo [INFO] PowerShell 7 noch nicht im PATH (normal nach Installation)
        set "INSTALL_SUCCESS=0"
    )

    REM Test 2: Standard-Installation prüfen
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo [OK] PowerShell 7 in Standard-Pfad installiert
        set "INSTALL_SUCCESS=1"
    )

    REM Test 3: Store-Installation prüfen
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
        echo [OK] PowerShell 7 Store-Version installiert
        set "INSTALL_SUCCESS=1"
    )

    echo.
    if "!INSTALL_SUCCESS!"=="1" (
        echo [RESULT] Installation erfolgreich verifiziert!
        echo.
        echo [NAECHSTE SCHRITTE]
        echo 1. Schliesse diese Konsole komplett
        echo 2. Starte START.bat neu (wichtig für PATH-Update)
        echo 3. PowerShell 7 wird automatisch erkannt und verwendet
        echo.
        echo [INFO] Falls PowerShell 7 nicht erkannt wird:
        echo   - Computer neu starten (PATH-Update)
        echo   - Als Administrator einmal ausführen
    ) else (
        echo [WARNING] Installation abgeschlossen aber Verifikation teilweise fehlgeschlagen
        echo [INFO] PowerShell 7 ist möglicherweise installiert aber noch nicht verfügbar
        echo [LOESUNG] Computer neu starten oder als Administrator nochmal versuchen
    )
) else (
    echo.
    echo [ERROR] Installation fehlgeschlagen! (Exit Code: %errorlevel%)
    echo.
    echo [DIAGNOSE] Mögliche Ursachen und Lösungen:
    echo   1. [RECHTE] Als Administrator starten (Rechtsklick → "Als Admin ausführen")
    echo   2. [INTERNET] Internetverbindung prüfen (winget benötigt Internet)
    echo   3. [WINGET] Windows Updates installieren (winget aktualisieren)
    echo   4. [FIREWALL] Firewall/Antivirus temporär deaktivieren
    echo   5. [STORE] Microsoft Store öffnen und Updates installieren
    echo.
    echo [ALTERNATIVE] Manuelle Installation:
    echo   - GitHub: https://github.com/PowerShell/PowerShell/releases/latest
    echo   - Microsoft Store: "PowerShell" suchen und installieren
)

:END
echo.
pause