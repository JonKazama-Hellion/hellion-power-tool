@echo off
REM ================================================================
REM              HELLION LAUNCHER v7.0 "Moon"
REM         AUTO-INSTALL EDITION (Merged with startup.bat)
REM ================================================================
REM Entwickelt von: Hellion Online Media - Florian Wathling
REM Version: 7.0 "Moon" (Enhanced Edition)
REM Website: https://hellion-online-media.de
REM Auto-Installation: Winget -> PowerShell 7 -> Tool
REM ================================================================

setlocal EnableDelayedExpansion
color 0B
title Hellion Tool v7.0 Moon - Full Auto
cls

REM Version und Build-Info
set "LAUNCHER_VERSION=7.0.2"
set "LAUNCHER_CODENAME=Moon-Bugfix"
set "LAUNCHER_BUILD=%date:~-4%%date:~3,2%%date:~0,2%"

echo ==============================================================================
echo                    HELLION POWER TOOL v%LAUNCHER_VERSION% "%LAUNCHER_CODENAME%"
echo                         FULL AUTO EDITION
echo ==============================================================================
echo   Build: %LAUNCHER_BUILD% - Auto-Install: Winget + PowerShell 7
echo   Florian Wathling - Hellion Online Media  
echo   https://hellion-online-media.de
echo ==============================================================================
echo.

REM ================================================================
REM                    ORDNERSTRUKTUR ERSTELLEN
REM ================================================================

echo [*] Initialisiere Ordnerstruktur...

REM Hauptordner erstellen
if not exist "logs" (
    mkdir "logs"
    echo   [OK] logs\ Ordner erstellt
) else (
    echo   [OK] logs\ bereits vorhanden
)

if not exist "backups" (
    mkdir "backups"
    echo   [OK] backups\ Ordner erstellt
) else (
    echo   [OK] backups\ bereits vorhanden
)

if not exist "old-versions" (
    mkdir "old-versions"
    echo   [OK] old-versions\ Ordner erstellt
) else (
    echo   [OK] old-versions\ bereits vorhanden
)

if not exist "config" (
    mkdir "config"
    echo   [OK] config\ Ordner erstellt
) else (
    echo   [OK] config\ bereits vorhanden
)

if not exist "temp" (
    mkdir "temp"
    echo   [OK] temp\ Ordner erstellt
) else (
    echo   [OK] temp\ bereits vorhanden
)

echo.

REM ================================================================
REM                    CONFIG-DATEIEN ERSTELLEN
REM ================================================================

echo [*] Initialisiere Konfiguration...

REM settings.json erstellen falls nicht vorhanden
REM settings.json wird jetzt über Git-Updates verwaltet
if not exist "config\settings.json" (
    echo   [*] WARNUNG: settings.json fehlt - führen Sie 'git pull' aus!
    echo   [*] Erstelle Notfall-Konfiguration...
    (
        echo {
        echo   "version": "%LAUNCHER_VERSION%",
        echo   "codename": "%LAUNCHER_CODENAME%",
        echo   "debug_mode": false,
        echo   "auto_update": true,
        echo   "repository_url": "https://github.com/JonKazama-Hellion/hellion-power-tool.git"
        echo }
    ) > "config\settings.json"
    echo   [OK] Notfall-settings.json erstellt
) else (
    echo   [OK] settings.json vorhanden (Version wird über Git aktualisiert)
)

REM User-Override-System prüfen
if not exist "config\user_overrides.json" (
    if exist "config\user_overrides.json.example" (
        echo   [INFO] Für eigene Einstellungen: Kopieren Sie user_overrides.json.example zu user_overrides.json
    )
)

REM repository.txt erstellen falls nicht vorhanden  
if not exist "config\repository.txt" (
    echo   [*] Erstelle config\repository.txt...
    echo https://github.com/JonKazama-Hellion/hellion-power-tool.git > "config\repository.txt"
    echo   [OK] repository.txt erstellt
) else (
    echo   [OK] repository.txt bereits vorhanden
)

REM version.txt erstellen/aktualisieren
REM version.txt wird über Git-Updates verwaltet
if not exist "config\version.txt" (
    echo   [*] WARNUNG: version.txt fehlt - führen Sie 'git pull' aus!
    echo   [*] Erstelle Notfall-Version...
    echo %LAUNCHER_VERSION% > "config\version.txt"
    echo   [OK] Notfall-version.txt erstellt
) else (
    echo   [OK] version.txt vorhanden (wird über Git aktualisiert)
)

echo.

REM ================================================================
REM                    DEBUG-MODUS PRUEFEN
REM ================================================================

REM Debug-Mode aus settings.json lesen
set "DEBUG_MODE=false"
if exist "config\settings.json" (
    for /f "tokens=2 delims=:" %%a in ('findstr "debug_mode" "config\settings.json"') do (
        set "DEBUG_LINE=%%a"
        set "DEBUG_LINE=!DEBUG_LINE: =!"
        set "DEBUG_LINE=!DEBUG_LINE:,=!"
        if "!DEBUG_LINE!"=="true" set "DEBUG_MODE=true"
    )
)

if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] Debug-Modus aktiviert
    echo [DEBUG] Launcher Version: %LAUNCHER_VERSION% %LAUNCHER_CODENAME%
    echo [DEBUG] Build: %LAUNCHER_BUILD%
    echo [DEBUG] Arbeitsverzeichnis: %CD%
    echo.
)

REM ================================================================
REM                    LOGGING INITIALISIEREN
REM ================================================================

set "LOG_FILE=logs\%date:~-4%-%date:~3,2%-%date:~0,2%_startup.log"
set "ERROR_LOG=logs\%date:~-4%-%date:~3,2%-%date:~0,2%_error.log"

echo [*] Starte Logging...
echo ================================================================ >> "%LOG_FILE%"
echo HELLION LAUNCHER v%LAUNCHER_VERSION% %LAUNCHER_CODENAME% - START >> "%LOG_FILE%"
echo Zeitstempel: %date% %time% >> "%LOG_FILE%"
echo Build: %LAUNCHER_BUILD% >> "%LOG_FILE%"
echo ================================================================ >> "%LOG_FILE%"
echo   [OK] Log initialisiert: %LOG_FILE%

if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] Log-Dateien:
    echo [DEBUG]   Startup: %LOG_FILE%
    echo [DEBUG]   Errors:  %ERROR_LOG%
    echo.
)

REM ================================================================
REM                    AUTO-INSTALLATION SYSTEM
REM ================================================================

echo [*] Starte Auto-Installation-Check...
echo Auto-Installation-Check gestartet >> "%LOG_FILE%"

REM Windows-Version für Kompatibilität prüfen
for /f "tokens=4-5 delims=. " %%i in ('ver') do set WINDOWS_VERSION=%%i.%%j
echo   [*] Windows Version: %WINDOWS_VERSION%
echo Windows Version: %WINDOWS_VERSION% >> "%LOG_FILE%"

if not "%WINDOWS_VERSION%"=="10.0" (
    echo   [WARNING] Windows 10/11 empfohlen für volle Funktionalität
    echo Windows Version Warning >> "%LOG_FILE%"
)

REM ================================================================
REM                    SCHRITT 1: POWERSHELL CHECK
REM ================================================================

:CHECK_POWERSHELL
echo.
echo [1/3] PowerShell-Check...
echo PowerShell-Check gestartet >> "%LOG_FILE%"

set "PWSH_AVAILABLE=0"
set "POWERSHELL_AVAILABLE=0"
set "HAS_PS5=0"

REM Test PowerShell 7 (pwsh) - PRIORITÄT
where pwsh >nul 2>&1
if !errorlevel! == 0 (
    echo     [OK] PowerShell 7 vorhanden!
    echo PowerShell 7 gefunden >> "%LOG_FILE%"
    set "PWSH_AVAILABLE=1"
    set "USE_POWERSHELL=pwsh"
    set "DIRECT_PWSH=pwsh"
    if "%DEBUG_MODE%"=="true" (
        echo [DEBUG] pwsh Version:
        pwsh -NoProfile -Command "Write-Host 'PowerShell Version:' $PSVersionTable.PSVersion.ToString()" 2>>"%ERROR_LOG%"
    )
    goto :CHECK_COMPLETE
)

REM Test Windows PowerShell (Fallback)
where powershell >nul 2>&1
if !errorlevel! == 0 (
    echo     [OK] Windows PowerShell vorhanden
    echo Windows PowerShell gefunden >> "%LOG_FILE%"
    set "POWERSHELL_AVAILABLE=1"
    set "HAS_PS5=1"
    set "USE_POWERSHELL=powershell"
    if "%DEBUG_MODE%"=="true" (
        echo [DEBUG] Windows PowerShell Version:
        powershell -NoProfile -Command "Write-Host 'PowerShell Version:' $PSVersionTable.PSVersion.ToString()" 2>>"%ERROR_LOG%"
    )
) else (
    echo     [!] Keine PowerShell gefunden
    echo Keine PowerShell gefunden >> "%LOG_FILE%"
)

REM ================================================================
REM                    SCHRITT 2: WINGET CHECK & INSTALL
REM ================================================================

:CHECK_WINGET
echo.
echo [2/3] Winget-Check...
echo Winget-Check gestartet >> "%LOG_FILE%"

where winget >nul 2>&1
if !errorlevel! == 0 (
    echo     [OK] Winget vorhanden!
    echo Winget gefunden >> "%LOG_FILE%"
    goto :INSTALL_PS7
)

echo     [!] Winget fehlt - Starte Installation...
echo Winget fehlt - Auto-Installation wird gestartet >> "%LOG_FILE%"

if not "%WINDOWS_VERSION%"=="10.0" (
    echo     [ERROR] Winget benötigt Windows 10/11
    echo Winget Windows Version Error >> "%LOG_FILE%"
    goto :MANUAL_INSTALL
)

echo.
echo ==============================================================================
echo                        WINGET AUTO-INSTALLATION
echo ==============================================================================
echo.
echo Winget (Windows Package Manager) wird für automatische Updates benötigt.
echo Die Installation erfolgt über PowerShell oder den Microsoft Store.
echo.
choice /C JN /N /M "Winget jetzt installieren? [J/N]: "
if %errorlevel%==2 goto :SKIP_WINGET

echo Winget Installation vom Benutzer bestätigt >> "%LOG_FILE%"

REM Methode 1: Via PowerShell (bevorzugt)
if "%HAS_PS5%"=="1" (
    echo.
    echo [*] Installiere Winget via PowerShell...
    echo     Dies öffnet kurz den Microsoft Store im Hintergrund...
    echo.
    echo Winget Installation via PowerShell gestartet >> "%LOG_FILE%"
    
    powershell -NoProfile -Command "& { $ProgressPreference = 'SilentlyContinue'; Write-Host 'Lade App Installer...'; try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop; Write-Host '[OK] Installation erfolgreich!' -ForegroundColor Green } catch { Write-Host '[!] Store-Installation fehlgeschlagen' -ForegroundColor Yellow; Write-Host 'Versuche GitHub-Download...' -ForegroundColor Yellow; $url = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; $output = \"$env:TEMP\AppInstaller.msixbundle\"; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; Add-AppxPackage -Path $output; Remove-Item $output; Write-Host '[OK] GitHub Installation erfolgreich!' -ForegroundColor Green } catch { Write-Host '[ERROR] Installation fehlgeschlagen: ' $_.Exception.Message -ForegroundColor Red } } }"
    
    timeout /t 3 /nobreak >nul
    
    REM Prüfe Installation
    where winget >nul 2>&1
    if !errorlevel! == 0 (
        echo.
        echo [OK] Winget erfolgreich installiert!
        echo Winget Installation erfolgreich >> "%LOG_FILE%"
        goto :INSTALL_PS7
    ) else (
        echo [WARNING] Winget Installation moeglicherweise fehlgeschlagen
        echo Winget Installation möglicherweise fehlgeschlagen >> "%LOG_FILE%"
    )
)

REM Methode 2: Manueller Store-Verweis (Fallback)
echo.
echo [!] Automatische Installation nicht möglich
echo.
echo Bitte installieren Sie manuell:
echo.
echo 1. Microsoft Store öffnen
echo 2. Nach "App Installer" suchen
echo 3. Installieren und zurückkommen
echo.
choice /C MS /N /M "[M]icrosoft Store öffnen oder [S]kip: "
if %errorlevel%==1 (
    start ms-windows-store://pdp/?productid=9NBLGGH4NNS1
    echo.
    echo Nach der Installation diese Datei neu starten!
    pause
    exit /b
)

REM Finaler Winget-Check
timeout /t 3 /nobreak >nul
where winget >nul 2>&1
if !errorlevel! == 0 (
    echo.
    echo [OK] Winget ist jetzt verfügbar!
    echo Winget final verfügbar >> "%LOG_FILE%"
) else (
    echo.
    echo [WARNING] Winget-Installation möglicherweise fehlgeschlagen
    echo           Versuche trotzdem fortzufahren...
    echo Winget Installation unsicher >> "%LOG_FILE%"
)

REM ================================================================
REM                    SCHRITT 3: POWERSHELL 7 INSTALLATION
REM ================================================================

:INSTALL_PS7
echo.
echo [3/3] PowerShell 7 Installation...
echo PowerShell 7 Installation Check >> "%LOG_FILE%"

where pwsh >nul 2>&1
if !errorlevel! == 0 (
    echo     [OK] PowerShell 7 bereits vorhanden!
    echo PowerShell 7 bereits installiert >> "%LOG_FILE%"
    set "PWSH_AVAILABLE=1"
    goto :CHECK_COMPLETE
)

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo     [ERROR] Winget nicht verfügbar - kann PS7 nicht installieren
    echo PowerShell 7 Installation - Winget fehlt >> "%LOG_FILE%"
    goto :TRY_PS5
)

echo PowerShell 7 wird installiert (ca. 2 Minuten)...
echo.
echo PowerShell 7 Installation gestartet >> "%LOG_FILE%"

winget install Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --force

if !errorlevel! == 0 (
    echo.
    echo [OK] PowerShell 7 installiert!
    echo PowerShell 7 Installation erfolgreich >> "%LOG_FILE%"
    
    REM Path aktualisieren
    set "PATH=!PATH!;%PROGRAMFILES%\PowerShell\7"
    
    REM Kurz warten
    timeout /t 2 /nobreak >nul
    
    REM Testen
    where pwsh >nul 2>&1
    if !errorlevel! == 0 (
        echo [OK] PowerShell 7 bereit!
        echo PowerShell 7 bereit >> "%LOG_FILE%"
        set "PWSH_AVAILABLE=1"
        goto :CHECK_COMPLETE
    ) else (
        echo [INFO] Neustart erforderlich für volle Funktionalität
        echo        Versuche trotzdem zu starten...
        echo PowerShell 7 - Neustart empfohlen >> "%LOG_FILE%"
        
        REM Direkter Pfad-Versuch
        if exist "%PROGRAMFILES%\PowerShell\7\pwsh.exe" (
            set "DIRECT_PWSH=%PROGRAMFILES%\PowerShell\7\pwsh.exe"
            set "PWSH_AVAILABLE=1"
            echo Direkter PowerShell 7 Pfad gefunden >> "%LOG_FILE%"
            goto :CHECK_COMPLETE
        )
    )
) else (
    echo [ERROR] PS7-Installation fehlgeschlagen
    echo PowerShell 7 Installation fehlgeschlagen >> "%LOG_FILE%"
    goto :TRY_PS5
)

REM ================================================================
REM                         FALLBACK OPTIONEN
REM ================================================================

:SKIP_WINGET
echo.
echo [INFO] Ohne Winget fortfahren...
echo Winget übersprungen >> "%LOG_FILE%"
if "%HAS_PS5%"=="1" goto :TRY_PS5
goto :MANUAL_INSTALL

:TRY_PS5
if "%HAS_PS5%"=="1" (
    echo.
    echo [*] Verwende Windows PowerShell 5 als Fallback...
    echo PowerShell 5 Fallback wird verwendet >> "%LOG_FILE%"
    set "POWERSHELL_AVAILABLE=1"
    goto :CHECK_COMPLETE
)
goto :MANUAL_INSTALL

:MANUAL_INSTALL
echo.
echo ==============================================================================
echo                        MANUELLE INSTALLATION ERFORDERLICH
echo ==============================================================================
echo.
echo Automatische Installation nicht möglich.
echo.
echo Bitte installieren Sie:
echo.
echo 1. WINGET (App Installer):
echo    - Microsoft Store -^> "App Installer"
echo    - Oder: https://github.com/microsoft/winget-cli/releases
echo.
echo 2. POWERSHELL 7:
echo    - https://github.com/PowerShell/PowerShell/releases
echo    - Oder: Microsoft Store -^> "PowerShell"
echo.
echo Manuelle Installation erforderlich >> "%LOG_FILE%"
choice /C GB /N /M "[G]itHub öffnen oder [B]eenden: "
if %errorlevel%==1 (
    start https://github.com/PowerShell/PowerShell/releases/latest
)
pause
goto :END_ERROR

:CHECK_COMPLETE
echo.
echo [*] Installation-Check abgeschlossen
echo Installation-Check abgeschlossen >> "%LOG_FILE%"

REM PowerShell-Auswahl bereits erfolgt - nur Debug-Info
if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] PowerShell-Status:
    echo [DEBUG]   PWSH_AVAILABLE: !PWSH_AVAILABLE!
    echo [DEBUG]   POWERSHELL_AVAILABLE: !POWERSHELL_AVAILABLE!
    echo [DEBUG]   USE_POWERSHELL: !USE_POWERSHELL!
    echo [DEBUG]   DIRECT_PWSH: !DIRECT_PWSH!
)

REM Prüfe ob PowerShell-Variable gesetzt ist
if not defined USE_POWERSHELL (
    echo   [ERROR] Keine PowerShell-Version verfügbar!
    echo ERROR: Keine PowerShell verfügbar >> "%LOG_FILE%"
    echo ERROR: Keine PowerShell verfügbar >> "%ERROR_LOG%"
    echo.
    echo LÖSUNG: Führen Sie das Installationssystem erneut aus
    pause
    exit /b 1
) else (
    echo   [OK] PowerShell bereit: !USE_POWERSHELL!
    echo PowerShell bereit: !USE_POWERSHELL! >> "%LOG_FILE%"
)

echo.

REM ================================================================
REM                    GIT UND UPDATE-SYSTEM
REM ================================================================

echo [*] Pruefe Update-System...
echo Pruefe Update-System... >> "%LOG_FILE%"

REM Git-Verfügbarkeit prüfen
where git >nul 2>&1
if !errorlevel! == 0 (
    echo   [OK] Git verfuegbar
    echo Git verfuegbar >> "%LOG_FILE%"
    set "GIT_AVAILABLE=1"
    
    REM GitHub URL aus Config lesen
    if exist "config\repository.txt" (
        set /p GITHUB_URL=<"config\repository.txt"
        echo   [OK] Repository URL: !GITHUB_URL!
        echo Repository URL gelesen: !GITHUB_URL! >> "%LOG_FILE%"
    ) else (
        set "GITHUB_URL=https://github.com/JonKazama-Hellion/hellion-power-tool.git"
        echo !GITHUB_URL! > "config\repository.txt"
        echo   [INFO] Standard Repository URL gesetzt
        echo Standard Repository URL gesetzt >> "%LOG_FILE%"
    )
    
    REM Auto-Update prüfen
    set "AUTO_UPDATE=true"
    if exist "config\settings.json" (
        for /f "tokens=2 delims=:" %%a in ('findstr "auto_update" "config\settings.json"') do (
            set "UPDATE_LINE=%%a"
            set "UPDATE_LINE=!UPDATE_LINE: =!"
            set "UPDATE_LINE=!UPDATE_LINE:,=!"
            if "!UPDATE_LINE!"=="false" set "AUTO_UPDATE=false"
        )
    )
    
    if "!AUTO_UPDATE!"=="true" (
        echo   [*] Auto-Update aktiviert
        call :CheckUpdates
    ) else (
        echo   [INFO] Auto-Update deaktiviert
        echo Auto-Update deaktiviert >> "%LOG_FILE%"
    )
    
) else (
    echo   [WARNING] Git nicht verfuegbar - Keine Updates moeglich
    echo Git nicht verfuegbar >> "%LOG_FILE%"
    set "GIT_AVAILABLE=0"
)

echo.

REM ================================================================
REM                    SCRIPT-DATEI FINDEN
REM ================================================================

echo [*] Suche PowerShell-Script...
echo Suche PowerShell-Script... >> "%LOG_FILE%"

set "SCRIPT_PATH="
set "SCRIPT_NAME=hellion_tool_v70_moon.ps1"

REM Erst spezifisches v7.0 Script suchen
if exist "%SCRIPT_NAME%" (
    set "SCRIPT_PATH=%SCRIPT_NAME%"
    echo   [OK] Haupt-Script gefunden: %SCRIPT_NAME%
    echo Haupt-Script gefunden: %SCRIPT_NAME% >> "%LOG_FILE%"
) else (
    REM Fallback: Beliebige Version suchen
    echo   [WARNING] %SCRIPT_NAME% nicht gefunden, suche alternatives...
    for %%f in ("hellion_tool_v*.ps1") do (
        set "SCRIPT_PATH=%%f"
        echo   [OK] Alternative gefunden: %%f
        echo Alternative Script gefunden: %%f >> "%LOG_FILE%"
        goto :ScriptFound
    )
)

:ScriptFound
if not defined SCRIPT_PATH (
    echo   [ERROR] Kein PowerShell-Script gefunden!
    echo ERROR: Kein PowerShell-Script gefunden >> "%LOG_FILE%"
    echo ERROR: Kein PowerShell-Script gefunden >> "%ERROR_LOG%"
    echo.
    echo LOESUNG: Laden Sie das Hellion Tool herunter oder fuehren Sie ein Update durch
    pause
    exit /b 1
)

if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] Script-Pfad: %SCRIPT_PATH%
    echo [DEBUG] Arbeitsverzeichnis: %CD%
    echo [DEBUG] PowerShell-Executable: %USE_POWERSHELL%
    echo.
)

REM ================================================================
REM                    BACKUP ALTE LOGS (OPTIONAL)
REM ================================================================

echo [*] Bereinige alte Logs...
echo Bereinige alte Logs... >> "%LOG_FILE%"

REM Lösche Logs älter als 30 Tage (vereinfacht)
forfiles /p "logs" /m "*.log" /d -30 /c "cmd /c del @path" >nul 2>&1
if !errorlevel! == 0 (
    echo   [OK] Alte Logs bereinigt
    echo Alte Logs bereinigt >> "%LOG_FILE%"
) else (
    if "%DEBUG_MODE%"=="true" (
        echo [DEBUG] Keine alten Logs zum Bereinigen gefunden
    )
)

echo.

REM ================================================================
REM                    TOOL STARTEN
REM ================================================================

echo [*] Starte Hellion Tool v%LAUNCHER_VERSION% "%LAUNCHER_CODENAME%"...
echo ================================================================
echo   Script: %SCRIPT_PATH%
echo   PowerShell: %USE_POWERSHELL%
echo   Debug: %DEBUG_MODE%
echo ================================================================
echo.

REM Log Script-Start
echo Script-Start: %SCRIPT_PATH% >> "%LOG_FILE%"
echo PowerShell: %USE_POWERSHELL% >> "%LOG_FILE%"
echo Startzeit: %date% %time% >> "%LOG_FILE%"

REM Tool mit entsprechender PowerShell-Version starten
echo ==============================================================================
echo                         STARTE HELLION TOOL
echo ==============================================================================
echo   Alle Voraussetzungen erfüllt!
echo   Script: %SCRIPT_PATH%
echo   PowerShell: %USE_POWERSHELL%
echo   Debug: %DEBUG_MODE%
echo ==============================================================================
echo.

timeout /t 2 /nobreak >nul

if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] Starte mit Debug-Parametern...
    echo [DEBUG] Kommando: %USE_POWERSHELL% -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
    echo.
)

if defined DIRECT_PWSH (
    "%USE_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" 2>>"%ERROR_LOG%"
) else (
    %USE_POWERSHELL% -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" 2>>"%ERROR_LOG%"
)

REM Exit-Code erfassen
set "SCRIPT_EXIT_CODE=!errorlevel!"

REM Log Script-Ende
echo Script-Ende: Exit-Code !SCRIPT_EXIT_CODE! >> "%LOG_FILE%"
echo Endzeit: %date% %time% >> "%LOG_FILE%"

REM Debug: Exit-Code anzeigen
if "%DEBUG_MODE%"=="true" (
    echo [DEBUG] Empfangener Exit-Code: !SCRIPT_EXIT_CODE!
)

REM Prüfe auf UAC-Restart Signal-Datei
if exist "temp\uac_restart.signal" (
    echo UAC-Restart erkannt - Launcher beendet sich stillschweigend >> "%LOG_FILE%"
    del "temp\uac_restart.signal" >nul 2>&1
    exit /b 0
)

if !SCRIPT_EXIT_CODE! == 0 (
    echo   [OK] Tool erfolgreich beendet
    echo Tool erfolgreich beendet >> "%LOG_FILE%"
    
    REM 30-Tage-Erinnerung pruefen
    call :Check30DayReminder
    
    REM Desktop-Verknuepfung anbieten
    call :OfferDesktopShortcut
    
) else (
    echo   [WARNING] Tool mit Exit-Code !SCRIPT_EXIT_CODE! beendet
    echo Tool mit Exit-Code !SCRIPT_EXIT_CODE! beendet >> "%LOG_FILE%"
    echo Tool Exit-Code: !SCRIPT_EXIT_CODE! >> "%ERROR_LOG%"
    
    REM Fehlerbehandlung
    if !SCRIPT_EXIT_CODE! neq 0 (
        echo.
        echo [INFO] Falls Fehler aufgetreten sind: Als Administrator ausführen!
        if "%DEBUG_MODE%"=="true" (
            echo [DEBUG] Fehler-Log: %ERROR_LOG%
        )
    )
)

echo.
echo ==============================================================================
echo                    HELLION LAUNCHER v%LAUNCHER_VERSION% BEENDET
echo ==============================================================================

if "%DEBUG_MODE%"=="true" (
    pause
)

exit /b !SCRIPT_EXIT_CODE!

REM ================================================================
REM                    FEHLER-ENDE
REM ================================================================

:END_ERROR
echo.
echo ==============================================================================
echo                    INSTALLATION ABGEBROCHEN
echo ==============================================================================
echo   Launcher: v%LAUNCHER_VERSION% "%LAUNCHER_CODENAME%"
echo   Status: Installation unvollständig
echo   Logs: %LOG_FILE%
echo ==============================================================================
echo Installation abgebrochen >> "%LOG_FILE%"
exit /b 1

REM ================================================================
REM                    UPDATE-FUNKTIONEN
REM ================================================================

:CheckUpdates
echo   [*] Pruefe auf Updates...
echo Pruefe auf Updates... >> "%LOG_FILE%"

if not exist ".git" (
    echo   [INFO] Kein Git-Repository gefunden - Initialisiere Auto-Update...
    echo Kein Git-Repository gefunden - Initialisiere >> "%LOG_FILE%"
    call :InitializeGitRepo
    if !errorlevel! neq 0 (
        echo   [WARNING] Git-Initialisierung fehlgeschlagen - Ueberspringe Updates
        echo Git-Initialisierung fehlgeschlagen >> "%LOG_FILE%"
        goto :EOF
    )
)

REM Git fetch
git fetch origin main >nul 2>&1
if !errorlevel! neq 0 (
    echo   [WARNING] Git fetch fehlgeschlagen
    echo Git fetch fehlgeschlagen >> "%LOG_FILE%"
    goto :EOF
)

REM Prüfe auf verfügbare Updates
for /f %%i in ('git rev-list HEAD...origin/main --count 2^>nul') do set BEHIND=%%i

if not defined BEHIND set BEHIND=0

if !BEHIND! GTR 0 (
    echo   [*] !BEHIND! Update(s) verfuegbar!
    echo !BEHIND! Updates verfuegbar >> "%LOG_FILE%"
    
    REM Backup erstellen vor Update
    call :CreateBackup
    
    REM Updates installieren
    echo   [*] Installiere Updates...
    echo Installiere Updates... >> "%LOG_FILE%"
    
    git pull origin main >nul 2>&1
    if !errorlevel! == 0 (
        echo   [OK] Updates erfolgreich installiert
        echo Updates erfolgreich installiert >> "%LOG_FILE%"
    ) else (
        echo   [ERROR] Update fehlgeschlagen
        echo Update fehlgeschlagen >> "%LOG_FILE%"
        echo Update fehlgeschlagen >> "%ERROR_LOG%"
    )
) else (
    echo   [OK] Bereits auf dem neuesten Stand
    echo Bereits auf dem neuesten Stand >> "%LOG_FILE%"
)
goto :EOF

:CreateBackup
echo   [*] Erstelle Backup...
echo Erstelle Backup... >> "%LOG_FILE%"

set "BACKUP_TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%"
set "BACKUP_TIMESTAMP=%BACKUP_TIMESTAMP: =0%"

REM Aktuelles Script sichern
if exist "%SCRIPT_NAME%" (
    set "BACKUP_FILE=backups\hellion_tool_backup_%BACKUP_TIMESTAMP%.ps1"
    copy "%SCRIPT_NAME%" "!BACKUP_FILE!" >nul
    if !errorlevel! == 0 (
        echo     [OK] Backup erstellt: !BACKUP_FILE!
        echo Backup erstellt: !BACKUP_FILE! >> "%LOG_FILE%"
    ) else (
        echo     [WARNING] Backup fehlgeschlagen
        echo Backup fehlgeschlagen >> "%LOG_FILE%"
    )
)

REM Alte Backups bereinigen (max 10)
set /a BACKUP_COUNT=0
for %%f in ("backups\hellion_tool_backup_*.ps1") do set /a BACKUP_COUNT+=1

if !BACKUP_COUNT! GTR 10 (
    echo     [*] Bereinige alte Backups...
    for /f "skip=10" %%f in ('dir /b /o-d "backups\hellion_tool_backup_*.ps1"') do (
        del "backups\%%f" >nul 2>&1
        if "%DEBUG_MODE%"=="true" echo [DEBUG] Backup geloescht: %%f
    )
)
goto :EOF

REM ================================================================
REM                    30-TAGE-ERINNERUNG
REM ================================================================

:Check30DayReminder
REM Prüfe wann das Tool zuletzt verwendet wurde
set "REMINDER_FILE=config\last_run.txt"
set "TODAY_DATE=%date:~-4%%date:~3,2%%date:~0,2%"

REM Erstelle/aktualisiere last_run.txt mit heutigem Datum
echo %TODAY_DATE% > "%REMINDER_FILE%"

REM Prüfe ob es eine ältere last_run Datei gibt
if exist "config\last_reminder.txt" (
    set /p LAST_REMINDER=<"config\last_reminder.txt"
) else (
    set "LAST_REMINDER=00000000"
)

REM Berechne Datums-Differenz (vereinfacht)
set /a "DATE_TODAY=%TODAY_DATE%"
set /a "DATE_LAST=%LAST_REMINDER%"
set /a "DATE_DIFF=%DATE_TODAY%-%DATE_LAST%"

REM Zeige Erinnerung wenn mehr als 30 Tage vergangen (vereinfachte Logik)
if %DATE_DIFF% GTR 30 (
    echo.
    echo ==============================================================================
    echo                           📅 WARTUNGS-ERINNERUNG
    echo ==============================================================================
    echo   Das Hellion Power Tool wurde längere Zeit nicht verwendet.
    echo.
    echo   💡 EMPFEHLUNG: Führen Sie das Tool alle 30 Tage aus für:
    echo      • System-Bereinigung ^(Temp-Dateien, Cache^)
    echo      • Software-Updates ^(Winget Updates^)
    echo      • System-Reparaturen ^(SFC, DISM falls nötig^)
    echo      • Optimale System-Performance
    echo.
    echo   ⏰ Nächste empfohlene Ausführung: In ca. 30 Tagen
    echo   📁 Tipp: Erstellen Sie eine Verknüpfung auf dem Desktop!
    echo ==============================================================================
    echo.
    
    REM Aktualisiere Erinnerungs-Datum
    echo %TODAY_DATE% > "config\last_reminder.txt"
    echo Wartungs-Erinnerung angezeigt >> "%LOG_FILE%"
    
    REM Kurze Pause damit User die Meldung liest
    timeout /t 5 /nobreak >nul
)

goto :EOF

REM ================================================================
REM                    DESKTOP-VERKNUEPFUNG
REM ================================================================

:OfferDesktopShortcut
REM Prüfe ob bereits eine Desktop-Verknüpfung existiert
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
set "SHORTCUT_NAME=Hellion Power Tool.lnk"
set "SHORTCUT_PATH=%DESKTOP_PATH%\%SHORTCUT_NAME%"

REM Prüfe auch Public Desktop für alle User
set "PUBLIC_DESKTOP=%PUBLIC%\Desktop"
set "PUBLIC_SHORTCUT=%PUBLIC_DESKTOP%\%SHORTCUT_NAME%"

REM Prüfe ob Verknüpfung bereits existiert
if exist "%SHORTCUT_PATH%" goto :EOF
if exist "%PUBLIC_SHORTCUT%" goto :EOF

REM Prüfe ob ein Marker existiert, dass User bereits gefragt wurde
if exist "config\shortcut_declined.txt" goto :EOF

echo.
echo ==============================================================================
echo                         🔗 DESKTOP-VERKNUEPFUNG
echo ==============================================================================
echo   Moechten Sie eine Desktop-Verknuepfung erstellen?
echo.
echo   Vorteile:
echo   • Schneller Zugriff auf das Hellion Power Tool
echo   • Professionelles Icon auf dem Desktop  
echo   • Einfacher Start ohne Ordner-Navigation
echo.

choice /C JN /N /M "Desktop-Verknuepfung erstellen? [J/N]: "

if %errorlevel%==1 (
    echo.
    echo   [*] Erstelle Desktop-Verknuepfung...
    call :CreateDesktopShortcut
) else (
    echo   [INFO] Verknuepfung uebersprungen
    echo Desktop-Verknuepfung uebersprungen >> "%LOG_FILE%"
    
    REM Marker erstellen damit nicht wieder gefragt wird
    echo DECLINED > "config\shortcut_declined.txt"
)

goto :EOF

:CreateDesktopShortcut
REM PowerShell-Script erstellen für Verknüpfung mit Icon
set "PS_SCRIPT=%TEMP%\create_hellion_shortcut.ps1"

REM Erstelle PowerShell-Script für Verknüpfungs-Erstellung
(
    echo $WshShell = New-Object -comObject WScript.Shell
    echo $LauncherPath = "%~dp0launcher.bat"
    echo $ShortcutPath = "%SHORTCUT_PATH%"
    echo $Shortcut = $WshShell.CreateShortcut($ShortcutPath^)
    echo $Shortcut.TargetPath = $LauncherPath
    echo $Shortcut.WorkingDirectory = "%~dp0"
    echo $Shortcut.Description = "Hellion Power Tool v%LAUNCHER_VERSION% - System-Optimierung"
    echo $Shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,21"
    echo $Shortcut.Save(^)
    echo Write-Host "Desktop-Verknuepfung erfolgreich erstellt!" -ForegroundColor Green
) > "%PS_SCRIPT%"

REM PowerShell-Script ausführen
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" 2>nul

REM Temporäres Script löschen
del "%PS_SCRIPT%" >nul 2>&1

REM Prüfe ob Verknüpfung erstellt wurde
if exist "%SHORTCUT_PATH%" (
    echo   [OK] Desktop-Verknuepfung erstellt: %SHORTCUT_NAME%
    echo Desktop-Verknuepfung erstellt >> "%LOG_FILE%"
    echo.
    echo   Tipp: Sie finden die Verknuepfung jetzt auf Ihrem Desktop! 🖥️
) else (
    echo   [WARNING] Verknuepfung konnte nicht erstellt werden
    echo Desktop-Verknuepfung fehlgeschlagen >> "%LOG_FILE%"
)

goto :EOF

REM ================================================================
REM                GIT-REPOSITORY INITIALISIERUNG
REM ================================================================

:InitializeGitRepo
REM Initialisiert Git-Repository für Auto-Updates bei ZIP-Downloads
echo.
echo ==============================================================================
echo                        🔧 GIT AUTO-UPDATE SETUP
echo ==============================================================================
echo   Ihr Tool wurde als ZIP heruntergeladen.
echo   Für automatische Updates wird jetzt Git-Repository initialisiert...
echo.

REM Backup der aktuellen Dateien erstellen
echo   [*] Erstelle Sicherheitskopie...
if not exist "temp" mkdir "temp" >nul 2>&1
xcopy /s /y "*" "temp\zip-backup\" >nul 2>&1

REM Git-Repository initialisieren
echo   [*] Initialisiere Git-Repository...
git init >nul 2>&1
if !errorlevel! neq 0 (
    echo   [ERROR] Git init fehlgeschlagen
    echo Git init fehlgeschlagen >> "%LOG_FILE%"
    exit /b 1
)

REM Remote-Repository hinzufügen
echo   [*] Verbinde mit GitHub-Repository...
git remote add origin %REPOSITORY_URL% >nul 2>&1
if !errorlevel! neq 0 (
    echo   [ERROR] Remote-Repository konnte nicht hinzugefügt werden
    echo Remote add fehlgeschlagen >> "%LOG_FILE%"
    exit /b 1
)

REM Fetch Repository-Daten
echo   [*] Lade Repository-Daten...
git fetch origin main >nul 2>&1
if !errorlevel! neq 0 (
    echo   [ERROR] Git fetch fehlgeschlagen - Repository nicht erreichbar
    echo Git fetch initial fehlgeschlagen >> "%LOG_FILE%"
    exit /b 1
)

REM Branch auf main setzen
echo   [*] Konfiguriere Branch...
git branch -M main >nul 2>&1
git branch --set-upstream-to=origin/main main >nul 2>&1

REM Prüfe ob Updates verfügbar
echo   [*] Prüfe auf verfügbare Updates...
for /f %%i in ('git rev-list --count origin/main 2^>nul') do set REMOTE_COMMITS=%%i
if not defined REMOTE_COMMITS set REMOTE_COMMITS=0

if !REMOTE_COMMITS! GTR 0 (
    echo.
    echo   ⚠️  WICHTIGER HINWEIS:
    echo   Es sind neuere Versionen verfügbar (!REMOTE_COMMITS! Commits)
    echo.
    echo   EMPFEHLUNG: Lassen Sie das erste Update jetzt durchlaufen.
    echo   Dies synchronisiert Ihre Dateien mit der neuesten Version.
    echo.
    choice /C JN /N /M "Erstes Update jetzt durchfuehren? [J/N]: "
    
    if !errorlevel!==1 (
        echo.
        echo   [*] Führe initiales Update durch...
        
        REM Lokale Änderungen stagen (falls vorhanden)
        git add . >nul 2>&1
        git commit -m "Initial ZIP download state" >nul 2>&1
        
        REM Update durchführen
        git pull origin main >nul 2>&1
        if !errorlevel! == 0 (
            echo   [OK] Initiales Update erfolgreich!
            echo   [INFO] Tool wird mit aktueller Version neu gestartet...
            echo Git-Repository initialisiert und Update durchgeführt >> "%LOG_FILE%"
            echo.
            echo   🔄 NEUSTART ERFORDERLICH
            echo   Das Tool wird nun neu gestartet um die Updates zu laden.
            echo.
            timeout /t 3 /nobreak >nul
            
            REM Tool neu starten
            start "" "%~f0"
            exit /b 0
        ) else (
            echo   [WARNING] Update teilweise fehlgeschlagen
            echo Initiales Update fehlgeschlagen >> "%LOG_FILE%"
        )
    ) else (
        echo   [INFO] Update übersprungen - wird beim nächsten Start verfügbar sein
        echo Update übersprungen bei Git-Init >> "%LOG_FILE%"
    )
)

echo.
echo   [OK] Git-Repository erfolgreich initialisiert!
echo   [INFO] Auto-Updates sind jetzt aktiviert für zukünftige Starts.
echo Git-Repository erfolgreich initialisiert >> "%LOG_FILE%"
echo.
echo ==============================================================================

exit /b 0