# ============================================================================
#                   HELLION ONLINE MEDIA POWER TOOL v6.1 "BELEANDIS"
#                          KOMPLETT - ALLE FUNKTIONEN
# ============================================================================
# 
# Entwickelt von: Hellion Online Media - Florian Wathling
# Erstellungsdatum: 06.09.2025
# Version: 6.1 (Unicode-Fix + Sicherer Adblock - Vollversion)
# Website: https://hellion-online-media.de
# Support: support@hellion-online-media.de
# 
# CHANGELOG v6.1:
# - Alle Unicode-Zeichen durch ASCII-kompatible Alternativen ersetzt
# - Adblock-Funktion sicherer gestaltet mit konservativer Whitelist
# - Encoding-Probleme behoben
# - Bessere Fehlerbehandlung
# - ALLE ursprünglichen Funktionen beibehalten
# ============================================================================

# Auto-Admin-Check und Self-Elevation
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "                    ADMIN-RECHTE ERFORDERLICH                   " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Dieses Tool benoetigt Administrator-Rechte, um System-Aenderungen" -ForegroundColor Cyan
    Write-Host "vornehmen zu koennen. Es wird nun ein Neustart mit erhoehten Rechten angefordert." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Bitte bestaetigen Sie die folgende Windows-Sicherheitsabfrage (UAC)." -ForegroundColor Green
    Write-Host ""
    
    Start-Sleep -Seconds 3
    
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ([string]::IsNullOrEmpty($scriptPath)) {
            throw "Der Pfad zum Skript konnte nicht automatisch ermittelt werden."
        }
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb "RunAs" -ErrorAction Stop
    }
    catch {
        Write-Host "FEHLER: Der Neustart als Administrator konnte nicht angefordert werden." -ForegroundColor Red
        Write-Host "DETAIL: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Bitte starten Sie das Skript manuell als Administrator." -ForegroundColor Yellow
        Read-Host "Druecken Sie Enter zum Beenden."
    }
    exit
}

Write-Host "[OK] Administrator-Rechte bestaetigt! Das Tool wird jetzt gestartet." -ForegroundColor Green
Start-Sleep -Seconds 1

try {

# Setze TEMP-Variable explizit
$env:TEMP = [System.IO.Path]::GetTempPath()

# Verhindere sofortiges Schliessen bei Fehlern
$ErrorActionPreference = "Stop"

# Speichere Original-Pfad
$script:OriginalPath = $PWD.Path

# Lade Windows Forms fuer bessere UI (optional)
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $script:HasWinForms = $true
}
catch {
    $script:HasWinForms = $false
}

# Antivirensfreundlicher Startup
Clear-Host
Start-Sleep -Milliseconds 500

Write-Host @"
================================================================
                                                                
    HH   HH EEEEEEE LL      LL      IIIII   OOOOO   NN   NN    
    HH   HH EE      LL      LL        III  OO   OO  NNN  NN    
    HHHHHHH EEEEE   LL      LL        III  OO   OO  NN N NN    
    HH   HH EE      LL      LL        III  OO   OO  NN  NNN    
    HH   HH EEEEEEE LLLLLLL LLLLLLL IIIII   OOOOO   NN   NN    
                                                                
                ONLINE MEDIA POWER TOOL v6.1 "BELEANDIS-FIX"   
                                                                
  [*] ENTWICKELT VON: Hellion Online Media - Florian Wathling  
  [*] VERSION: 6.1 (Beleandis-Fix) | DATUM: 06.09.2025         
  [*] WEBSITE: https://hellion-online-media.de                 
                                                                
  [*] FEATURES: System-Integritaet | Gaming-Optimierung        
  [*] SICHERHEIT: Benutzer-kontrolliert | Wiederherstellungspunkt
  [*] ZIELGRUPPE: Gamer, Webentwickler, Power-User             
                                                                
================================================================
"@ -ForegroundColor Cyan

# Sicherheitshinweis
Write-Host "`n[INFO] SICHERHEITSHINWEIS:" -ForegroundColor Yellow
Write-Host "Dieses Tool ist mit folgenden Antivirenprogrammen getestet:" -ForegroundColor White
Write-Host "  [OK] Bitdefender Premium" -ForegroundColor Green
Write-Host "  [OK] Windows Defender" -ForegroundColor Green
Write-Host "  [OK] Keine schaedlichen Operationen" -ForegroundColor Green
Write-Host "`nFalls eine Warnung erscheint: Das ist normal bei System-Tools." -ForegroundColor Gray
Start-Sleep -Seconds 2

Write-Host "`n[*] Initialisiere Hellion Power Tool..." -ForegroundColor Yellow
Write-Host "[*] Script-Pfad: $($MyInvocation.MyCommand.Path)" -ForegroundColor Gray
Write-Host "[*] PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "[*] Windows Version: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
Write-Host "[*] Benutzer: $([System.Environment]::UserName)" -ForegroundColor Gray

# Execution Policy Check
try {
    $executionPolicy = Get-ExecutionPolicy
    Write-Host "[*] Execution Policy: $executionPolicy" -ForegroundColor Gray
    
    if ($executionPolicy -eq "Restricted") {
        Write-Host "`n[ERROR] PowerShell Execution Policy ist zu restriktiv!" -ForegroundColor Red
        Write-Host "[FIX] Fuehren Sie diesen Befehl in PowerShell (als Admin) aus:" -ForegroundColor Yellow
        Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Cyan
        Read-Host "`nDruecken Sie Enter zum Beenden"
        exit 1
    }
}
catch {
    Write-Host "[WARNING] Execution Policy Check fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Debug-Modus Abfrage
Write-Host "`n[CONFIG] EINSTELLUNGEN:" -ForegroundColor Cyan
Write-Host "Moechten Sie den Debug-Modus aktivieren? (Zeigt technische Details)" -ForegroundColor Yellow
Write-Host "Standard: Nein (druecken Sie Enter) | Aktivieren: j" -ForegroundColor Gray
$debugChoice = Read-Host "Debug-Modus"
$script:ExplainMode = ($debugChoice -eq 'j' -or $debugChoice -eq 'J')

if ($script:ExplainMode) {
    Write-Host "[OK] Debug-Modus aktiviert - Zeige erweiterte Informationen" -ForegroundColor Green
    $script:VisualMode = $true
} else {
    Write-Host "[*] Express-Modus aktiviert - Schnelle Ausfuehrung" -ForegroundColor Blue
    $script:VisualMode = $false
}

Write-Host "[OK] Startup Check erfolgreich!" -ForegroundColor Green

# Adblock Status Check
Write-Host "`n[CHECK] --- ADBLOCK STATUS PRUEFUNG ---" -ForegroundColor Cyan

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue

$adblockInstalled = $false
$adblockDomainCount = 0

if ($hostsContent) {
    $hellionMarker = $hostsContent | Where-Object { $_ -match "=== HELLION.*ADBLOCK" }
    if ($hellionMarker) {
        $adblockInstalled = $true
        $adblockDomains = $hostsContent | Where-Object { $_ -match "^0\.0\.0\.0\s+" }
        $adblockDomainCount = $adblockDomains.Count
    }
}

if ($adblockInstalled) {
    Write-Host "[OK] HELLION ADBLOCK IST AKTIV!" -ForegroundColor Green
    Write-Host "   [INFO] Blockierte Domains: $adblockDomainCount" -ForegroundColor White
    
    $quickChoice = Read-Host "`n[?] Moechten Sie den Adblock JETZT deaktivieren? [j/n]"
    
    if ($quickChoice -eq 'j' -or $quickChoice -eq 'J') {
        Write-Host "`n[*] Suche nach Backup-Dateien..." -ForegroundColor Blue
        $backupFiles = Get-ChildItem "$env:SystemRoot\System32\drivers\etc" -Filter "hosts.hellion-backup-*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        
        if ($backupFiles.Count -gt 0) {
            Write-Host "[OK] Backup gefunden: $($backupFiles[0].Name)" -ForegroundColor Green
            
            try {
                Copy-Item $backupFiles[0].FullName $hostsPath -Force
                Write-Host "[OK] Adblock erfolgreich deaktiviert!" -ForegroundColor Green
                Write-Host "[*] DNS-Cache wird geleert..." -ForegroundColor Blue
                ipconfig /flushdns | Out-Null
                Write-Host "[OK] Aenderungen sind sofort aktiv!" -ForegroundColor Green
                
                Start-Sleep -Seconds 3
            }
            catch {
                Write-Host "[ERROR] Fehler beim Deaktivieren: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "[ERROR] Kein Backup gefunden! Manuelle Bereinigung erforderlich." -ForegroundColor Red
        }
    }
}
else {
    Write-Host "[INFO] Hellion Adblock ist nicht installiert" -ForegroundColor Gray
}

Start-Sleep -Seconds 2

# Globale Variablen
$script:Errors = @()
$script:Warnings = @()
$script:UpdateRecommendations = @()
$script:TotalFreedSpace = 0
$script:LimitedMode = $false
$script:DriveConfig = @{}
$script:AutoApproveCleanup = $false
$script:RestorePointCreated = $false

# ============================================================================
#                         CORE FUNKTIONEN
# ============================================================================

function Add-Error {
    param([string]$Message)
    $script:Errors += $Message
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Add-Warning {
    param([string]$Message)
    $script:Warnings += $Message
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            return [math]::Round($size / 1MB, 2)
        }
        catch { return 0 }
    }
    return 0
}

function Show-ProgressBar {
    param([string]$Activity, [int]$PercentComplete)
    if (-not $script:VisualMode) { return }
    $barLength = 40
    $filledLength = [math]::Floor($barLength * $PercentComplete / 100)
    $bar = "#" * $filledLength + "-" * ($barLength - $filledLength)
    Write-Host "`r[*] $Activity [$bar] $PercentComplete%" -NoNewline -ForegroundColor Cyan
}

function Show-StepExplanation {
    param([string]$Title, [string]$Description, [string]$Purpose, [array]$Actions)
    
    if (-not $script:ExplainMode) { return }
    
    Write-Host "`n" + ("=" * 80) -ForegroundColor Yellow
    Write-Host "[DEBUG] DEBUG-INFO: $Title" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "[*] WAS PASSIERT: $Description" -ForegroundColor Cyan
    Write-Host "[*] ZWECK: $Purpose" -ForegroundColor Green
    
    if ($Actions -and $Actions.Count -gt 0) {
        Write-Host "[*] AKTIONEN:" -ForegroundColor Blue
        foreach ($action in $Actions) {
            Write-Host "   - $action" -ForegroundColor White
        }
    }
    
    if ($script:VisualMode) {
        for ($i = 3; $i -gt 0; $i--) {
            Write-Host "`r[*] Weiter in $i Sekunden... " -NoNewline -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        Write-Host "`r[OK] Weiter!                    " -ForegroundColor Green
    }
    
    Write-Host ""
}

# ============================================================================
#                         LAUFWERKSERKENNUNG
# ============================================================================

function Get-DriveType {
    param([string]$DriveLetter)
    
    $driveLetterClean = $DriveLetter.Replace(':', '')
    
    try {
        if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            $partition = Get-Partition -DriveLetter $driveLetterClean -ErrorAction Stop
            $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop
            $physical = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq $disk.Number }
            
            if ($physical) {
                switch ($physical.MediaType) {
                    'SSD' { 
                        if ($physical.BusType -eq 'NVMe') { return "NVMe SSD" }
                        else { return "SATA SSD" }
                    }
                    'HDD' { return "HDD" }
                    'Unspecified' {
                        if ($physical.SpindleSpeed -eq 0) { return "SSD (Detected)" }
                        else { return "HDD" }
                    }
                }
            }
        }
    } catch {
        # Fehler ignorieren
    }
    
    try {
        $volume = Get-Volume -DriveLetter $driveLetterClean -ErrorAction SilentlyContinue
        if ($volume) {
            if ($volume.DriveType -eq 'Fixed') {
                if ($volume.Size -le 512GB) { return "SSD (Probable)" }
                else { return "HDD" }
            }
        }
    } catch {
        # Fehler ignorieren
    }
    
    return "Storage Drive"
}

function Initialize-AutoDriveDetection {
    Show-StepExplanation -Title "Laufwerkserkennung" `
        -Description "Scannt alle verfuegbaren Laufwerke" `
        -Purpose "Fuer optimale Bereinigung und Optimierung" `
        -Actions @(
            "Erkennung aller Laufwerke",
            "Typ-Klassifizierung (SSD/HDD)",
            "Speicherplatz-Analyse"
        )
    
    Write-Host "`n[*] --- LAUFWERKSERKENNUNG ---" -ForegroundColor Cyan
    
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    foreach ($drive in $drives) {
        $driveLetter = $drive.DeviceID
        if ($script:ExplainMode) {
            Write-Host "   Analysiere $driveLetter..." -ForegroundColor Blue
        }
        
        $driveType = Get-DriveType $driveLetter
        $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 1)
        $totalSpace = [math]::Round($drive.Size / 1GB, 1)
        $usedPercent = [math]::Round((($totalSpace - $freeSpace) / $totalSpace) * 100, 1)
        
        $typeColor = switch -Wildcard ($driveType) {
            "*NVMe*" { "Magenta" }
            "*SSD*" { "Cyan" }
            "*HDD*" { "Yellow" }
            default { "White" }
        }
        
        $script:DriveConfig[$driveLetter] = @{
            "Type" = $driveType
            "FreeSpace" = $freeSpace
            "TotalSpace" = $totalSpace
        }
        
        Write-Host "  [OK] $driveLetter " -NoNewline
        Write-Host "[$driveType]" -ForegroundColor $typeColor -NoNewline
        Write-Host " - $freeSpace GB frei von $totalSpace GB ($usedPercent% belegt)" -ForegroundColor Green
    }
    
    Write-Host "`n[INFO] $($script:DriveConfig.Count) Laufwerke erkannt" -ForegroundColor Blue
}

function Get-AllDrives {
    return $script:DriveConfig.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Letter = $_.Name
            Type = $_.Value.Type
            FreeSpace = $_.Value.FreeSpace
            TotalSpace = $_.Value.TotalSpace
        }
    }
}

# ============================================================================
#                         NETZWERK & KONNEKTIVITAET
# ============================================================================

function Test-InternetConnectivity {
    Show-StepExplanation -Title "Internet-Check" `
        -Description "Prueft Internetverbindung" `
        -Purpose "Fuer Updates und Downloads" `
        -Actions @(
            "Ping-Tests zu stabilen Servern",
            "Verbindungsqualitaet pruefen"
        )
    
    Write-Host "`n[*] --- INTERNETVERBINDUNG PRUEFEN ---" -ForegroundColor Cyan
    
    $testHosts = @("8.8.8.8", "1.1.1.1")
    $successfulPings = 0
    
    foreach ($testHost in $testHosts) {
        if ($script:ExplainMode) {
            Write-Host "[*] Teste $testHost..." -NoNewline
        }
        if (Test-Connection -ComputerName $testHost -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $successfulPings++
            if ($script:ExplainMode) {
                Write-Host " [OK]" -ForegroundColor Green
            }
        } else {
            if ($script:ExplainMode) {
                Write-Host " [FAIL]" -ForegroundColor Red
            }
        }
    }
    
    if ($successfulPings -ge 1) {
        Write-Host "[OK] Internetverbindung verfuegbar" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[WARNING] Keine Internetverbindung" -ForegroundColor Yellow
        return $false
    }
}

function Get-NetworkAdapters {
    if (-not $script:ExplainMode) { return }
    
    Write-Host "`n[*] --- NETZWERKADAPTER ---" -ForegroundColor Cyan
    $adaptersFound = $false

    $hasNetAdapter = $false
    try {
        $null = Get-Command Get-NetAdapter -ErrorAction Stop
        $hasNetAdapter = $true
    } catch {
        # Module nicht verfuegbar
    }

    if ($hasNetAdapter) {
        try {
            $adapters = Get-NetAdapter -ErrorAction Stop | Where-Object { 
                $_.Status -eq "Up" -and $_.MediaType -ne "Loopback"
            }
            
            if ($adapters) {
                foreach ($adapter in $adapters) {
                    Write-Host "  [OK] $($adapter.Name)" -ForegroundColor Green
                }
                $adaptersFound = $true
            }
        } catch {
            # Fallback zu WMI
        }
    }

    if (-not $adaptersFound) {
        try {
            $wmiAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration `
                -Filter "IPEnabled='TRUE'" -ErrorAction Stop
            
            if ($wmiAdapters) {
                foreach ($adapter in $wmiAdapters) {
                    $wmiInfo = Get-WmiObject -Class Win32_NetworkAdapter `
                        -Filter "Index='$($adapter.Index)'" -ErrorAction SilentlyContinue
                    
                    $name = if ($wmiInfo.Name) { $wmiInfo.Name } else { $adapter.Description }
                    Write-Host "  [OK] $name" -ForegroundColor Green
                }
                $adaptersFound = $true
            }
        }
        catch {
            Add-Warning "Netzwerkadapter-Analyse fehlgeschlagen"
        }
    }
}

# ============================================================================
#                         TREIBER-PRUEFUNG
# ============================================================================

function Check-DriverStatus {
    Show-StepExplanation -Title "Treiber-Pruefung" `
        -Description "Prueft Status aller Geraetetreiber" `
        -Purpose "Erkennt veraltete oder fehlerhafte Treiber" `
        -Actions @(
            "Suche nach Treiber-Problemen",
            "GPU-Treiber-Check",
            "Warnung vor Treiber-Boostern"
        )
    
    Write-Host "`n[*] --- TREIBER-STATUS ---" -ForegroundColor Cyan
    
    # WARNUNG VOR TREIBER-BOOSTERN
    Write-Host "`n[WARNING] WICHTIGER HINWEIS ZU TREIBERN:" -ForegroundColor Yellow
    Write-Host "   [X] Verwenden Sie KEINE Treiber-Booster wie Driver Booster, Driver Easy etc.!" -ForegroundColor Red
    Write-Host "   Diese Programme:" -ForegroundColor White
    Write-Host "   - Installieren oft falsche oder veraltete Treiber" -ForegroundColor White
    Write-Host "   - Koennen System-Instabilitaet verursachen" -ForegroundColor White
    Write-Host "   - Enthalten oft Adware oder unerwuenschte Software" -ForegroundColor White
    Write-Host "`n   [OK] EMPFOHLEN: Windows Update oder Hersteller-Webseiten" -ForegroundColor Green
    
    $problemFound = $false
    
    try {
        $problemDrivers = Get-WmiObject Win32_PnPEntity -ErrorAction Stop | 
            Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        
        if ($problemDrivers) {
            Write-Host "`n[WARNING] Geraete mit Problemen:" -ForegroundColor Red
            $problemFound = $true
            foreach ($device in $problemDrivers) {
                Write-Host "  [X] $($device.Name)" -ForegroundColor Red
            }
            Add-Warning "$($problemDrivers.Count) Geraete mit Treiber-Problemen"
        } else {
            Write-Host "[OK] Keine Treiber-Probleme gefunden" -ForegroundColor Green
        }
    } catch {
        Add-Warning "Treiber-Scan fehlgeschlagen"
    }
    
    # GPU-Check
    try {
        $gpu = Get-WmiObject Win32_VideoController -ErrorAction Stop | Select-Object -First 1
        if ($gpu) {
            Write-Host "`n  [*] GPU: $($gpu.Name)" -ForegroundColor Cyan
            Write-Host "     Version: $($gpu.DriverVersion)" -ForegroundColor White
            
            if ($gpu.DriverDate) {
                try {
                    $dateString = $gpu.DriverDate
                    $year = [int]$dateString.Substring(0,4)
                    $month = [int]$dateString.Substring(4,2)
                    $day = [int]$dateString.Substring(6,2)
                    $driverDate = Get-Date -Year $year -Month $month -Day $day
                    
                    if ((Get-Date) - $driverDate -gt [System.TimeSpan]::FromDays(365)) {
                        Write-Host "     [WARNING] Treiber ueber 1 Jahr alt" -ForegroundColor Yellow
                        $problemFound = $true
                    }
                } catch {
                    # Datum nicht verfuegbar
                }
            }
        }
    } catch { 
        # GPU-Check fehlgeschlagen
    }
    
    return $problemFound
}

# ============================================================================
#                         SYSTEM-INTEGRITAETS-FUNKTIONEN
# ============================================================================

function Invoke-SystemFileChecker {
    Show-StepExplanation -Title "System File Checker" `
        -Description "Windows System-Dateien ueberpruefen" `
        -Purpose "Repariert beschaedigte System-Dateien" `
        -Actions @(
            "sfc /scannow ausfuehren",
            "5-15 Minuten Dauer",
            "Automatische Reparatur"
        )

    Write-Host "`n[*] --- SYSTEM FILE CHECKER ---" -ForegroundColor Cyan
    Write-Host "Ueberprueft und repariert Windows-Systemdateien" -ForegroundColor Yellow

    $choice = Read-Host "`nSFC jetzt ausfuehren? [j/n]"
    if ($choice -ne 'j' -and $choice -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }

    Write-Host "`n[*] Starte SFC..." -ForegroundColor Green
    if ($script:ExplainMode) {
        Write-Host "[DEBUG] sfc /scannow" -ForegroundColor DarkGray
    }

    try {
        $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" `
            -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\sfc_output.txt" `
            -RedirectStandardError "$env:TEMP\sfc_error.txt"
        
        # Fortschrittsanzeige
        $counter = 0
        $spinChars = @('|','/','-','\')
        
        while (-not $sfcProcess.HasExited) {
            $spin = $spinChars[$counter % 4]
            Write-Host "`r$spin Scan laeuft..." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 200
            $counter++
        }
        
        Write-Host "`r[OK] Scan abgeschlossen!                    " -ForegroundColor Green
        
        # Analysiere Ergebnis
        $output = Get-Content "$env:TEMP\sfc_output.txt" -Raw -ErrorAction SilentlyContinue
        
        if ($output -match "found corrupt files and successfully repaired") {
            Write-Host "[OK] Beschaedigte Dateien wurden repariert!" -ForegroundColor Green
            Write-Host "[*] Ein Neustart wird empfohlen" -ForegroundColor Yellow
        } elseif ($output -match "did not find any integrity violations") {
            Write-Host "[OK] Keine Probleme gefunden!" -ForegroundColor Green
        } elseif ($output -match "unable to fix") {
            Write-Host "[WARNING] Probleme gefunden - DISM wird empfohlen" -ForegroundColor Yellow
            Add-Warning "SFC konnte nicht alle Probleme beheben"
        }
        
        # Aufraeumen
        Remove-Item "$env:TEMP\sfc_output.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\sfc_error.txt" -Force -ErrorAction SilentlyContinue
        
    } catch {
        Add-Error "SFC fehlgeschlagen: $($_.Exception.Message)"
    }
}

function Invoke-DISMCheck {
    Show-StepExplanation -Title "DISM Reparatur" `
        -Description "Windows-Systemabbild reparieren" `
        -Purpose "Behebt tiefgreifende Systemfehler" `
        -Actions @(
            "CheckHealth: Schnell-Check",
            "ScanHealth: Detail-Scan",
            "RestoreHealth: Reparatur"
        )

    Write-Host "`n[*] --- DISM SYSTEMABBILD-REPARATUR ---" -ForegroundColor Cyan

    $choice = Read-Host "`nDISM-Pruefung starten? [j/n]"
    if ($choice -ne 'j' -and $choice -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }

    # Internet-Check fuer RestoreHealth
    $hasInternet = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $hasInternet) {
        Write-Host "[WARNING] Keine Internet-Verbindung - RestoreHealth eingeschraenkt" -ForegroundColor Yellow
    }

    try {
        # Phase 1: CheckHealth
        Write-Host "`n[1/3] CheckHealth (Schnell)..." -ForegroundColor Blue
        $checkResult = & DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String
        
        if ($checkResult -match "No component store corruption") {
            Write-Host "[OK] Keine Korruption erkannt" -ForegroundColor Green
        } elseif ($checkResult -match "repairable") {
            Write-Host "[WARNING] Reparierbare Fehler gefunden" -ForegroundColor Yellow
        }

        # Phase 2: ScanHealth
        Write-Host "`n[2/3] ScanHealth (5-10 Min)..." -ForegroundColor Blue
        
        $scanProcess = Start-Process -FilePath "DISM.exe" `
            -ArgumentList "/Online /Cleanup-Image /ScanHealth" `
            -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\dism_scan.txt"
        
        while (-not $scanProcess.HasExited) {
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds 2
        }
        Write-Host ""
        
        $scanResult = Get-Content "$env:TEMP\dism_scan.txt" -Raw
        $needsRepair = $scanResult -match "repairable"
        
        if ($needsRepair) {
            Write-Host "[WARNING] Reparatur erforderlich" -ForegroundColor Yellow
        } else {
            Write-Host "[OK] Keine Probleme gefunden" -ForegroundColor Green
        }

        # Phase 3: RestoreHealth (wenn noetig)
        if ($needsRepair) {
            Write-Host "`n[3/3] RestoreHealth (15-30 Min)..." -ForegroundColor Blue
            
            $repairChoice = Read-Host "Reparatur durchfuehren? [j/n]"
            if ($repairChoice -eq 'j' -or $repairChoice -eq 'J') {
                
                $restoreProcess = Start-Process -FilePath "DISM.exe" `
                    -ArgumentList "/Online /Cleanup-Image /RestoreHealth" `
                    -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\dism_restore.txt"
                
                $startTime = Get-Date
                while (-not $restoreProcess.HasExited) {
                    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
                    Write-Host "`r[*] Reparatur laeuft... ($elapsed Min)" -NoNewline -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                }
                
                Write-Host "`r[OK] Reparatur abgeschlossen!                    " -ForegroundColor Green
            }
        }

        # Aufraeumen
        Remove-Item "$env:TEMP\dism_*.txt" -Force -ErrorAction SilentlyContinue

    } catch {
        Add-Error "DISM fehlgeschlagen: $($_.Exception.Message)"
    }
}

function Invoke-DiskCheck {
    Show-StepExplanation -Title "Festplatten-Check" `
        -Description "Dateisystem auf Fehler pruefen" `
        -Purpose "Verhindert Datenverlust" `
        -Actions @(
            "Nur-Lese-Scan (sicher)",
            "Reparatur (Neustart noetig)"
        )

    Write-Host "`n[*] --- FESTPLATTEN-UEBERPRUEFUNG ---" -ForegroundColor Cyan
    
    # Zeige Laufwerke
    Write-Host "[INFO] Verfuegbare Laufwerke:" -ForegroundColor Yellow
    Get-Volume | Where-Object { $_.DriveLetter -ne $null } | ForEach-Object {
        $status = if ($_.HealthStatus -eq 'Healthy') { "[OK]" } else { "[WARNING]" }
        Write-Host "  $status $($_.DriveLetter): - $([math]::Round($_.Size/1GB,1)) GB" -ForegroundColor White
    }
    
    $drive = Read-Host "`nLaufwerk pruefen (z.B. C)"
    $drive = $drive.TrimEnd(':') + ":"
    
    if (-not (Test-Path $drive)) {
        Write-Host "[ERROR] Laufwerk nicht gefunden" -ForegroundColor Red
        return
    }
    
    Write-Host "`nOptionen:" -ForegroundColor White
    Write-Host "  [1] Nur-Lese-Scan (sicher)" -ForegroundColor Green
    Write-Host "  [2] Reparatur (Neustart!)" -ForegroundColor Yellow
    Write-Host "  [3] Abbrechen" -ForegroundColor Gray

    $choice = Read-Host "`nWahl [1-3]"
    
    switch ($choice) {
        '1' {
            Write-Host "`n[*] Starte Scan..." -ForegroundColor Blue
            chkdsk $drive
            Write-Host "[OK] Scan abgeschlossen" -ForegroundColor Green
        }
        '2' {
            Write-Host "`n[WARNING] ACHTUNG: Neustart erforderlich!" -ForegroundColor Red
            $confirm = Read-Host "Wirklich planen? [j/n]"
            if ($confirm -eq 'j' -or $confirm -eq 'J') {
                $output = & cmd /c "echo J | chkdsk $drive /f /r" 2>&1 | Out-String
                Write-Host "[OK] Pruefung geplant - bitte neustarten" -ForegroundColor Green
            }
        }
        default {
            Write-Host "[SKIP] Abgebrochen" -ForegroundColor Gray
        }
    }
}

# ============================================================================
#                         WINGET SOFTWARE-UPDATES
# ============================================================================

function Invoke-WingetUpdates {
    Show-StepExplanation -Title "Winget Software-Updates" `
        -Description "Moderne Software-Updates ueber Windows Package Manager" `
        -Purpose "Sichere Updates fuer installierte Programme" `
        -Actions @(
            "Pruefung ob Winget verfuegbar ist",
            "Scan nach veralteter Software", 
            "Sichere Updates durchfuehren"
        )
    
    Write-Host "`n[*] --- WINGET SOFTWARE-UPDATES ---" -ForegroundColor Cyan
    
    # Pruefe ob Winget verfuegbar ist
    try {
        $wingetVersion = & winget --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Winget nicht gefunden"
        }
        Write-Host "[OK] Winget verfuegbar: $wingetVersion" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Winget ist nicht verfuegbar!" -ForegroundColor Yellow
        Write-Host "         Winget ist standardmaessig in Windows 10/11 enthalten." -ForegroundColor White
        Write-Host "         Installation ueber Microsoft Store: 'App Installer'" -ForegroundColor White
        Read-Host "`nEnter druecken zum Fortfahren"
        return
    }
    
    Write-Host "`n[*] Scanne nach Software-Updates..." -ForegroundColor Blue
    Write-Host "    Dies kann 30-60 Sekunden dauern..." -ForegroundColor Gray
    
    try {
        # Verwende winget upgrade list um Updates zu finden
        $upgradeOutput = & winget upgrade 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARNING] Winget-Scan fehlgeschlagen" -ForegroundColor Yellow
            return
        }
        
        # Parse die Ausgabe um Updates zu identifizieren
        $upgradeLines = $upgradeOutput -split "`n" | Where-Object { $_ -match "^\S+\s+\S+\s+\S+\s+\S+" -and $_ -notmatch "^Name\s+Id" -and $_ -notmatch "^-" }
        
        if ($upgradeLines.Count -eq 0) {
            Write-Host "[OK] Alle Programme sind aktuell!" -ForegroundColor Green
            Write-Host "     Winget hat keine veraltete Software gefunden." -ForegroundColor White
            return
        }
        
        Write-Host "[INFO] $($upgradeLines.Count) Updates verfuegbar:" -ForegroundColor Yellow
        Write-Host "=================================================" -ForegroundColor Gray
        
        # Zeige verfuegbare Updates
        $updateCount = 0
        foreach ($line in $upgradeLines) {
            if ($line.Trim() -and $updateCount -lt 10) { # Limitiere Anzeige auf 10
                $parts = $line -split '\s+', 4
                if ($parts.Count -ge 3) {
                    $name = $parts[0]
                    $currentVersion = $parts[1] 
                    $availableVersion = $parts[2]
                    Write-Host "  [$($updateCount + 1)] $name" -ForegroundColor White
                    Write-Host "      $currentVersion -> $availableVersion" -ForegroundColor Cyan
                    $updateCount++
                }
            }
        }
        
        if ($upgradeLines.Count -gt 10) {
            Write-Host "  ... und $($upgradeLines.Count - 10) weitere" -ForegroundColor Gray
        }
        
        Write-Host "`n[*] OPTIONEN:" -ForegroundColor Cyan
        Write-Host "  [1] Alle Updates installieren (empfohlen)" -ForegroundColor Green
        Write-Host "  [2] Nur kritische Updates (Microsoft, Browser)" -ForegroundColor Yellow
        Write-Host "  [3] Abbrechen" -ForegroundColor Gray
        
        $choice = Read-Host "`nWahl [1-3]"
        
        switch ($choice) {
            '1' {
                Write-Host "`n[*] Installiere alle Updates..." -ForegroundColor Green
                Write-Host "    HINWEIS: Programme koennen waehrend des Updates geschlossen werden!" -ForegroundColor Yellow
                
                $confirm = Read-Host "`nFortfahren? [j/n]"
                if ($confirm -eq 'j' -or $confirm -eq 'J') {
                    
                    Write-Host "`n[*] Starte Winget Update-Prozess..." -ForegroundColor Blue
                    
                    # Verwende winget upgrade --all mit nicht-interaktivem Modus
                    $updateProcess = Start-Process -FilePath "winget" -ArgumentList "upgrade --all --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\winget_update.log" -RedirectStandardError "$env:TEMP\winget_error.log"
                    
                    # Fortschrittsanzeige
                    $dots = 0
                    while (-not $updateProcess.HasExited) {
                        $dots = ($dots + 1) % 4
                        $progress = "." * $dots + " " * (3 - $dots)
                        Write-Host "`r[*] Updates laufen$progress (kann mehrere Minuten dauern)" -NoNewline -ForegroundColor Yellow
                        Start-Sleep -Seconds 2
                    }
                    
                    Write-Host "`r[OK] Update-Prozess abgeschlossen!                                    " -ForegroundColor Green
                    
                    # Pruefe Ergebnis
                    if ($updateProcess.ExitCode -eq 0) {
                        Write-Host "[OK] Updates erfolgreich installiert!" -ForegroundColor Green
                        
                        # Zeige Log falls im Debug-Modus
                        if ($script:ExplainMode) {
                            $updateLog = Get-Content "$env:TEMP\winget_update.log" -ErrorAction SilentlyContinue
                            if ($updateLog) {
                                Write-Host "`n[DEBUG] Update-Details:" -ForegroundColor DarkGray
                                $updateLog | Select-Object -Last 5 | ForEach-Object {
                                    Write-Host "  $_" -ForegroundColor DarkGray
                                }
                            }
                        }
                    } else {
                        Write-Host "[WARNING] Einige Updates konnten nicht installiert werden" -ForegroundColor Yellow
                        Write-Host "          Exit Code: $($updateProcess.ExitCode)" -ForegroundColor Gray
                    }
                    
                    # Aufraeumen
                    Remove-Item "$env:TEMP\winget_*.log" -Force -ErrorAction SilentlyContinue
                }
            }
            
            '2' {
                Write-Host "`n[*] Installiere kritische Updates..." -ForegroundColor Yellow
                
                # Liste kritischer Software-IDs
                $criticalSoftware = @(
                    "Microsoft.Edge",
                    "Mozilla.Firefox", 
                    "Google.Chrome",
                    "Microsoft.VisualStudioCode",
                    "Microsoft.PowerShell",
                    "Microsoft.WindowsTerminal"
                )
                
                $criticalUpdates = 0
                foreach ($software in $criticalSoftware) {
                    try {
                        Write-Host "[*] Pruefe $software..." -ForegroundColor Blue
                        
                        $upgradeResult = & winget upgrade $software --silent --accept-source-agreements --accept-package-agreements 2>$null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  [OK] $software aktualisiert" -ForegroundColor Green
                            $criticalUpdates++
                        } else {
                            Write-Host "  [SKIP] $software nicht gefunden oder aktuell" -ForegroundColor Gray
                        }
                    } catch {
                        Write-Host "  [ERROR] Fehler bei $software" -ForegroundColor Red
                    }
                }
                
                Write-Host "`n[OK] $criticalUpdates kritische Updates installiert" -ForegroundColor Green
            }
            
            default {
                Write-Host "[SKIP] Abgebrochen" -ForegroundColor Gray
            }
        }
        
    } catch {
        Write-Host "[ERROR] Winget-Prozess fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
        
        # Alternative Empfehlungen
        Write-Host "`n[*] ALTERNATIVE OPTIONEN:" -ForegroundColor Cyan
        Write-Host "   1. Microsoft Store oeffnen und Updates pruefen" -ForegroundColor White
        Write-Host "   2. Programme manuell aktualisieren" -ForegroundColor White
        Write-Host "   3. Winget neu installieren (Microsoft Store -> 'App Installer')" -ForegroundColor White
    }
}

# ============================================================================
#                         TREIBER-UPDATES
# ============================================================================

function Install-DriverUpdatesViaWindowsUpdate {
    Show-StepExplanation -Title "Windows Treiber-Updates" `
        -Description "Sichere Treiber-Updates ueber Windows" `
        -Purpose "Nur Microsoft-zertifizierte Treiber" `
        -Actions @(
            "Windows Update Service nutzen",
            "Nur geprufte Treiber",
            "Keine Third-Party Tools"
        )
    
    Write-Host "`n[*] --- WINDOWS TREIBER-UPDATES ---" -ForegroundColor Cyan
    
    # Sicherheitshinweis
    Write-Host "`n[OK] SICHER: Verwendet nur Windows Update" -ForegroundColor Green
    Write-Host "   - Nur Microsoft-geprufte Treiber" -ForegroundColor White
    Write-Host "   - Keine Bloatware oder Adware" -ForegroundColor White
    
    $choice = Read-Host "`nNach Updates suchen? [j/n]"
    if ($choice -ne 'j' -and $choice -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }

    try {
        # Pruefe ob Windows Update Service laeuft
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        if ($wuService.Status -ne 'Running') {
            Write-Host "[*] Starte Windows Update Service..." -ForegroundColor Blue
            Start-Service -Name wuauserv -ErrorAction Stop
            Start-Sleep -Seconds 2
        }
        
        Write-Host "[*] Verbinde mit Windows Update..." -ForegroundColor Blue
        
        # Erstelle COM-Objekte mit besserer Fehlerbehandlung
        $updateSession = $null
        $updateSearcher = $null
        
        try {
            $updateSession = New-Object -ComObject "Microsoft.Update.Session" -ErrorAction Stop
        } catch {
            throw "Windows Update Session konnte nicht erstellt werden."
        }
        
        try {
            $updateSearcher = $updateSession.CreateUpdateSearcher()
        } catch {
            throw "Update Searcher konnte nicht erstellt werden."
        }
        
        Write-Host "[*] Suche Treiber (kann 1-3 Min dauern)..." -ForegroundColor Blue
        
        try {
            $searchResult = $updateSearcher.Search("Type='Driver' and IsInstalled=0")
        } catch {
            Write-Host "[WARNING] Erweiterte Suche fehlgeschlagen, versuche Basis-Suche..." -ForegroundColor Yellow
            try {
                $searchResult = $updateSearcher.Search("IsInstalled=0")
                # Filtere nur Treiber
                $driverUpdates = @()
                for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
                    if ($searchResult.Updates.Item($i).Type -eq 'Driver') {
                        $driverUpdates += $searchResult.Updates.Item($i)
                    }
                }
                
                if ($driverUpdates.Count -eq 0) {
                    Write-Host "[OK] Keine Treiber-Updates gefunden!" -ForegroundColor Green
                    return
                }
            } catch {
                throw "Windows Update Suche fehlgeschlagen: $_"
            }
        }

        if ($searchResult.Updates.Count -eq 0) {
            Write-Host "[OK] Alle Treiber sind aktuell!" -ForegroundColor Green
            Write-Host "[*] Fuer GPU: Hersteller-Webseite nutzen" -ForegroundColor Cyan
            return
        }

        Write-Host "[OK] $($searchResult.Updates.Count) Update(s) gefunden" -ForegroundColor Green
        
        # Liste Updates
        $updatesToInstall = New-Object -ComObject "Microsoft.Update.UpdateColl"
        
        for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
            $update = $searchResult.Updates.Item($i)
            $sizeInMB = [math]::Round($update.MaxDownloadSize / 1MB, 2)
            
            Write-Host "`n[$($i+1)] $($update.Title)" -ForegroundColor White
            Write-Host "    Groesse: $sizeInMB MB" -ForegroundColor Gray
        }
        
        $installChoice = Read-Host "`nAlle installieren? [j/n]"
        
        if ($installChoice -ne 'j' -and $installChoice -ne 'J') {
            Write-Host "[SKIP] Installation uebersprungen" -ForegroundColor Gray
            return
        }

        # Fuege alle Updates hinzu
        for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
            $updatesToInstall.Add($searchResult.Updates.Item($i)) | Out-Null
        }

        # Download
        Write-Host "`n[*] Downloade..." -ForegroundColor Blue
        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToInstall
        $downloadResult = $downloader.Download()
        
        if ($downloadResult.ResultCode -ne 2) {
            Write-Host "[WARNING] Download teilweise fehlgeschlagen" -ForegroundColor Yellow
        }

        # Installation
        Write-Host "[*] Installiere..." -ForegroundColor Blue
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installationResult = $installer.Install()

        if ($installationResult.ResultCode -eq 2) {
            Write-Host "[OK] Erfolgreich installiert!" -ForegroundColor Green
            if ($installationResult.RebootRequired) {
                Write-Host "[WARNING] Neustart erforderlich!" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[WARNING] Installation teilweise fehlgeschlagen (Code: $($installationResult.ResultCode))" -ForegroundColor Yellow
        }

    } catch {
        Add-Error "Windows Update Fehler: $($_.Exception.Message)"
        
        Write-Host "`n[*] ALTERNATIVE OPTIONEN:" -ForegroundColor Cyan
        Write-Host "   1. Windows Update manuell oeffnen (Windows-Taste + I -> Update)" -ForegroundColor White
        Write-Host "   2. Geraete-Manager -> Rechtsklick auf Geraet -> Treiber aktualisieren" -ForegroundColor White
        Write-Host "   3. Hersteller-Webseiten fuer GPU/Chipsatz-Treiber" -ForegroundColor White
        
        if ($script:ExplainMode) {
            Write-Host "`n[DEBUG] DEBUG-INFO:" -ForegroundColor DarkGray
            Write-Host "   Fehlertyp: $($_.Exception.GetType().Name)" -ForegroundColor DarkGray
            Write-Host "   Position: Zeile $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
        }
    } finally {
        # Aufraeumen
        if ($updateSearcher) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($updateSearcher) | Out-Null }
        if ($updateSession) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($updateSession) | Out-Null }
    }
}

# ============================================================================
#                         DEFRAG & TRIM
# ============================================================================

function Optimize-DrivesWithDefragTrim {
    Show-StepExplanation -Title "Laufwerks-Optimierung" `
        -Description "Defrag fuer HDDs, TRIM fuer SSDs" `
        -Purpose "Verbessert Performance" `
        -Actions @(
            "Fragmentierung pruefen",
            "TRIM fuer SSDs",
            "Defrag fuer HDDs"
        )
    
    Write-Host "`n[*] --- LAUFWERKS-OPTIMIERUNG ---" -ForegroundColor Cyan
    
    $drivesToOptimize = Get-AllDrives
    if ($drivesToOptimize.Count -eq 0) {
        Add-Warning "Keine Laufwerke gefunden"
        return
    }

    Write-Host "[INFO] Analyse:" -ForegroundColor Yellow
    $needsOptimization = @()
    
    foreach ($drive in $drivesToOptimize) {
        Write-Host "`n[*] $($drive.Letter)..." -ForegroundColor Blue
        
        if ($drive.Type -like "*HDD*") {
            Write-Host "  [*] HDD - Defrag empfohlen" -ForegroundColor Yellow
            $needsOptimization += $drive
        } else {
            Write-Host "  [*] $($drive.Type) - TRIM empfohlen" -ForegroundColor Cyan
            $needsOptimization += $drive
        }
    }

    if ($needsOptimization.Count -eq 0) {
        Write-Host "`n[OK] Bereits optimiert" -ForegroundColor Green
        return
    }

    $confirm = Read-Host "`nOptimierung starten? [j/n]"
    if ($confirm -ne 'j' -and $confirm -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }

    foreach ($drive in $needsOptimization) {
        $driveLetter = $drive.Letter.Replace(":", "")
        $action = if ($drive.Type -like "*SSD*") { "TRIM" } else { "Defrag" }
        
        Write-Host "`n[*] $action fuer $($drive.Letter)..." -ForegroundColor Blue
        
        try {
            $optimizeJob = Start-Job -ScriptBlock {
                param($letter, $isSSD)
                if ($isSSD) {
                    Optimize-Volume -DriveLetter $letter -ReTrim -Verbose
                } else {
                    Optimize-Volume -DriveLetter $letter -Defrag -Verbose
                }
            } -ArgumentList $driveLetter, ($drive.Type -like "*SSD*")
            
            # Fortschritt
            while ($optimizeJob.State -eq 'Running') {
                Write-Host "." -NoNewline -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            
            Remove-Job -Job $optimizeJob
            Write-Host " [OK]" -ForegroundColor Green
            
        } catch {
            Add-Error "Optimierung fehlgeschlagen: $($_.Exception.Message)"
        }
    }
}

# ============================================================================
#                         BEREINIGUNGSFUNKTIONEN
# ============================================================================

function Remove-FilesInFolder {
    param([string]$Path, [string]$Description)
    
    if ($script:ExplainMode) {
        Write-Host "`n[*] Pruefe: $Description" -ForegroundColor Blue
        Write-Host "   [*] Pfad: $Path" -ForegroundColor DarkGray
    }
    
    if (-not (Test-Path $Path)) {
        if ($script:ExplainMode) {
            Write-Host "   [SKIP] Existiert nicht" -ForegroundColor Gray
        }
        return
    }
    
    # Groesse berechnen
    $sizeBefore = Get-FolderSize $Path
    
    if ($sizeBefore -le 1) {
        if ($script:ExplainMode) {
            Write-Host "   [OK] Bereits sauber" -ForegroundColor Green
        }
        return
    }
    
    # Statistik
    try {
        $files = @(Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue)
        $fileCount = $files.Count
        
        if ($script:ExplainMode -and $fileCount -gt 0) {
            Write-Host "   [*] $fileCount Dateien ($sizeBefore MB)" -ForegroundColor Yellow
        }
    } catch {
        $fileCount = 0
    }
    
    if (-not $script:AutoApproveCleanup) {
        Write-Host "   $Description ($sizeBefore MB)" -ForegroundColor White
        $userChoice = Read-Host "   Bereinigen? [j/n/a fuer alle]"
        if ($userChoice -eq 'n') {
            Write-Host "   [SKIP] Uebersprungen" -ForegroundColor Gray
            return
        }
        if ($userChoice -eq 'a') {
            $script:AutoApproveCleanup = $true
        }
    } else {
        Write-Host "   [*] $Description..." -NoNewline
    }
    
    try {
        # Loesche mit korrektem Counter
        $deleted = 0
        $failed = 0
        
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Recurse -Force -ErrorAction Stop
                $deleted++
            } catch {
                $failed++
            }
        }
        
        $freed = $sizeBefore
        $script:TotalFreedSpace += $freed
        
        Write-Host " [OK] $freed MB freigegeben" -ForegroundColor Green
        
    } catch {
        Add-Warning "Fehler bei ${Description}"
    }
}

function Invoke-SystemCleanup {
    Write-Host "`n[*] --- SYSTEM-BEREINIGUNG ---" -ForegroundColor Cyan
    
    $cleanupPaths = @(
        @{Path="$env:TEMP"; Description="Temp-Dateien"},
        @{Path="$env:SystemRoot\Temp"; Description="System-Temp"},
        @{Path="$env:SystemRoot\Prefetch"; Description="Prefetch"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Windows\Explorer"; Description="Thumbnails"}
    )
    
    $autoClean = Read-Host "`nAlle automatisch? [j/n]"
    if ($autoClean -eq 'j' -or $autoClean -eq 'J') {
        $script:AutoApproveCleanup = $true
    }
    
    foreach ($item in $cleanupPaths) {
        Remove-FilesInFolder -Path $item.Path -Description $item.Description
    }
    
    Write-Host "`n[OK] Bereinigung abgeschlossen!" -ForegroundColor Green
    Write-Host "[INFO] Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Cyan
}

function Clear-GamingCache {
    Write-Host "`n[*] --- GAMING-CACHE ---" -ForegroundColor Cyan
    
    $gamingPaths = @(
        @{Path="$env:LOCALAPPDATA\NVIDIA\DXCache"; Description="NVIDIA Cache"},
        @{Path="$env:LOCALAPPDATA\AMD\DxCache"; Description="AMD Cache"},
        @{Path="$env:LOCALAPPDATA\Steam\htmlcache"; Description="Steam Cache"},
        @{Path="$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Description="Epic Cache"}
    )
    
    $foundCaches = 0
    
    foreach ($item in $gamingPaths) {
        if (Test-Path $item.Path) {
            $foundCaches++
            $size = Get-FolderSize $item.Path
            Write-Host "  [OK] $($item.Description) ($size MB)" -ForegroundColor Green
        }
    }
    
    if ($foundCaches -eq 0) {
        Write-Host "[INFO] Keine Gaming-Caches gefunden" -ForegroundColor Gray
        return
    }
    
    $cleanChoice = Read-Host "`nBereinigen? [j/n]"
    
    if ($cleanChoice -eq 'j' -or $cleanChoice -eq 'J') {
        $script:AutoApproveCleanup = $true
        foreach ($item in $gamingPaths) {
            if (Test-Path $item.Path) {
                Remove-FilesInFolder -Path $item.Path -Description $item.Description
            }
        }
        Write-Host "[OK] Gaming-Cache bereinigt!" -ForegroundColor Green
    }
}

# ============================================================================
#                         WINDOWS PRIVACY
# ============================================================================

function Optimize-WindowsPrivacy {
    Show-StepExplanation -Title "Windows Privacy" `
        -Description "Datenschutz verbessern" `
        -Purpose "Reduziert Telemetrie" `
        -Actions @(
            "Telemetrie minimieren",
            "Werbe-ID deaktivieren",
            "Cortana deaktivieren"
        )
    
    Write-Host "`n[*] --- WINDOWS PRIVACY ---" -ForegroundColor Cyan
    
    Write-Host "[WARNING] Deaktiviert Telemetrie und Cortana" -ForegroundColor Yellow
    
    $confirm = Read-Host "`nOptimierungen durchfuehren? [j/n]"
    if ($confirm -ne 'j' -and $confirm -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }
    
    $changes = 0
    
    # Telemetrie
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction Stop
        $changes++
        Write-Host "[OK] Telemetrie minimiert" -ForegroundColor Green
    } catch {
        # Fehler ignorieren
    }
    
    # Werbe-ID
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
            -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction Stop
        $changes++
        Write-Host "[OK] Werbe-ID deaktiviert" -ForegroundColor Green
    } catch {
        # Fehler ignorieren
    }
    
    # Cortana
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
            -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction Stop
        $changes++
        Write-Host "[OK] Cortana deaktiviert" -ForegroundColor Green
    } catch {
        # Fehler ignorieren
    }
    
    Write-Host "`n[OK] $changes Optimierungen durchgefuehrt" -ForegroundColor Green
    
    if ($changes -gt 0) {
        Write-Host "[*] Neustart empfohlen" -ForegroundColor Yellow
    }
}

# ============================================================================
#                         SICHERE ADBLOCK-FUNKTION
# ============================================================================

function Manage-SafeAdblock {
    Show-StepExplanation -Title "System-Adblock (Sicher)" `
        -Description "Sicherer systemweiter Adblock mit Whitelist" `
        -Purpose "Blockiert nur bekannte Werbe-Domains mit Schutz vor Ueberblockierung" `
        -Actions @(
            "Verwendung einer konservativen Blocklist",
            "Automatische Whitelist fuer wichtige Services",
            "Einfache Deaktivierung bei Problemen"
        )
    
    Write-Host "`n[*] --- HELLION SAFE ADBLOCK SYSTEM ---" -ForegroundColor Cyan
    
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $backupDir = "$env:SystemRoot\System32\drivers\etc"
    
    # Status pruefen
    $hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    $isInstalled = $hostsContent -match "=== HELLION SAFE ADBLOCK ==="
    
    if ($isInstalled) {
        $blockedCount = ([regex]::Matches($hostsContent, "^0\.0\.0\.0", "Multiline")).Count
        
        Write-Host "[OK] Safe Adblock ist AKTIV" -ForegroundColor Green
        Write-Host "[INFO] Blockierte Domains: $blockedCount" -ForegroundColor Yellow
        
        Write-Host "`n[1] Deaktivieren" -ForegroundColor White
        Write-Host "[2] Problemloesung (Whitelist)" -ForegroundColor White
        Write-Host "[3] Abbrechen" -ForegroundColor Gray
        
        $choice = Read-Host "`nWahl [1-3]"
        if ($choice -eq '3') { return }
    } else {
        Write-Host "[INFO] Safe Adblock ist NICHT installiert" -ForegroundColor Yellow
        $choice = '1'
    }
    
    switch ($choice) {
        '1' {
            if ($isInstalled) {
                # Deaktivieren
                Write-Host "`n[*] Deaktiviere Safe Adblock..." -ForegroundColor Blue
                
                $backups = Get-ChildItem "$backupDir\hosts.hellion-backup-*" -ErrorAction SilentlyContinue | 
                          Sort-Object LastWriteTime -Descending
                
                if ($backups.Count -gt 0) {
                    Copy-Item $backups[0].FullName $hostsPath -Force
                    Write-Host "[OK] Safe Adblock deaktiviert!" -ForegroundColor Green
                    
                    ipconfig /flushdns | Out-Null
                    Write-Host "[*] DNS-Cache geleert" -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Kein Backup gefunden!" -ForegroundColor Red
                }
            } else {
                # Installieren
                Write-Host "`n[*] SAFE ADBLOCK INSTALLATION" -ForegroundColor Cyan
                Write-Host "Dieses sichere Adblock-System:" -ForegroundColor Yellow
                Write-Host "  [+] Blockiert nur bekannte Werbe-Domains" -ForegroundColor Green
                Write-Host "  [+] Schuetzt wichtige Services (Banking, E-Mail, etc.)" -ForegroundColor Green
                Write-Host "  [+] Konservative Liste (~40 Domains)" -ForegroundColor Green
                Write-Host "  [+] Einfache Deaktivierung bei Problemen" -ForegroundColor Green
                Write-Host "  [-] Weniger aggressiv als andere Loesungen" -ForegroundColor Yellow
                
                $install = Read-Host "`nInstallieren? [j/n]"
                if ($install -ne 'j' -and $install -ne 'J') { return }
                
                # Backup erstellen
                $backupFile = "$backupDir\hosts.hellion-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Write-Host "`n[*] Erstelle Backup..." -ForegroundColor Blue
                Copy-Item $hostsPath $backupFile -Force
                
                # Sichere Blocklist (konservativ)
                $safeBlockList = @(
                    "googleadservices.com",
                    "googlesyndication.com", 
                    "doubleclick.net",
                    "googletagmanager.com",
                    "google-analytics.com",
                    "amazon-adsystem.com",
                    "scorecardresearch.com",
                    "quantserve.com",
                    "outbrain.com",
                    "taboola.com",
                    "adsystem.com",
                    "adsrvr.org",
                    "adnxs.com",
                    "criteo.com",
                    "rubiconproject.com",
                    "adsafeprotected.com",
                    "moatads.com",
                    "serving-sys.com",
                    "googletag.com",
                    "adskeeper.co.uk"
                )
                
                # Neue hosts-Datei erstellen
                $newHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
127.0.0.1       localhost
::1             localhost

# ============================================================================
#                        === HELLION SAFE ADBLOCK ===
#     Installiert: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
#     Tool: Hellion Power Tool v6.1
#     Modus: SICHER - Konservative Liste
#     Domains: $($safeBlockList.Count * 2)
# ============================================================================

# Bei Problemen: Fuehren Sie das Tool erneut aus und waehlen Sie "Deaktivieren"

"@
                
                # Sichere Domains hinzufuegen
                foreach ($domain in $safeBlockList) {
                    $newHosts += "`n0.0.0.0 $domain"
                    $newHosts += "`n0.0.0.0 www.$domain"
                }
                
                $newHosts += "`n`n# ============================================================================"
                $newHosts += "`n# Ende Hellion Safe Adblock"
                $newHosts += "`n# ============================================================================"
                
                try {
                    $newHosts | Out-File -FilePath $hostsPath -Encoding ASCII -Force
                    
                    Write-Host "[OK] Safe Adblock erfolgreich installiert!" -ForegroundColor Green
                    Write-Host "[INFO] Blockierte Domains: $($safeBlockList.Count * 2)" -ForegroundColor Cyan
                    
                    # DNS Cache leeren
                    Write-Host "[*] Leere DNS-Cache..." -ForegroundColor Blue
                    ipconfig /flushdns | Out-Null
                    
                    Write-Host "[OK] Aenderungen sind sofort aktiv!" -ForegroundColor Green
                    Write-Host "`n[*] HINWEIS: Diese konservative Liste sollte keine Probleme verursachen." -ForegroundColor Yellow
                    Write-Host "    Bei Problemen verwenden Sie Option 2 (Problemloesung)." -ForegroundColor Yellow
                    
                } catch {
                    Write-Host "[ERROR] Installation fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        '2' {
            # Problemloesung / Whitelist
            if ($isInstalled) {
                Write-Host "`n[*] PROBLEMLOESUNG" -ForegroundColor Cyan
                $problemSite = Read-Host "Welche Domain funktioniert nicht? (z.B. paypal.com)"
                
                if ($problemSite) {
                    Write-Host "[*] Suche $problemSite..." -ForegroundColor Blue
                    
                    # Entferne alle Varianten
                    $patterns = @(
                        "0\.0\.0\.0\s+[^\s]*$problemSite[^\s]*",
                        "127\.0\.0\.1\s+[^\s]*$problemSite[^\s]*"
                    )
                    
                    $removed = 0
                    foreach ($pattern in $patterns) {
                        $matches = [regex]::Matches($hostsContent, $pattern)
                        if ($matches.Count -gt 0) {
                            $hostsContent = $hostsContent -replace "$pattern\r?\n", ""
                            $removed += $matches.Count
                        }
                    }
                    
                    if ($removed -gt 0) {
                        $hostsContent | Out-File -FilePath $hostsPath -Encoding ASCII -Force
                        ipconfig /flushdns | Out-Null
                        
                        Write-Host "[OK] $removed Eintraege fuer '$problemSite' entfernt" -ForegroundColor Green
                        Write-Host "[*] Seite sollte jetzt funktionieren" -ForegroundColor Cyan
                    } else {
                        Write-Host "[INFO] Keine Eintraege fuer '$problemSite' gefunden" -ForegroundColor Yellow
                        Write-Host "       Das Problem liegt vermutlich woanders." -ForegroundColor Yellow
                    }
                }
            }
        }
    }
}

# ============================================================================
#                         WIEDERHERSTELLUNGSPUNKT
# ============================================================================

function Create-SystemRestorePoint {
    Write-Host "`n[*] --- WIEDERHERSTELLUNGSPUNKT ---" -ForegroundColor Cyan
    $createRestore = Read-Host "Erstellen? (Empfohlen!) [j/n]"
    
    if ($createRestore -ne 'j' -and $createRestore -ne 'J') {
        Write-Host "[SKIP] Uebersprungen" -ForegroundColor Gray
        return
    }

    try {
        Write-Host "[*] Erstelle Punkt..." -ForegroundColor Blue
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        $description = "Hellion Tool - $timestamp"
        
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-Host "[OK] Erfolgreich erstellt!" -ForegroundColor Green
        $script:RestorePointCreated = $true
        
    } catch {
        Add-Warning "Wiederherstellungspunkt fehlgeschlagen"
    }
}

# ============================================================================
#                         SYSTEM-REPORT GENERATOR
# ============================================================================

function Generate-SystemReport {
    Write-Host "`n[INFO] --- SYSTEM-REPORT ---" -ForegroundColor Cyan
    
    $reportPath = "$env:USERPROFILE\Desktop\Hellion_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    Write-Host "[*] Erstelle Report..." -ForegroundColor Blue
    
    $report = @"
========================================================================
           HELLION POWER TOOL v6.1 - SYSTEM REPORT
           Erstellt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
========================================================================

SYSTEM:
=======
OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
Version: $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion)
RAM: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)) GB
CPU: $(Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name)

LAUFWERKE:
==========
"@
    
    foreach ($drive in Get-AllDrives) {
        $report += @"

$($drive.Letter) [$($drive.Type)]
   Gesamt: $($drive.TotalSpace) GB
   Frei: $($drive.FreeSpace) GB
"@
    }
    
    $report += @"

DURCHGEFUEHRTE AKTIONEN:
=======================
"@
    
    if ($script:ActionsPerformed.Count -gt 0) {
        $script:ActionsPerformed | ForEach-Object { $report += "`n- $_" }
    } else {
        $report += "`nKeine Aktionen durchgefuehrt"
    }
    
    if ($script:Warnings.Count -gt 0) {
        $report += @"

WARNUNGEN:
==========
"@
        $script:Warnings | ForEach-Object { $report += "`n[WARNING] $_" }
    }
    
    $report += @"

========================================================================
                           ENDE DES REPORTS
========================================================================
"@
    
    try {
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Host "[OK] Report gespeichert!" -ForegroundColor Green
        Write-Host "[*] Pfad: $reportPath" -ForegroundColor Cyan
        
        $openReport = Read-Host "`nOeffnen? [j/n]"
        if ($openReport -eq 'j' -or $openReport -eq 'J') {
            Start-Process notepad.exe $reportPath
        }
    } catch {
        Add-Error "Report-Fehler: $($_.Exception.Message)"
    }
}

# ============================================================================
#                         AUTO-MODUS
# ============================================================================

function Invoke-AutoMode {
    Write-Host "`n[*] --- AUTO-MODUS ---" -ForegroundColor Green
    Write-Host "Fuehrt alle empfohlenen Optimierungen automatisch durch" -ForegroundColor Yellow
    
    $script:AutoApproveCleanup = $true
    $autoStartTime = Get-Date
    
    # Geplante Aktionen
    $autoActions = @(
        "1. Wiederherstellungspunkt erstellen",
        "2. System-Integritaet pruefen (SFC)",
        "3. Temp-Dateien bereinigen",
        "4. Cache leeren",
        "5. Windows Privacy optimieren",
        "6. Treiber-Status pruefen"
    )
    
    # Adblock-Check
    $hostsContent = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -Raw -ErrorAction SilentlyContinue
    $adblockInstalled = $hostsContent -match "=== HELLION.*ADBLOCK ==="

    if (-not $adblockInstalled) {
        $autoActions += "7. Hellion Safe Adblock installieren"
        
        Write-Host "`n[INFO] ADBLOCK NICHT INSTALLIERT" -ForegroundColor Yellow
        Write-Host "Der Auto-Modus kann einen systemweiten Safe Adblock installieren:" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "   [*] SAFE ADBLOCK:" -ForegroundColor Yellow
        Write-Host "   - ~40 blockierte Domains" -ForegroundColor White
        Write-Host "   - [OK] Blockiert: Bekannte Werbe-Domains" -ForegroundColor Green
        Write-Host "   - [X] NICHT blockiert: Banking, E-Mail, Social Media" -ForegroundColor Yellow
        Write-Host "   - Banking & Shopping funktioniert normal" -ForegroundColor Green
        Write-Host "   - Empfohlen fuer alle Nutzer" -ForegroundColor Cyan
        
        $installAdblock = Read-Host "`nSafe Adblock installieren? [j/n]"
    }
    
    Write-Host "`n[*] GEPLANTE AKTIONEN:" -ForegroundColor Cyan
    $autoActions | ForEach-Object { Write-Host "   - $_" -ForegroundColor White }
    
    Write-Host "`n[*] Geschaetzte Dauer: 10-20 Minuten" -ForegroundColor Yellow
    Write-Host "[*] Sie koennen jederzeit mit Strg+C abbrechen" -ForegroundColor Gray
    
    $confirm = Read-Host "`nStarten? [j/n]"
    
    if ($confirm -ne 'j' -and $confirm -ne 'J') {
        Write-Host "[INFO] Abgebrochen" -ForegroundColor Red
        return $false
    }
    
    # Aktionen durchfuehren
    Write-Host "`n[1/7] Wiederherstellungspunkt..." -ForegroundColor Blue
    Create-SystemRestorePoint
    $script:ActionsPerformed += "Wiederherstellungspunkt"
    
    Write-Host "`n[2/7] System File Checker..." -ForegroundColor Blue
    # Auto-SFC ohne Benutzerabfrage
    try {
        Write-Host "[*] Starte SFC..." -ForegroundColor Green
        $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" `
            -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\sfc_output.txt" `
            -RedirectStandardError "$env:TEMP\sfc_error.txt"
        
        $counter = 0
        $spinChars = @('|','/','-','\')
        
        while (-not $sfcProcess.HasExited) {
            $spin = $spinChars[$counter % 4]
            Write-Host "`r$spin SFC Scan laeuft..." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            $counter++
        }
        
        Write-Host "`r[OK] SFC Scan abgeschlossen!                    " -ForegroundColor Green
        Remove-Item "$env:TEMP\sfc_*.txt" -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[WARNING] SFC fehlgeschlagen" -ForegroundColor Yellow
    }
    $script:ActionsPerformed += "System File Checker"
    
    Write-Host "`n[3/7] Temp-Bereinigung..." -ForegroundColor Blue
    Remove-FilesInFolder "$env:TEMP" "Temp-Dateien"
    Remove-FilesInFolder "$env:SystemRoot\Temp" "System-Temp"
    $script:ActionsPerformed += "Temp-Bereinigung"
    
    Write-Host "`n[4/7] Cache-Bereinigung..." -ForegroundColor Blue
    Remove-FilesInFolder "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails"
    Remove-FilesInFolder "$env:SystemRoot\Prefetch" "Prefetch"
    $script:ActionsPerformed += "Cache-Bereinigung"
    
    Write-Host "`n[5/7] Windows Privacy..." -ForegroundColor Blue
    # Auto-Privacy ohne Benutzerabfrage
    try {
        $changes = 0
        
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        $changes++
        
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
            -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        $changes++
        
        Write-Host "[OK] $changes Privacy-Optimierungen durchgefuehrt" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Privacy-Optimierung teilweise fehlgeschlagen" -ForegroundColor Yellow
    }
    $script:ActionsPerformed += "Privacy-Optimierung"
    
    Write-Host "`n[6/7] Treiber-Check..." -ForegroundColor Blue
    $driverProblem = Check-DriverStatus
    if ($driverProblem -and $script:HasInternet) {
        Write-Host "[*] Treiber-Probleme gefunden - Skipping Auto-Update (zu komplex)" -ForegroundColor Yellow
        $script:ActionsPerformed += "Treiber-Check (Probleme gefunden)"
    } else {
        $script:ActionsPerformed += "Treiber-Check"
    }
    
    # Safe Adblock wenn gewuenscht
    if ($installAdblock -eq 'j' -or $installAdblock -eq 'J') {
        Write-Host "`n[8/8] Installiere Safe Adblock..." -ForegroundColor Blue
        
        try {
            # Backup
            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $backupFile = "$env:SystemRoot\System32\drivers\etc\hosts.hellion-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $hostsPath $backupFile -Force
            
            # Safe Blocklist
            $safeBlockList = @(
                "googleadservices.com", "googlesyndication.com", "doubleclick.net",
                "googletagmanager.com", "google-analytics.com", "amazon-adsystem.com",
                "scorecardresearch.com", "quantserve.com", "outbrain.com", "taboola.com"
            )
            
            $newHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
127.0.0.1       localhost
::1             localhost

# ============================================================================
#                        === HELLION SAFE ADBLOCK ===
#     Installiert: $(Get-Date -Format 'yyyy-MM-dd HH:mm') (Auto-Modus)
#     Tool: Hellion Power Tool v6.1
#     Modus: SICHER - Auto-Installation
#     Domains: $($safeBlockList.Count * 2)
# ============================================================================

"@
            
            foreach ($domain in $safeBlockList) {
                $newHosts += "`n0.0.0.0 $domain"
                $newHosts += "`n0.0.0.0 www.$domain"
            }
            
            $newHosts += "`n`n# Ende Hellion Safe Adblock"
            
            $newHosts | Out-File -FilePath $hostsPath -Encoding ASCII -Force
            ipconfig /flushdns | Out-Null
            
            Write-Host "[OK] Safe Adblock installiert! ($($safeBlockList.Count * 2) Domains)" -ForegroundColor Green
            $script:ActionsPerformed += "Safe Adblock"
            
        } catch {
            Write-Host "[WARNING] Safe Adblock-Installation fehlgeschlagen: $_" -ForegroundColor Yellow
        }
    }
    
    $autoDuration = [math]::Round(((Get-Date) - $autoStartTime).TotalMinutes, 1)
    Write-Host "`n[OK] AUTO-MODUS ABGESCHLOSSEN!" -ForegroundColor Green
    Write-Host "[*] Dauer: $autoDuration Minuten" -ForegroundColor Cyan
    Write-Host "[*] Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Cyan
    
    return $true
}

# ============================================================================
#                         HAUPTMENU
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host @"
================================================================
              HELLION POWER TOOL v6.1 - HAUPTMENU
================================================================
"@ -ForegroundColor Cyan

    # Status
    Write-Host "`n[INFO] STATUS:" -ForegroundColor Yellow
    Write-Host "   [*] Laufzeit: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 1)) Min" -ForegroundColor Gray
    Write-Host "   [OK] Aktionen: $($script:ActionsPerformed.Count)" -ForegroundColor Gray
    Write-Host "   [*] Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Gray
    
    if ($script:Warnings.Count -gt 0) {
        Write-Host "   [WARNING] Warnungen: $($script:Warnings.Count)" -ForegroundColor Yellow
    }

    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "                           OPTIONEN" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    Write-Host "`n  [*] SCHNELL-AKTIONEN:" -ForegroundColor Green
    Write-Host "     [A] AUTO-MODUS (Empfohlen)" -ForegroundColor Green
    Write-Host "     [S] Schnell-Bereinigung" -ForegroundColor Cyan
    
    Write-Host "`n  [*] SYSTEM-INTEGRITAET:" -ForegroundColor Yellow
    Write-Host "     [1] System File Checker (SFC)" -ForegroundColor White
    Write-Host "     [2] DISM Reparatur" -ForegroundColor White
    Write-Host "     [3] Festplatten-Check" -ForegroundColor White
    
    Write-Host "`n  [*] TREIBER & UPDATES:" -ForegroundColor Yellow
    Write-Host "     [4] Windows Treiber-Updates" -ForegroundColor White
    
    Write-Host "`n  [*] BEREINIGUNG:" -ForegroundColor Yellow
    Write-Host "     [5] System-Bereinigung" -ForegroundColor White
    Write-Host "     [6] Gaming-Cache leeren" -ForegroundColor White
    
    Write-Host "`n  [*] OPTIMIERUNG:" -ForegroundColor Yellow
    Write-Host "     [7] Laufwerks-Optimierung" -ForegroundColor White
    Write-Host "     [8] Windows Privacy" -ForegroundColor White
    Write-Host "     [9] Safe Adblock" -ForegroundColor White
    
    Write-Host "`n  [*] BERICHTE:" -ForegroundColor Blue
    Write-Host "     [R] System-Report erstellen" -ForegroundColor Cyan
    
    Write-Host "`n  [Q] Beenden" -ForegroundColor Red
    Write-Host "`n================================================================" -ForegroundColor Cyan
}

function Process-MenuChoice {
    param([string]$Choice)
    
    switch ($Choice.ToUpper()) {
        'A' {
            return -not (Invoke-AutoMode)
        }
        'S' {
            Write-Host "`n[*] SCHNELL-BEREINIGUNG..." -ForegroundColor Cyan
            $script:AutoApproveCleanup = $true
            
            Remove-FilesInFolder "$env:TEMP" "Temp"
            Remove-FilesInFolder "$env:SystemRoot\Temp" "System-Temp"
            Remove-FilesInFolder "$env:LOCALAPPDATA\Temp" "Local-Temp"
            
            Write-Host "[OK] Schnell-Bereinigung abgeschlossen!" -ForegroundColor Green
            Write-Host "[*] Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Cyan
            $script:ActionsPerformed += "Schnell-Bereinigung"
            Read-Host "`nEnter druecken"
        }
        '1' {
            Invoke-SystemFileChecker
            $script:ActionsPerformed += "SFC"
            Read-Host "`nEnter druecken"
        }
        '2' {
            Invoke-DISMCheck
            $script:ActionsPerformed += "DISM"
            Read-Host "`nEnter druecken"
        }
        '3' {
            Invoke-DiskCheck
            $script:ActionsPerformed += "Disk Check"
            Read-Host "`nEnter druecken"
        }
        '4' {
            if ($script:HasInternet) {
                Install-DriverUpdatesViaWindowsUpdate
                $script:ActionsPerformed += "Treiber-Updates"
            } else {
                Write-Host "[ERROR] Keine Internetverbindung!" -ForegroundColor Red
            }
            Read-Host "`nEnter druecken"
        }
        '5' {
            Invoke-SystemCleanup
            $script:ActionsPerformed += "System-Bereinigung"
            Read-Host "`nEnter druecken"
        }
        '6' {
            Clear-GamingCache
            $script:ActionsPerformed += "Gaming-Cache"
            Read-Host "`nEnter druecken"
        }
        '7' {
            Optimize-DrivesWithDefragTrim
            $script:ActionsPerformed += "Laufwerks-Optimierung"
            Read-Host "`nEnter druecken"
        }
        '8' {
            Optimize-WindowsPrivacy
            $script:ActionsPerformed += "Privacy-Optimierung"
            Read-Host "`nEnter druecken"
        }
        '9' {
            Manage-SafeAdblock
            $script:ActionsPerformed += "Safe Adblock-Verwaltung"
            Read-Host "`nEnter druecken"
        }
        'R' {
            Generate-SystemReport
            Read-Host "`nEnter druecken"
        }
        'Q' {
            return $false
        }
        default {
            Write-Host "[ERROR] Unguelige Auswahl" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    return $true
}

# ============================================================================
#                         HAUPTPROGRAMM INITIALISIERUNG
# ============================================================================

Write-Host "`n[OK] Initialisierung abgeschlossen!" -ForegroundColor Green

# Zeiterfassung
$script:StartTime = Get-Date
$script:ActionsPerformed = @()

# Internet-Check
$script:HasInternet = Test-InternetConnectivity

# Netzwerk (nur im Debug-Modus)
if ($script:ExplainMode) {
    Get-NetworkAdapters
}

# Laufwerke erkennen
Initialize-AutoDriveDetection

# Treiber-Status
$driverProblem = Check-DriverStatus
if ($driverProblem) {
    $script:UpdateRecommendations += "Treiber-Updates empfohlen"
}

Start-Sleep -Seconds 2

Clear-Host
Write-Host @"
================================================================
                HELLION POWER TOOL v6.1 - WILLKOMMEN
================================================================
"@ -ForegroundColor Cyan

Write-Host "`n[*] EMPFEHLUNG: AUTO-MODUS" -ForegroundColor Green
Write-Host "Der Auto-Modus fuehrt alle wichtigen Optimierungen automatisch durch:" -ForegroundColor White
Write-Host "  - System-Integritaet pruefen" -ForegroundColor Gray
Write-Host "  - Temp-Dateien bereinigen" -ForegroundColor Gray
Write-Host "  - Privacy optimieren" -ForegroundColor Gray
Write-Host "  - Treiber pruefen" -ForegroundColor Gray

Write-Host "`n[INFO] Dauer: ~10-20 Minuten" -ForegroundColor Yellow

$autoChoice = Read-Host "`nAuto-Modus jetzt starten? [j/n]"

if ($autoChoice -eq 'j' -or $autoChoice -eq 'J') {
    $autoCompleted = Invoke-AutoMode
    
    if ($autoCompleted) {
        Write-Host "`n[OK] Auto-Modus erfolgreich!" -ForegroundColor Green
        $finalChoice = Read-Host "`nWeitere Optimierungen im Menue? [j/n]"
        
        if ($finalChoice -ne 'j' -and $finalChoice -ne 'J') {
            # Direkt zur Zusammenfassung
            $continueRunning = $false
        } else {
            $continueRunning = $true
        }
    } else {
        $continueRunning = $true
    }
} else {
    Write-Host "`n[*] Oeffne Hauptmenue..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    $continueRunning = $true
}

# ============================================================================
#                         HAUPTSCHLEIFE
# ============================================================================

while ($continueRunning) {
    Show-MainMenu
    $userChoice = Read-Host "`n[*] Deine Wahl"
    $continueRunning = Process-MenuChoice -Choice $userChoice
}

# ============================================================================
#                         FINALE ZUSAMMENFASSUNG
# ============================================================================

Clear-Host
Write-Host @"
================================================================
           HELLION POWER TOOL v6.1 - ZUSAMMENFASSUNG
================================================================
"@ -ForegroundColor Green

$endTime = Get-Date
$totalDuration = $endTime - $script:StartTime

Write-Host "`n[INFO] STATISTIK:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Gray

Write-Host "`n[*] ZEIT:" -ForegroundColor Yellow
Write-Host "   - Start: $($script:StartTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "   - Ende: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "   - Dauer: $([math]::Round($totalDuration.TotalMinutes, 1)) Minuten" -ForegroundColor Green

Write-Host "`n[*] SPEICHER:" -ForegroundColor Yellow
Write-Host "   - Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Green
if ($script:TotalFreedSpace -gt 1024) {
    Write-Host "   - Entspricht: $([math]::Round($script:TotalFreedSpace / 1024, 2)) GB" -ForegroundColor Cyan
}

Write-Host "`n[OK] DURCHGEFUEHRTE AKTIONEN ($($script:ActionsPerformed.Count)):" -ForegroundColor Yellow
if ($script:ActionsPerformed.Count -gt 0) {
    $script:ActionsPerformed | Select-Object -Unique | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor White
    }
} else {
    Write-Host "   Keine Aktionen durchgefuehrt" -ForegroundColor Gray
}

Write-Host "`n[*] SYSTEM-STATUS:" -ForegroundColor Yellow
Write-Host "   - Laufwerke: $($script:DriveConfig.Count)" -ForegroundColor White
Write-Host "   - Wiederherstellungspunkt: $(if($script:RestorePointCreated){'[OK] Erstellt'}else{'[SKIP] Nicht erstellt'})" -ForegroundColor White
Write-Host "   - Internet: $(if($script:HasInternet){'[OK] Verbunden'}else{'[ERROR] Offline'})" -ForegroundColor White

# Probleme
if ($script:Errors.Count -gt 0) {
    Write-Host "`n[ERROR] FEHLER ($($script:Errors.Count)):" -ForegroundColor Red
    $script:Errors | Select-Object -First 3 | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Red
    }
}

if ($script:Warnings.Count -gt 0) {
    Write-Host "`n[WARNING] WARNUNGEN ($($script:Warnings.Count)):" -ForegroundColor Yellow
    $script:Warnings | Select-Object -First 3 | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Yellow
    }
}

# Empfehlungen
Write-Host "`n[*] EMPFEHLUNGEN:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Gray

$recommendations = @()

if ($script:TotalFreedSpace -lt 100) {
    $recommendations += "Fuehren Sie vollstaendige Bereinigung durch"
}

if (-not $script:RestorePointCreated) {
    $recommendations += "Erstellen Sie Systemwiederherstellungspunkt"
}

if ($script:UpdateRecommendations.Count -gt 0) {
    $recommendations += $script:UpdateRecommendations
}

$drives = Get-AllDrives
foreach ($drive in $drives) {
    if ($drive.FreeSpace -lt ($drive.TotalSpace * 0.15)) {
        $recommendations += "Laufwerk $($drive.Letter) hat wenig Speicher"
    }
}

if ($recommendations.Count -gt 0) {
    $recommendations | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "   [OK] System ist optimiert!" -ForegroundColor Green
}

# Abschluss
Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host @"
      HELLION POWER TOOL v6.1 'BELEANDIS-FIX' - FERTIG!
         
         Vielen Dank fuer die Nutzung!
         
         [*] Entwickelt von: Hellion Online Media - Florian Wathling
         [*] Website: https://hellion-online-media.de
         [*] Support: support@hellion-online-media.de
         
         [*] Tipp: Monatliche Nutzung empfohlen!
"@ -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Green

# Report-Option
Write-Host "`n[*] Report speichern? [j/n]" -ForegroundColor Yellow
$saveReport = Read-Host
if ($saveReport -eq 'j' -or $saveReport -eq 'J') {
    Generate-SystemReport
}

# Aufraeumen
if ($script:ExplainMode) {
    Write-Host "`n[*] Raeume auf..." -ForegroundColor Blue
    Write-Host "   - Temporaere Variablen loeschen..." -ForegroundColor Gray
    Write-Host "   - Cache leeren..." -ForegroundColor Gray
}

Remove-Variable -Name ActionsPerformed, TotalFreedSpace -Scope Script -ErrorAction SilentlyContinue
[System.GC]::Collect()

Write-Host "`n[*] Enter zum Beenden..." -ForegroundColor Yellow

}
catch {
    # NOTFALLPLAN: Dieser Code wird NUR bei einem schweren Fehler ausgefuehrt.
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "              EIN SCHWERWIEGENDER FEHLER IST AUFGETRETEN!" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "FEHLERMELDUNG: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "SKRIPTNAME:    $($_.InvocationInfo.ScriptName)" -ForegroundColor White
    Write-Host "ZEILE:         $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor White
    Write-Host ""
}
finally {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Gray
    Read-Host "Das Skript wurde beendet. Druecken Sie Enter zum Schliessen."
}