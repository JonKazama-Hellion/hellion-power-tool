@echo off
title Hellion Power Tool v7.1.2 "Fenrir"
color 0B

echo ==============================================================================
echo                HELLION POWER TOOL v7.1.2 "Fenrir"  
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
echo [*] Starte Hellion Power Tool...
timeout /t 1 /nobreak >nul

REM Rufe den einfachen Launcher auf
call launcher\simple-launcher.bat %DEBUG_MODE%

pause