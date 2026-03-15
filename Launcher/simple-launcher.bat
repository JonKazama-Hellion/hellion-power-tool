@echo off
setlocal enabledelayedexpansion
title Hellion Simple Launcher v7.2.0.0
color 0A

REM Debug-Mode Parameter
set "DEBUG_MODE=%1"
if "%DEBUG_MODE%"=="" set "DEBUG_MODE=0"

REM Direct-Mode Parameter (ueberspringt Menu)
set "DIRECT_MODE=%2"

echo.
echo   ================================================================
echo          HELLION SIMPLE LAUNCHER v7.2.0.0
echo          Hellion Online Media
echo   ================================================================
echo.
echo   Modus: Debug=%DEBUG_MODE%
echo.

REM ===== SICHERE VERZEICHNIS-ERKENNUNG =====
echo   Validiere Arbeitsverzeichnis...

REM Bestimme absoluten Pfad des Launchers (100% sicher)
set "LAUNCHER_DIR=%~dp0"
set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"

REM Intelligente Root-Verzeichnis Bestimmung (funktioniert von ROOT und /Launcher)

REM Pruefe ob wir bereits im Root-Verzeichnis sind
if exist "%CD%\hellion_tool_main.ps1" if exist "%CD%\config\version.txt" (
    set "ROOT_DIR=%CD%"
    echo   [OK] Root: !ROOT_DIR!
    goto :ROOT_FOUND
)

REM Pruefe ob wir im Launcher-Subdir sind (original Verhalten)
call :FIND_ROOT_DIRECTORY ROOT_DIR

if "!ROOT_DIR!"=="" (
    echo.
    echo   [ERROR] Root-Verzeichnis nicht gefunden!
    echo.
    echo   Der Simple-Launcher kann aufgerufen werden von:
    echo     1. Aus dem Root-Verzeichnis (via START.bat)
    echo     2. Aus dem Launcher/-Unterverzeichnis
    echo.
    echo   Empfehlung: Nutze START.bat im Root-Verzeichnis
    echo.
    pause
    exit /b 1
)

:ROOT_FOUND

echo   [OK] Launcher: !LAUNCHER_DIR!

REM Wechsel ins sichere Hauptverzeichnis
cd /d "!ROOT_DIR!"
echo   [OK] Arbeitsverzeichnis: !ROOT_DIR!
echo.

REM Finde PowerShell (Prioritaet: PS7 > PS5)
set "USE_PS=powershell"
set "PS_VERSION=5"

REM Multi-Level PS7 Detection (Phase 1)
where pwsh >nul 2>&1

if %errorlevel%==0 (
    echo   [OK] PowerShell 7 gefunden (PATH)
    set "USE_PS=pwsh"
    set "PS_VERSION=7"
    goto :PS_DETECTION_DONE
) else (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo   [OK] PowerShell 7 gefunden (Programm-Pfad)
        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
        set "PS_VERSION=7"
        goto :PS_DETECTION_DONE
    ) else (
        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
            echo   [OK] PowerShell 7 gefunden (Store)
            set "USE_PS=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"
            set "PS_VERSION=7"
            goto :PS_DETECTION_DONE
        ) else (
            echo.
            echo   PowerShell 7 nicht gefunden
            echo   Empfehlung: PS7 bietet bessere Performance
            echo.
            echo   [J] Ja, PowerShell 7 installieren (empfohlen)
            echo   [N] Nein, Windows PowerShell 5.x verwenden
            echo.
            choice /c JN /n /m "   PowerShell 7 installieren? [J/N]: "
            if errorlevel 2 (
                echo   Verwende Windows PowerShell (v5.x)
                set "USE_PS=powershell"
                set "PS_VERSION=5"
            ) else (
                echo.
                echo   Starte PowerShell 7 Installation...
                call "%~dp0install-ps7.bat"

                echo.
                echo   Pruefe Verfuegbarkeit nach Installation...
                timeout /t 3 /nobreak >nul

                REM Multi-Level PS7 Detection (robust)
                where pwsh >nul 2>&1
                if !errorlevel!==0 (
                    echo   [OK] PowerShell 7 verfuegbar (PATH)
                    set "USE_PS=pwsh"
                    set "PS_VERSION=7"
                    goto :PS_DETECTION_DONE
                ) else (
                    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
                        echo   [OK] PowerShell 7 verfuegbar (Programm-Pfad)
                        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
                        set "PS_VERSION=7"
                        goto :PS_DETECTION_DONE
                    ) else (
                        if exist "!LOCALAPPDATA!\Microsoft\WindowsApps\pwsh.exe" (
                            echo   [OK] PowerShell 7 verfuegbar (Store)
                            set "USE_PS=!LOCALAPPDATA!\Microsoft\WindowsApps\pwsh.exe"
                            set "PS_VERSION=7"
                            goto :PS_DETECTION_DONE
                        ) else (
                            echo   [WARNING] PowerShell 7 nach Installation nicht gefunden
                            echo   Verwende Windows PowerShell als Fallback
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
echo   PowerShell Version: %PS_VERSION%
echo.

REM ===== LAUNCHER LOGIC =====
if "%DIRECT_MODE%"=="DIRECT" (
    echo   Direct-Modus - starte Tool sofort
    goto :OPTION_1
)

REM ===== ERWEITERTE LAUNCHER-OPTIONEN =====
echo   ----------------------------------------------------------------
echo   --- ERWEITERTE OPTIONEN ---
echo.
echo   [1] Hellion Tool starten            (Standard)
echo   [2] Update-Check
echo   [3] PowerShell 7 installieren
echo   [4] Git installieren
echo   [5] Emergency-Updater
echo   [0] Beenden
echo   ----------------------------------------------------------------
echo.
choice /c 123450 /n /m "   Option waehlen [1/2/3/4/5/0]: "

if errorlevel 6 goto :OPT_EXIT
if errorlevel 5 goto :OPT_EMERGENCY
if errorlevel 4 goto :OPT_GIT
if errorlevel 3 goto :OPT_PS7
if errorlevel 2 goto :OPT_UPDATE
goto :OPTION_1

:OPT_EXIT
echo.
echo   Launcher beendet.
exit /b 0

:OPT_EMERGENCY
echo.
echo   Starte Emergency-Updater...
call "!LAUNCHER_DIR!\emergency-update.bat"
echo.
timeout /t 2 /nobreak >nul
goto :OPTION_1

:OPT_GIT
echo.
echo   Starte Git Installation...
call "!LAUNCHER_DIR!\install-git.bat"
echo.
timeout /t 2 /nobreak >nul
goto :OPTION_1

:OPT_PS7
echo.
echo   Starte PowerShell 7 Installation...
call "!LAUNCHER_DIR!\install-ps7.bat"
echo.
REM Nach PS7 Installation: Neupruefung der PowerShell-Version
echo   Pruefe PowerShell nach Installation...
where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] PowerShell 7 jetzt verfuegbar
    set "USE_PS=pwsh"
    set "PS_VERSION=7"
) else (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo   [OK] PowerShell 7 installiert (Programm-Pfad)
        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
        set "PS_VERSION=7"
    ) else (
        echo   PowerShell 7 nicht gefunden - verwende PS5
    )
)
echo.
timeout /t 2 /nobreak >nul
goto :OPTION_1

:OPT_UPDATE
echo.
echo   Starte Update-Pruefung...
call "!LAUNCHER_DIR!\update-check.bat"
echo.
timeout /t 2 /nobreak >nul

REM Option 1 (oder Fallback): Hellion Tool starten
:OPTION_1
echo.

REM Pruefe ob Hauptscript existiert
if not exist "hellion_tool_main.ps1" (
    echo   [ERROR] hellion_tool_main.ps1 nicht gefunden!
    echo   Stelle sicher dass du im richtigen Verzeichnis bist
    pause
    exit /b 1
)

echo   Starte Hellion Power Tool...
echo.

REM Starte das Tool
if "%DEBUG_MODE%"=="1" (
    echo   Modus: Debug
    "%USE_PS%" -NoProfile -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -DebugMode
) else (
    echo   Modus: Normal
    "%USE_PS%" -NoProfile -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -ForceDebugLevel 0
)

echo.
echo   ================================================================
echo   Tool beendet.
echo   Launcher schliesst sich in 10 Sekunden...
echo   (Beliebige Taste zum Schliessen)
echo   ================================================================
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

REM Methode 3: Aufwaerts-Suche vom aktuellen Verzeichnis
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

REM Pruefe auf charakteristische Dateien/Ordner
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
