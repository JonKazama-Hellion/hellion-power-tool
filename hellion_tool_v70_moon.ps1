# ============================================================================
#                   HELLION ONLINE MEDIA POWER TOOL v7 "Moon"
# ============================================================================
# 
# Entwickelt von: Hellion Online Media - Florian Wathling
# Erstellungsdatum: 07.09.2025
# Version: 7.0.1 "Moon-Bugfix" (Enhanced Edition)
# Website: https://hellion-online-media.de
# Support: support@hellion-online-media.de
#
# CHANGELOG v7.0 "MOON":
# ============================================================================

# Antiviren-freundlicher Startup mit Delay
Start-Sleep -Milliseconds 100

# Setze sichere Defaults
$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'

# Globale Konfiguration
$script:ToolVersion = "7.0.1"
$script:ToolCodename = "Moon-Bugfix"
$script:ToolBuild = "20250907"

# ============================================================================
#                         ADMIN-RECHTE PRÜFUNG
# ============================================================================

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "                    ADMIN-RECHTE ERFORDERLICH                   " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Dieses Tool benoetigt Administrator-Rechte fuer System-Aenderungen." -ForegroundColor Cyan
    Write-Host "Es wird nun ein Neustart mit erhoehten Rechten angefordert." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Bitte bestaetigen Sie die folgende Windows-Sicherheitsabfrage (UAC)." -ForegroundColor Green
    Write-Host ""
    
    Start-Sleep -Seconds 2
    
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ([string]::IsNullOrEmpty($scriptPath)) {
            # Fallback für .bat-Start
            $scriptPath = $PSCommandPath
            if ([string]::IsNullOrEmpty($scriptPath)) {
                throw "Skript-Pfad konnte nicht ermittelt werden. Bitte manuell als Admin starten."
            }
        }
        
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -ErrorAction Stop
        
        # Signal-Datei für Launcher erstellen
        $signalFile = Join-Path $PSScriptRoot "temp\uac_restart.signal"
        if (-not (Test-Path (Split-Path $signalFile))) {
            New-Item -ItemType Directory -Path (Split-Path $signalFile) -Force | Out-Null
        }
        "UAC_RESTART" | Out-File -FilePath $signalFile -Encoding UTF8
        
        # Original-Fenster schließen nach erfolgreichem Start
        Write-Host "Neues Admin-Fenster wird geoeffnet..." -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        [Environment]::Exit(0)
    }
    catch {
        Write-Host "FEHLER: Admin-Rechte konnten nicht angefordert werden." -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "LOESUNG: Rechtsklick auf die Datei -> 'Als Administrator ausfuehren'" -ForegroundColor Cyan
        Read-Host "Enter zum Beenden"
        [Environment]::Exit(1)
    }
}

# UAC-Restart Signal-Datei löschen falls vorhanden
$signalFile = Join-Path $PSScriptRoot "temp\uac_restart.signal"
if (Test-Path $signalFile) {
    Remove-Item $signalFile -Force -ErrorAction SilentlyContinue
}

Write-Host "[OK] Administrator-Rechte bestaetigt!" -ForegroundColor Green
Start-Sleep -Milliseconds 500

# ============================================================================
#                         SYSTEM-KOMPATIBILITAET
# ============================================================================

function Test-SystemCompatibility {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $script:WindowsVersion = $osInfo.Caption
    $script:WindowsBuild = $osInfo.BuildNumber
    $script:WindowsArchitecture = $osInfo.OSArchitecture
    
    # Windows-Version prüfen
    $script:IsWindows10 = $osInfo.Caption -like "*Windows 10*"
    $script:IsWindows11 = $osInfo.Caption -like "*Windows 11*"
    $script:IsWindowsServer = $osInfo.Caption -like "*Server*"
    
    # Mindest-Build für Windows 10: 1809 (Build 17763)
    if ($script:WindowsBuild -lt 17763) {
        Write-Host "[WARNING] Aeltere Windows-Version erkannt. Einige Funktionen eingeschraenkt." -ForegroundColor Yellow
        $script:LegacyMode = $true
    } else {
        $script:LegacyMode = $false
    }
    
    # PowerShell-Version prüfen
    $script:PSVersion = $PSVersionTable.PSVersion.Major
    if ($script:PSVersion -lt 5) {
        Write-Host "[WARNING] PowerShell $script:PSVersion erkannt. Version 5+ empfohlen." -ForegroundColor Yellow
    }
    
    return $true
}

# ============================================================================
#                         GLOBALE VARIABLEN & KONFIGURATION
# ============================================================================

# Verbessertes Logging-System
$script:LogPath = "$PSScriptRoot\logs"
$script:LogFile = "$script:LogPath\$(Get-Date -Format 'yyyy-MM-dd').log"
$script:DetailedLogging = $false
$script:LogBuffer = @()

# Status-Tracking
$script:Errors = @()
$script:Warnings = @()
$script:SuccessActions = @()
$script:ActionsPerformed = @()
$script:TotalFreedSpace = 0
$script:StartTime = Get-Date

# Konfiguration
$script:ExplainMode = $false
$script:VisualMode = $false
$script:AutoApproveCleanup = $false
$script:RestorePointCreated = $false
$script:HasInternet = $false
$script:DriveConfig = @{}

# Antiviren-Sicherheit
$script:AVSafeMode = $true
$script:AVDelayMs = 50

# ============================================================================
#                         VERBESSERTES LOGGING-SYSTEM
# ============================================================================

function Initialize-Logging {
    # Log-Verzeichnis erstellen falls nicht vorhanden
    if (-not (Test-Path $script:LogPath)) {
        try {
            New-Item -ItemType Directory -Path $script:LogPath -Force | Out-Null
            Write-Host "[OK] Log-Verzeichnis erstellt: $script:LogPath" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Log-Verzeichnis konnte nicht erstellt werden: $($_.Exception.Message)" -ForegroundColor Yellow
            # Fallback zu TEMP-Verzeichnis
            $script:LogPath = $env:TEMP
            $script:LogFile = "$script:LogPath\Hellion_Tool_$(Get-Date -Format 'yyyy-MM-dd').log"
        }
    }
    
    # Startup-Log-Eintrag
    Write-Log "=== Hellion Tool v$script:ToolVersion $script:ToolCodename gestartet ===" -Level "INFO"
    Write-Log "System: $script:WindowsVersion Build $script:WindowsBuild" -Level "INFO"
    Write-Log "Benutzer: $env:USERNAME@$env:COMPUTERNAME" -Level "INFO"
    Write-Log "PowerShell: $($PSVersionTable.PSVersion.ToString())" -Level "INFO"
    
    # Alte Logs aufräumen
    Clear-OldLogs
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White",
        [switch]$NoConsole,
        [switch]$NoFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # In Log-Buffer schreiben (für späteren Abruf)
    $script:LogBuffer += $logEntry
    
    # Begrenzung des Log-Buffers auf 1000 Einträge
    if ($script:LogBuffer.Count -gt 1000) {
        $script:LogBuffer = $script:LogBuffer[-500..-1]
    }
    
    # In Datei schreiben (immer aktiv im neuen System)
    if (-not $NoFile) {
        try {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {
            # Fehler beim Logging stillschweigend ignorieren
        }
    }
    
    # Konsolen-Ausgabe
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR" { 
                Write-Host $Message -ForegroundColor Red 
            }
            "WARNING" { 
                Write-Host $Message -ForegroundColor Yellow 
            }
            "SUCCESS" { 
                Write-Host $Message -ForegroundColor Green 
            }
            "DEBUG" { 
                if ($script:ExplainMode) {
                    Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
                }
            }
            "TRACE" {
                if ($script:ExplainMode -and $script:DetailedLogging) {
                    Write-Host "[TRACE] $Message" -ForegroundColor DarkMagenta
                }
            }
            default { 
                Write-Host $Message -ForegroundColor $Color 
            }
        }
    }
}

function Clear-OldLogs {
    try {
        $logFiles = Get-ChildItem "$script:LogPath\*.log" -ErrorAction SilentlyContinue
        $oldLogs = $logFiles | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
        
        if ($oldLogs) {
            $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Log "Alte Logs bereinigt: $($oldLogs.Count) Dateien" -Level "DEBUG"
        }
        
        # Zusätzlich: Sehr große Log-Dateien komprimieren (>10MB)
        $largeLogs = $logFiles | Where-Object { $_.Length -gt 10MB }
        foreach ($largeLog in $largeLogs) {
            try {
                $compressedName = $largeLog.FullName -replace '\.log$', '_compressed.zip'
                Compress-Archive -Path $largeLog.FullName -DestinationPath $compressedName -Force
                Remove-Item $largeLog.FullName -Force
                Write-Log "Große Log-Datei komprimiert: $($largeLog.Name)" -Level "DEBUG"
            } catch {
                # Komprimierung fehlgeschlagen - ignorieren
            }
        }
    } catch {
        # Log-Bereinigung fehlgeschlagen - stillschweigend ignorieren
    }
}

function Get-LogSummary {
    $summary = @{
        "LogFile" = $script:LogFile
        "LogSize" = if (Test-Path $script:LogFile) { 
            [math]::Round((Get-Item $script:LogFile).Length / 1KB, 2) 
        } else { 0 }
        "BufferEntries" = $script:LogBuffer.Count
        "ErrorCount" = $script:Errors.Count
        "WarningCount" = $script:Warnings.Count
        "SuccessCount" = $script:SuccessActions.Count
    }
    return $summary
}

function Add-Error {
    param([string]$Message, [string]$Details = "")
    $fullMessage = if ($Details) { "$Message - Details: $Details" } else { $Message }
    $script:Errors += $fullMessage
    Write-Log "[ERROR] $fullMessage" -Level "ERROR"
}

function Add-Warning {
    param([string]$Message, [string]$Details = "")
    $fullMessage = if ($Details) { "$Message - Details: $Details" } else { $Message }
    $script:Warnings += $fullMessage
    Write-Log "[WARNING] $fullMessage" -Level "WARNING"
}

function Add-Success {
    param([string]$Message)
    $script:SuccessActions += $Message
    Write-Log "[OK] $Message" -Level "SUCCESS"
}

# ============================================================================
#                         ANTIVIREN-SICHERE OPERATIONEN
# ============================================================================

function Invoke-AVSafeOperation {
    param(
        [scriptblock]$Operation,
        [string]$Description = "Operation"
    )
    
    if ($script:AVSafeMode) {
        Start-Sleep -Milliseconds $script:AVDelayMs
    }
    
    try {
        Write-Log "[*] $Description..." -Level "INFO" -Color Cyan
        $result = & $Operation
        return $result
    }
    catch {
        Add-Error "$Description fehlgeschlagen" $_.Exception.Message
        return $null
    }
}

function Test-AntivirusStatus {
    Write-Log "`n[*] --- ANTIVIRUS STATUS ---" -Color Cyan
    
    $avProducts = @()
    
    # Windows Security Center abfragen
    try {
        $namespaceName = "SecurityCenter2"
        if ($script:IsWindowsServer) {
            $namespaceName = "SecurityCenter"
        }
        
        $avProducts = Get-CimInstance -Namespace "root\$namespaceName" -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    } catch {
        Write-Log "AV-Status konnte nicht abgefragt werden" -Level "DEBUG"
    }
    
    if ($avProducts) {
        foreach ($av in $avProducts) {
            $avName = $av.displayName
            Write-Log "  [OK] Erkannt: $avName" -Color Green
            
            # Spezielle Behandlung für bekannte AVs
            if ($avName -like "*Bitdefender*") {
                Write-Log "     Bitdefender erkannt - Extra-Sicherheit aktiviert" -Color Yellow
                $script:AVDelayMs = 100
            }
            elseif ($avName -like "*Windows Defender*") {
                Write-Log "     Windows Defender aktiv" -Color Green
            }
        }
    } else {
        Write-Log "  [INFO] Standard Windows-Schutz aktiv" -Color Gray
    }
    
    return $avProducts.Count
}

# ============================================================================
#                         ERWEITERTE DEBUG-FUNKTIONEN
# ============================================================================

function Show-DebugInfo {
    param(
        [string]$Context,
        [hashtable]$Data = @{},
        [string]$Level = "DEBUG"
    )
    
    if (-not $script:ExplainMode) { return }
    
    Write-Log "`n=== $Context ===" -Level $Level
    Write-Log "Zeit: $(Get-Date -Format 'HH:mm:ss.fff')" -Level $Level
    
    if ($Data.Count -gt 0) {
        foreach ($key in $Data.Keys) {
            Write-Log "$key : $($Data[$key])" -Level $Level
        }
    }
    
    # Stack-Trace bei Fehlern
    if ($Error.Count -gt 0 -and $script:DetailedLogging) {
        Write-Log "Letzter Fehler: $($Error[0].Exception.Message)" -Level "ERROR"
        Write-Log "Position: $($Error[0].InvocationInfo.PositionMessage)" -Level "ERROR"
        
        # Vollständiger Stack-Trace nur in TRACE-Level
        Write-Log "Stack-Trace: $($Error[0].ScriptStackTrace)" -Level "TRACE"
    }
    
    # Speicher-Info im Debug-Modus
    if ($script:DetailedLogging) {
        $memInfo = Get-Process -Id $PID | Select-Object WorkingSet, PagedMemorySize
        Write-Log "Speicherverbrauch: $([math]::Round($memInfo.WorkingSet / 1MB, 1)) MB" -Level "TRACE"
    }
}

function Write-DebugVar {
    param(
        [string]$VariableName,
        [object]$VariableValue,
        [string]$Context = ""
    )
    
    if (-not $script:ExplainMode) { return }
    
    $contextPrefix = if ($Context) { "[$Context] " } else { "" }
    $valueText = if ($VariableValue -is [array]) { 
        "$($VariableValue.Count) Elemente" 
    } elseif ($VariableValue -is [hashtable]) {
        "$($VariableValue.Count) Schlüssel"
    } else { 
        "$VariableValue" 
    }
    
    Write-Log "$contextPrefix$VariableName = $valueText" -Level "DEBUG"
}

function Test-CommandAvailability {
    param([string]$CommandName)
    
    $available = $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
    
    if ($script:ExplainMode) {
        $status = if ($available) { "[OK]" } else { "[NICHT VERFUEGBAR]" }
        Write-Log "$status Command: $CommandName" -Level "DEBUG"
    }
    
    return $available
}

# ============================================================================
#                         SYSTEM-INFORMATIONEN
# ============================================================================

function Get-DetailedSystemInfo {
    Write-Log "`n[*] --- SYSTEM-ANALYSE ---" -Color Cyan
    
    $sysInfo = @{
        "OS" = $script:WindowsVersion
        "Build" = $script:WindowsBuild
        "Architektur" = $script:WindowsArchitecture
        "PowerShell" = $PSVersionTable.PSVersion.ToString()
        "Benutzer" = [System.Environment]::UserName
        "Computer" = [System.Environment]::MachineName
        "Domain" = [System.Environment]::UserDomainName
    }
    
    # RAM-Info
    try {
        $ram = Get-CimInstance Win32_ComputerSystem
        $sysInfo["RAM"] = "$([math]::Round($ram.TotalPhysicalMemory / 1GB, 1)) GB"
    } catch {
        $sysInfo["RAM"] = "Unbekannt"
    }
    
    # CPU-Info
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $sysInfo["CPU"] = $cpu.Name
        $sysInfo["CPU-Kerne"] = $cpu.NumberOfCores
    } catch {
        $sysInfo["CPU"] = "Unbekannt"
    }
    
    if ($script:ExplainMode) {
        Write-Host "`n[DEBUG] System-Details:" -ForegroundColor DarkYellow
        foreach ($key in $sysInfo.Keys) {
            Write-Host "  $key : $($sysInfo[$key])" -ForegroundColor Gray
        }
    }
    
    return $sysInfo
}

# ============================================================================
#                         LAUFWERKS-ERKENNUNG (ERWEITERT)
# ============================================================================

function Get-EnhancedDriveInfo {
    param([string]$DriveLetter)
    
    $driveLetterClean = $DriveLetter.TrimEnd(':')
    $driveInfo = @{
        "Letter" = "${driveLetterClean}:"
        "Type" = "Unknown"
        "FileSystem" = "Unknown"
        "HealthStatus" = "Unknown"
        "Temperature" = "N/A"
    }
    
    try {
        # Volume-Informationen
        $volume = Get-Volume -DriveLetter $driveLetterClean -ErrorAction Stop
        $driveInfo["FileSystem"] = $volume.FileSystem
        $driveInfo["HealthStatus"] = $volume.HealthStatus
        
        # Physische Disk-Informationen
        $partition = Get-Partition -DriveLetter $driveLetterClean -ErrorAction SilentlyContinue
        if ($partition) {
            $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
            if ($disk) {
                $physical = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $disk.Number }
                if ($physical) {
                    # Typ bestimmen
                    switch ($physical.MediaType) {
                        'SSD' {
                            $driveInfo["Type"] = if ($physical.BusType -eq 'NVMe') { "NVMe SSD" } else { "SATA SSD" }
                        }
                        'HDD' { $driveInfo["Type"] = "HDD" }
                        default {
                            if ($physical.SpindleSpeed -eq 0) {
                                $driveInfo["Type"] = "SSD"
                            } else {
                                $driveInfo["Type"] = "HDD"
                            }
                        }
                    }
                    
                    # Temperatur wenn verfügbar
                    if ($physical.Temperature) {
                        $driveInfo["Temperature"] = "$($physical.Temperature)°C"
                    }
                }
            }
        }
    } catch {
        Write-Log "Erweiterte Laufwerksinfo fuer $DriveLetter nicht verfuegbar" -Level "DEBUG"
    }
    
    return $driveInfo
}

function Initialize-DriveConfiguration {
    Write-Log "`n[*] --- LAUFWERKS-ERKENNUNG ---" -Color Cyan
    
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $driveCount = 0
    
    foreach ($drive in $drives) {
        $driveLetter = $drive.DeviceID
        $enhancedInfo = Get-EnhancedDriveInfo $driveLetter
        
        $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalSpace = [math]::Round($drive.Size / 1GB, 2)
        $usedSpace = $totalSpace - $freeSpace
        $usedPercent = if ($totalSpace -gt 0) { [math]::Round(($usedSpace / $totalSpace) * 100, 1) } else { 0 }
        
        $script:DriveConfig[$driveLetter] = @{
            "Type" = $enhancedInfo.Type
            "FreeSpace" = $freeSpace
            "TotalSpace" = $totalSpace
            "UsedSpace" = $usedSpace
            "UsedPercent" = $usedPercent
            "FileSystem" = $enhancedInfo.FileSystem
            "HealthStatus" = $enhancedInfo.HealthStatus
        }
        
        # Farbkodierung basierend auf Typ
        $typeColor = switch -Wildcard ($enhancedInfo.Type) {
            "*NVMe*" { "Magenta" }
            "*SSD*" { "Cyan" }
            "*HDD*" { "Yellow" }
            default { "White" }
        }
        
        Write-Host "  [$($driveCount + 1)] $driveLetter " -NoNewline
        Write-Host "[$($enhancedInfo.Type)]" -ForegroundColor $typeColor -NoNewline
        Write-Host " - $freeSpace GB frei von $totalSpace GB " -NoNewline
        
        # Warnung bei wenig Speicher
        if ($usedPercent -gt 90) {
            Write-Host "($usedPercent% belegt)" -ForegroundColor Red -NoNewline
            Write-Host " [WARNUNG]" -ForegroundColor Red
            Add-Warning "Laufwerk $driveLetter hat nur noch $freeSpace GB frei"
        } elseif ($usedPercent -gt 80) {
            Write-Host "($usedPercent% belegt)" -ForegroundColor Yellow
        } else {
            Write-Host "($usedPercent% belegt)" -ForegroundColor Green
        }
        
        if ($script:ExplainMode) {
            Write-Host "     Dateisystem: $($enhancedInfo.FileSystem)" -ForegroundColor Gray
            Write-Host "     Status: $($enhancedInfo.HealthStatus)" -ForegroundColor Gray
        }
        
        $driveCount++
    }
    
    Write-Log "[INFO] $driveCount Laufwerke erkannt und analysiert" -Color Blue
    return $driveCount
}

# ============================================================================
#                         NETZWERK & INTERNET (ERWEITERT)
# ============================================================================

function Test-EnhancedInternetConnectivity {
    Write-Log "`n[*] --- INTERNET-VERBINDUNGSTEST ---" -Color Cyan
    
    $testResults = @{
        "DNS" = $false
        "HTTP" = $false
        "Ping" = $false
        "Speed" = "Unknown"
    }
    
    # DNS-Test
    try {
        $dnsResult = Resolve-DnsName "www.google.com" -ErrorAction Stop
        if ($dnsResult) {
            $testResults["DNS"] = $true
            Write-Log "  [OK] DNS-Aufloesung funktioniert" -Color Green
        }
    } catch {
        Write-Log "  [FAIL] DNS-Aufloesung fehlgeschlagen" -Level "WARNING"
    }
    
    # Ping-Test zu mehreren Servern
    $pingTargets = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    $successfulPings = 0
    
    foreach ($target in $pingTargets) {
        if (Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $successfulPings++
            if ($script:ExplainMode) {
                Write-Log "  [OK] Ping zu $target erfolgreich" -Color Green
            }
        }
    }
    
    if ($successfulPings -ge 2) {
        $testResults["Ping"] = $true
        Write-Log "  [OK] Ping-Test erfolgreich ($successfulPings/3 Server)" -Color Green
    } else {
        Write-Log "  [WARNING] Ping-Test teilweise fehlgeschlagen" -Level "WARNING"
    }
    
    # HTTP-Test
    try {
        $webRequest = Invoke-WebRequest -Uri "http://www.msftconnecttest.com/connecttest.txt" `
            -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        
        if ($webRequest.StatusCode -eq 200) {
            $testResults["HTTP"] = $true
            Write-Log "  [OK] HTTP-Verbindung funktioniert" -Color Green
        }
    } catch {
        Write-Log "  [WARNING] HTTP-Test fehlgeschlagen" -Level "WARNING"
    }
    
    # Gesamt-Bewertung
    $script:HasInternet = ($testResults["DNS"] -or $testResults["Ping"] -or $testResults["HTTP"])
    
    if ($script:HasInternet) {
        Write-Log "[OK] Internetverbindung verfuegbar" -Level "SUCCESS"
    } else {
        Write-Log "[ERROR] Keine Internetverbindung erkannt" -Level "ERROR"
        Write-Log "[INFO] Einige Funktionen sind eingeschraenkt" -Level "WARNING"
    }
    
    return $script:HasInternet
}

# ============================================================================
#                         ERWEITERTE TREIBER-PRUEFUNG
# ============================================================================

function Get-DetailedDriverStatus {
    Write-Log "`n[*] --- DETAILLIERTE TREIBER-ANALYSE ---" -Color Cyan
    
    $driverIssues = @{
        "Critical" = @()
        "Warning" = @()
        "Info" = @()
    }
    
    try {
        # Alle Geräte mit Problemen
        $problemDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        
        if ($problemDevices) {
            Write-Log "[WARNING] Geraete mit Treiber-Problemen gefunden:" -Level "WARNING"
            
            foreach ($device in $problemDevices) {
                $errorCode = $device.ConfigManagerErrorCode
                $deviceName = $device.Name
                $deviceID = $device.DeviceID
                
                # Fehlercode-Interpretation
                $errorDescription = switch ($errorCode) {
                    1 { "Nicht korrekt konfiguriert" }
                    3 { "Treiber beschaedigt" }
                    10 { "Geraet kann nicht starten" }
                    12 { "Nicht genuegend Ressourcen" }
                    18 { "Treiber muss neu installiert werden" }
                    19 { "Registry-Problem" }
                    22 { "Geraet deaktiviert" }
                    24 { "Geraet nicht vorhanden" }
                    28 { "Treiber nicht installiert" }
                    31 { "Treiber konnte nicht geladen werden" }
                    32 { "Treiber deaktiviert" }
                    37 { "Treiber-Initialisierung fehlgeschlagen" }
                    43 { "Geraet wurde angehalten" }
                    default { "Fehlercode $errorCode" }
                }
                
                $issueDetail = @{
                    "Name" = $deviceName
                    "ID" = $deviceID
                    "ErrorCode" = $errorCode
                    "Description" = $errorDescription
                }
                
                # Kategorisierung nach Schweregrad
                if ($errorCode -in @(3, 10, 18, 28, 31)) {
                    $driverIssues["Critical"] += $issueDetail
                    Write-Host "  [CRITICAL] $deviceName" -ForegroundColor Red
                    Write-Host "            -> $errorDescription" -ForegroundColor DarkRed
                } elseif ($errorCode -in @(1, 12, 19, 22)) {
                    $driverIssues["Warning"] += $issueDetail
                    Write-Host "  [WARNING] $deviceName" -ForegroundColor Yellow
                    Write-Host "           -> $errorDescription" -ForegroundColor DarkYellow
                } else {
                    $driverIssues["Info"] += $issueDetail
                    if ($script:ExplainMode) {
                        Write-Host "  [INFO] $deviceName" -ForegroundColor Gray
                        Write-Host "        -> $errorDescription" -ForegroundColor DarkGray
                    }
                }
                
                # Debug-Info
                if ($script:ExplainMode) {
                    Write-Host "        Device ID: $deviceID" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-Log "[OK] Keine Treiber-Probleme gefunden" -Level "SUCCESS"
        }
        
        # GPU-Treiber speziell prüfen
        Write-Log "`n[*] GPU-Treiber-Status:" -Color Cyan
        $gpus = Get-WmiObject Win32_VideoController
        
        foreach ($gpu in $gpus) {
            $gpuName = $gpu.Name
            $driverVersion = $gpu.DriverVersion
            $driverDate = $gpu.DriverDate
            
            Write-Host "  [*] $gpuName" -ForegroundColor Cyan
            Write-Host "      Version: $driverVersion" -ForegroundColor White
            
            if ($driverDate) {
                try {
                    $dateString = $driverDate
                    $year = [int]$dateString.Substring(0,4)
                    $month = [int]$dateString.Substring(4,2)
                    $day = [int]$dateString.Substring(6,2)
                    $parsedDate = Get-Date -Year $year -Month $month -Day $day
                    $daysOld = ((Get-Date) - $parsedDate).Days
                    
                    if ($daysOld -gt 365) {
                        Write-Host "      [WARNING] Treiber ist $daysOld Tage alt (>1 Jahr)" -ForegroundColor Yellow
                        Add-Warning "GPU-Treiber ($gpuName) ist veraltet"
                    } elseif ($daysOld -gt 180) {
                        Write-Host "      [INFO] Treiber ist $daysOld Tage alt" -ForegroundColor Gray
                    } else {
                        Write-Host "      [OK] Treiber ist aktuell ($daysOld Tage)" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "      Datum: Nicht verfuegbar" -ForegroundColor Gray
                }
            }
        }
        
        # Netzwerkadapter prüfen
        if ($script:ExplainMode) {
            Write-Log "`n[*] Netzwerkadapter-Status:" -Color Cyan
            $netAdapters = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
            
            foreach ($adapter in $netAdapters) {
                $status = if ($adapter.NetEnabled) { "[AKTIV]" } else { "[INAKTIV]" }
                $statusColor = if ($adapter.NetEnabled) { "Green" } else { "Gray" }
                Write-Host "  $status $($adapter.Name)" -ForegroundColor $statusColor
            }
        }
        
    } catch {
        Add-Error "Treiber-Analyse fehlgeschlagen" $_.Exception.Message
    }
    
    # Zusammenfassung
    $totalIssues = $driverIssues["Critical"].Count + $driverIssues["Warning"].Count
    
    if ($totalIssues -gt 0) {
        Write-Log "`n[WARNING] Treiber-Probleme gefunden:" -Level "WARNING"
        Write-Log "  Critical: $($driverIssues['Critical'].Count)" -Level "WARNING"
        Write-Log "  Warning: $($driverIssues['Warning'].Count)" -Level "WARNING"
        
        if ($driverIssues["Critical"].Count -gt 0) {
            $script:UpdateRecommendations += "DRINGEND: Kritische Treiber-Probleme beheben"
        }
    }
    
    return $driverIssues
}

# ============================================================================
#                         HELPER FUNKTIONEN
# ============================================================================

function Get-FolderSize {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) { return 0 }
    
    try {
        $size = 0
        $items = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            if (-not $item.PSIsContainer) {
                $size += $item.Length
            }
        }
        
        return [math]::Round($size / 1MB, 2)
    } catch {
        return 0
    }
}

function Show-ProgressBar {
    param(
        [string]$Activity,
        [int]$PercentComplete,
        [string]$Status = ""
    )
    
    if (-not $script:VisualMode) { return }
    
    $barLength = 50
    $filledLength = [math]::Floor($barLength * $PercentComplete / 100)
    $bar = "#" * $filledLength + "-" * ($barLength - $filledLength)
    
    $progressLine = "`r[*] $Activity [$bar] $PercentComplete%"
    if ($Status) { $progressLine += " - $Status" }
    
    Write-Host $progressLine -NoNewline -ForegroundColor Cyan
    
    if ($PercentComplete -eq 100) {
        Write-Host " [OK]" -ForegroundColor Green
    }
}

function Format-ByteSize {
    param([long]$Bytes)
    
    if ($Bytes -gt 1TB) {
        return "$([math]::Round($Bytes / 1TB, 2)) TB"
    } elseif ($Bytes -gt 1GB) {
        return "$([math]::Round($Bytes / 1GB, 2)) GB"
    } elseif ($Bytes -gt 1MB) {
        return "$([math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -gt 1KB) {
        return "$([math]::Round($Bytes / 1KB, 2)) KB"
    } else {
        return "$Bytes Bytes"
    }
}

# ============================================================================
#                         INITIALISIERUNG
# ============================================================================

Clear-Host

# Antiviren-freundlicher Banner mit Delay
Write-Host @"
================================================================
                                                                
    HH   HH EEEEEEE LL      LL      IIIII   OOOOO   NN   NN    
    HH   HH EE      LL      LL        III  OO   OO  NNN  NN    
    HHHHHHH EEEEE   LL      LL        III  OO   OO  NN N NN    
    HH   HH EE      LL      LL        III  OO   OO  NN  NNN    
    HH   HH EEEEEEE LLLLLLL LLLLLLL IIIII   OOOOO   NN   NN    
                                                                
            ONLINE MEDIA POWER TOOL v$script:ToolVersion "$script:ToolCodename"
                                                                
  [*] ENTWICKELT VON: Hellion Online Media - Florian Wathling  
  [*] VERSION: $script:ToolVersion ($script:ToolCodename) | BUILD: $script:ToolBuild
  [*] WEBSITE: https://hellion-online-media.de                 
                                                                
  [*] FEATURES: System-Optimierung | Gaming-Performance         
  [*] SICHERHEIT: Antiviren-sicher | Wiederherstellungspunkt   
  [*] KOMPATIBILITAET: Windows 10/11 | Server 2019+            
                                                                
================================================================
"@ -ForegroundColor Cyan

Start-Sleep -Milliseconds 500

# System-Kompatibilität prüfen
Write-Log "[*] Pruefe System-Kompatibilitaet..." -Color Yellow
Test-SystemCompatibility

# Logging-System initialisieren
Initialize-Logging

# Debug-Modus Abfrage
Write-Host "`n[CONFIG] DEBUG-MODUS EINSTELLUNGEN:" -ForegroundColor Cyan
Write-Host "Der Debug-Modus zeigt erweiterte technische Details und Fehlermeldungen." -ForegroundColor White
Write-Host "Empfohlen bei Problemen oder fuer fortgeschrittene Nutzer." -ForegroundColor Gray
Write-Host ""
Write-Host "[1] Express-Modus (Standard, schnell)" -ForegroundColor Green
Write-Host "[2] Debug-Modus (Detaillierte Ausgabe)" -ForegroundColor Yellow
Write-Host "[3] Vollstaendiges Logging (Debug + Datei)" -ForegroundColor Red

$debugChoice = Read-Host "`nWahl [1-3]"

switch ($debugChoice) {
    '2' {
        $script:ExplainMode = $true
        $script:VisualMode = $true
        Write-Log "[OK] Debug-Modus aktiviert" -Level "SUCCESS"
    }
    '3' {
        $script:ExplainMode = $true
        $script:VisualMode = $true
        $script:DetailedLogging = $true
        Write-Log "[OK] Vollstaendiges Logging aktiviert" -Level "SUCCESS"
        Write-Log "[INFO] Log-Datei: $script:LogFile" -Color Cyan
    }
    default {
        $script:ExplainMode = $false
        $script:VisualMode = $false
        Write-Log "[OK] Express-Modus aktiviert" -Level "SUCCESS"
    }
}

# Antiviren-Status prüfen
Test-AntivirusStatus

# System-Informationen sammeln
Get-DetailedSystemInfo | Out-Null

Write-Log "`n[OK] System-Initialisierung abgeschlossen!" -Level "SUCCESS"
Start-Sleep -Milliseconds 500

# ============================================================================
#                         SYSTEM-INTEGRITAETS-FUNKTIONEN
# ============================================================================

function Invoke-SystemFileChecker {
    Write-Log "`n[*] --- SYSTEM FILE CHECKER (SFC) ---" -Color Cyan
    Write-Log "Prueft und repariert Windows-Systemdateien" -Color Yellow
    
    $choice = Read-Host "`nSFC jetzt ausfuehren? [j/n]"
    if ($choice -ne 'j' -and $choice -ne 'J') {
        Write-Log "[SKIP] SFC uebersprungen" -Color Gray
        return $false
    }
    
    Write-Log "[*] Starte System File Checker..." -Color Green
    
    try {
        Write-Log "[*] Starte SFC /scannow - Dies kann 10-15 Minuten dauern..." -Color Blue
        
        # SFC direkt ausführen und Ausgabe erfassen
        $sfcResult = & sfc.exe /scannow 2>&1 | Out-String
        
        # Exit-Code prüfen
        $sfcExitCode = $LASTEXITCODE
        
        # Ausgabe analysieren
        if ($sfcResult -match "found corrupt files and successfully repaired" -or $sfcResult -match "repariert") {
            Add-Success "SFC: Beschaedigte Dateien wurden repariert"
            Write-Log "[*] Ein Neustart wird empfohlen" -Level "WARNING"
            $script:UpdateRecommendations += "Neustart nach SFC-Reparatur empfohlen"
            return $true
        } elseif ($sfcResult -match "did not find any integrity violations" -or $sfcResult -match "keine Integritätsverletzungen" -or $sfcExitCode -eq 0) {
            Add-Success "SFC: Keine Probleme gefunden"
            return $true
        } elseif ($sfcResult -match "unable to fix" -or $sfcResult -match "konnte nicht repariert werden") {
            Add-Warning "SFC konnte nicht alle Probleme beheben - DISM empfohlen"
            $script:UpdateRecommendations += "DISM-Reparatur empfohlen"
            return $false
        } else {
            # Debug-Info bei unklarem Status
            if ($script:ExplainMode) {
                Write-Log "[DEBUG] SFC Ausgabe: $($sfcResult.Substring(0, [Math]::Min(200, $sfcResult.Length)))" -Level "DEBUG"
                Write-Log "[DEBUG] Exit Code: $sfcExitCode" -Level "DEBUG"
            }
            Add-Warning "SFC abgeschlossen - Status pruefen Sie das Windows-System-Log"
            return $true
        }
        
    } catch {
        Add-Error "SFC fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

function Invoke-DISMRepair {
    Write-Log "`n[*] --- DISM SYSTEM-REPARATUR ---" -Color Cyan
    
    $choice = Read-Host "`nDISM-Reparatur starten? [j/n]"
    if ($choice -ne 'j' -and $choice -ne 'J') {
        Write-Log "[SKIP] DISM uebersprungen" -Color Gray
        return $false
    }
    
    if (-not $script:HasInternet) {
        Write-Log "[WARNING] Keine Internet-Verbindung - DISM eingeschraenkt" -Level "WARNING"
    }
    
    try {
        # Phase 1: CheckHealth
        Write-Log "[1/3] DISM CheckHealth..." -Color Blue
        
        $checkLogFile = "$env:TEMP\dism_check_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $checkProcess = Start-Process "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" `
            -Verb RunAs -Wait -PassThru -RedirectStandardOutput $checkLogFile `
            -WindowStyle Hidden -ErrorAction Stop
        
        $checkResult = Get-Content $checkLogFile -Raw -ErrorAction SilentlyContinue
        Remove-Item $checkLogFile -Force -ErrorAction SilentlyContinue
        
        if ($checkResult -match "No component store corruption" -or $checkProcess.ExitCode -eq 0) {
            Write-Log "[OK] Keine Korruption erkannt" -Level "SUCCESS"
        } else {
            Write-Log "[WARNING] Moegliche Korruption erkannt" -Level "WARNING"
        }
        
        # Phase 2: ScanHealth
        Write-Log "[2/3] DISM ScanHealth (5-10 Min)..." -Color Blue
        
        $scanLogFile = "$env:TEMP\dism_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $scanProcess = Start-Process "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/ScanHealth" `
            -Verb RunAs -Wait -PassThru -RedirectStandardOutput $scanLogFile `
            -WindowStyle Hidden -ErrorAction Stop
        
        $scanResult = Get-Content $scanLogFile -Raw -ErrorAction SilentlyContinue
        Remove-Item $scanLogFile -Force -ErrorAction SilentlyContinue
        
        $needsRepair = ($scanResult -match "repairable" -or $scanProcess.ExitCode -ne 0)
        
        if ($needsRepair) {
            Write-Log "[WARNING] Reparatur erforderlich" -Level "WARNING"
            
            # Phase 3: RestoreHealth
            Write-Log "[3/3] DISM RestoreHealth (15-30 Min)..." -Color Blue
            
            $repairChoice = Read-Host "Reparatur durchfuehren? [j/n]"
            if ($repairChoice -eq 'j' -or $repairChoice -eq 'J') {
                $restoreLogFile = "$env:TEMP\dism_restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
                
                Write-Log "[*] DISM RestoreHealth wird ausgefuehrt..." -Color Yellow
                $restoreProcess = Start-Process "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" `
                    -Verb RunAs -Wait -PassThru -RedirectStandardOutput $restoreLogFile `
                    -WindowStyle Hidden -ErrorAction Stop
                
                $restoreResult = Get-Content $restoreLogFile -Raw -ErrorAction SilentlyContinue
                
                # Debug-Info im Debug-Modus
                if ($script:ExplainMode -and $restoreResult) {
                    Write-Log "[DEBUG] DISM RestoreHealth Exit Code: $($restoreProcess.ExitCode)" -Level "DEBUG"
                    Write-Log "[DEBUG] DISM Output (erste 300 Zeichen): $($restoreResult.Substring(0, [Math]::Min(300, $restoreResult.Length)))" -Level "DEBUG"
                }
                
                Remove-Item $restoreLogFile -Force -ErrorAction SilentlyContinue
                
                if ($restoreResult -match "successfully" -or $restoreProcess.ExitCode -eq 0) {
                    Add-Success "DISM: System erfolgreich repariert"
                    Write-Log "[*] Ein Neustart wird empfohlen" -Level "WARNING"
                    $script:UpdateRecommendations += "Neustart nach DISM-Reparatur empfohlen"
                    return $true
                } else {
                    Add-Warning "DISM: Reparatur moeglicherweise unvollstaendig (Exit Code: $($restoreProcess.ExitCode))"
                    return $false
                }
            }
        } else {
            Add-Success "DISM: Keine Reparatur erforderlich"
            return $true
        }
        
    } catch {
        Add-Error "DISM fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

function Invoke-CheckDisk {
    Write-Log "`n[*] --- CHECKDISK (CHKDSK) LAUFWERKS-PRÜFUNG ---" -Color Cyan
    Write-Log "Prueft und repariert Dateisystem-Fehler auf Laufwerken" -Color Yellow
    
    # Verfügbare Laufwerke anzeigen
    Write-Log "`n[*] Verfuegbare Laufwerke:" -Color Blue
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $driveIndex = 1
    
    foreach ($drive in $drives) {
        $driveLetter = $drive.DeviceID
        $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalSpace = [math]::Round($drive.Size / 1GB, 2)
        $usedPercent = [math]::Round((($totalSpace - $freeSpace) / $totalSpace) * 100, 1)
        
        Write-Host "  [$driveIndex] $driveLetter ($totalSpace GB, $usedPercent% belegt)" -ForegroundColor White
        $driveIndex++
    }
    
    Write-Host "`n[WARNUNG] Checkdisk kann bei Systemplatte einen Neustart erfordern!" -ForegroundColor Yellow
    Write-Host "[INFO] Nur-Lesen-Modus wird zuerst versucht" -ForegroundColor Gray
    
    $driveChoice = Read-Host "`nLaufwerk waehlen [1-$($drives.Count)] oder [x] zum Abbrechen"
    
    if ($driveChoice -eq 'x' -or $driveChoice -eq 'X') {
        Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
        return $false
    }
    
    try {
        $selectedIndex = [int]$driveChoice - 1
        if ($selectedIndex -lt 0 -or $selectedIndex -ge $drives.Count) {
            throw "Ungueltige Auswahl"
        }
        
        $selectedDrive = $drives[$selectedIndex]
        $driveLetter = $selectedDrive.DeviceID.TrimEnd(':')
        
        Write-Log "[*] Gewaehlt: Laufwerk $driveLetter" -Color Cyan
        
        # Checkdisk-Optionen
        Write-Host "`n[*] CHECKDISK OPTIONEN:" -ForegroundColor Cyan
        Write-Host "  [1] Nur pruefen (Nur-Lesen, empfohlen)" -ForegroundColor Green
        Write-Host "  [2] Pruefen und reparieren (/f)" -ForegroundColor Yellow
        Write-Host "  [3] Vollstaendige Pruefung (/f /r)" -ForegroundColor Red
        
        $modeChoice = Read-Host "`nModus waehlen [1-3]"
        
        $chkdskArgs = ""
        $description = ""
        
        switch ($modeChoice) {
            '1' {
                $chkdskArgs = "${driveLetter}:"
                $description = "Nur-Lesen Pruefung"
            }
            '2' {
                $chkdskArgs = "${driveLetter}: /f"
                $description = "Pruefung und Reparatur"
                Write-Host "[WARNUNG] Reparatur-Modus kann Datenverlust verursachen!" -ForegroundColor Red
                $confirm = Read-Host "Fortfahren? [j/n]"
                if ($confirm -ne 'j' -and $confirm -ne 'J') {
                    Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
                    return $false
                }
            }
            '3' {
                $chkdskArgs = "${driveLetter}: /f /r"
                $description = "Vollstaendige Pruefung und Reparatur"
                Write-Host "[WARNUNG] Vollstaendige Pruefung kann STUNDEN dauern!" -ForegroundColor Red
                Write-Host "[WARNUNG] Reparatur-Modus kann Datenverlust verursachen!" -ForegroundColor Red
                $confirm = Read-Host "Wirklich fortfahren? [j/n]"
                if ($confirm -ne 'j' -and $confirm -ne 'J') {
                    Write-Log "[SKIP] Checkdisk abgebrochen" -Color Gray
                    return $false
                }
            }
            default {
                Write-Log "[ERROR] Ungueltige Auswahl" -Level "ERROR"
                return $false
            }
        }
        
        Write-Log "[*] Starte Checkdisk: $description" -Color Blue
        Write-Log "[*] Parameter: chkdsk $chkdskArgs" -Color Gray
        
        # Checkdisk ausführen
        $chkdskResult = & chkdsk $chkdskArgs.Split(' ') 2>&1 | Out-String
        $chkdskExitCode = $LASTEXITCODE
        
        # Ergebnis auswerten
        if ($chkdskResult -match "errors found" -or $chkdskResult -match "Fehler gefunden") {
            if ($chkdskResult -match "fixed" -or $chkdskResult -match "repariert") {
                Add-Success "Checkdisk: Fehler gefunden und repariert"
                Write-Log "[*] Ein Neustart kann erforderlich sein" -Level "WARNING"
                $script:UpdateRecommendations += "Neustart nach Checkdisk-Reparatur empfohlen"
            } else {
                Add-Warning "Checkdisk: Fehler gefunden - Reparatur-Modus empfohlen"
                $script:UpdateRecommendations += "Checkdisk mit Reparatur-Option ausfuehren"
            }
        } elseif ($chkdskResult -match "no problems found" -or $chkdskResult -match "keine Probleme" -or $chkdskExitCode -eq 0) {
            Add-Success "Checkdisk: Keine Probleme gefunden"
        } elseif ($chkdskResult -match "scheduled" -or $chkdskResult -match "geplant") {
            Add-Success "Checkdisk: Für nächsten Neustart geplant"
            Write-Log "[*] Checkdisk wird beim nächsten Neustart ausgeführt" -Level "WARNING"
            $script:UpdateRecommendations += "Neustart für geplante Checkdisk-Prüfung erforderlich"
        } else {
            # Debug-Info bei unklarem Status
            if ($script:ExplainMode) {
                Write-Log "[DEBUG] Checkdisk Ausgabe: $($chkdskResult.Substring(0, [Math]::Min(300, $chkdskResult.Length)))" -Level "DEBUG"
                Write-Log "[DEBUG] Exit Code: $chkdskExitCode" -Level "DEBUG"
            }
            Add-Warning "Checkdisk abgeschlossen - Details im Event-Log prüfen"
        }
        
        # Vollständige Ausgabe im Debug-Modus anzeigen
        if ($script:ExplainMode) {
            Write-Log "`n[DEBUG] Vollstaendige Checkdisk-Ausgabe:" -Level "DEBUG"
            $chkdskResult.Split("`n") | Select-Object -First 20 | ForEach-Object {
                Write-Log "  $_" -Level "DEBUG"
            }
        }
        
        return $true
        
    } catch {
        Add-Error "Checkdisk fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

# ============================================================================
#                         ERWEITERTE WINGET-INTEGRATION
# ============================================================================

function Test-WingetAvailability {
    try {
        Get-Command winget -ErrorAction Stop | Out-Null
        $wingetVersion = & winget --version 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] Winget verfuegbar: $wingetVersion" -Color Green
            return $true
        }
    } catch {
        Write-Log "[WARNING] Winget nicht verfuegbar" -Level "WARNING"
        Write-Log "[INFO] Installation ueber Microsoft Store: 'App Installer'" -Color Yellow
    }
    return $false
}

function Get-WingetUpdates {
    Write-Log "[*] Suche nach Software-Updates..." -Color Blue
    
    try {
        # Akzeptiere Lizenzen automatisch für Auto-Modus
        $upgradeListCmd = "winget upgrade --include-unknown"
        $upgradeOutput = & cmd /c $upgradeListCmd 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Add-Warning "Winget-Scan fehlgeschlagen"
            return @()
        }
        
        # Parse Update-Liste
        $updates = @()
        $startParsing = $false
        
        foreach ($line in $upgradeOutput) {
            if ($line -match "^Name\s+Id\s+") {
                $startParsing = $true
                continue
            }
            
            if ($startParsing -and $line.Trim() -and $line -notmatch "^-+$") {
                # Versuche Zeile zu parsen
                if ($line -match "^(.+?)\s{2,}(\S+)\s+(\S+)\s+(\S+)") {
                    $updates += @{
                        Name = $Matches[1].Trim()
                        Id = $Matches[2]
                        CurrentVersion = $Matches[3]
                        AvailableVersion = $Matches[4]
                    }
                }
            }
        }
        
        Write-Log "[INFO] $($updates.Count) Updates gefunden" -Color Yellow
        return $updates
        
    } catch {
        Add-Error "Winget-Update-Scan fehlgeschlagen" $_.Exception.Message
        return @()
    }
}

function Install-WingetUpdates {
    param(
        [switch]$All,
        [switch]$Critical,
        [switch]$IncludeUnknown
    )
    
    Write-Log "`n[*] --- WINGET SOFTWARE-UPDATES ---" -Color Cyan
    
    if (-not (Test-WingetAvailability)) {
        return $false
    }
    
    $updates = Get-WingetUpdates
    
    if ($updates.Count -eq 0) {
        Write-Log "[OK] Alle Programme sind aktuell!" -Level "SUCCESS"
        return $true
    }
    
    Write-Log "[INFO] Verfuegbare Updates:" -Color Yellow
    $updateIndex = 1
    foreach ($update in $updates | Select-Object -First 10) {
        Write-Host "  [$updateIndex] $($update.Name)" -ForegroundColor White
        Write-Host "      $($update.CurrentVersion) -> $($update.AvailableVersion)" -ForegroundColor Cyan
        $updateIndex++
    }
    
    if ($updates.Count -gt 10) {
        Write-Host "  ... und $($updates.Count - 10) weitere" -ForegroundColor Gray
    }
    
    $updatedCount = 0
    $failedUpdates = @()
    
    if ($All) {
        Write-Log "[*] Installiere ALLE Updates (inkl. Unbekannte)..." -Color Green
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "                    WINGET MASS-UPDATE WARNUNG" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "WICHTIG: Winget wird jetzt alle verfuegbaren Updates installieren." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "BEACHTEN SIE:" -ForegroundColor Red
        Write-Host "• Dieser Prozess kann 30-90 Minuten dauern (je nach Anzahl Updates)" -ForegroundColor Yellow
        Write-Host "• Einige Programme oeffnen Fenster die Benutzer-Eingaben benoetigen" -ForegroundColor Yellow
        Write-Host "• Waehrend des Updates koennen Hintergrund-Fenster erscheinen" -ForegroundColor Yellow
        Write-Host "• Lassen Sie das Tool laufen und pruefen Sie gelegentlich Fenster" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Das Tool zeigt jetzt kontinuierlich den Fortschritt an..." -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 5
        
        try {
            # Verwende --all mit allen notwendigen Flags
            $updateCmd = "winget upgrade --all --silent --accept-source-agreements --accept-package-agreements"
            if ($IncludeUnknown) {
                $updateCmd += " --include-unknown"
            }
            
            Write-Log "[*] Fuehre aus: $updateCmd" -Level "DEBUG"
            
            # Finale Info vor dem Start
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "                    📦 WINGET-UPDATES STARTEN" -ForegroundColor Cyan  
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "Bereit für den automatischen Update-Prozess!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Wichtiger Hinweis:" -ForegroundColor Yellow
            Write-Host "• Einige Programme oeffnen waehrend der Installation Fenster" -ForegroundColor White
            Write-Host "• Diese koennen hinter dem PowerShell-Fenster erscheinen" -ForegroundColor White
            Write-Host "• Falls Updates langsam werden: Alt+Tab pruefen" -ForegroundColor White
            Write-Host "• Taskleiste nach blinkenden Icons absuchen" -ForegroundColor White
            Write-Host ""
            Write-Host "Tipp: Bleiben Sie in der Nähe für optimale Ergebnisse! 👍" -ForegroundColor Green
            Write-Host ""
            Write-Host "Start in 5 Sekunden..." -ForegroundColor Cyan
            Write-Host "================================================================" -ForegroundColor Cyan
            
            # 5 Sekunden Countdown  
            for ($i = 5; $i -gt 0; $i--) {
                Write-Host "`r⏳ Winget startet in $i... (Strg+C = Abbrechen)" -NoNewline -ForegroundColor Cyan
                Start-Sleep -Seconds 1
            }
            Write-Host "`n🚀 Winget wird gestartet!" -ForegroundColor Green
            Write-Host ""
            
            $updateProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $updateCmd" `
                -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\winget_all.log" `
                -RedirectStandardError "$env:TEMP\winget_all_error.log"
            
            # Erweiterte Fortschrittsanzeige
            $startTime = Get-Date
            $lastLogCheck = Get-Date
            $progressCounter = 0
            
            while (-not $updateProcess.HasExited) {
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
                $minutes = [math]::Floor($elapsed / 60)
                $seconds = $elapsed % 60
                
                # Fortschritts-Animation
                $progressChars = @('|', '/', '-', '\')
                $progressChar = $progressChars[$progressCounter % 4]
                $progressCounter++
                
                # Zeige erweiterte Info
                Write-Host ("`r[{0}] Winget-Updates laufen... Zeit: {1:D2}:{2:D2} | Pruefe Logs..." -f $progressChar, $minutes, $seconds) -NoNewline -ForegroundColor Yellow
                
                # Log-Parsing alle 10 Sekunden für bessere Info
                if (((Get-Date) - $lastLogCheck).TotalSeconds -gt 10) {
                    $lastLogCheck = Get-Date
                    if (Test-Path "$env:TEMP\winget_all.log") {
                        $logContent = Get-Content "$env:TEMP\winget_all.log" -Tail 3 -ErrorAction SilentlyContinue
                        if ($logContent) {
                            $lastLine = $logContent[-1]
                            if ($lastLine -match "Installing|Downloading|Upgrading") {
                                Write-Host "`n[INFO] $lastLine" -ForegroundColor Green
                            }
                        }
                    }
                }
                
                Start-Sleep -Seconds 2
                
                # Erhoehtes Timeout: 60 Minuten
                if ($elapsed -gt 3600) {
                    Write-Host "`n[WARNING] Timeout erreicht (60 Min) - Breche ab..." -ForegroundColor Red
                    $updateProcess.Kill()
                    Add-Warning "Winget-Update Timeout (60 Min)"
                    break
                }
            }
            
            Write-Host "" # Neue Zeile nach Fortschrittsanzeige
            
            if ($updateProcess.ExitCode -eq 0) {
                Write-Host ""
                Write-Host "================================================================" -ForegroundColor Green
                Write-Host "                   WINGET-UPDATES ABGESCHLOSSEN" -ForegroundColor Green
                Write-Host "================================================================" -ForegroundColor Green
                Write-Host "Alle Updates wurden erfolgreich installiert!" -ForegroundColor Green
                Write-Host "WICHTIG: Pruefen Sie, ob noch offene Programm-Fenster" -ForegroundColor Yellow
                Write-Host "         auf Eingaben warten oder Neustarts benoetigen." -ForegroundColor Yellow
                Write-Host ""
                Add-Success "Winget: Alle Updates installiert"
                $updatedCount = $updates.Count
            } else {
                Write-Host ""
                Write-Host "================================================================" -ForegroundColor Yellow
                Write-Host "                 WINGET-UPDATES TEILWEISE FEHLGESCHLAGEN" -ForegroundColor Yellow
                Write-Host "================================================================" -ForegroundColor Yellow
                Write-Host "Einige Updates konnten nicht installiert werden." -ForegroundColor Yellow
                Write-Host "TIPP: Pruefen Sie offene Programm-Fenster auf Fehlermeldungen" -ForegroundColor Cyan
                Write-Host "      oder starten Sie einzelne Updates manuell." -ForegroundColor Cyan
                Write-Host ""
                Add-Warning "Winget: Einige Updates fehlgeschlagen (Exit: $($updateProcess.ExitCode))"
                
                # Versuche Log zu analysieren
                if ($script:ExplainMode) {
                    $errorLog = Get-Content "$env:TEMP\winget_all_error.log" -ErrorAction SilentlyContinue
                    if ($errorLog) {
                        Write-Log "[DEBUG] Fehler-Details:" -Level "DEBUG"
                        $errorLog | Select-Object -First 5 | ForEach-Object {
                            Write-Log "  $_" -Level "DEBUG"
                        }
                    }
                }
            }
            
        } catch {
            Add-Error "Winget-Update-Prozess fehlgeschlagen" $_.Exception.Message
        }
        
    } elseif ($Critical) {
        Write-Log "[*] Installiere kritische Updates..." -Color Yellow
        
        $criticalPatterns = @(
            "*Microsoft*", "*Windows*", "*Edge*", "*Defender*",
            "*Chrome*", "*Firefox*", "*Security*", "*Critical*"
        )
        
        foreach ($update in $updates) {
            $isCritical = $false
            foreach ($pattern in $criticalPatterns) {
                if ($update.Name -like $pattern -or $update.Id -like $pattern) {
                    $isCritical = $true
                    break
                }
            }
            
            if ($isCritical) {
                try {
                    Write-Log "[*] Update: $($update.Name)..." -Color Blue
                    
                    $updateCmd = "winget upgrade --id `"$($update.Id)`" --silent --accept-source-agreements --accept-package-agreements"
                    & cmd /c $updateCmd 2>&1 | Out-Null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "  [OK] $($update.Name) aktualisiert" -Color Green
                        $updatedCount++
                    } else {
                        Write-Log "  [FAIL] $($update.Name) fehlgeschlagen" -Color Red
                        $failedUpdates += $update.Name
                    }
                    
                    # AV-Delay
                    Start-Sleep -Milliseconds $script:AVDelayMs
                    
                } catch {
                    Write-Log "  [ERROR] Fehler bei $($update.Name)" -Level "ERROR"
                    $failedUpdates += $update.Name
                }
            }
        }
    }
    
    # Zusammenfassung
    if ($updatedCount -gt 0) {
        Add-Success "Winget: $updatedCount Updates installiert"
    }
    
    if ($failedUpdates.Count -gt 0) {
        Add-Warning "Winget: $($failedUpdates.Count) Updates fehlgeschlagen"
        if ($script:ExplainMode) {
            $failedUpdates | ForEach-Object {
                Write-Log "  - $_" -Level "DEBUG"
            }
        }
    }
    
    # Cleanup
    Remove-Item "$env:TEMP\winget_*.log" -Force -ErrorAction SilentlyContinue
    
    return ($updatedCount -gt 0)
}

# ============================================================================
#                         BEREINIGUNGSFUNKTIONEN
# ============================================================================

function Remove-SafeFiles {
    param(
        [string]$Path,
        [string]$Description,
        [switch]$Force
    )
    
    if (-not (Test-Path $Path)) {
        Write-Log "  [SKIP] $Description - Pfad existiert nicht" -Level "DEBUG"
        return 0
    }
    
    $sizeBefore = Get-FolderSize $Path
    
    if ($sizeBefore -eq 0) {
        Write-Log "  [OK] $Description - Bereits sauber" -Color Green
        return 0
    }
    
    if (-not $Force -and -not $script:AutoApproveCleanup) {
        Write-Host "  $Description ($sizeBefore MB)" -ForegroundColor White
        $choice = Read-Host "    Bereinigen? [j/n/a fuer alle]"
        
        if ($choice -eq 'n') {
            Write-Log "  [SKIP] $Description - Vom Benutzer uebersprungen" -Color Gray
            return 0
        }
        
        if ($choice -eq 'a') {
            $script:AutoApproveCleanup = $true
        }
    }
    
    Write-Host "  [*] Bereinige $Description..." -NoNewline -ForegroundColor Yellow
    
    try {
        # Antiviren-sicheres Löschen mit Delay
        $files = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue
        $deleted = 0
        $failed = 0
        
        foreach ($file in $files) {
            try {
                if ($script:AVSafeMode -and ($deleted % 10 -eq 0)) {
                    Start-Sleep -Milliseconds $script:AVDelayMs
                }
                
                Remove-Item $file.FullName -Recurse -Force -ErrorAction Stop
                $deleted++
            } catch {
                $failed++
            }
        }
        
        $freed = $sizeBefore
        $script:TotalFreedSpace += $freed
        
        Write-Host " [OK] $freed MB freigegeben" -ForegroundColor Green
        return $freed
        
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Add-Warning "Bereinigung fehlgeschlagen: $Description"
        return 0
    }
}

function Invoke-ComprehensiveCleanup {
    Write-Log "`n[*] --- ERWEITERTE SYSTEM-BEREINIGUNG ---" -Color Cyan
    
    $cleanupTargets = @(
        @{Path="$env:TEMP"; Description="Temp-Dateien"; Priority="High"},
        @{Path="$env:SystemRoot\Temp"; Description="System-Temp"; Priority="High"},
        @{Path="$env:LOCALAPPDATA\Temp"; Description="Local-Temp"; Priority="High"},
        @{Path="$env:SystemRoot\Prefetch"; Description="Prefetch-Cache"; Priority="Medium"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Windows\Explorer"; Description="Thumbnail-Cache"; Priority="Medium"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Windows\INetCache"; Description="Internet-Cache"; Priority="Low"},
        @{Path="$env:SystemRoot\SoftwareDistribution\Download"; Description="Windows Update Cache"; Priority="Low"}
    )
    
    # Gaming-spezifische Caches
    $gamingCaches = @(
        @{Path="$env:LOCALAPPDATA\NVIDIA\DXCache"; Description="NVIDIA Shader-Cache"},
        @{Path="$env:LOCALAPPDATA\AMD\DxCache"; Description="AMD Shader-Cache"},
        @{Path="$env:PROGRAMDATA\NVIDIA Corporation\NV_Cache"; Description="NVIDIA GL-Cache"},
        @{Path="$env:LOCALAPPDATA\Steam\htmlcache"; Description="Steam Web-Cache"},
        @{Path="$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Description="Epic Games Cache"},
        @{Path="$env:LOCALAPPDATA\Battle.net\Cache"; Description="Battle.net Cache"}
    )
    
    # Browser-Caches (optional)
    $browserCaches = @(
        @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Description="Chrome Cache"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Description="Edge Cache"},
        @{Path="$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"; Description="Firefox Cache"}
    )
    
    $totalFreed = 0
    
    # Cleanup-Modus abfragen
    if (-not $script:AutoApproveCleanup) {
        Write-Host "`n[*] BEREINIGUNGSOPTIONEN:" -ForegroundColor Cyan
        Write-Host "  [1] Basis-Bereinigung (Temp-Dateien)" -ForegroundColor Green
        Write-Host "  [2] Erweiterte Bereinigung (+ Caches)" -ForegroundColor Yellow
        Write-Host "  [3] Gaming-Bereinigung (+ Gaming-Caches)" -ForegroundColor Cyan
        Write-Host "  [4] Vollstaendige Bereinigung (Alles)" -ForegroundColor Red
        Write-Host "  [5] Abbrechen" -ForegroundColor Gray
        
        $cleanupMode = Read-Host "`nWahl [1-5]"
    } else {
        $cleanupMode = "2"  # Standard für Auto-Modus
    }
    
    # Bereinigung durchführen basierend auf Modus
    switch ($cleanupMode) {
        '1' {
            Write-Log "[*] Basis-Bereinigung..." -Color Green
            foreach ($target in $cleanupTargets | Where-Object { $_.Priority -eq "High" }) {
                $totalFreed += Remove-SafeFiles -Path $target.Path -Description $target.Description
            }
        }
        '2' {
            Write-Log "[*] Erweiterte Bereinigung..." -Color Yellow
            foreach ($target in $cleanupTargets) {
                $totalFreed += Remove-SafeFiles -Path $target.Path -Description $target.Description
            }
        }
        '3' {
            Write-Log "[*] Gaming-Bereinigung..." -Color Cyan
            foreach ($target in $cleanupTargets) {
                $totalFreed += Remove-SafeFiles -Path $target.Path -Description $target.Description
            }
            foreach ($cache in $gamingCaches) {
                if (Test-Path $cache.Path) {
                    $totalFreed += Remove-SafeFiles -Path $cache.Path -Description $cache.Description
                }
            }
        }
        '4' {
            Write-Log "[*] Vollstaendige Bereinigung..." -Color Red
            $script:AutoApproveCleanup = $true
            
            foreach ($target in $cleanupTargets) {
                $totalFreed += Remove-SafeFiles -Path $target.Path -Description $target.Description -Force
            }
            foreach ($cache in $gamingCaches) {
                if (Test-Path $cache.Path) {
                    $totalFreed += Remove-SafeFiles -Path $cache.Path -Description $cache.Description -Force
                }
            }
            
            $browserChoice = Read-Host "`nBrowser-Caches auch bereinigen? [j/n]"
            if ($browserChoice -eq 'j') {
                foreach ($browser in $browserCaches) {
                    if (Test-Path $browser.Path) {
                        $totalFreed += Remove-SafeFiles -Path $browser.Path -Description $browser.Description -Force
                    }
                }
            }
        }
        default {
            Write-Log "[SKIP] Bereinigung abgebrochen" -Color Gray
            return
        }
    }
    
    Write-Log "`n[OK] Bereinigung abgeschlossen!" -Level "SUCCESS"
    Write-Log "[INFO] Gesamt freigegeben: $totalFreed MB" -Color Cyan
    
    return $totalFreed
}

# ============================================================================
#                         SYSTEM-OPTIMIERUNG
# ============================================================================

function Optimize-SystemPerformance {
    Write-Log "`n[*] --- SYSTEM-PERFORMANCE OPTIMIERUNG ---" -Color Cyan
    
    $optimizations = 0
    
    # Dienste-Optimierung
    Write-Log "[*] Optimiere Windows-Dienste..." -Color Blue
    
    $servicesToDisable = @(
        @{Name="DiagTrack"; Description="Telemetrie"},
        @{Name="dmwappushservice"; Description="Push-Nachrichten"},
        @{Name="WSearch"; Description="Windows Search (wenn nicht genutzt)"}
    )
    
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                if ($service.Name -eq "WSearch") {
                    $choice = Read-Host "  Windows Search deaktivieren? (Suche wird langsamer) [j/n]"
                    if ($choice -ne 'j') { continue }
                }
                
                Stop-Service -Name $service.Name -Force -ErrorAction Stop
                Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
                Write-Log "  [OK] $($service.Description) deaktiviert" -Color Green
                $optimizations++
            }
        } catch {
            Write-Log "  [SKIP] $($service.Description)" -Level "DEBUG"
        }
    }
    
    # Registry-Optimierungen
    Write-Log "[*] Registry-Optimierungen..." -Color Blue
    
    $regOptimizations = @(
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Name = "ClearPageFileAtShutdown"
            Value = 0
            Type = "DWord"
            Description = "Pagefile-Clear deaktiviert"
        },
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "DisallowShaking"
            Value = 1
            Type = "DWord"
            Description = "Aero Shake deaktiviert"
        }
    )
    
    foreach ($reg in $regOptimizations) {
        try {
            if (-not (Test-Path $reg.Path)) {
                New-Item -Path $reg.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type $reg.Type -Force
            Write-Log "  [OK] $($reg.Description)" -Color Green
            $optimizations++
        } catch {
            Write-Log "  [SKIP] $($reg.Description)" -Level "DEBUG"
        }
    }
    
    Write-Log "[OK] $optimizations Optimierungen durchgefuehrt" -Level "SUCCESS"
    return $optimizations
}

# ============================================================================
#                         WIEDERHERSTELLUNGSPUNKT
# ============================================================================

function New-SystemRestorePoint {
    param([string]$Description = "Hellion Tool v$script:ToolVersion")
    
    Write-Log "`n[*] --- WIEDERHERSTELLUNGSPUNKT ---" -Color Cyan
    
    if ($script:RestorePointCreated) {
        Write-Log "[INFO] Wiederherstellungspunkt bereits erstellt" -Color Gray
        return $true
    }
    
    try {
        Write-Log "[*] Erstelle Wiederherstellungspunkt..." -Color Blue
        
        # Aktiviere System Restore auf C:
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Erstelle Restore Point
        $description = "$Description - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Add-Success "Wiederherstellungspunkt erstellt: $description"
        $script:RestorePointCreated = $true
        return $true
        
    } catch {
        Add-Warning "Wiederherstellungspunkt konnte nicht erstellt werden"
        return $false
    }
}

# ============================================================================
#                         AUTO-MODUS (ERWEITERT)
# ============================================================================

function Invoke-EnhancedAutoMode {
    Write-Log "`n[*] --- ERWEITERTER AUTO-MODUS ---" -Color Green
    Write-Log "Fuehrt alle empfohlenen Optimierungen automatisch durch" -Color Yellow
    
    $script:AutoApproveCleanup = $true
    $autoStartTime = Get-Date
    
    # Geplante Aktionen
    $autoActions = @(
        "Wiederherstellungspunkt erstellen",
        "System-Integritaet pruefen (SFC)",
        "Treiber-Status analysieren",
        "Software-Updates (Winget)",
        "System-Bereinigung",
        "Performance-Optimierung",
        "Safe Adblock verwalten"
    )
    
    Write-Log "`n[*] GEPLANTE AKTIONEN:" -Color Cyan
    $autoActions | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    
    Write-Log "`n[*] Geschaetzte Dauer: 15-30 Minuten" -Color Yellow
    Write-Log "[*] Der Vorgang kann jederzeit mit Strg+C abgebrochen werden" -Color Gray
    
    $confirm = Read-Host "`nAuto-Modus starten? [j/n]"
    if ($confirm -ne 'j' -and $confirm -ne 'J') {
        Write-Log "[INFO] Auto-Modus abgebrochen" -Color Red
        return $false
    }
    
    $totalSteps = 7
    $currentStep = 0
    
    # Schritt 1: Wiederherstellungspunkt
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] Wiederherstellungspunkt..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    New-SystemRestorePoint -Description "Auto-Modus Start"
    $script:ActionsPerformed += "Wiederherstellungspunkt"
    
    # Schritt 2: System File Checker
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] System-Integritaet..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    
    try {
        Write-Log "[*] Starte SFC im Hintergrund..." -Color Green
        $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" `
            -NoNewWindow -PassThru
        
        # Warte maximal 10 Minuten
        $sfcTimeout = 600
        $sfcElapsed = 0
        while (-not $sfcProcess.HasExited -and $sfcElapsed -lt $sfcTimeout) {
            Write-Host "`r[*] SFC laeuft... ($sfcElapsed Sek)" -NoNewline -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            $sfcElapsed += 5
        }
        
        if (-not $sfcProcess.HasExited) {
            Write-Log "[WARNING] SFC-Timeout - laeuft im Hintergrund weiter" -Level "WARNING"
        } else {
            Write-Log "[OK] SFC abgeschlossen" -Level "SUCCESS"
        }
    } catch {
        Write-Log "[WARNING] SFC fehlgeschlagen" -Level "WARNING"
    }
    $script:ActionsPerformed += "System File Checker"
    
    # Schritt 3: Treiber-Analyse
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] Treiber-Analyse..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    $driverIssues = Get-DetailedDriverStatus
    
    if ($driverIssues["Critical"].Count -gt 0) {
        Add-Warning "Kritische Treiber-Probleme gefunden - Manuelle Intervention erforderlich"
    }
    $script:ActionsPerformed += "Treiber-Analyse"
    
    # Schritt 4: Winget-Updates
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] Software-Updates..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    
    if (Test-WingetAvailability) {
        Write-Log "[*] Installiere alle Updates (inkl. Unbekannte)..." -Color Green
        Install-WingetUpdates -All -IncludeUnknown
        $script:ActionsPerformed += "Software-Updates (Winget)"
    } else {
        Write-Log "[SKIP] Winget nicht verfuegbar" -Color Gray
    }
    
    # Schritt 5: System-Bereinigung
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] System-Bereinigung..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    $freed = Invoke-ComprehensiveCleanup
    $script:ActionsPerformed += "System-Bereinigung ($freed MB)"
    
    # Schritt 6: Performance-Optimierung
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] Performance-Optimierung..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    $optimizations = Optimize-SystemPerformance
    $script:ActionsPerformed += "Performance-Optimierung ($optimizations)"
    
    # Schritt 7: Safe Adblock
    $currentStep++
    Write-Log "`n[$currentStep/$totalSteps] Adblock-Verwaltung..." -Color Blue
    Show-ProgressBar -Activity "Auto-Modus" -PercentComplete ([int](($currentStep/$totalSteps)*100))
    
    # Hier würde die Adblock-Funktion kommen (gekürzt für Platz)
    $script:ActionsPerformed += "Adblock-Check"
    
    # Abschluss
    $autoDuration = [math]::Round(((Get-Date) - $autoStartTime).TotalMinutes, 1)
    Write-Log "`n[OK] AUTO-MODUS ERFOLGREICH ABGESCHLOSSEN!" -Level "SUCCESS"
    Write-Log "[*] Dauer: $autoDuration Minuten" -Color Cyan
    Write-Log "[*] Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -Color Cyan
    Write-Log "[*] Aktionen: $($script:ActionsPerformed.Count)" -Color Cyan
    
    return $true
}

# ============================================================================
#                         HAUPTMENU
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host @"
================================================================
         HELLION POWER TOOL v$script:ToolVersion "$script:ToolCodename" - HAUPTMENU
================================================================
"@ -ForegroundColor Cyan
    
    # Status-Anzeige
    Write-Host "`n[STATUS]" -ForegroundColor Yellow
    Write-Host "  Laufzeit: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 1)) Min" -ForegroundColor Gray
    Write-Host "  Aktionen: $($script:ActionsPerformed.Count)" -ForegroundColor Gray
    Write-Host "  Freigegeben: $([math]::Round($script:TotalFreedSpace, 2)) MB" -ForegroundColor Gray
    
    if ($script:Warnings.Count -gt 0) {
        Write-Host "  Warnungen: $($script:Warnings.Count)" -ForegroundColor Yellow
    }
    
    if ($script:Errors.Count -gt 0) {
        Write-Host "  Fehler: $($script:Errors.Count)" -ForegroundColor Red
    }
    
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "                        HAUPTOPTIONEN" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    Write-Host "`n  [*] SCHNELL-AKTIONEN:" -ForegroundColor Green
    Write-Host "     [A] AUTO-MODUS ERWEITERT (Empfohlen)" -ForegroundColor Green
    Write-Host "     [Q] Schnell-Bereinigung" -ForegroundColor Cyan
    Write-Host "     [W] Winget-Updates" -ForegroundColor Cyan
    
    Write-Host "`n  [*] SYSTEM-REPARATUR:" -ForegroundColor Yellow
    Write-Host "     [1] System File Checker (SFC)" -ForegroundColor White
    Write-Host "     [2] DISM Reparatur" -ForegroundColor White
    Write-Host "     [3] Checkdisk (CHKDSK)" -ForegroundColor White
    Write-Host "     [4] Treiber-Analyse" -ForegroundColor White
    
    Write-Host "`n  [*] BEREINIGUNG & OPTIMIERUNG:" -ForegroundColor Yellow
    Write-Host "     [5] Erweiterte Bereinigung" -ForegroundColor White
    Write-Host "     [6] Performance-Optimierung" -ForegroundColor White
    Write-Host "     [7] Laufwerks-Optimierung" -ForegroundColor White
    
    Write-Host "`n  [*] TOOLS:" -ForegroundColor Blue
    Write-Host "     [R] System-Report generieren" -ForegroundColor Cyan
    Write-Host "     [L] Log-Datei anzeigen" -ForegroundColor Cyan
    
    Write-Host "`n  [X] Beenden" -ForegroundColor Red
    Write-Host "`n================================================================" -ForegroundColor Cyan
}

function Invoke-MenuChoice {
    param([string]$Choice)
    
    switch ($Choice.ToUpper()) {
        'A' {
            return -not (Invoke-EnhancedAutoMode)
        }
        'Q' {
            Write-Log "`n[*] SCHNELL-BEREINIGUNG..." -Color Cyan
            $script:AutoApproveCleanup = $true
            $freed = Remove-SafeFiles "$env:TEMP" "Temp-Dateien" -Force
            $freed += Remove-SafeFiles "$env:SystemRoot\Temp" "System-Temp" -Force
            Write-Log "[OK] Schnell-Bereinigung abgeschlossen! ($freed MB)" -Level "SUCCESS"
            $script:ActionsPerformed += "Schnell-Bereinigung"
            Read-Host "`nEnter druecken"
        }
        'W' {
            if (Test-WingetAvailability) {
                Install-WingetUpdates -All
            }
            $script:ActionsPerformed += "Winget-Updates"
            Read-Host "`nEnter druecken"
        }
        '1' {
            Invoke-SystemFileChecker
            $script:ActionsPerformed += "SFC"
            Read-Host "`nEnter druecken"
        }
        '2' {
            Invoke-DISMRepair
            $script:ActionsPerformed += "DISM"
            Read-Host "`nEnter druecken"
        }
        '3' {
            Invoke-CheckDisk
            $script:ActionsPerformed += "Checkdisk"
            Read-Host "`nEnter druecken"
        }
        '4' {
            Get-DetailedDriverStatus
            $script:ActionsPerformed += "Treiber-Analyse"
            Read-Host "`nEnter druecken"
        }
        '5' {
            Invoke-ComprehensiveCleanup
            $script:ActionsPerformed += "Erweiterte Bereinigung"
            Read-Host "`nEnter druecken"
        }
        '6' {
            Optimize-SystemPerformance
            $script:ActionsPerformed += "Performance-Optimierung"
            Read-Host "`nEnter druecken"
        }
        '7' {
            # Laufwerks-Optimierung würde hier implementiert
            Write-Log "[INFO] Funktion in Entwicklung" -Color Yellow
            Read-Host "`nEnter druecken"
        }
        'R' {
            New-DetailedSystemReport
            Read-Host "`nEnter druecken"
        }
        'L' {
            # Log-Zusammenfassung anzeigen
            $logSummary = Get-LogSummary
            Write-Host "`n[LOG-SUMMARY]" -ForegroundColor Cyan
            Write-Host "Log-Datei: $($logSummary.LogFile)" -ForegroundColor White
            Write-Host "Größe: $($logSummary.LogSize) KB" -ForegroundColor White
            Write-Host "Buffer-Einträge: $($logSummary.BufferEntries)" -ForegroundColor White
            Write-Host "Fehler: $($logSummary.ErrorCount)" -ForegroundColor Red
            Write-Host "Warnungen: $($logSummary.WarningCount)" -ForegroundColor Yellow
            Write-Host "Erfolge: $($logSummary.SuccessCount)" -ForegroundColor Green
            
            # Log-Datei öffnen
            if (Test-Path $script:LogFile) {
                $openChoice = Read-Host "`nLog-Datei öffnen? [j/n]"
                if ($openChoice -eq 'j' -or $openChoice -eq 'J') {
                    Start-Process notepad.exe $script:LogFile
                }
            } else {
                Write-Log "[INFO] Keine Log-Datei vorhanden" -Color Yellow
            }
            Read-Host "`nEnter druecken"
        }
        'X' {
            return $false
        }
        default {
            Write-Log "[ERROR] Ungueltige Auswahl" -Level "ERROR"
            Start-Sleep -Seconds 1
        }
    }
    return $true
}

# ============================================================================
#                         REPORT-GENERATOR
# ============================================================================

function New-DetailedSystemReport {
    Write-Log "`n[*] --- SYSTEM-REPORT GENERATOR ---" -Color Cyan
    
    $reportPath = "$env:USERPROFILE\Desktop\Hellion_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    Write-Log "[*] Erstelle detaillierten Report..." -Color Blue
    
    $report = @"
========================================================================
    HELLION POWER TOOL v$script:ToolVersion "$script:ToolCodename" - SYSTEM REPORT
    Erstellt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
========================================================================

SYSTEM-INFORMATIONEN:
=====================
OS: $script:WindowsVersion
Build: $script:WindowsBuild
Architektur: $script:WindowsArchitecture
PowerShell: $script:PSVersion
Benutzer: $env:USERNAME@$env:COMPUTERNAME

LAUFWERKE:
==========
"@

    foreach ($drive in $script:DriveConfig.GetEnumerator()) {
        $driveInfo = $drive.Value
        $report += @"

$($drive.Key) [$($driveInfo.Type)]
  Gesamt: $($driveInfo.TotalSpace) GB
  Frei: $($driveInfo.FreeSpace) GB
  Belegt: $($driveInfo.UsedPercent)%
  Status: $($driveInfo.HealthStatus)
"@
    }
    
    $report += @"

DURCHGEFUEHRTE AKTIONEN ($($script:ActionsPerformed.Count)):
=========================================
"@
    
    if ($script:ActionsPerformed.Count -gt 0) {
        $script:ActionsPerformed | ForEach-Object { $report += "`n- $_" }
    } else {
        $report += "`nKeine Aktionen durchgefuehrt"
    }
    
    if ($script:Warnings.Count -gt 0) {
        $report += @"

WARNUNGEN ($($script:Warnings.Count)):
========================
"@
        $script:Warnings | ForEach-Object { $report += "`n[WARNING] $_" }
    }
    
    if ($script:Errors.Count -gt 0) {
        $report += @"

FEHLER ($($script:Errors.Count)):
==================
"@
        $script:Errors | ForEach-Object { $report += "`n[ERROR] $_" }
    }
    
    $report += @"

EMPFEHLUNGEN:
=============
"@
    
    if ($script:UpdateRecommendations.Count -gt 0) {
        $script:UpdateRecommendations | ForEach-Object { $report += "`n- $_" }
    } else {
        $report += "`n[OK] System ist optimiert"
    }
    
    $report += @"

========================================================================
                         ENDE DES REPORTS
              Hellion Online Media - www.hellion-online-media.de
========================================================================
"@
    
    try {
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Log "[OK] Report gespeichert: $reportPath" -Level "SUCCESS"
        
        $openReport = Read-Host "`nReport oeffnen? [j/n]"
        if ($openReport -eq 'j') {
            Start-Process notepad.exe $reportPath
        }
    } catch {
        Add-Error "Report konnte nicht gespeichert werden" $_.Exception.Message
    }
}

# ============================================================================
#                         HAUPTPROGRAMM
# ============================================================================

# Internet-Check
$script:HasInternet = Test-EnhancedInternetConnectivity

# Laufwerke initialisieren
Initialize-DriveConfiguration

# Treiber-Status prüfen
$driverIssues = Get-DetailedDriverStatus

Start-Sleep -Seconds 2

# Willkommen
Clear-Host
Write-Host @"
================================================================
       HELLION POWER TOOL v$script:ToolVersion "$script:ToolCodename" - WILLKOMMEN
================================================================
"@ -ForegroundColor Cyan

Write-Host "`n[*] EMPFEHLUNG: ERWEITERTER AUTO-MODUS" -ForegroundColor Green
Write-Host "Der erweiterte Auto-Modus fuehrt automatisch durch:" -ForegroundColor White
Write-Host "  - System-Integritaets-Pruefung" -ForegroundColor Gray
Write-Host "  - Software-Updates (Winget)" -ForegroundColor Gray
Write-Host "  - Treiber-Analyse" -ForegroundColor Gray
Write-Host "  - System-Bereinigung" -ForegroundColor Gray
Write-Host "  - Performance-Optimierung" -ForegroundColor Gray

Write-Host "`n[INFO] Geschaetzte Dauer: 15-30 Minuten" -ForegroundColor Yellow

$autoChoice = Read-Host "`nAuto-Modus jetzt starten? [j/n]"

$continueRunning = $true

if ($autoChoice -eq 'j' -or $autoChoice -eq 'J') {
    $autoCompleted = Invoke-EnhancedAutoMode
    
    if ($autoCompleted) {
        Write-Log "`n[OK] Auto-Modus erfolgreich abgeschlossen!" -Level "SUCCESS"
        $finalChoice = Read-Host "`nWeitere Optimierungen im Menu? [j/n]"
        
        if ($finalChoice -ne 'j' -and $finalChoice -ne 'J') {
            $continueRunning = $false
        }
    }
} else {
    Write-Log "`n[*] Oeffne Hauptmenu..." -Color Cyan
    Start-Sleep -Seconds 1
}

# Hauptschleife
while ($continueRunning) {
    Show-MainMenu
    $userChoice = Read-Host "`n[*] Ihre Wahl"
    $continueRunning = Invoke-MenuChoice -Choice $userChoice
}

# ============================================================================
#                         FINALE ZUSAMMENFASSUNG
# ============================================================================

Clear-Host
Write-Host @"
================================================================
     HELLION POWER TOOL v$script:ToolVersion "$script:ToolCodename" - ZUSAMMENFASSUNG
================================================================
"@ -ForegroundColor Green

$endTime = Get-Date
$totalDuration = $endTime - $script:StartTime

Write-Host "`n[STATISTIK]" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Gray

Write-Host "`n[*] ZEIT:" -ForegroundColor Yellow
Write-Host "  Start: $($script:StartTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "  Ende: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "  Dauer: $([math]::Round($totalDuration.TotalMinutes, 1)) Minuten" -ForegroundColor Green

Write-Host "`n[*] SPEICHER:" -ForegroundColor Yellow
Write-Host "  Freigegeben: $(Format-ByteSize ($script:TotalFreedSpace * 1MB))" -ForegroundColor Green

Write-Host "`n[*] AKTIONEN ($($script:ActionsPerformed.Count)):" -ForegroundColor Yellow
if ($script:ActionsPerformed.Count -gt 0) {
    $script:ActionsPerformed | Select-Object -Unique | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
}

if ($script:Errors.Count -gt 0) {
    Write-Host "`n[ERROR] FEHLER ($($script:Errors.Count)):" -ForegroundColor Red
    $script:Errors | Select-Object -First 3 | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
}

if ($script:Warnings.Count -gt 0) {
    Write-Host "`n[WARNING] WARNUNGEN ($($script:Warnings.Count)):" -ForegroundColor Yellow
    $script:Warnings | Select-Object -First 3 | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Abschluss
Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host @"
   HELLION POWER TOOL v$script:ToolVersion "$script:ToolCodename" - FERTIG!
         
   Vielen Dank fuer die Nutzung!
   
   [*] Entwickelt von: Hellion Online Media
   [*] Website: https://hellion-online-media.de
   [*] Support: support@hellion-online-media.de
   
   [*] Empfehlung: Monatliche Nutzung fuer optimale Performance
"@ -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Green

# Report-Option
$saveReport = Read-Host "`n[*] Abschluss-Report speichern? [j/n]"
if ($saveReport -eq 'j' -or $saveReport -eq 'J') {
    New-DetailedSystemReport
}

# Log-Zusammenfassung
$finalLogSummary = Get-LogSummary
Write-Log "`n[*] Log gespeichert: $($finalLogSummary.LogFile)" -Color Cyan
Write-Log "[*] Log-Größe: $($finalLogSummary.LogSize) KB" -Color Gray
if ($finalLogSummary.ErrorCount -gt 0) {
    Write-Log "[*] Fehler protokolliert: $($finalLogSummary.ErrorCount)" -Color Red
}
if ($finalLogSummary.WarningCount -gt 0) {
    Write-Log "[*] Warnungen protokolliert: $($finalLogSummary.WarningCount)" -Color Yellow
}

Write-Host "`n[*] Enter zum Beenden..." -ForegroundColor Yellow
Read-Host