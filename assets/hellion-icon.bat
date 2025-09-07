@echo off
REM Icon-Generator für Hellion Power Tool
REM Erstellt ein einfaches Icon aus Windows-Ressourcen

REM Erstelle assets-Ordner falls nicht vorhanden
if not exist "%~dp0" mkdir "%~dp0" 2>nul

REM Verwende Windows shell32.dll Icon #21 (Werkzeug/Tool Icon)
REM Oder #68 (Computer/System Icon) als Alternative
echo Windows-System-Icon wird als Fallback verwendet
echo Icon-Pfad: %SystemRoot%\System32\shell32.dll,21