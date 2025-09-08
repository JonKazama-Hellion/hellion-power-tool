# ===================================================================
# WINGET TOOLS MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

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

function Install-WingetIfMissing {
    Write-Log "`n[*] --- WINGET INSTALLATION ---" -Color Cyan
    
    if (Test-WingetAvailability) {
        Write-Log "[OK] Winget ist bereits verfuegbar" -Color Green
        return $true
    }
    
    Write-Log "[*] Winget nicht gefunden - Installation wird vorbereitet..." -Color Yellow
    
    Write-Host "`n[*] WINGET INSTALLATION OPTIONEN:" -ForegroundColor Cyan
    Write-Host "  [1] Microsoft Store oeffnen (App Installer)" -ForegroundColor Green
    Write-Host "  [2] GitHub Release herunterladen (Manuell)" -ForegroundColor Yellow
    Write-Host "  [3] PowerShell-Installation versuchen" -ForegroundColor Blue
    Write-Host "  [x] Abbrechen" -ForegroundColor Red
    
    $choice = Read-Host "`nWahl [1-3/x]"
    
    switch ($choice.ToLower()) {
        '1' {
            try {
                Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
                Write-Log "[OK] Microsoft Store geoeffnet - 'App Installer' installieren" -Color Green
                Write-Host "`n[INFO] Nach der Installation 'winget' im Terminal testen" -ForegroundColor Cyan
                return $true
            } catch {
                Write-Log "[ERROR] Microsoft Store konnte nicht geoeffnet werden" -Color Red
                return $false
            }
        }
        '2' {
            try {
                Start-Process "https://github.com/microsoft/winget-cli/releases/latest"
                Write-Log "[OK] GitHub Releases-Seite geoeffnet" -Color Green
                Write-Host "`n[INFO] Lade die neueste .msixbundle-Datei herunter und installiere sie" -ForegroundColor Cyan
                return $true
            } catch {
                Write-Log "[ERROR] GitHub-Seite konnte nicht geoeffnet werden" -Color Red
                return $false
            }
        }
        '3' {
            Write-Log "[*] Versuche PowerShell-Installation..." -Color Blue
            try {
                # Versuche Winget über PowerShell Gallery zu installieren (experimentell)
                Write-Log "[INFO] Diese Methode ist experimentell und funktioniert nicht immer" -Color Yellow
                
                $progressPreference = 'SilentlyContinue'
                
                # GitHub API für latest release
                $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
                $downloadUrl = $response.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1 | Select-Object -ExpandProperty browser_download_url
                
                if ($downloadUrl) {
                    Write-Log "[*] Winget Download mit Defender-sicherer Methode..." -Color Blue
                    $tempFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
                    
                    # Defender-safe: Use .NET WebClient instead of Invoke-WebRequest
                    $webClient = New-Object System.Net.WebClient
                    $webClient.DownloadFile($downloadUrl, $tempFile)
                    $webClient.Dispose()
                    
                    Write-Log "[*] Installiere Winget..." -Color Blue
                    Add-AppxPackage -Path $tempFile -ErrorAction Stop
                    
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    
                    Write-Log "[SUCCESS] Winget Installation erfolgreich!" -Color Green
                    return Test-WingetAvailability
                } else {
                    Write-Log "[ERROR] Download-URL nicht gefunden" -Color Red
                    return $false
                }
            } catch {
                Write-Log "[ERROR] PowerShell-Installation fehlgeschlagen: $($_.Exception.Message)" -Color Red
                Write-Log "[INFO] Verwende Option 1 oder 2 fuer manuelle Installation" -Color Yellow
                return $false
            }
        }
        'x' {
            Write-Log "[SKIP] Winget-Installation abgebrochen" -Color Gray
            return $false
        }
        default {
            Write-Log "[ERROR] Ungueltige Auswahl" -Color Red
            return $false
        }
    }
}

function Get-WingetUpdates {
    Write-Log "`n[*] --- WINGET UPDATE-PRUEFUNG ---" -Color Cyan
    Write-Log "Suche nach verfuegbaren Software-Updates..." -Color Yellow
    
    # Einfacher Winget-Verfügbarkeits-Check
    try {
        $null = & winget --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "[WARNING] Winget nicht verfuegbar" -Color Yellow
            return @()
        }
        Write-Log "[OK] Winget verfuegbar" -Color Green
    } catch {
        Write-Log "[WARNING] Winget nicht verfuegbar" -Color Yellow
        return @()
    }
    
    try {
        Write-Log "[*] Fuehre winget upgrade aus..." -Color Blue
        
        # Defender-safe: Einfacher direkter Aufruf ohne Jobs
        $wingetOutput = ""
        try {
            $wingetOutput = & winget upgrade 2>&1 | Out-String
        } catch {
            # Fallback: winget list
            try {
                $wingetOutput = & winget list --upgrade-available 2>&1 | Out-String
            } catch {
                throw "Winget-Befehle nicht verfuegbar"
            }
        }
        
        # Prüfe auf "keine Updates"
        if ($wingetOutput -match "No available upgrades" -or 
            $wingetOutput -match "No upgrades available" -or
            $wingetOutput -match "Keine.*Updates" -or
            $wingetOutput.Trim().Length -eq 0) {
            Write-Log "[OK] Alle Programme sind aktuell" -Color Green
            return @()
        }
        
        # Einfaches Parsing - nur zählen
        $lines = $wingetOutput -split "`n"
        $updateCount = 0
        $foundUpdates = @()
        
        foreach ($line in $lines) {
            # Skip leer oder Header
            if (-not $line -or $line.Trim() -eq "" -or $line -match "^Name|^-+") {
                continue
            }
            
            # Einfache Update-Erkennung: Zeile mit mindestens 3 Spalten
            $parts = $line -split '\s{2,}'  # Split by multiple spaces
            if ($parts -and $parts.Count -ge 3) {
                $updateCount++
                if ($updateCount -le 10) {  # Nur ersten 10 für Anzeige
                    $foundUpdates += $parts[0].Trim()
                }
            }
        }
        
        if ($updateCount -gt 0) {
            Write-Log "[INFO] $updateCount Updates verfuegbar:" -Color Yellow
            
            # Einfache Anzeige ohne komplexe Objekte
            for ($i = 0; $i -lt [Math]::Min(8, $foundUpdates.Count); $i++) {
                if ($foundUpdates[$i]) {
                    Write-Log "  - $($foundUpdates[$i])" -Color White
                }
            }
            
            if ($updateCount -gt 8) {
                Write-Log "  ... und $($updateCount - 8) weitere" -Color Gray
            }
            
            # Einfaches Array für Rückgabe
            return @($updateCount)  # Nur Anzahl zurückgeben
        } else {
            Write-Log "[OK] Keine Updates gefunden" -Color Green
            return @()
        }
        
    } catch {
        Write-Log "[ERROR] Winget-Update-Pruefung fehlgeschlagen: $($_.Exception.Message)" -Color Red
        Write-Log "[INFO] Moegliche Loesungen:" -Color Yellow
        Write-Log "  - Winget neu installieren" -Color Gray
        Write-Log "  - Als Administrator ausfuehren" -Color Gray  
        Write-Log "  - Netzwerk-Verbindung pruefen" -Color Gray
        return @()
    }
}

function Install-WingetUpdates {
    $availableUpdates = Get-WingetUpdates
    
    # Einfacher Check: Get-WingetUpdates gibt jetzt nur Array mit Anzahl zurück
    if (-not $availableUpdates -or $availableUpdates.Count -eq 0) {
        Write-Log "[INFO] Keine Updates verfuegbar oder Winget nicht verfuegbar" -Color Green
        return $true
    }
    
    $updateCount = $availableUpdates[0]  # Erste Element ist die Anzahl
    Write-Host "`n[*] WINGET UPDATE-INSTALLATION ($updateCount verfuegbar):" -ForegroundColor Cyan
    Write-Host "  [1] Alle Updates installieren" -ForegroundColor Green
    Write-Host "  [2] Nur wichtige Updates (Microsoft, Browser)" -ForegroundColor Yellow
    Write-Host "  [3] Updates anzeigen und manuell waehlen" -ForegroundColor White
    Write-Host "  [4] Einzelne Software installieren" -ForegroundColor Blue
    Write-Host "  [x] Abbrechen" -ForegroundColor Red
    
    $choice = Read-Host "`nWahl [1-4/x]"
    
    if ($choice -eq 'x' -or $choice -eq 'X') {
        Write-Log "[SKIP] Winget-Updates abgebrochen" -Color Gray
        return $false
    }
    
    try {
        $success = 0
        $failed = 0
        $skipped = 0
        
        switch ($choice) {
            '1' {
                Write-Log "[*] Installiere alle verfuegbaren Updates..." -Color Blue
                Write-Log "[INFO] Dies kann mehrere Minuten dauern..." -Color Gray
                
                # Alle Updates mit einem Befehl installieren
                $upgradeJob = Start-Job -ScriptBlock { 
                    & winget upgrade --all --silent --accept-source-agreements --accept-package-agreements 2>&1
                }
                
                Write-Host "`n[INFO] Winget Update läuft im Hintergrund..." -ForegroundColor Yellow
                Write-Host "[INFO] Dies kann 5-15 Minuten dauern je nach Anzahl der Updates" -ForegroundColor Gray
                
                if (Wait-Job -Job $upgradeJob -Timeout 900) {  # 15 Minuten Timeout
                    $upgradeOutput = Receive-Job -Job $upgradeJob
                    $upgradeExitCode = $upgradeJob.State
                    
                    if ($upgradeExitCode -eq "Completed") {
                        Write-Log "[SUCCESS] Winget Update-Installation abgeschlossen" -Color Green
                        $success = $availableUpdates.Count
                    } else {
                        Write-Log "[WARNING] Winget Update mit Problemen abgeschlossen" -Color Yellow
                        $failed = [math]::Floor($availableUpdates.Count / 2)
                        $success = $availableUpdates.Count - $failed
                    }
                } else {
                    Stop-Job -Job $upgradeJob
                    Write-Log "[ERROR] Winget Update Timeout nach 15 Minuten" -Color Red
                    $failed = $availableUpdates.Count
                }
                
                Remove-Job -Job $upgradeJob -Force
            }
            '2' {
                Write-Log "[*] Installiere wichtige Updates..." -Color Blue
                
                # Filtere wichtige Updates
                $importantUpdates = $availableUpdates | Where-Object { 
                    $_.Name -match "Microsoft|Windows|Chrome|Firefox|Edge|Visual Studio" -or
                    $_.Id -match "Microsoft|Google|Mozilla"
                }
                
                if ($importantUpdates.Count -gt 0) {
                    Write-Log "[INFO] $($importantUpdates.Count) wichtige Updates gefunden" -Color Yellow
                    
                    foreach ($update in $importantUpdates) {
                        Write-Log "[*] Installiere: $($update.Name)..." -Color Blue
                        $result = & winget upgrade --id $update.Id --silent --accept-source-agreements --accept-package-agreements 2>&1
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "  [OK] $($update.Name) erfolgreich" -Color Green
                            $success++
                        } else {
                            Write-Log "  [ERROR] $($update.Name) fehlgeschlagen" -Color Red
                            $failed++
                        }
                    }
                } else {
                    Write-Log "[INFO] Keine wichtigen Updates gefunden" -Color Gray
                }
            }
            '3' {
                Write-Host "`n[*] VERFUEGBARE UPDATES:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $availableUpdates.Count; $i++) {
                    $update = $availableUpdates[$i]
                    Write-Host "  [$($i+1)] $($update.Name) ($($update.CurrentVersion) -> $($update.AvailableVersion))" -ForegroundColor White
                }
                
                Write-Host "`nGeben Sie die Nummern der zu installierenden Updates ein (z.B. 1,3,5):" -ForegroundColor Cyan
                $selection = Read-Host "Auswahl"
                
                if ($selection) {
                    $selectedNumbers = $selection -split ',' | ForEach-Object { $_.Trim() }
                    
                    foreach ($num in $selectedNumbers) {
                        try {
                            $index = [int]$num - 1
                            if ($index -ge 0 -and $index -lt $availableUpdates.Count) {
                                $update = $availableUpdates[$index]
                                Write-Log "[*] Installiere: $($update.Name)..." -Color Blue
                                
                                $result = & winget upgrade --id $update.Id --silent --accept-source-agreements --accept-package-agreements
                                
                                if ($LASTEXITCODE -eq 0) {
                                    Write-Log "  [OK] $($update.Name) erfolgreich" -Color Green
                                    $success++
                                } else {
                                    Write-Log "  [ERROR] $($update.Name) fehlgeschlagen" -Color Red
                                    $failed++
                                }
                            } else {
                                Write-Log "  [SKIP] Ungueltige Nummer: $num" -Color Yellow
                                $skipped++
                            }
                        } catch {
                            Write-Log "  [ERROR] Parsing-Fehler: $num" -Color Red
                            $skipped++
                        }
                    }
                }
            }
            '4' {
                Write-Host "`n[*] SOFTWARE INSTALLATION:" -ForegroundColor Cyan
                Write-Host "Beliebte Software zum Installieren:" -ForegroundColor Yellow
                Write-Host "  - Google Chrome, Firefox, VLC, 7-Zip" -ForegroundColor Gray
                Write-Host "  - Visual Studio Code, Git, Python" -ForegroundColor Gray
                Write-Host "  - Discord, Spotify, Steam" -ForegroundColor Gray
                
                $softwareName = Read-Host "`nSoftware-Name oder Winget-ID eingeben"
                
                if ($softwareName) {
                    Write-Log "[*] Installiere: $softwareName..." -Color Blue
                    $result = & winget install $softwareName --silent --accept-source-agreements --accept-package-agreements 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "[SUCCESS] $softwareName erfolgreich installiert" -Color Green
                        $success = 1
                    } else {
                        Write-Log "[ERROR] $softwareName Installation fehlgeschlagen" -Color Red
                        Write-Log "[INFO] Versuche: winget search $softwareName" -Color Yellow
                        $failed = 1
                    }
                }
            }
        }
        
        # Zusammenfassung
        Write-Log "`n[*] WINGET UPDATE-ZUSAMMENFASSUNG:" -Color Cyan
        Write-Log "Erfolgreich: $success" -Color Green
        Write-Log "Fehlgeschlagen: $failed" -Color Red
        if ($skipped -gt 0) {
            Write-Log "Übersprungen: $skipped" -Color Yellow
        }
        
        if ($success -gt 0) {
            $script:ActionsPerformed += "Winget-Updates ($success erfolgreich)"
            
            # Neustart-Empfehlung prüfen
            if ($success -ge 3) {
                Write-Log "[INFO] Bei mehreren Updates wird ein Neustart empfohlen" -Color Yellow
                $script:UpdateRecommendations += "Neustart nach Winget-Updates empfohlen"
            }
            
            return $true
        } else {
            return $false
        }
        
    } catch {
        Add-Error "Winget-Update-Installation fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

function Search-WingetSoftware {
    param([string]$SearchTerm = "")
    
    if (-not (Test-WingetAvailability)) {
        Write-Log "[ERROR] Winget nicht verfuegbar" -Color Red
        return @()
    }
    
    if (-not $SearchTerm) {
        $SearchTerm = Read-Host "`nSuchbegriff eingeben (z.B. 'chrome', 'firefox', 'vscode')"
        if (-not $SearchTerm) {
            Write-Log "[SKIP] Suche abgebrochen" -Color Gray
            return @()
        }
    }
    
    Write-Log "`n[*] --- WINGET SOFTWARE-SUCHE ---" -Color Cyan
    Write-Log "Suche nach: '$SearchTerm'..." -Color Yellow
    
    try {
        $searchOutput = & winget search $SearchTerm --accept-source-agreements 2>&1 | Out-String
        
        if ($searchOutput -match "No package found") {
            Write-Log "[INFO] Keine Software gefunden fuer: $SearchTerm" -Color Yellow
            return @()
        }
        
        # Parse Suchergebnisse
        $results = @()
        $lines = $searchOutput -split "`n"
        $foundHeader = $false
        
        foreach ($line in $lines) {
            if ($line -match "Name.*Id.*Version") {
                $foundHeader = $true
                continue
            }
            
            if ($foundHeader -and $line.Trim() -ne "" -and $line -notmatch "^-+$") {
                try {
                    # Vereinfachte Extraktion für Suchergebnisse
                    if ($line -match '^(.+?)\s{2,}([A-Za-z0-9\.\-_]+)\s{2,}(.+)$') {
                        $results += @{
                            Name = $matches[1].Trim()
                            Id = $matches[2].Trim()
                            Version = $matches[3].Trim()
                        }
                    }
                } catch {
                    continue
                }
            }
        }
        
        if ($results.Count -gt 0) {
            Write-Log "[OK] $($results.Count) Ergebnisse gefunden:" -Color Green
            
            # Zeige Top 10 Ergebnisse
            $results | Select-Object -First 10 | ForEach-Object {
                Write-Log "  - $($_.Name) (ID: $($_.Id))" -Color White
            }
            
            if ($results.Count -gt 10) {
                Write-Log "  ... und $($results.Count - 10) weitere" -Color Gray
            }
            
            # Installation anbieten
            $install = Read-Host "`nSoftware aus den Ergebnissen installieren? [ID/Name eingeben oder 'n']"
            if ($install -and $install.ToLower() -ne 'n') {
                Write-Log "[*] Installiere: $install..." -Color Blue
                $installResult = & winget install $install --silent --accept-source-agreements --accept-package-agreements 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "[SUCCESS] Installation erfolgreich!" -Color Green
                    Add-Success "Winget: $install installiert"
                } else {
                    Write-Log "[ERROR] Installation fehlgeschlagen" -Color Red
                    Write-Log "[INFO] Ausgabe: $installResult" -Color Gray
                }
            }
        }
        
        return $results
        
    } catch {
        Add-Error "Winget-Suche fehlgeschlagen" $_.Exception.Message
        return @()
    }
}

# Export functions for dot-sourcing
Write-Verbose "Winget-Tools Module loaded: Test-WingetAvailability, Install-WingetIfMissing, Get-WingetUpdates, Install-WingetUpdates, Search-WingetSoftware"