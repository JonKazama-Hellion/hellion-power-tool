@echo off
setlocal enabledelayedexpansion
title Hellion Simple Launcher v7.1.5.4
color 0B

REM Debug-Mode Parameter
set "DEBUG_MODE=%1"
if "%DEBUG_MODE%"=="" set "DEBUG_MODE=0"

REM Direct-Mode Parameter (überspringt Menu)
set "DIRECT_MODE=%2"

echo ==============================================================================
echo                  HELLION SIMPLE LAUNCHER v7.1.5.4
echo                 (Defender-Safe, Minimal, Robust)
echo ==============================================================================
echo [INFO] Debug-Mode: %DEBUG_MODE%
echo.

REM ===== SICHERE VERZEICHNIS-ERKENNUNG =====
echo [*] Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Launchers (100% sicher)
set "LAUNCHER_DIR=%~dp0"
set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"

REM Intelligente Root-Verzeichnis Bestimmung (funktioniert von ROOT und /Launcher)
echo [DEBUG] Launcher-Dir: !LAUNCHER_DIR!
echo [DEBUG] Aktuelles Dir: %CD%

REM Prüfe ob wir bereits im Root-Verzeichnis sind
if exist "%CD%\hellion_tool_main.ps1" if exist "%CD%\config\version.txt" (
    set "ROOT_DIR=%CD%"
    echo [OK] Bereits im Root-Verzeichnis: !ROOT_DIR!
    goto :ROOT_FOUND
)

REM Prüfe ob wir im Launcher-Subdir sind (original Verhalten)
call :FIND_ROOT_DIRECTORY ROOT_DIR

if "!ROOT_DIR!"=="" (
    echo [ERROR] Hellion Tool Root-Verzeichnis konnte nicht gefunden werden
    echo [INFO] Simple-launcher kann aufgerufen werden von:
    echo   1. Aus dem Root-Verzeichnis (via START.bat)
    echo   2. Aus dem Launcher/-Unterverzeichnis (direkter Doppelklick)
    echo [DEBUG] Launcher-Dir: !LAUNCHER_DIR!
    echo [DEBUG] Aktuelles Dir: %CD%
    echo.
    echo [LOESUNG]
    echo - Nutze START.bat im Root-Verzeichnis (empfohlen)
    echo - Oder kopiere simple-launcher.bat in Launcher/-Ordner
    echo.
    pause
    exit /b 1
)

:ROOT_FOUND

echo [OK] Root-Verzeichnis: !ROOT_DIR!
echo [OK] Launcher-Verzeichnis: !LAUNCHER_DIR!

REM Wechsel ins sichere Hauptverzeichnis
cd /d "!ROOT_DIR!"
echo [OK] Arbeite in: !ROOT_DIR!
echo.

REM Finde PowerShell (Prioritaet: PS7 > PS5)
set "USE_PS=powershell"
set "PS_VERSION=5"

REM Multi-Level PS7 Detection (Phase 1)
where pwsh >nul 2>&1

if %errorlevel%==0 (
    echo [OK] PowerShell 7 gefunden ueber PATH (empfohlen)
    set "USE_PS=pwsh"
    set "PS_VERSION=7"
    goto :PS_DETECTION_DONE
) else (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo [OK] PowerShell 7 ueber direkten Pfad gefunden
        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
        set "PS_VERSION=7"
        goto :PS_DETECTION_DONE
    ) else (
        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
            echo [OK] PowerShell 7 ueber Store-Installation gefunden
            set "USE_PS=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"
            set "PS_VERSION=7"
            goto :PS_DETECTION_DONE
        ) else (
            echo [INFO] PowerShell 7 nicht gefunden
            echo [EMPFEHLUNG] PowerShell 7 bietet bessere Performance
            echo.
            echo [ANGEBOT] PowerShell 7 jetzt installieren?
            echo   [J] Ja, installiere PowerShell 7 (empfohlen)
            echo   [N] Nein, verwende Windows PowerShell (v5.x)
            echo.
            choice /c JN /n /m "PowerShell 7 installieren? [J/N]: "
            if errorlevel 2 (
                echo [INFO] Verwende Windows PowerShell (v5.x)
                set "USE_PS=powershell"
                set "PS_VERSION=5"
            ) else (
                echo.
                echo [INSTALL] Starte PowerShell 7 Installation...
                call "%~dp0install-ps7.bat"
                
                echo.
                echo [RECHECK] Pruefe PowerShell 7 Verfuegbarkeit nach Installation...
                
                REM Erweiterte PS7-Erkennung nach Installation
                echo [RECHECK] Warte 3 Sekunden auf PATH-Refresh...
                timeout /t 3 /nobreak >nul
                
                REM Multi-Level PS7 Detection (robust)
                where pwsh >nul 2>&1
                if %errorlevel%==0 (
                    echo [SUCCESS] PowerShell 7 gefunden ueber PATH
                    set "USE_PS=pwsh"
                    set "PS_VERSION=7"
                    goto :PS_DETECTION_DONE
                ) else (
                    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
                        echo [SUCCESS] PowerShell 7 ueber direkten Pfad gefunden
                        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
                        set "PS_VERSION=7"
                        goto :PS_DETECTION_DONE
                    ) else (
                        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
                            echo [SUCCESS] PowerShell 7 ueber Store-App gefunden
                            set "USE_PS=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"
                            set "PS_VERSION=7"
                            goto :PS_DETECTION_DONE
                        ) else (
                            echo [WARNING] PowerShell 7 nach Installation nicht gefunden
                            echo [FALLBACK] Verwende Windows PowerShell fuer diesen Start
                            set "USE_PS=powershell"
                            set "PS_VERSION=5"
                            pause
                        )
                    )
                )
            )
        )
    )
)

:PS_DETECTION_DONE
echo [INFO] PowerShell Version: %PS_VERSION%
echo.

REM ===== LAUNCHER LOGIC =====
if "%DIRECT_MODE%"=="DIRECT" (
    echo [INFO] Direct-Modus - starte Tool sofort
    goto :OPTION_1
)

REM ===== ERWEITERTE LAUNCHER-OPTIONEN =====
echo [*] Launcher-Optionen verfuegbar
echo.
echo [MENU] Waehle eine Option:
echo   [1] Hellion Tool direkt starten (Standard)
echo   [2] Update-Check durchfuehren
echo   [3] PowerShell 7 installieren/updaten
echo   [4] Git installieren/updaten
echo   [5] Emergency-Updater ausführen
echo   [0] Beenden
echo.
choice /c 123450 /n /m "Waehle Option [1/2/3/4/5/0]: "

if errorlevel 6 (
    echo [INFO] Launcher beendet
    exit /b 0
)
if errorlevel 5 (
    echo.
    echo [EMERGENCY] Starte Emergency-Updater...
    call "!LAUNCHER_DIR!\emergency-update.bat"
    echo.
    echo [*] Zurueck zum Launcher...
    timeout /t 2 /nobreak >nul
    echo.
)
if errorlevel 4 (
    echo.
    echo [GIT-INSTALL] Starte Git Installation...
    call "!LAUNCHER_DIR!\install-git.bat"
    echo.
    echo [*] Zurueck zum Launcher...
    timeout /t 2 /nobreak >nul
    echo.
)
if errorlevel 3 (
    echo.
    echo [PS7-INSTALL] Starte PowerShell 7 Installation...
    call "!LAUNCHER_DIR!\install-ps7.bat"
    echo.
    echo [*] Zurueck zum Launcher...
    timeout /t 2 /nobreak >nul
    echo.

    REM Nach PS7 Installation: Neuprüfung der PowerShell-Version
    echo [RECHECK] Pruefe PowerShell nach Installation...
    where pwsh >nul 2>&1
    if %errorlevel%==0 (
        echo [SUCCESS] PowerShell 7 jetzt verfuegbar - verwende PS7
        set "USE_PS=pwsh"
        set "PS_VERSION=7"
    ) else (
        if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
            echo [SUCCESS] PowerShell 7 installiert - verwende direkten Pfad
            set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
            set "PS_VERSION=7"
        ) else (
            echo [INFO] PowerShell 7 Installation beendet - verwende PS5
        )
    )
    echo.
)
if errorlevel 2 (
    echo.
    echo [UPDATE-CHECK] Starte Update-Pruefung...
    call "!LAUNCHER_DIR!\update-check.bat"
    echo.
    echo [*] Zurueck zum Launcher...
    timeout /t 2 /nobreak >nul
    echo.
)

REM Option 1 (oder Fallback): Hellion Tool starten
:OPTION_1
echo.

REM Pruefe ob Hauptscript existiert
if not exist "hellion_tool_main.ps1" (
    echo [ERROR] hellion_tool_main.ps1 nicht gefunden!
    echo [LOESUNG] Stelle sicher dass du im richtigen Verzeichnis bist
    pause
    exit /b 1
)

echo [*] Starte Hellion Power Tool...
echo.

REM Starte das Tool
if "%DEBUG_MODE%"=="1" (
    echo [DEBUG] Starte mit Debug-Modus
    "%USE_PS%" -NoProfile -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -DebugMode
) else (
    echo [NORMAL] Starte im Normal-Modus  
    "%USE_PS%" -NoProfile -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -ForceDebugLevel 0
)

echo.
echo [FINISHED] Tool beendet
echo.
echo [INFO] Launcher schliesst sich in 10 Sekunden automatisch...
echo [TIP] Druecke beliebige Taste um sofort zu schliessen
timeout /t 10 >nul
goto :EOF

REM ===== ROOT-VERZEICHNIS FINDER (100% SICHER) =====
REM Findet das Hellion Tool Root-Verzeichnis mit mehreren Fallback-Methoden
REM Parameter: %1=RESULT_VAR
:FIND_ROOT_DIRECTORY
set "RESULT_VAR=%~1"
set "FOUND_ROOT="

REM Methode 1: Standard-Annahme - Launcher ist in Launcher/-Subdir
set "TEST_ROOT=%LAUNCHER_DIR%\.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_1
if "!IS_VALID_1!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 2: Batch-Parameter %~dp0 verwenden
set "TEST_ROOT=%~dp0.."
call :VALIDATE_ROOT_DIR "!TEST_ROOT!" IS_VALID_2
if "!IS_VALID_2!"=="YES" (
    set "FOUND_ROOT=!TEST_ROOT!"
    goto :FOUND_ROOT_SUCCESS
)

REM Methode 3: Aufwärts-Suche vom aktuellen Verzeichnis
set "SEARCH_DIR=%CD%"
for /L %%i in (1,1,5) do (
    call :VALIDATE_ROOT_DIR "!SEARCH_DIR!" IS_VALID_3
    if "!IS_VALID_3!"=="YES" (
        set "FOUND_ROOT=!SEARCH_DIR!"
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!SEARCH_DIR!") do set "SEARCH_DIR=%%~dpj"
    set "SEARCH_DIR=!SEARCH_DIR:~0,-1!"
)

REM Methode 4: Suche nach charakteristischen Dateien
set "CHECK_DIR=%CD%"
for /L %%i in (1,1,3) do (
    if exist "!CHECK_DIR!\START.bat" if exist "!CHECK_DIR!\hellion_tool_main.ps1" (
        set "FOUND_ROOT=!CHECK_DIR!"
        goto :FOUND_ROOT_SUCCESS
    )
    for %%j in ("!CHECK_DIR!") do set "CHECK_DIR=%%~dpj"
    set "CHECK_DIR=!CHECK_DIR:~0,-1!"
)

goto :FOUND_ROOT_FAILED

:FOUND_ROOT_SUCCESS
REM Bereinige Pfad (entferne doppelte Backslashes, etc.)
for %%i in ("!FOUND_ROOT!") do set "FOUND_ROOT=%%~fi"
set "%RESULT_VAR%=!FOUND_ROOT!"
goto :EOF

:FOUND_ROOT_FAILED
set "%RESULT_VAR%="
goto :EOF

REM Validiert ob ein Verzeichnis das Hellion Root-Dir ist
REM Parameter: %1=TEST_DIR %2=RESULT_VAR
:VALIDATE_ROOT_DIR
set "TEST_DIR=%~1"
set "RESULT_VAR=%~2"

if not exist "!TEST_DIR!" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)

REM Prüfe auf charakteristische Dateien/Ordner
if not exist "!TEST_DIR!\config" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\config\version.txt" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\Launcher" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)
if not exist "!TEST_DIR!\modules" (
    set "%RESULT_VAR%=NO"
    goto :EOF
)

set "%RESULT_VAR%=YES"
goto :EOF