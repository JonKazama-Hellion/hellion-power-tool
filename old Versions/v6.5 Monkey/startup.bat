@echo off
REM ============================================================================
REM         HELLION TOOL v6.5 - FULL AUTO LAUNCHER
REM         Installiert automatisch: Winget -> PowerShell 7 -> Startet Tool
REM ============================================================================

setlocal EnableDelayedExpansion
color 0B
title Hellion Tool v6.5 Full Auto

echo ==============================================================================
echo                    HELLION POWER TOOL v6.5 "MONKEY"
echo                         FULL AUTO EDITION
echo ==============================================================================
echo.

REM ============================================================================
REM                    SCHRITT 1: POWERSHELL CHECK
REM ============================================================================

:CHECK_POWERSHELL
echo [1/3] PowerShell-Check...
where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo      [OK] PowerShell 7 vorhanden!
    goto :START_TOOL
)

where powershell >nul 2>&1
if %errorlevel%==0 (
    echo      [OK] Windows PowerShell vorhanden
    set "HAS_PS5=1"
) else (
    echo      [!] Keine PowerShell gefunden
    set "HAS_PS5=0"
)

REM ============================================================================
REM                    SCHRITT 2: WINGET CHECK & INSTALL
REM ============================================================================

:CHECK_WINGET
echo.
echo [2/3] Winget-Check...
where winget >nul 2>&1
if %errorlevel%==0 (
    echo      [OK] Winget vorhanden!
    goto :INSTALL_PS7
)

echo      [!] Winget fehlt - Starte Installation...
echo.

REM Pruefe Windows-Version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if not "%VERSION%"=="10.0" (
    echo      [ERROR] Winget benoetigt Windows 10/11
    goto :MANUAL_INSTALL
)

echo ==============================================================================
echo                        WINGET INSTALLATION
echo ==============================================================================
echo.
echo Winget (Windows Package Manager) wird benoetigt fuer automatische Updates.
echo.
choice /C JN /N /M "Winget jetzt installieren? [J/N]: "
if %errorlevel%==2 goto :SKIP_WINGET

REM Methode 1: Via PowerShell (wenn PS5 vorhanden)
if "%HAS_PS5%"=="1" (
    echo.
    echo [*] Installiere Winget via PowerShell...
    echo     Dies oeffnet kurz den Microsoft Store im Hintergrund...
    echo.
    
    powershell -NoProfile -Command "& { $ProgressPreference = 'SilentlyContinue'; Write-Host 'Lade App Installer...'; try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop; Write-Host '[OK] Installation erfolgreich!' -ForegroundColor Green } catch { Write-Host '[!] Store-Installation fehlgeschlagen' -ForegroundColor Yellow; Write-Host 'Versuche GitHub-Download...' -ForegroundColor Yellow; $url = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; $output = \"$env:TEMP\AppInstaller.msixbundle\"; Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; Add-AppxPackage -Path $output; Remove-Item $output } }"
    
    timeout /t 3 /nobreak >nul
    
    REM Pruefe ob Installation erfolgreich
    where winget >nul 2>&1
    if %errorlevel%==0 (
        echo.
        echo [OK] Winget erfolgreich installiert!
        goto :INSTALL_PS7
    )
)

REM Methode 2: Direkter Download (Fallback)
echo.
echo [*] Lade Winget von GitHub...
echo.

if "%HAS_PS5%"=="1" (
    REM Mit PowerShell downloaden
    powershell -NoProfile -Command "& { $ProgressPreference = 'SilentlyContinue'; Write-Host 'Download laeuft...'; $url = 'https://aka.ms/getwinget'; $output = \"$env:TEMP\AppInstaller.msixbundle\"; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; Write-Host '[OK] Download abgeschlossen' -ForegroundColor Green; Write-Host 'Installiere...'; Add-AppxPackage -Path $output; Remove-Item $output; Write-Host '[OK] Installation abgeschlossen' -ForegroundColor Green } catch { Write-Host '[ERROR] Installation fehlgeschlagen: ' $_.Exception.Message -ForegroundColor Red } }"
) else (
    REM Ohne PowerShell - nutze Browser
    echo [!] PowerShell nicht verfuegbar fuer automatischen Download
    echo.
    echo Bitte installieren Sie manuell:
    echo.
    echo 1. Oeffne Microsoft Store
    echo 2. Suche nach "App Installer"
    echo 3. Installieren und zurueckkommen
    echo.
    choice /C MS /N /M "[M]icrosoft Store oeffnen oder [S]topp: "
    if %errorlevel%==1 (
        start ms-windows-store://pdp/?productid=9NBLGGH4NNS1
        echo.
        echo Nach Installation diese Datei neu starten!
        pause
        exit /b
    )
    goto :END
)

REM Finaler Check
timeout /t 3 /nobreak >nul
where winget >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo [OK] Winget ist jetzt verfuegbar!
) else (
    echo.
    echo [WARNING] Winget-Installation moeglicherweise fehlgeschlagen
    echo           Versuche trotzdem fortzufahren...
)

REM ============================================================================
REM                    SCHRITT 3: POWERSHELL 7 INSTALLATION
REM ============================================================================

:INSTALL_PS7
echo.
echo [3/3] PowerShell 7 Installation...
echo.

where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo      [OK] PowerShell 7 bereits vorhanden!
    goto :START_TOOL
)

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo      [ERROR] Winget nicht verfuegbar - kann PS7 nicht installieren
    goto :MANUAL_INSTALL
)

echo PowerShell 7 wird installiert (ca. 2 Minuten)...
echo.

winget install Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --force

if %errorlevel%==0 (
    echo.
    echo [OK] PowerShell 7 installiert!
    
    REM Path aktualisieren
    set "PATH=!PATH!;%PROGRAMFILES%\PowerShell\7"
    
    REM Kurz warten
    timeout /t 2 /nobreak >nul
    
    REM Testen
    where pwsh >nul 2>&1
    if %errorlevel%==0 (
        echo [OK] PowerShell 7 bereit!
        goto :START_TOOL
    ) else (
        echo [INFO] Neustart erforderlich fuer volle Funktionalitaet
        echo        Versuche trotzdem zu starten...
        
        REM Direkter Pfad-Versuch
        if exist "%PROGRAMFILES%\PowerShell\7\pwsh.exe" (
            set "DIRECT_PWSH=%PROGRAMFILES%\PowerShell\7\pwsh.exe"
            goto :START_TOOL_DIRECT
        )
    )
) else (
    echo [ERROR] PS7-Installation fehlgeschlagen
    goto :TRY_PS5
)

REM ============================================================================
REM                         FALLBACK OPTIONEN
REM ============================================================================

:SKIP_WINGET
echo.
echo [INFO] Ohne Winget fortfahren...
if "%HAS_PS5%"=="1" goto :TRY_PS5
goto :MANUAL_INSTALL

:TRY_PS5
if "%HAS_PS5%"=="1" (
    echo.
    echo [*] Verwende Windows PowerShell 5 als Fallback...
    timeout /t 2 /nobreak >nul
    powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0hellion_tool_v65_monkey.ps1"
    goto :END
)
goto :MANUAL_INSTALL

:MANUAL_INSTALL
echo.
echo ==============================================================================
echo                        MANUELLE INSTALLATION ERFORDERLICH
echo ==============================================================================
echo.
echo Automatische Installation nicht moeglich.
echo.
echo Bitte installieren Sie:
echo.
echo 1. WINGET (App Installer):
echo    - Microsoft Store -> "App Installer"
echo    - Oder: https://github.com/microsoft/winget-cli/releases
echo.
echo 2. POWERSHELL 7:
echo    - https://github.com/PowerShell/PowerShell/releases
echo    - Oder: Microsoft Store -> "PowerShell"
echo.
choice /C GB /N /M "[G]itHub oeffnen oder [B]eenden: "
if %errorlevel%==1 (
    start https://github.com/PowerShell/PowerShell/releases/latest
)
pause
goto :END

REM ============================================================================
REM                         TOOL STARTEN
REM ============================================================================

:START_TOOL
echo.
echo ==============================================================================
echo                         STARTE HELLION TOOL
echo ==============================================================================
echo.
echo Alle Voraussetzungen erfuellt!
echo.
timeout /t 2 /nobreak >nul

pwsh -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0hellion_tool_v65_monkey.ps1"
goto :CHECK_ERROR

:START_TOOL_DIRECT
echo.
echo [*] Starte mit direktem Pfad...
"%DIRECT_PWSH%" -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0hellion_tool_v65_monkey.ps1"
goto :CHECK_ERROR

:CHECK_ERROR
if %errorlevel% neq 0 (
    echo.
    echo [INFO] Falls Fehler: Als Administrator ausfuehren!
    pause
)

REM ============================================================================
REM                              ENDE
REM ============================================================================

:END
exit /b