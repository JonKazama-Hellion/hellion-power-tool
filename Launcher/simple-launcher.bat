@echo off
title Hellion Simple Launcher
color 0B

REM Debug-Mode Parameter
set "DEBUG_MODE=%1"
if "%DEBUG_MODE%"=="" set "DEBUG_MODE=0"

echo ==============================================================================  
echo                    HELLION SIMPLE LAUNCHER
echo                 (Defender-Safe, Minimal, Robust)
echo ==============================================================================
echo [INFO] Debug-Mode: %DEBUG_MODE%
echo.

REM Wechsel ins Hauptverzeichnis
cd /d "%~dp0.."

REM Finde PowerShell (Priorität: PS7 → PS5)
set "USE_PS=powershell"
set "PS_VERSION=5"

REM Multi-Level PS7 Detection (Phase 1)
where pwsh >nul 2>&1

if %errorlevel%==0 (
    echo [OK] PowerShell 7 gefunden über PATH (empfohlen)
    set "USE_PS=pwsh"
    set "PS_VERSION=7"
    goto :PS_DETECTION_DONE
) else (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        echo [OK] PowerShell 7 über direkten Pfad gefunden
        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
        set "PS_VERSION=7"
        goto :PS_DETECTION_DONE
    ) else (
        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
            echo [OK] PowerShell 7 über Store-Installation gefunden
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
                    echo [SUCCESS] PowerShell 7 gefunden über PATH
                    set "USE_PS=pwsh"
                    set "PS_VERSION=7"
                    goto :PS_DETECTION_DONE
                ) else (
                    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
                        echo [SUCCESS] PowerShell 7 über direkten Pfad gefunden
                        set "USE_PS=C:\Program Files\PowerShell\7\pwsh.exe"
                        set "PS_VERSION=7"
                        goto :PS_DETECTION_DONE
                    ) else (
                        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" (
                            echo [SUCCESS] PowerShell 7 über Store-App gefunden
                            set "USE_PS=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"
                            set "PS_VERSION=7"
                            goto :PS_DETECTION_DONE
                        ) else (
                            echo [WARNING] PowerShell 7 nach Installation nicht gefunden
                            echo [FALLBACK] Verwende Windows PowerShell für diesen Start
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

REM Update Check anbieten
echo [*] Update-Check verfuegbar
choice /c JN /n /m "Update-Check durchfuehren? [J/N]: "
if not errorlevel 2 (
    echo.
    echo [UPDATE-CHECK] Starte Update-Pruefung...
    call "%~dp0update-check.bat"
    echo.
    echo [*] Zurueck zum Launcher...
    timeout /t 2 /nobreak >nul
    echo.
)
echo.

REM Prüfe ob Hauptscript existiert
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