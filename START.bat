@echo off
title Hellion Power Tool v7.1.5.2 "Baldur"
color 0B

echo ==============================================================================
echo                HELLION POWER TOOL v7.1.5.2 "Baldur"
echo ==============================================================================
echo.

REM Debug-Modus wählen
set "DEBUG_MODE=0"
choice /c 01 /n /m "Debug-Level [0=Normal, 1=Debug]: "
if errorlevel 2 set "DEBUG_MODE=1"

echo.
if "%DEBUG_MODE%"=="1" (
    echo [DEBUG] Debug-Modus aktiviert
) else (
    echo [INFO] Normal-Modus aktiviert
)

echo.
echo === OPTIONEN ===
echo [S] Sofort starten (Standard)
echo [D] Desktop-Verknuepfung erstellen  
echo [P] PowerShell 7 installieren
echo [H] Hilfe und Informationen
echo.
choice /c SDPH /n /m "Waehle eine Option [S/D/P/H]: "

if errorlevel 4 goto :HELP
if errorlevel 3 goto :INSTALL_PS7  
if errorlevel 2 goto :DESKTOP_SHORTCUT
if errorlevel 1 goto :START_TOOL

:START_TOOL
echo.
echo [*] Starte Hellion Power Tool...
timeout /t 1 /nobreak >nul
call launcher\simple-launcher.bat %DEBUG_MODE%
goto :END

:DESKTOP_SHORTCUT
echo.
echo [*] Erstelle Desktop-Verknuepfung...
call assets\create-desktop-shortcut.bat
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul
goto :START_TOOL

:INSTALL_PS7
echo.
echo [*] Starte PowerShell 7 Installation...
call launcher\install-ps7.bat
echo.
echo Zurueck zum Hauptstart...
timeout /t 2 /nobreak >nul  
goto :START_TOOL

:HELP
echo.
echo === HELLION POWER TOOL HILFE ===
echo.
echo OPTIONEN:
echo [S] Standard-Start - Startet das Tool normal
echo [D] Desktop-Verknuepfung - Erstellt Shortcut auf Desktop
echo [P] PowerShell 7 - Installiert/Aktualisiert PowerShell 7 (empfohlen)
echo [H] Diese Hilfe anzeigen
echo.
echo EMPFEHLUNG:
echo 1. Zuerst PowerShell 7 installieren (Option P)
echo 2. Desktop-Verknuepfung erstellen (Option D) 
echo 3. Tool starten (Option S)
echo.
echo PowerShell 7 bietet bessere Performance und Kompatibilitaet!
echo.
pause
cls
goto :RESTART

:RESTART
echo ==============================================================================
echo                HELLION POWER TOOL v7.1.5.2 "Baldur"
echo ==============================================================================
echo.
if "%DEBUG_MODE%"=="1" (
    echo [DEBUG] Debug-Modus aktiviert
) else (
    echo [INFO] Normal-Modus aktiviert  
)
echo.
goto :START_TOOL

:END
REM Auto-close - kein pause mehr dank simple-launcher.bat timeout