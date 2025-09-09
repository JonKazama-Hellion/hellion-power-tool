# Hellion Power Tool - Desktop Shortcut Creator with Custom Icon
# Supports PNG to ICO conversion for custom branding

Write-Host "=============================================================================="
Write-Host "                HELLION DESKTOP-VERKNUEPFUNG ERSTELLEN"
Write-Host "=============================================================================="
Write-Host ""

# Pfade definieren
$toolPath = Join-Path (Split-Path $PSScriptRoot -Parent) "START.bat"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Hellion Power Tool.lnk"

# Custom Icon Pfade
$customIco = Join-Path $PSScriptRoot "Gmark.ico"
$customPng = Join-Path $PSScriptRoot "Gmark.png"
$iconPath = "$env:SystemRoot\System32\shell32.dll,21"  # Default Windows Tool Icon

Write-Host "[*] Prüfe Custom-Icon Verfügbarkeit..."

# Prüfe vorhandene ICO-Datei
if (Test-Path $customIco) {
    $iconPath = $customIco
    Write-Host "[OK] Verwende vorhandene ICO: Gmark.ico" -ForegroundColor Green
} elseif (Test-Path $customPng) {
    Write-Host "[CONVERT] PNG gefunden, konvertiere zu ICO..." -ForegroundColor Yellow
    
    # PNG zu ICO Konvertierung
    try {
        Add-Type -AssemblyName System.Drawing
        
        # Lade PNG
        $pngImage = [System.Drawing.Image]::FromFile($customPng)
        
        # Erstelle Multi-Resolution Icon für bessere Windows-Darstellung
        $bitmap256 = New-Object System.Drawing.Bitmap($pngImage, 256, 256)
        $bitmap48 = New-Object System.Drawing.Bitmap($pngImage, 48, 48)
        $bitmap32 = New-Object System.Drawing.Bitmap($pngImage, 32, 32)
        $bitmap16 = New-Object System.Drawing.Bitmap($pngImage, 16, 16)
        
        # Verwende höchste Auflösung als Basis
        $icon = [System.Drawing.Icon]::FromHandle($bitmap256.GetHicon())
        
        # Speichere als ICO
        $fileStream = [System.IO.File]::Create($customIco)
        $icon.Save($fileStream)
        $fileStream.Close()
        
        # Cleanup
        $pngImage.Dispose()
        $bitmap256.Dispose()
        $bitmap48.Dispose()
        $bitmap32.Dispose()
        $bitmap16.Dispose()
        $icon.Dispose()
        
        if (Test-Path $customIco) {
            $iconPath = $customIco
            Write-Host "[SUCCESS] PNG zu ICO konvertiert: Gmark.ico" -ForegroundColor Green
        } else {
            throw "ICO-Datei wurde nicht erstellt"
        }
        
    } catch {
        Write-Host "[WARNING] PNG-Konvertierung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "[INFO] Verwende Windows Standard-Icon" -ForegroundColor Cyan
    }
} else {
    Write-Host "[INFO] Kein Custom-Icon gefunden, verwende Windows Standard" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[ICON] $iconPath" -ForegroundColor White
Write-Host ""

# Erstelle Desktop-Verknüpfung
Write-Host "[*] Erstelle Desktop-Verknüpfung..."

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $toolPath
    $Shortcut.WorkingDirectory = (Split-Path $toolPath -Parent)
    $Shortcut.Description = "Hellion Power Tool v7.1.5.1 - System-Optimierung und Reparatur"
    $Shortcut.IconLocation = $iconPath
    $Shortcut.WindowStyle = 1  # Normal window
    $Shortcut.Hotkey = ""      # Kein Hotkey
    $Shortcut.Save()
    
    # Zusätzlich: Registry-Eintrag für bessere Icon-Darstellung
    try {
        $shortcutName = [System.IO.Path]::GetFileNameWithoutExtension($shortcutPath)
        Write-Host "[OPTIMIZE] Optimiere Icon-Darstellung..." -ForegroundColor Cyan
    } catch {
        # Ignoriere Registry-Fehler
    }
    
    if (Test-Path $shortcutPath) {
        Write-Host ""
        Write-Host "[SUCCESS] Desktop-Verknuepfung erfolgreich erstellt!" -ForegroundColor Green
        Write-Host "[PFAD] $shortcutPath" -ForegroundColor White
        Write-Host ""
        Write-Host "[TIP] Du kannst das Tool jetzt direkt vom Desktop starten" -ForegroundColor Cyan
        
        # Zeige Icon-Info und refresh Icon-Cache
        if ($iconPath -eq $customIco) {
            Write-Host "[CUSTOM] Verwendet dein Gmark-Logo!" -ForegroundColor Magenta
            
            Write-Host "[REFRESH] Aktualisiere Icon-Cache für bessere Qualität..." -ForegroundColor Cyan
            try {
                # Icon-Cache refresh
                & ie4uinit.exe -show 2>$null
                Start-Sleep -Seconds 1
                & ie4uinit.exe -ClearIconCache 2>$null
                
                Write-Host "[TIP] Falls Icon noch pixelig: Desktop F5 drücken oder neu anmelden" -ForegroundColor Yellow
            } catch {
                Write-Host "[INFO] Icon-Cache Refresh nicht möglich - kein Problem" -ForegroundColor Gray
            }
        }
        
    } else {
        throw "Verknüpfung wurde nicht erstellt"
    }
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Verknuepfung konnte nicht erstellt werden" -ForegroundColor Red
    Write-Host "[GRUND] $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[LOESUNG] Versuche manuell oder pruefe Berechtigungen" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Druecke beliebige Taste um fortzufahren..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")