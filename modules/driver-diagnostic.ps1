# ===================================================================
# DRIVER DIAGNOSTIC MODULE
# Hellion Power Tool - Erweiterte Treiber-Diagnose für versteckte Probleme
# ===================================================================

function Start-DriverDiagnostic {
    Write-Log "`n[*] --- ERWEITERTE TREIBER-DIAGNOSE ---" -Color Cyan
    Write-Host ""
    Write-Host "Dieses Modul analysiert versteckte Treiber-Probleme, die im Gerätemanager" -ForegroundColor Yellow
    Write-Host "oft nicht sichtbar sind (wie ene.sys, problematische Kernel-Treiber, etc.)" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        Write-Host "=== ERWEITERTE TREIBER-DIAGNOSE ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "[1] Vollständige Treiber-Analyse (Empfohlen)" -ForegroundColor Green
        Write-Host "[2] Problematische Treiber scannen (ene.sys, etc.)" -ForegroundColor Yellow
        Write-Host "[2b] ENE.SYS Problem-Analyse & Automatische Reparatur" -ForegroundColor Cyan
        Write-Host "[2c] ENE.SYS Treiber Zwangs-Entfernung (Erweitert)" -ForegroundColor Red
        Write-Host "[3] Treiber Event Log Analyse" -ForegroundColor Cyan
        Write-Host "[4] Detaillierte System-Treiber Liste" -ForegroundColor White
        Write-Host "[5] Treiber-Verifikation aktivieren (Erweitert)" -ForegroundColor Magenta
        Write-Host "[6] Installierte Treiber-Pakete anzeigen" -ForegroundColor Blue
        Write-Host "[0] Zurück zum Hauptmenü" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host "Wähle eine Option"
        
        switch ($choice) {
            "1" { Invoke-FullDriverAnalysis }
            "2" { Find-ProblematicDrivers }
            "2b" { Analyze-ENEDriverProblem }
            "2c" { Remove-ENEDriverForce }
            "3" { Analyze-DriverEventLogs }
            "4" { Get-DetailedDriverList }
            "5" { Enable-DriverVerifier }
            "6" { Get-InstalledDriverPackages }
            "0" { return }
            default { 
                Write-Host "Ungültige Auswahl! Bitte wähle 0-6, 2b oder 2c." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Write-Host "Drücke eine beliebige Taste um fortzufahren..." -ForegroundColor Yellow
            [Console]::ReadKey() | Out-Null
            Clear-Host
        }
        
    } while ($choice -ne "0")
}

function Invoke-FullDriverAnalysis {
    Write-Log "[*] Starte vollständige Treiber-Analyse..." -Color Yellow
    Write-Host ""
    
    # Schritt 1: Problematische Treiber suchen (nur ENE-spezifisch für diese Analyse)
    Write-Host "[1/4] Suche nach bekannten problematischen Treibern..." -ForegroundColor Cyan
    # Überspringe Find-ProblematicDrivers hier - das verwirrt nur
    $problematicDrivers = @()
    
    # Schritt 2: Event Logs analysieren
    Write-Host "[2/4] Analysiere Event Logs für Treiber-Fehler..." -ForegroundColor Cyan
    $eventErrors = Analyze-DriverEventLogs -Silent
    
    # Schritt 3: Nicht signierte Treiber finden
    Write-Host "[3/4] Suche nach nicht signierten Treibern..." -ForegroundColor Cyan
    $unsignedDrivers = Get-UnsignedDrivers
    
    # Schritt 4: Veraltete Treiber identifizieren
    Write-Host "[4/4] Identifiziere veraltete Treiber..." -ForegroundColor Cyan
    $outdatedDrivers = Get-OutdatedDrivers
    
    # Zusammenfassung
    Write-Host ""
    Write-Log "=== TREIBER-ANALYSE ZUSAMMENFASSUNG ===" -Color Green
    Write-Host ""
    
    if ($problematicDrivers.Count -gt 0) {
        Write-Host "⚠️  PROBLEMATISCHE TREIBER GEFUNDEN:" -ForegroundColor Red
        $problematicDrivers | ForEach-Object {
            Write-Host "   • $($_.Name) - $($_.Problem)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($eventErrors.Count -gt 0) {
        Write-Host "🔥 TREIBER-FEHLER IM EVENT LOG:" -ForegroundColor Red
        Write-Host "   Anzahl kritischer Fehler: $($eventErrors.Count)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    if ($unsignedDrivers.Count -gt 0) {
        Write-Host "⚠️  NICHT SIGNIERTE TREIBER:" -ForegroundColor Orange
        Write-Host "   Anzahl: $($unsignedDrivers.Count)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    if ($problematicDrivers.Count -eq 0 -and $eventErrors.Count -eq 0 -and $unsignedDrivers.Count -eq 0) {
        Write-Host "✅ Keine kritischen Treiber-Probleme erkannt!" -ForegroundColor Green
    } else {
        Write-Host "💡 EMPFEHLUNG: Führe spezifische Diagnosen für gefundene Probleme aus." -ForegroundColor Cyan
    }
}

function Find-ProblematicDrivers {
    param([switch]$Silent)
    
    if (-not $Silent) {
        Write-Log "[*] Suche nach bekannten problematischen Treibern..." -Color Yellow
        Write-Host ""
    }
    
    $problematicDrivers = [System.Collections.ArrayList]::new()
    
    # Liste bekannter problematischer Treiber
    $knownProblematicDrivers = @{
        "ene.sys" = "ENE Technology CardReader/LED Controller - kann Bootprobleme verursachen"
        "nvlddmkm.sys" = "NVIDIA Display Driver - häufige BSOD-Ursache bei veralteten Versionen"
        "atikmdag.sys" = "AMD/ATI Display Driver - kann System-Instabilität verursachen"
        "rt640x64.sys" = "Realtek Ethernet Driver - Netzwerk-Probleme"
        "igdkmd64.sys" = "Intel Graphics Driver - Display-Probleme"
        "aswsp.sys" = "Avast Antivirus - kann Performance-Probleme verursachen"
        "klif.sys" = "Kaspersky Driver - System-Kompatibilitätsprobleme"
        "fltmgr.sys" = "File System Filter Manager - Critical System File"
        "win32k.sys" = "Windows Kernel - Blue Screen häufige Ursache"
        "ntoskrnl.exe" = "Windows NT Kernel - Memory Management Issues"
    }
    
    # Aktuelle Treiber abrufen
    try {
        # Verwende Get-WmiObject für zuverlässigere Daten
        $systemDrivers = Get-WmiObject -Class Win32_SystemDriver
        $pnpDrivers = Get-WmiObject -Class Win32_PnPEntity -ErrorAction SilentlyContinue
        
        foreach ($knownDriver in $knownProblematicDrivers.GetEnumerator()) {
            # Suche in System-Treibern
            $driverFound = $systemDrivers | Where-Object { 
                $_.Name -like "*$($knownDriver.Key.Replace('.sys',''))*" -or 
                $_.PathName -like "*$($knownDriver.Key)*" 
            } | Select-Object -First 1
            
            # Fallback: Suche in PnP-Geräten
            if (-not $driverFound -and $pnpDrivers) {
                $driverFound = $pnpDrivers | Where-Object { 
                    $_.Name -like "*$($knownDriver.Key.Replace('.sys',''))*" -or
                    $_.HardwareID -like "*$($knownDriver.Key.Replace('.sys',''))*"
                } | Select-Object -First 1
            }
            
            if ($driverFound) {
                $driverInfo = [PSCustomObject]@{
                    Name = $knownDriver.Key
                    Problem = $knownDriver.Value
                    DriverStatus = if ($driverFound.State) { $driverFound.State } elseif ($driverFound.Status) { $driverFound.Status } else { "Unknown" }
                    StartType = if ($driverFound.StartMode) { $driverFound.StartMode } else { "Unknown" }
                    Path = if ($driverFound.PathName) { $driverFound.PathName } else { "System Driver" }
                }
                [void]$problematicDrivers.Add($driverInfo)
                
                if (-not $Silent) {
                    Write-Host "⚠️  Gefunden: $($knownDriver.Key)" -ForegroundColor Red
                    Write-Host "   Problem: $($knownDriver.Value)" -ForegroundColor Yellow
                    Write-Host "   Status: $($driverInfo.DriverStatus)" -ForegroundColor White
                    Write-Host ""
                }
            }
        }
        
        # Spezielle ene.sys Analyse - nur ECHTE ENE-Hardware
        $eneDrivers = @()
        $eneDrivers += $systemDrivers | Where-Object { 
            $_.Name -eq "ene" -or $_.PathName -like "*\ene.sys" -or $_.PathName -like "*\enecir.sys"
        }
        $eneDrivers += $pnpDevices | Where-Object { 
            $_.HardwareID -like "ENE\*" -or $_.HardwareID -like "*VID_1524*"
        } | Select-Object -First 5
        
        if ($eneDrivers.Count -gt 0) {
            if (-not $Silent) {
                Write-Host "🔍 SPEZIELLE ENE.SYS ANALYSE:" -ForegroundColor Magenta
                $eneDrivers | ForEach-Object {
                    Write-Host "   • Name: $($_.Name)" -ForegroundColor White
                    Write-Host "   • Type: $(if ($_.State) { 'System Driver' } else { 'Device' })" -ForegroundColor Gray
                    Write-Host "   • Pfad: $(if ($_.PathName) { $_.PathName } else { $_.HardwareID })" -ForegroundColor Gray
                    Write-Host "   • Status: $(if ($_.State) { $_.State } else { $_.Status })" -ForegroundColor $(if (($_.State -eq "Running") -or ($_.Status -eq "OK")) { "Green" } else { "Red" })
                    Write-Host ""
                }
            }
        }
        
    } catch {
        Write-Log "Fehler beim Abrufen der Treiber-Information: $($_.Exception.Message)" -Level "ERROR"
    }
    
    if (-not $Silent) {
        if ($problematicDrivers.Count -eq 0) {
            Write-Host "✅ Keine bekannten problematischen Treiber aktiv gefunden." -ForegroundColor Green
        } else {
            Write-Host "⚠️  $($problematicDrivers.Count) problematische(r) Treiber gefunden!" -ForegroundColor Red
        }
    }
    
    return $problematicDrivers
}

function Analyze-DriverEventLogs {
    param([switch]$Silent)
    
    if (-not $Silent) {
        Write-Log "[*] Analysiere Event Logs für Treiber-Fehler..." -Color Yellow
        Write-Host ""
    }
    
    $driverErrors = @()
    
    try {
        # System Event Log nach Treiber-Fehlern durchsuchen
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1,2,3  # Critical, Error, Warning
            StartTime = (Get-Date).AddDays(-7)
        } -ErrorAction SilentlyContinue | Where-Object {
            $_.LevelDisplayName -in @('Critical', 'Error') -and
            ($_.Message -like "*driver*" -or $_.Message -like "*treiber*" -or 
             $_.Message -like "*.sys*" -or $_.ProviderName -like "*driver*")
        } | Select-Object -First 50
        
        if ($events) {
            foreach ($logEvent in $events) {
                $errorInfo = [PSCustomObject]@{
                    TimeCreated = $logEvent.TimeCreated
                    Level = $logEvent.LevelDisplayName
                    Source = $logEvent.ProviderName
                    EventID = $logEvent.Id
                    Message = $logEvent.Message.Substring(0, [Math]::Min(200, $logEvent.Message.Length))
                }
                $driverErrors += $errorInfo
                
                if (-not $Silent) {
                    Write-Host "🔥 $($logEvent.TimeCreated.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Red
                    Write-Host "   Level: $($logEvent.LevelDisplayName) | Source: $($logEvent.ProviderName)" -ForegroundColor Yellow
                    Write-Host "   Event ID: $($logEvent.Id)" -ForegroundColor Gray
                    Write-Host "   Message: $($errorInfo.Message)..." -ForegroundColor White
                    Write-Host ""
                }
            }
        }
        
        # Zusätzlich: Application Event Log für Driver-Crashes
        $appEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Level = 1,2
            StartTime = (Get-Date).AddDays(-3)
        } -ErrorAction SilentlyContinue | Where-Object {
            $_.Message -like "*driver*" -or $_.Message -like "*.sys*"
        } | Select-Object -First 20
        
        if ($appEvents -and -not $Silent) {
            Write-Host "📱 APPLICATION LOG - TREIBER-BEZOGENE FEHLER:" -ForegroundColor Cyan
            $appEvents | ForEach-Object {
                Write-Host "   • $($_.TimeCreated.ToString('MM-dd HH:mm')) - $($_.ProviderName)" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
    } catch {
        Write-Log "Fehler beim Analysieren der Event Logs: $($_.Exception.Message)" -Level "ERROR"
    }
    
    if (-not $Silent) {
        if ($driverErrors.Count -eq 0) {
            Write-Host "✅ Keine kritischen Treiber-Fehler in den letzten 7 Tagen." -ForegroundColor Green
        } else {
            Write-Host "⚠️  $($driverErrors.Count) Treiber-bezogene Fehler in den letzten 7 Tagen gefunden!" -ForegroundColor Red
        }
    }
    
    return $driverErrors
}

function Get-DetailedDriverList {
    Write-Log "[*] Erstelle detaillierte Treiber-Liste..." -Color Yellow
    Write-Host ""
    
    try {
        # Erweiterte Treiber-Information mit WMI (zuverlässiger)
        Write-Host "💾 ALLE SYSTEM-TREIBER (TOP 50):" -ForegroundColor Cyan
        Write-Host ""
        
        $drivers = Get-WmiObject -Class Win32_SystemDriver | 
            Sort-Object Name | 
            Select-Object -First 50
        
        $drivers | ForEach-Object {
            $status = if ($_.State -eq "Running") { "🟢" } else { "🔴" }
            Write-Host "$status $($_.Name)" -ForegroundColor $(if ($_.State -eq "Running") { "Green" } else { "Red" })
            Write-Host "   Status: $($_.State)" -ForegroundColor Gray
            Write-Host "   Start-Typ: $($_.StartMode)" -ForegroundColor Gray
            Write-Host "   Pfad: $($_.PathName)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "💡 Hinweis: Nur die ersten 50 Treiber werden angezeigt." -ForegroundColor Yellow
        
    } catch {
        Write-Log "Fehler beim Abrufen der Treiber-Liste: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Get-UnsignedDrivers {
    Write-Log "[*] Suche nach nicht signierten Treibern..." -Color Yellow
    
    $unsignedDrivers = @()
    
    try {
        # Verwende sigverif oder alternative Methoden
        $drivers = Get-WmiObject -Class Win32_SystemDriver
        
        foreach ($driver in $drivers) {
            if ($driver.PathName) {
                $signature = Get-AuthenticodeSignature -FilePath $driver.PathName -ErrorAction SilentlyContinue
                if ($signature -and $signature.Status -ne "Valid") {
                    $unsignedDrivers += [PSCustomObject]@{
                        Name = $driver.Name
                        Path = $driver.PathName
                        SignatureStatus = $signature.Status
                        State = $driver.State
                    }
                }
            }
        }
    } catch {
        Write-Log "Fehler bei der Signatur-Überprüfung: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $unsignedDrivers
}

function Get-OutdatedDrivers {
    Write-Log "[*] Identifiziere veraltete Treiber..." -Color Yellow
    
    $outdatedDrivers = @()
    
    try {
        # Verwende Windows Update API oder WMI für Treiber-Versionen
        $devices = Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        
        foreach ($device in $devices) {
            $outdatedDrivers += [PSCustomObject]@{
                Name = $device.Name
                DeviceID = $device.DeviceID
                ErrorCode = $device.ConfigManagerErrorCode
                Status = $device.Status
            }
        }
    } catch {
        Write-Log "Fehler bei der Identifikation veralteter Treiber: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $outdatedDrivers
}

function Enable-DriverVerifier {
    Write-Log "[*] Treiber-Verifikation (ERWEITERT)" -Color Magenta
    Write-Host ""
    Write-Host "⚠️  WARNUNG: Driver Verifier ist ein erweiterte Diagnose-Tool!" -ForegroundColor Red
    Write-Host "Es kann System-Instabilität verursachen und sollte nur von" -ForegroundColor Red
    Write-Host "erfahrenen Benutzern verwendet werden." -ForegroundColor Red
    Write-Host ""
    Write-Host "Driver Verifier überwacht Kernel-Modus-Treiber und identifiziert" -ForegroundColor Yellow
    Write-Host "illegale Funktionsaufrufe oder Aktionen die das System beschädigen können." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Möchtest du Driver Verifier Informationen anzeigen? (j/n)"
    
    if ($confirm -eq "j" -or $confirm -eq "J" -or $confirm -eq "y" -or $confirm -eq "Y") {
        try {
            Write-Host ""
            Write-Host "📊 AKTUELLE VERIFIER EINSTELLUNGEN:" -ForegroundColor Cyan
            & verifier /query
            
            Write-Host ""
            Write-Host "💡 Um Driver Verifier zu konfigurieren, führe aus:" -ForegroundColor Yellow
            Write-Host "   verifier.exe (GUI)" -ForegroundColor White
            Write-Host "   verifier /standard /driver drivername.sys" -ForegroundColor White
            Write-Host ""
            Write-Host "⚠️  WICHTIG: Erstelle vor der Aktivierung einen" -ForegroundColor Red
            Write-Host "   Systemwiederherstellungspunkt!" -ForegroundColor Red
            
        } catch {
            Write-Log "Fehler beim Abrufen der Verifier-Informationen: $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Analyze-ENEDriverProblem {
    Write-Log "[*] ENE.SYS PROBLEM-ANALYSE & AUTOMATISCHE REPARATUR" -Color Magenta
    Write-Host ""
    Write-Host "🔍 ANALYSIERE ENE.SYS TREIBER UND HARDWARE..." -ForegroundColor Cyan
    Write-Host ""
    
    # Schritt 1: ENE Treiber finden
    Write-Host "[1/5] Suche nach ENE-Treibern..." -ForegroundColor Yellow
    $systemDrivers = Get-WmiObject -Class Win32_SystemDriver
    $pnpDevices = Get-WmiObject -Class Win32_PnPEntity -ErrorAction SilentlyContinue
    
    # Suche nur nach ECHTEN ENE-Treibern (sehr spezifisch)
    $eneSystemDriver = $systemDrivers | Where-Object { 
        $_.Name -eq "ene" -or
        $_.PathName -like "*\ene.sys" -or 
        $_.PathName -like "*\enecir.sys" -or
        $_.PathName -like "*ENE Technology*" -or
        $_.Name -like "ENE*" -and $_.Name -notlike "*generic*"
    }
    # Suche nur nach ECHTER ENE-Hardware (sehr spezifisch)  
    $eneDevices = $pnpDevices | Where-Object { 
        $_.HardwareID -like "ENE\*" -or
        $_.HardwareID -like "*VID_1524*" -or  # ENE Technology Vendor ID
        $_.Name -like "*ENE Technology*" -or
        $_.Manufacturer -like "*ENE Technology*" -or
        ($_.Name -like "*Card Reader*" -and ($_.HardwareID -like "*ENE*" -or $_.HardwareID -like "*1524*"))
    }
    
    # Schritt 2: Hardware-Analyse
    Write-Host "[2/5] Analysiere verwandte Hardware..." -ForegroundColor Yellow
    $cardReaders = $pnpDevices | Where-Object { 
        $_.Name -like "*Card Reader*" -or 
        $_.Name -like "*Memory*" -or
        $_.Description -like "*Storage*" 
    }
    
    # Schritt 3: Event Log nach ENE-spezifischen Fehlern durchsuchen
    Write-Host "[3/5] Durchsuche Event Logs nach ENE-spezifischen Problemen..." -ForegroundColor Yellow
    $eneErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1,2
        StartTime = (Get-Date).AddDays(-14)
    } -ErrorAction SilentlyContinue | Where-Object {
        ($_.Message -like "*ene.sys*" -or 
         $_.Message -like "*ENE Technology*" -or 
         $_.Message -like "*Card Reader*" -or
         $_.ProviderName -like "*ENE*") -and
         $_.Message -notlike "*Server*" -and
         $_.Message -notlike "*Zeitabschnitt*"
    } | Select-Object -First 5
    
    # Schritt 4: System-Info sammeln
    Write-Host "[4/5] Sammle System-Informationen..." -ForegroundColor Yellow
    $computerInfo = Get-WmiObject -Class Win32_ComputerSystem
    $biosInfo = Get-WmiObject -Class Win32_BIOS
    
    # Schritt 5: Analyse und Empfehlungen
    Write-Host "[5/5] Generiere Analyse-Bericht..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "📊 ENE.SYS PROBLEM-ANALYSE ERGEBNIS" -ForegroundColor Green  
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    # Hardware-Info
    Write-Host "💻 SYSTEM-INFORMATION:" -ForegroundColor Cyan
    Write-Host "   • Hersteller: $($computerInfo.Manufacturer)" -ForegroundColor White
    Write-Host "   • Modell: $($computerInfo.Model)" -ForegroundColor White
    Write-Host "   • BIOS: $($biosInfo.SMBIOSBIOSVersion)" -ForegroundColor White
    Write-Host ""
    
    # ENE Treiber Status mit detaillierter Problem-Analyse
    if ($eneSystemDriver) {
        Write-Host "🔧 ENE SYSTEM-TREIBER GEFUNDEN:" -ForegroundColor Red
        $eneSystemDriver | ForEach-Object {
            Write-Host "   • Name: $($_.Name)" -ForegroundColor White
            Write-Host "   • Status: $($_.State)" -ForegroundColor $(if ($_.State -eq "Running") { "Red" } else { "Green" })
            Write-Host "   • Start-Typ: $($_.StartMode)" -ForegroundColor Gray
            Write-Host "   • Pfad: $($_.PathName)" -ForegroundColor Gray
            
            # DETAILLIERTE PROBLEM-ANALYSE
            Write-Host ""
            Write-Host "   🔍 PROBLEM-ANALYSE:" -ForegroundColor Yellow
            
            # 1. Prüfe ob Treiber läuft aber nicht sollte
            if ($_.State -eq "Running") {
                Write-Host "   ❌ KRITISCH: Treiber läuft aktiv" -ForegroundColor Red
                Write-Host "      → Kann System-Instabilität verursachen" -ForegroundColor Red
                Write-Host "      → Bekannt für Bootprobleme und Bluescreens" -ForegroundColor Red
                
                # Prüfe zugehörige Hardware
                $relatedHardware = Get-WmiObject -Class Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { 
                    $_.HardwareID -like "*ENE*" -or $_.Name -like "*ENE*" 
                }
                
                if ($relatedHardware) {
                    Write-Host "      → Steuert Hardware: $($relatedHardware[0].Name)" -ForegroundColor Yellow
                } else {
                    Write-Host "      → KEINE zugehörige Hardware gefunden (Treiber unnötig!)" -ForegroundColor Red
                }
                
            } elseif ($_.State -eq "Stopped") {
                Write-Host "   ✅ GUT: Treiber ist deaktiviert" -ForegroundColor Green
                
                # Prüfe warum er gestoppt ist - nur ENE-spezifische Geräte
                $deviceErrors = Get-WmiObject -Class Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { 
                    ($_.HardwareID -like "*ENE*" -or 
                     $_.Name -like "*ENE*" -or 
                     $_.Description -like "*ENE*" -or
                     $_.HardwareID -like "*1524*" -or  # ENE Technology Vendor ID
                     $_.Name -like "*Card Reader*") -and 
                    $_.ConfigManagerErrorCode -ne 0 
                }
                
                if ($deviceErrors) {
                    Write-Host "   ⚠️  Grund: Hardware-Fehler erkannt" -ForegroundColor Yellow
                    $deviceErrors | ForEach-Object {
                        $errorDescription = switch ($_.ConfigManagerErrorCode) {
                            1 { "Gerät nicht richtig konfiguriert" }
                            3 { "Treiber beschädigt oder fehlend" }
                            10 { "Gerät kann nicht gestartet werden" }
                            12 { "Nicht genügend Ressourcen verfügbar" }
                            18 { "Treiber muss neu installiert werden" }
                            22 { "Gerät deaktiviert" }
                            28 { "Treiber nicht installiert" }
                            31 { "Gerät funktioniert nicht ordnungsgemäß" }
                            43 { "Windows hat dieses Gerät gestoppt (Code 43)" }
                            default { "Unbekannter Fehler (Code $($_.ConfigManagerErrorCode))" }
                        }
                        Write-Host "      → Fehler: $errorDescription" -ForegroundColor Red
                        Write-Host "      → Hardware: $($_.Name)" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "   ✅ Wurde präventiv deaktiviert (Windows-Schutz)" -ForegroundColor Green
                }
            }
            
            # 2. Prüfe Treiber-Datei
            if ($_.PathName -and (Test-Path $_.PathName)) {
                $fileInfo = Get-Item $_.PathName -ErrorAction SilentlyContinue
                if ($fileInfo) {
                    Write-Host ""
                    Write-Host "   📄 TREIBER-DATEI ANALYSE:" -ForegroundColor Cyan
                    Write-Host "      • Größe: $([math]::Round($fileInfo.Length / 1KB, 1)) KB" -ForegroundColor Gray
                    Write-Host "      • Erstellt: $($fileInfo.CreationTime.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
                    Write-Host "      • Version: $(try { $fileInfo.VersionInfo.FileVersion } catch { 'Unbekannt' })" -ForegroundColor Gray
                    
                    # Signatur prüfen
                    $signature = Get-AuthenticodeSignature $_.PathName -ErrorAction SilentlyContinue
                    if ($signature) {
                        switch ($signature.Status) {
                            "Valid" { Write-Host "      • Signatur: ✅ Gültig signiert" -ForegroundColor Green }
                            "NotSigned" { Write-Host "      • Signatur: ❌ Nicht signiert (Sicherheitsrisiko!)" -ForegroundColor Red }
                            "HashMismatch" { Write-Host "      • Signatur: ❌ Beschädigt oder manipuliert!" -ForegroundColor Red }
                            "NotTrusted" { Write-Host "      • Signatur: ⚠️  Nicht vertrauenswürdig" -ForegroundColor Yellow }
                            default { Write-Host "      • Signatur: ⚠️  Status unbekannt" -ForegroundColor Yellow }
                        }
                    }
                }
            } else {
                Write-Host "   ❌ KRITISCH: Treiber-Datei nicht gefunden!" -ForegroundColor Red
                Write-Host "      → Datei fehlt oder Pfad ungültig" -ForegroundColor Red
                Write-Host "      → System kann instabil werden" -ForegroundColor Red
            }
            
            # 3. Empfehlung basierend auf Analyse
            Write-Host ""
            Write-Host "   💡 AUTOMATISCHE EMPFEHLUNG:" -ForegroundColor Magenta
            if ($_.State -eq "Running") {
                Write-Host "      → SOFORTIGE AKTION ERFORDERLICH: Treiber deaktivieren!" -ForegroundColor Red
            } elseif ($deviceErrors) {
                Write-Host "      → Treiber komplett deinstallieren (Hardware defekt)" -ForegroundColor Yellow
            } else {
                Write-Host "      → Aktueller Zustand ist optimal (deaktiviert)" -ForegroundColor Green
            }
            
            Write-Host ""
        }
    } else {
        Write-Host "✅ KEIN ENE SYSTEM-TREIBER AKTIV" -ForegroundColor Green
        Write-Host ""
    }
    
    # ENE Hardware - nur echte ENE-Geräte anzeigen
    if ($eneDevices.Count -gt 0) {
        Write-Host "🔌 ENE-HARDWARE GEFUNDEN:" -ForegroundColor Yellow
        $eneDevices | Select-Object -First 5 | ForEach-Object {
            Write-Host "   • Gerät: $($_.Name)" -ForegroundColor White
            Write-Host "   • Status: $($_.Status)" -ForegroundColor $(if ($_.Status -eq "OK") { "Green" } else { "Red" })
            if ($_.HardwareID) {
                Write-Host "   • Hardware-ID: $($_.HardwareID[0])" -ForegroundColor Gray
            }
            Write-Host ""
        }
    } else {
        Write-Host "✅ KEINE ENE-HARDWARE GEFUNDEN" -ForegroundColor Green
        Write-Host ""
    }
    
    # Card Reader Hardware
    if ($cardReaders.Count -gt 0) {
        Write-Host "📱 CARD READER / SPEICHER-GERÄTE:" -ForegroundColor Yellow
        $cardReaders | Select-Object -First 3 | ForEach-Object {
            Write-Host "   • $($_.Name)" -ForegroundColor White
            Write-Host "     Status: $($_.Status)" -ForegroundColor $(if ($_.Status -eq "OK") { "Green" } else { "Red" })
        }
        Write-Host ""
    }
    
    # Fehler-Analyse
    if ($eneErrors.Count -gt 0) {
        Write-Host "⚠️  ENE-SPEZIFISCHE FEHLER (LETZTE 14 TAGE):" -ForegroundColor Red
        $eneErrors | ForEach-Object {
            Write-Host "   • $($_.TimeCreated.ToString('MM-dd HH:mm')) - $($_.LevelDisplayName)" -ForegroundColor Yellow
            Write-Host "     $($_.Message.Substring(0, [Math]::Min(150, $_.Message.Length)))..." -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "✅ KEINE ENE-SPEZIFISCHEN TREIBER-FEHLER GEFUNDEN" -ForegroundColor Green
        Write-Host ""
    }
    
    # AUTOMATISCHE REPARATUR UND LÖSUNGSVORSCHLÄGE
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "🔧 AUTOMATISCHE REPARATUR und LÖSUNGSVORSCHLÄGE" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    
    # Windows automatische Treiber-Reparatur anbieten
    if ($eneSystemDriver -and ($eneSystemDriver.State -eq "Running")) {
        Write-Host "🚨 PROBLEM: ENE-Treiber läuft und kann Probleme verursachen" -ForegroundColor Red
        Write-Host ""
        Write-Host "🔧 AUTOMATISCHE REPARATUR VERFÜGBAR:" -ForegroundColor Green
        Write-Host ""
        $autoFix = Read-Host "Soll Windows die ENE-Treiber automatisch reparieren? (j/n)"
        
        if ($autoFix -eq 'j' -or $autoFix -eq 'J' -or $autoFix -eq 'y' -or $autoFix -eq 'Y') {
            Write-Host ""
            Write-Host "Starte Windows automatische Treiber-Reparatur..." -ForegroundColor Yellow
            try {
                # Windows Treiber-Problembehandlung
                & pnputil /scan-devices
                Write-Host "✅ Geräte-Scan abgeschlossen" -ForegroundColor Green
                
                # Versuche problematische Geräte neu zu installieren
                $eneSystemDriver | ForEach-Object {
                    Write-Host "[*] Repariere: $($_.Name)" -ForegroundColor Yellow
                    try {
                        # Neuinstallation über pnputil versuchen
                        $deviceInstanceId = (Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.Name -like "*$($_.Name)*" } | Select-Object -First 1).PNPDeviceID
                        if ($deviceInstanceId) {
                            & pnputil /restart-device "$deviceInstanceId" 2>$null
                            Write-Host "   → Gerät neugestartet" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "   → Automatische Reparatur fehlgeschlagen" -ForegroundColor Red
                    }
                }
                Write-Host ""
                Write-Host "✅ Automatische Reparatur abgeschlossen!" -ForegroundColor Green
            } catch {
                Write-Host "❌ Automatische Reparatur fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "📋 MANUELLE LÖSUNGSSCHRITTE:" -ForegroundColor Yellow
        Write-Host "   1️⃣  SOFORT: Treiber deaktivieren" -ForegroundColor White
        Write-Host "       → Gerätemanager → Systemgeräte → ENE-Gerät → Deaktivieren" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   2️⃣  OPTIONAL: Treiber deinstallieren" -ForegroundColor White  
        Write-Host "       → Nur wenn Card Reader nicht benötigt wird" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   3️⃣  WENN CARD READER NÖTIG: Windows Update ausführen" -ForegroundColor White
        Write-Host "       → Settings → Windows Update → Check for updates" -ForegroundColor Gray
        Write-Host ""
        
    } elseif ($eneSystemDriver -and ($eneSystemDriver.State -eq "Stopped")) {
        Write-Host "✅ GUT: ENE-Treiber ist bereits deaktiviert" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 WEITERE MASSNAHMEN:" -ForegroundColor Yellow
        Write-Host "   1️⃣  PRÜFEN: Gibt es noch Probleme?" -ForegroundColor White
        Write-Host "       → Bluescreens, langsame Boots, USB-Probleme?" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   2️⃣  FALLS JA: Windows Problembehandlung ausführen" -ForegroundColor White
        Write-Host "       → Settings → Update & Security → Troubleshoot" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   3️⃣  FALLS WEITERHIN PROBLEME: Treiber deinstallieren" -ForegroundColor White
        Write-Host "       → Gerätemanager → Gerät löschen + Treiber entfernen" -ForegroundColor Gray
        Write-Host ""
        
    } else {
        Write-Host "✅ KEIN ENE-TREIBER PROBLEM ERKANNT" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 ALLGEMEINE SYSTEM-OPTIMIERUNG:" -ForegroundColor Yellow
        Write-Host "   1️⃣  Windows Update ausführen" -ForegroundColor White
        Write-Host "   2️⃣  Geräte-Manager nach Problemen durchsuchen" -ForegroundColor White  
        Write-Host "   3️⃣  System-Dateien prüfen: sfc /scannow" -ForegroundColor White
        Write-Host ""
    }
    
    # Hardware-spezifische Empfehlungen
    if ($cardReaders.Count -gt 0) {
        Write-Host "💳 CARD READER EMPFEHLUNGEN:" -ForegroundColor Cyan
        Write-Host "   • Wenn Card Reader NICHT benötigt → Im BIOS deaktivieren" -ForegroundColor White
        Write-Host "   • Wenn Card Reader BENÖTIGT → Hersteller-Treiber installieren" -ForegroundColor White
        Write-Host "   • Alternative: Externes USB Card Reader verwenden" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "⚠️  WICHTIG: Vor Änderungen Systemwiederherstellungspunkt erstellen!" -ForegroundColor Red
    Write-Host ""
}

function Remove-ENEDriverForce {
    Write-Log "[*] ENE.SYS TREIBER ZWANGS-ENTFERNUNG" -Color Red
    Write-Host ""
    Write-Host "🚨 ERWEITERTE ENE.SYS TREIBER-ENTFERNUNG" -ForegroundColor Red
    Write-Host ""
    Write-Host "Diese Funktion ist für Fälle wo:" -ForegroundColor Yellow
    Write-Host "• Windows meldet ENE-Treiber-Probleme beim Start" -ForegroundColor White
    Write-Host "• Gerätemanager zeigt 'kein Gerät gefunden'" -ForegroundColor White  
    Write-Host "• Normale Deinstallation funktioniert nicht" -ForegroundColor White
    Write-Host "• Hardware wurde bereits entfernt, Treiber ist aber noch da" -ForegroundColor White
    Write-Host ""
    
    Write-Host "⚠️  WARNUNG: Dies ist eine aggressive Reparatur!" -ForegroundColor Red
    Write-Host "Nur fortfahren wenn normale Methoden versagt haben!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Trotzdem fortfahren? (CONFIRM)"
    if ($confirm -ne "CONFIRM") {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "🛡️ [0/6] Erstelle Backup..." -ForegroundColor Blue
    
    # Versuche Wiederherstellungspunkt zu erstellen
    try {
        Write-Host "   📝 Versuche Wiederherstellungspunkt..." -ForegroundColor Yellow
        
        # Prüfe ob SystemRestore aktiviert ist
        $restoreEnabled = Get-WmiObject -Class Win32_SystemRestore -ErrorAction SilentlyContinue
        if ($restoreEnabled) {
            # Versuche zuerst normalen Wiederherstellungspunkt
            try {
                Checkpoint-Computer -Description "ENE-Treiber Reparatur Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                Write-Host "   ✅ Wiederherstellungspunkt erstellt" -ForegroundColor Green
            } catch {
                # Falls 24h-Limit, versuche Registry-Hack
                Write-Host "   ⚠️  24h-Limit aktiv, versuche Registry-Override..." -ForegroundColor Yellow
                try {
                    # Registry-Hack: Zeitlimit umgehen
                    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
                    Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 0 -ErrorAction Stop
                    
                    # Nochmal versuchen
                    Start-Sleep -Seconds 2
                    Checkpoint-Computer -Description "ENE-Treiber Reparatur Backup (Forced)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                    Write-Host "   ✅ Wiederherstellungspunkt erstellt (Registry-Override)" -ForegroundColor Green
                    
                    # Registry-Wert zurücksetzen (24h Standard)
                    Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 1440 -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "   ❌ Auch Registry-Override fehlgeschlagen" -ForegroundColor Red
                    throw $_
                }
            }
        } else {
            Write-Host "   ⚠️  Systemwiederherstellung nicht aktiviert" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ⚠️  Wiederherstellungspunkt konnte nicht erstellt werden" -ForegroundColor Yellow
        Write-Host "      Grund: $($_.Exception.Message)" -ForegroundColor Gray
        
        # Alternative: Registry-Backup
        try {
            Write-Host "   📂 Erstelle Registry-Backup..." -ForegroundColor Yellow
            $backupPath = "$env:TEMP\ENE_Registry_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            & reg export "HKLM\SYSTEM\CurrentControlSet\Services" "$backupPath" /y 2>$null
            if (Test-Path $backupPath) {
                Write-Host "   ✅ Registry-Backup erstellt: $backupPath" -ForegroundColor Green
                Write-Host "   💾 WICHTIG: Backup-Datei für Notfall aufbewahren!" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "   ❌ Auch Registry-Backup fehlgeschlagen" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    $continueAnyway = Read-Host "Ohne Backup fortfahren? (j/n)"
    if ($continueAnyway -ne 'j' -and $continueAnyway -ne 'J') {
        Write-Host "Abgebrochen - sicher ist sicher!" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "🔍 [1/6] Suche nach ENE-Treiber-Überresten..." -ForegroundColor Cyan
    
    # Schritt 1: Alle ENE-bezogenen Treiber und Dateien finden
    
    # System-Treiber
    $systemDrivers = Get-WmiObject -Class Win32_SystemDriver | Where-Object {
        $_.Name -like "*ene*" -or $_.PathName -like "*ene.sys*"
    }
    
    # PnP-Geräte (auch defekte)
    $pnpDevices = Get-WmiObject -Class Win32_PnPEntity | Where-Object {
        $_.HardwareID -like "*ENE*" -or $_.Name -like "*ENE*" -or
        $_.ConfigManagerErrorCode -ne 0 -and ($_.Name -like "*Card Reader*" -or $_.Description -like "*ENE*")
    }
    
    if ($systemDrivers -or $pnpDevices) {
        Write-Host "   ✅ ENE-Treiber gefunden!" -ForegroundColor Green
        
        if ($systemDrivers) {
            Write-Host "   📂 System-Treiber:" -ForegroundColor White
            $systemDrivers | ForEach-Object {
                Write-Host "      • $($_.Name) - $($_.PathName)" -ForegroundColor Gray
            }
        }
        
        if ($pnpDevices) {
            Write-Host "   🔌 PnP-Geräte (auch defekte):" -ForegroundColor White
            $pnpDevices | ForEach-Object {
                Write-Host "      • $($_.Name) - Fehlercode: $($_.ConfigManagerErrorCode)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "   ❌ Keine ENE-Treiber gefunden" -ForegroundColor Red
        Write-Host "   💡 Möglicherweise bereits entfernt oder anderes Problem" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "🗑️ [2/6] Stoppe und deaktiviere ENE-Treiber..." -ForegroundColor Cyan
    
    # Schritt 2: Treiber stoppen
    $systemDrivers | ForEach-Object {
        try {
            if ($_.State -eq "Running") {
                Write-Host "   🛑 Stoppe: $($_.Name)" -ForegroundColor Yellow
                & net stop $_.Name 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "      ✅ Gestoppt" -ForegroundColor Green
                } else {
                    Write-Host "      ⚠️  Bereits gestoppt oder Fehler" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ✅ Bereits gestoppt: $($_.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "      ❌ Fehler beim Stoppen: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "🧹 [3/6] Entferne PnP-Geräte (auch defekte)..." -ForegroundColor Cyan
    
    # Schritt 3: PnP-Geräte entfernen mit pnputil
    $pnpDevices | ForEach-Object {
        try {
            Write-Host "   🗑️ Entferne: $($_.Name)" -ForegroundColor Yellow
            $deviceID = $_.PNPDeviceID
            
            # Versuche verschiedene Entfernungs-Methoden
            Write-Host "      → Versuche pnputil..." -ForegroundColor Gray
            & pnputil /remove-device "$deviceID" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      ✅ Mit pnputil entfernt" -ForegroundColor Green
            } else {
                Write-Host "      → Versuche WMI-Methode..." -ForegroundColor Gray
                $_.Delete()
                Write-Host "      ✅ Mit WMI entfernt" -ForegroundColor Green
            }
        } catch {
            Write-Host "      ❌ Fehler: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "📁 [4/6] Entferne Treiber-Dateien..." -ForegroundColor Cyan
    
    # Schritt 4: Physische Treiber-Dateien löschen
    $commonENEPaths = @(
        "$env:SystemRoot\system32\drivers\ene.sys",
        "$env:SystemRoot\system32\drivers\enecir.sys",
        "$env:SystemRoot\system32\drivers\EneIo.sys"
    )
    
    # Zusätzlich: Pfade aus gefundenen Treibern
    $systemDrivers | ForEach-Object {
        if ($_.PathName -and $_.PathName -like "*.sys") {
            $commonENEPaths += $_.PathName
        }
    }
    
    $commonENEPaths | ForEach-Object {
        if (Test-Path $_) {
            try {
                Write-Host "   🗑️ Lösche: $_" -ForegroundColor Yellow
                Remove-Item $_ -Force
                Write-Host "      ✅ Gelöscht" -ForegroundColor Green
            } catch {
                Write-Host "      ❌ Datei gesperrt oder Fehler: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "🔍 [5/6] Bereinige Driver Store..." -ForegroundColor Cyan
    
    # Schritt 5: Driver Store nach ENE-Paketen durchsuchen
    try {
        $driverPackages = & pnputil /enum-drivers | Out-String
        $enePackages = $driverPackages -split "`n" | Where-Object { 
            $_ -like "*ENE*" -or $_ -like "*ene.inf*" -or $_ -like "*cardreader*ENE*"
        }
        
        if ($enePackages) {
            Write-Host "   📦 ENE-Pakete im Driver Store gefunden:" -ForegroundColor White
            $enePackages | ForEach-Object {
                Write-Host "      • $_" -ForegroundColor Gray
            }
            
            # Versuche OEM-Pakete zu entfernen (vorsichtig)
            $oemPackages = $driverPackages -split "`n" | Where-Object { $_ -like "Published Name*" } | 
                Where-Object { $_ -like "*ene*" -or $_ -like "*ENE*" }
            
            $oemPackages | ForEach-Object {
                if ($_ -match "oem\d+\.inf") {
                    $packageName = $matches[0]
                    try {
                        Write-Host "   🗑️ Entferne Paket: $packageName" -ForegroundColor Yellow
                        & pnputil /delete-driver $packageName /uninstall /force 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "      ✅ Paket entfernt" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "      ⚠️  Paket konnte nicht entfernt werden" -ForegroundColor Yellow
                    }
                }
            }
        } else {
            Write-Host "   ✅ Keine ENE-Pakete im Driver Store" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Fehler beim Driver Store Scan: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "🔧 [6/6] Abschluss und Empfehlungen..." -ForegroundColor Cyan
    
    Write-Host "   ✅ ENE-Treiber Zwangs-Entfernung abgeschlossen!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 NÄCHSTE SCHRITTE:" -ForegroundColor Yellow
    Write-Host "   1️⃣  System NEUSTARTEN (wichtig!)" -ForegroundColor White
    Write-Host "      → Damit Windows die Änderungen übernimmt" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2️⃣  Nach Neustart prüfen:" -ForegroundColor White
    Write-Host "      → Keine ENE-Fehlermeldungen mehr beim Start" -ForegroundColor Gray
    Write-Host "      → Gerätemanager zeigt keine ENE-Konflikte" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3️⃣  Falls Card Reader benötigt wird:" -ForegroundColor White
    Write-Host "      → Aktuellen Treiber vom Laptop-Hersteller laden" -ForegroundColor Gray
    Write-Host "      → Oder externes USB Card Reader verwenden" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Falls Probleme weiterbestehen:" -ForegroundColor Red
    Write-Host "   → Systemwiederherstellung auf Punkt vor ENE-Installation" -ForegroundColor Yellow
    Write-Host "   → Windows Event Log nach weiteren Fehlern durchsuchen" -ForegroundColor Yellow
    Write-Host ""
}

function Get-InstalledDriverPackages {
    Write-Log "[*] Zeige installierte Treiber-Pakete..." -Color Yellow
    Write-Host ""
    
    try {
        Write-Host "📦 INSTALLIERTE TREIBER-PAKETE (TOP 30):" -ForegroundColor Cyan
        Write-Host ""
        
        $packages = pnputil /enum-drivers | Out-String
        
        # Parse pnputil output (vereinfacht)
        $lines = $packages -split "`n"
        $driverCount = 0
        
        foreach ($line in $lines) {
            if ($line -match "Published Name" -and $driverCount -lt 30) {
                Write-Host "• $line" -ForegroundColor Green
                $driverCount++
            } elseif ($line -match "Driver Package Provider" -and $driverCount -le 30) {
                Write-Host "  $line" -ForegroundColor Gray
            } elseif ($line -match "Class Name" -and $driverCount -le 30) {
                Write-Host "  $line" -ForegroundColor White
                Write-Host ""
            }
        }
        
        Write-Host "💡 Fuer vollstaendige Liste: pnputil /enum-drivers" -ForegroundColor Yellow
        
    } catch {
        Write-Log "Fehler beim Abrufen der Treiber-Pakete: $($_.Exception.Message)" -Level "ERROR"
    }
}