@echo off
title PowerShell 7 Installation
color 0D

echo ==============================================================================
echo                    POWERSHELL 7 INSTALLATION MODULE
echo ==============================================================================
echo.

echo [*] Pruefe aktuellen PowerShell Status...

REM Check current PS7 status
where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] PowerShell 7 ist bereits via PATH verfuegbar
    pwsh --version 2>nul || echo Version konnte nicht ermittelt werden
    echo.
    echo [FRAGE] Trotzdem neu installieren/updaten?
    choice /c JN /n /m "[J/N]: "
    if errorlevel 2 goto :END
) else (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo [INFO] PowerShell 7 installiert aber nicht im PATH
        echo [FIX] Fuege PowerShell 7 zum PATH hinzu...
        echo.
    ) else (
        echo [INFO] PowerShell 7 ist nicht installiert
        echo.
    )
)

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
    echo [TEST] Teste neue Installation...
    where pwsh >nul 2>&1
    if %errorlevel%==0 (
        pwsh --version 2>nul
        echo [OK] PowerShell 7 ist jetzt verfuegbar!
    ) else (
        echo [INFO] PowerShell 7 installiert - Neustart der Konsole erforderlich
    )
    echo.
    echo [NAECHSTE SCHRITTE]
    echo 1. Schliesse diese Konsole
    echo 2. Starte START.bat neu
    echo 3. PowerShell 7 wird automatisch erkannt
) else (
    echo.
    echo [ERROR] Installation fehlgeschlagen!
    echo [INFO] Moegliche Loesungen:
    echo   - Als Administrator starten
    echo   - Internetverbindung pruefen
    echo   - Windows Updates installieren
)

:END
echo.
pause