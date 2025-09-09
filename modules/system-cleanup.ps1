# ===================================================================
# SYSTEM CLEANUP MODULE
# Hellion Power Tool - Modular Version  
# ===================================================================

function Get-FolderSize {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return 0
    }
    
    try {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return [math]::Round($size / 1MB, 2)
    } catch {
        return 0
    }
}

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
        Write-Information "[INFO]   $Description ($sizeBefore MB)" -InformationAction Continue
        $choice = Read-Host "    Bereinigen? [j/n/a fuer alle]"
        
        if ($choice -eq 'n') {
            Write-Log "  [SKIP] $Description - Vom Benutzer uebersprungen" -Color Gray
            return 0
        }
        
        if ($choice -eq 'a') {
            $script:AutoApproveCleanup = $true
        }
    }
    
    Write-Information "[INFO]   [*] Bereinige $Description..." -InformationAction Continue
    
    try {
        # Antiviren-sicheres Loeschen mit Delay
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
        
        Write-Information "[INFO]  [OK] $freed MB freigegeben" -InformationAction Continue
        return $freed
        
    } catch {
        Write-Error " [ERROR]"
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
        Write-Host ""
        Write-Host "[*] BEREINIGUNGSOPTIONEN:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   [1] " -ForegroundColor White -NoNewline
        Write-Host "Basis-Bereinigung " -ForegroundColor Green -NoNewline
        Write-Host "(Temp-Dateien)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [2] " -ForegroundColor White -NoNewline
        Write-Host "Erweiterte Bereinigung " -ForegroundColor Yellow -NoNewline
        Write-Host "(+ Caches)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [3] " -ForegroundColor White -NoNewline
        Write-Host "Gaming-Bereinigung " -ForegroundColor Magenta -NoNewline
        Write-Host "(+ Gaming-Caches)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [4] " -ForegroundColor White -NoNewline
        Write-Host "Vollstaendige Bereinigung " -ForegroundColor Red -NoNewline
        Write-Host "(Alles)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [5] " -ForegroundColor White -NoNewline
        Write-Host "Abbrechen" -ForegroundColor Red
        Write-Host ""
        
        $cleanupMode = Read-Host "`nWahl [1-5]"
    } else {
        $cleanupMode = "2"  # Standard fuer Auto-Modus
    }
    
    # Bereinigung durchfuehren basierend auf Modus
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
            Write-Log "  [WARNING] Konnte $($service.Description) nicht deaktivieren" -Color Yellow
        }
    }
    
    # Registry-Optimierungen
    Write-Log "[*] Wende Registry-Optimierungen an..." -Color Blue
    
    $regOptimizations = @(
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name="Max Cached Icons"; Value=4096; Description="Icon-Cache vergroessern"},
        @{Path="HKCU:\Control Panel\Desktop"; Name="MenuShowDelay"; Value=0; Description="Menu-Verzoegerung reduzieren"},
        @{Path="HKCU:\Control Panel\Mouse"; Name="MouseHoverTime"; Value=100; Description="Mouse-Hover-Zeit reduzieren"}
    )
    
    foreach ($reg in $regOptimizations) {
        try {
            if (-not (Test-Path $reg.Path)) {
                New-Item -Path $reg.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -ErrorAction Stop
            Write-Log "  [OK] $($reg.Description)" -Color Green
            $optimizations++
        } catch {
            Write-Log "  [WARNING] Registry-Optimierung fehlgeschlagen: $($reg.Description)" -Color Yellow
        }
    }
    
    Write-Log "`n[OK] Performance-Optimierung abgeschlossen!" -Level "SUCCESS"
    Write-Log "[INFO] $optimizations Optimierungen angewendet" -Color Cyan
    
    $script:ActionsPerformed += "Performance-Optimierung ($optimizations Aenderungen)"
    return $optimizations -gt 0
}

function Get-UnusedPrograms {
    Write-Log "`n[*] --- UNGENUTZTE PROGRAMME ANALYSE ---" -Color Cyan
    Write-Log "Analysiert Programme basierend auf Nutzung, Alter und Groesse" -Color Yellow
    
    $unusedPrograms = @()
    
    try {
        # Programme aus Registry auslesen
        $programs = @()
        
        # 64-bit Programme
        $programs += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.UninstallString } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize, InstallLocation
            
        # 32-bit Programme
        if (Test-Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\") {
            $programs += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.UninstallString } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize, InstallLocation
        }
            
        Write-Log "Gefunden: $($programs.Count) installierte Programme" -Color White
        
        # Ausgeschlossene System-Programme (nicht als ungenutzt markieren)
        $systemPrograms = @(
            "*Microsoft Visual C++*", "*Microsoft .NET*", "*Windows SDK*", "*DirectX*",
            "*Microsoft Office*", "*Windows Update*", "*Security Update*", "*Service Pack*",
            "*Driver*", "*Intel*", "*NVIDIA*", "*AMD*", "*Realtek*", "*Audio*",
            "*Runtime*", "*Redistributable*", "*Framework*", "*Java*", "*OpenJDK*",
            "*Python*", "*Node.js*", "*Git*", "*WinRAR*", "*7-Zip*", "*Adobe*",
            "*Browser*", "*Chrome*", "*Firefox*", "*Edge*", "*Steam*", "*Discord*",
            "*Antivirus*", "*Security*", "*Defender*", "*PowerToys*", "*Microsoft Power*"
        )
        
        Write-Log "[*] Analysiere Programme auf Nutzung..." -Color Blue
        $analysisCount = 0
        
        foreach ($program in $programs) {
            $analysisCount++
            if ($analysisCount % 50 -eq 0) {
                Write-Log "Analysiert: $analysisCount/$($programs.Count)" -Level "DEBUG"
            }
            
            $isUnused = $false
            $reasons = @()
            $riskLevel = "Low"
            
            # System-Programme ausschliessen
            $isSystemProgram = $false
            foreach ($sysPattern in $systemPrograms) {
                if ($program.DisplayName -like $sysPattern) {
                    $isSystemProgram = $true
                    break
                }
            }
            if ($isSystemProgram) { continue }
            
            # 1. Analyse: Installationsdatum (sehr alt = wahrscheinlich ungenutzt)
            if ($program.InstallDate) {
                try {
                    $installDate = [DateTime]::ParseExact($program.InstallDate, "yyyyMMdd", $null)
                    $daysSinceInstall = (Get-Date).Subtract($installDate).TotalDays
                    
                    if ($daysSinceInstall -gt 730) {  # 2+ Jahre
                        $reasons += "Sehr alt ($(([math]::Round($daysSinceInstall/365, 1))) Jahre)"
                        $riskLevel = "Medium"
                        $isUnused = $true
                    } elseif ($daysSinceInstall -gt 365) {  # 1+ Jahre
                        $reasons += "Alt ($(([math]::Round($daysSinceInstall/365, 1))) Jahre)"
                        $isUnused = $true
                    }
                } catch {
                    # Installationsdatum nicht parsbar - ignorieren
                }
            }
            
            # 2. Analyse: Groesse (nur als Hinweis, nicht automatisch ungenutzt)
            $sizeInMB = 0
            if ($program.EstimatedSize -and $program.EstimatedSize -gt 0) {
                $sizeInMB = [math]::Round($program.EstimatedSize / 1024, 1)
                
                # Groesse allein macht Programme NICHT ungenutzt
                # Nur in Kombination mit anderen Faktoren (Alter, keine Nutzung)
                if (($sizeInMB -gt 5000) -and ($isUnused -eq $true)) {  # >5GB UND bereits als ungenutzt markiert
                    $reasons += "Sehr gross ($sizeInMB MB)"
                    $riskLevel = "High"
                } elseif (($sizeInMB -gt 2000) -and ($isUnused -eq $true)) {  # >2GB UND bereits als ungenutzt markiert
                    $reasons += "Gross ($sizeInMB MB)"
                    if ($riskLevel -eq "Low") { $riskLevel = "Medium" }
                }
                
                # Nur Groesse-Warnung bei sehr grossen Programmen (ohne als ungenutzt zu markieren)
                if (($sizeInMB -gt 10000) -and ($isUnused -ne $true)) {  # >10GB
                    # Hinweis auf grosse Programme ohne sie als ungenutzt zu klassifizieren
                    Write-Log "Large program detected: $($program.DisplayName) ($sizeInMB MB)" -Level "DEBUG"
                }
            }
            
            # 3. Analyse: Installationsverzeichnis-Zugriff (letzte Nutzung)
            if ($program.InstallLocation -and (Test-Path $program.InstallLocation)) {
                try {
                    $installDir = Get-Item $program.InstallLocation -ErrorAction Stop
                    $daysSinceAccess = (Get-Date).Subtract($installDir.LastAccessTime).TotalDays
                    
                    if ($daysSinceAccess -gt 180) {  # 6+ Monate nicht zugegriffen
                        $reasons += "Lange nicht verwendet ($(([math]::Round($daysSinceAccess/30, 0))) Monate)"
                        $isUnused = $true
                    }
                } catch {
                    # Zugriff fehlgeschlagen - ignorieren
                }
            }
            
            # 4. Analyse: Version-Patterns (Trial, Demo, etc.)
            $versionText = "$($program.DisplayName) $($program.DisplayVersion)"
            if ($versionText -match "(trial|demo|evaluation|beta|preview)" -and $versionText -notmatch "(Microsoft|Windows)") {
                $reasons += "Testversion"
                $riskLevel = "High"
                $isUnused = $true
            }
            
            # Programm als ungenutzt markieren wenn Kriterien erfuellt
            if (($isUnused -eq $true) -and ($reasons.Count -gt 0)) {
                $unusedPrograms += [PSCustomObject]@{
                    Name = $program.DisplayName
                    Version = $program.DisplayVersion
                    Publisher = $program.Publisher
                    Size = if ($sizeInMB -gt 0) { "$sizeInMB MB" } else { "Unbekannt" }
                    InstallDate = $program.InstallDate
                    Reasons = ($reasons -join ", ")
                    RiskLevel = $riskLevel
                }
            }
        }
        
        # Ergebnisse sortieren nach Risiko und Groesse
        $unusedPrograms = $unusedPrograms | Sort-Object @{
            Expression = {
                switch ($_.RiskLevel) {
                    "High" { 1 }
                    "Medium" { 2 }
                    "Low" { 3 }
                    default { 4 }
                }
            }
        }, @{ Expression = { [double]($_.Size -replace " MB", "") }; Descending = $true }
        
        if ($unusedPrograms.Count -gt 0) {
            Write-Log "`n[*] POTENTIELL UNGENUTZTE PROGRAMME:" -Color Yellow
            Write-Log "Gefunden: $($unusedPrograms.Count) Programme die moeglicherweise entfernt werden koennen" -Color White
            
            # Top 5 anzeigen, Rest ins Log
            $displayCount = [Math]::Min(5, $unusedPrograms.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $prog = $unusedPrograms[$i]
                
                Write-Information "[INFO] `n  [$($i+1)] $($prog.Name)" -InformationAction Continue
                if ($prog.Publisher) { Write-Information "[INFO]       Publisher: $($prog.Publisher)" -InformationAction Continue }
                if ($prog.Version) { Write-Information "[INFO]       Version: $($prog.Version)" -InformationAction Continue }
                Write-Information "[INFO]       Groesse: $($prog.Size)" -InformationAction Continue
                Write-Information "[INFO]       Grund: $($prog.Reasons)" -InformationAction Continue
                Write-Information "[INFO]       Risiko: $($prog.RiskLevel)" -InformationAction Continue
            }
            
            if ($unusedPrograms.Count -gt $displayCount) {
                $remainingCount = $unusedPrograms.Count - $displayCount
                Write-Information "[INFO] `n  [INFO] ... und $remainingCount weitere Programme (siehe Log-Datei)" -InformationAction Continue
                
                # Alle weiteren Programme ins Log schreiben
                Write-Log "VOLLSTAENDIGE LISTE UNGENUTZTER PROGRAMME (Log-Datei):" -Level "DEBUG"
                for ($i = $displayCount; $i -lt $unusedPrograms.Count; $i++) {
                    $prog = $unusedPrograms[$i]
                    Write-Log "[$($i+1)] $($prog.Name) by $($prog.Publisher)" -Level "DEBUG"
                    Write-Log "     Version: $($prog.Version) | Groesse: $($prog.Size) | Risiko: $($prog.RiskLevel)" -Level "DEBUG"
                    Write-Log "     Grund: $($prog.Reasons)" -Level "DEBUG"
                }
            }
            
            # Statistiken
            $totalSize = ($unusedPrograms | Where-Object { $_.Size -ne "Unbekannt" } | 
                         ForEach-Object { [double]($_.Size -replace " MB", "") } | 
                         Measure-Object -Sum).Sum
            
            $highRiskCount = ($unusedPrograms | Where-Object { $_.RiskLevel -eq "High" }).Count
            $mediumRiskCount = ($unusedPrograms | Where-Object { $_.RiskLevel -eq "Medium" }).Count
            
            Write-Information "[INFO] `n[STATISTIKEN]" -InformationAction Continue
            Write-Information "[INFO]   Geschaetzte Speicher-Einsparung: $([math]::Round($totalSize, 1)) MB ($([math]::Round($totalSize/1024, 2)) GB)" -InformationAction Continue
            Write-Information "[INFO]   Hohes Risiko (empfohlen zu entfernen): $highRiskCount Programme" -InformationAction Continue
            Write-Information "[INFO]   Mittleres Risiko (pruefen): $mediumRiskCount Programme" -InformationAction Continue
            
            Write-Information "[INFO] `n[EMPFEHLUNG] Programme manuell pruefen - Automatische Deinstallation nicht implementiert" -InformationAction Continue
            
        } else {
            Write-Log "[OK] Keine offensichtlich ungenutzten Programme gefunden!" -Color Green
            Write-Log "[INFO] System scheint gut optimiert zu sein" -Color Cyan
        }
        
    } catch {
        Add-Error "Ungenutzte-Programme-Analyse fehlgeschlagen" $_.Exception.Message
    }
    
    return $unusedPrograms
}

# Export functions for dot-sourcing
Write-Verbose "System-Cleanup Module loaded: Remove-SafeFiles, Invoke-ComprehensiveCleanup, Optimize-SystemPerformance, Get-UnusedPrograms, Get-FolderSize"
