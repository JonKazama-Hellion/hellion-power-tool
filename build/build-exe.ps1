# ===================================================================
# HELLION POWER TOOL — PS2EXE Build-Script
# Kompiliert hellion_gui.ps1 zu hellion-gui.exe
# Nutzung:
#   .\build-exe.ps1 -Install   → PS2EXE Modul installieren
#   .\build-exe.ps1             → GUI kompilieren
# ===================================================================

param([switch]$Install)

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if ($Install) {
    Write-Host "Installiere PS2EXE Modul..." -ForegroundColor Cyan
    Install-Module ps2exe -Scope CurrentUser -Force
    Write-Host "PS2EXE erfolgreich installiert." -ForegroundColor Green
    return
}

if (-not (Get-Module ps2exe -ListAvailable)) {
    Write-Host "PS2EXE nicht gefunden!" -ForegroundColor Red
    Write-Host "Installiere zuerst mit: .\build-exe.ps1 -Install" -ForegroundColor Yellow
    return
}

$inputFile  = Join-Path $root "src\hellion_gui.ps1"
$outputFile = Join-Path $root "hellion-gui.exe"
$iconFile   = Join-Path $root "assets\icons\Gmark.ico"

if (-not (Test-Path $inputFile)) {
    Write-Host "Fehler: $inputFile nicht gefunden!" -ForegroundColor Red
    return
}

Write-Host "Kompiliere Hellion Power Tool GUI..." -ForegroundColor Cyan
Write-Host "  Input:  $inputFile" -ForegroundColor Gray
Write-Host "  Output: $outputFile" -ForegroundColor Gray

$params = @{
    InputFile  = $inputFile
    OutputFile = $outputFile
    noConsole    = $true
    requireAdmin = $true
    STA          = $true
    Title      = "Hellion Power Tool"
    Version    = "8.0.0.0"
    Company    = "Hellion Online Media"
    Copyright  = "Hellion Online Media 2026"
}

if (Test-Path $iconFile) {
    $params.IconFile = $iconFile
    Write-Host "  Icon:   $iconFile" -ForegroundColor Gray
}

try {
    Invoke-PS2EXE @params
    if (Test-Path $outputFile) {
        $size = (Get-Item $outputFile).Length / 1KB
        Write-Host ""
        Write-Host "Build erfolgreich!" -ForegroundColor Green
        Write-Host "  Datei:  $outputFile" -ForegroundColor Green
        Write-Host "  Größe: $([int]$size) KB" -ForegroundColor Green
    }
} catch {
    Write-Host "Build fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
}
