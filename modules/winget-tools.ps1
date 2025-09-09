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
    
    Write-Information "[INFO] `n[*] WINGET INSTALLATION OPTIONEN:" -InformationAction Continue
    Write-Information "[INFO]   [1] Microsoft Store oeffnen (App Installer)" -InformationAction Continue
    Write-Information "[INFO]   [2] GitHub Release herunterladen (Manuell)" -InformationAction Continue
    Write-Information "[INFO]   [3] PowerShell-Installation versuchen" -InformationAction Continue
    Write-Information "[INFO]   [x] Abbrechen" -InformationAction Continue
    
    $choice = Read-Host "`nWahl [1-3/x]"
    
    switch ($choice.ToLower()) {
        '1' {
            try {
                Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
                Write-Log "[OK] Microsoft Store geoeffnet - 'App Installer' installieren" -Color Green
                Write-Information "[INFO] `n[INFO] Nach der Installation 'winget' im Terminal testen" -InformationAction Continue
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
                Write-Information "[INFO] `n[INFO] Lade die neueste .msixbundle-Datei herunter und installiere sie" -InformationAction Continue
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
    
    # Winget-Verfügbarkeits-Check
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
        
        # Einfachster Ansatz - direkter winget upgrade Aufruf
        $wingetResult = & winget upgrade 2>&1 | Out-String
        
        # Prüfe auf "keine Updates"
        if ([string]::IsNullOrEmpty($wingetResult)) {
            Write-Log "[OK] Alle Programme sind aktuell" -Color Green
            return @()
        }
        
        if ($wingetResult.Contains("No available upgrades")) {
            Write-Log "[OK] Alle Programme sind aktuell" -Color Green
            return @()
        }
        
        if ($wingetResult.Contains("No upgrades available")) {
            Write-Log "[OK] Alle Programme sind aktuell" -Color Green
            return @()
        }
        
        # Suche nach der direkten Anzahl-Angabe in der Ausgabe
        $lines = $wingetResult -split "`r?`n"
        $updateCount = 0
        $foundUpdates = @()
        
        # Erst nach der offiziellen Zählung suchen
        foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            # Deutsche Ausgabe: "4 Aktualisierungen verfügbar."
            if ($trimmedLine -match "^(\d+)\s+Aktualisierungen?\s+verfügbar") {
                $updateCount = [int]$matches[1]
                Write-Log "[DEBUG] Gefunden: Deutsche Ausgabe '$trimmedLine' -> $updateCount Updates" -Level "DEBUG"
                break
            }
            # Englische Ausgabe: "4 available upgrades"
            if ($trimmedLine -match "^(\d+)\s+available\s+upgrades?") {
                $updateCount = [int]$matches[1]
                Write-Log "[DEBUG] Gefunden: Englische Ausgabe '$trimmedLine' -> $updateCount Updates" -Level "DEBUG"
                break
            }
        }
        
        # Falls keine direkte Zählung gefunden, zähle Update-Zeilen in der Tabelle
        if ($updateCount -eq 0) {
            Write-Log "[DEBUG] Keine direkte Zählung gefunden - parse Tabelle" -Level "DEBUG"
            $inUpdateSection = $false
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i].Trim()
                
                # Finde Header-Zeile
                if ($line.Contains("Name") -and $line.Contains("Id") -and $line.Contains("Version")) {
                    $inUpdateSection = $true
                    continue
                }
                
                # Skip Trennzeilen
                if ($line.StartsWith("---")) {
                    continue
                }
                
                # Wenn in Update-Sektion und Zeile hat mindestens 3 Wörter
                if ($inUpdateSection) {
                    $parts = $line -split '\s+'
                    if ($parts.Count -ge 3) {
                        $updateCount = $updateCount + 1
                        if ($foundUpdates.Count -lt 8) {
                            $foundUpdates += $parts[0]
                        }
                    }
                    
                    # Stop bei neuer Sektion
                    if ($line.StartsWith("Für die folgenden")) {
                        break
                    }
                }
            }
        }
        
        # Sammle Update-Namen für die Anzeige (auch wenn wir schon die Anzahl haben)
        if ($updateCount -gt 0 -and $foundUpdates.Count -eq 0) {
            $inUpdateSection = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i].Trim()
                
                if ($line.Contains("Name") -and $line.Contains("Id") -and $line.Contains("Version")) {
                    $inUpdateSection = $true
                    continue
                }
                
                if ($line.StartsWith("---")) {
                    continue
                }
                
                if ($inUpdateSection) {
                    $parts = $line -split '\s+'
                    if ($parts.Count -ge 3 -and $foundUpdates.Count -lt 8) {
                        $foundUpdates += $parts[0]
                    }
                    
                    if ($line.StartsWith("Für die folgenden")) {
                        break
                    }
                }
            }
        }
        
        # Zeige Ergebnis
        if ($updateCount -gt 0) {
            Write-Log "[INFO] $updateCount Updates verfuegbar:" -Color Yellow
            
            for ($j = 0; $j -lt $foundUpdates.Count; $j++) {
                Write-Log "  - $($foundUpdates[$j])" -Color White
            }
            
            if ($updateCount -gt $foundUpdates.Count) {
                Write-Log "  ... und weitere" -Color Gray
            }
            
            # Erstelle Array für .Count
            $resultArray = @()
            for ($k = 0; $k -lt $updateCount; $k++) {
                $resultArray += "Update$k"
            }
            return $resultArray
            
        } else {
            Write-Log "[OK] Keine Updates gefunden" -Color Green
            return @()
        }
        
    } catch {
        Write-Log "[ERROR] Winget-Update-Pruefung fehlgeschlagen: $($_.Exception.Message)" -Color Red
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
    Write-Information "[INFO] `n[*] WINGET UPDATE-INSTALLATION ($updateCount verfuegbar):" -InformationAction Continue
    Write-Information "[INFO]   [1] Alle Updates installieren" -InformationAction Continue
    Write-Information "[INFO]   [2] Nur wichtige Updates (Microsoft, Browser)" -InformationAction Continue
    Write-Information "[INFO]   [3] Updates anzeigen und manuell waehlen" -InformationAction Continue
    Write-Information "[INFO]   [4] Einzelne Software installieren" -InformationAction Continue
    Write-Information "[INFO]   [x] Abbrechen" -InformationAction Continue
    
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
                
                Write-Information "[INFO] `n[INFO] Winget Update läuft im Hintergrund..." -InformationAction Continue
                Write-Information "[INFO] Dies kann 5-15 Minuten dauern je nach Anzahl der Updates" -InformationAction Continue
                
                if (Wait-Job -Job $upgradeJob -Timeout 900) {  # 15 Minuten Timeout
                    Receive-Job -Job $upgradeJob | Out-Null
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
                        & winget upgrade --id $update.Id --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                        
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
                Write-Information "[INFO] `n[*] VERFUEGBARE UPDATES:" -InformationAction Continue
                for ($i = 0; $i -lt $availableUpdates.Count; $i++) {
                    $update = $availableUpdates[$i]
                    Write-Information "[INFO]   [$($i+1)] $($update.Name) ($($update.CurrentVersion) -> $($update.AvailableVersion))" -InformationAction Continue
                }
                
                Write-Information "[INFO] `nGeben Sie die Nummern der zu installierenden Updates ein (z.B. 1,3,5):" -InformationAction Continue
                $selection = Read-Host "Auswahl"
                
                if ($selection) {
                    $selectedNumbers = $selection -split ',' | ForEach-Object { $_.Trim() }
                    
                    foreach ($num in $selectedNumbers) {
                        try {
                            $index = [int]$num - 1
                            if ($index -ge 0 -and $index -lt $availableUpdates.Count) {
                                $update = $availableUpdates[$index]
                                Write-Log "[*] Installiere: $($update.Name)..." -Color Blue
                                
                                & winget upgrade --id $update.Id --silent --accept-source-agreements --accept-package-agreements | Out-Null
                                
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
                Write-Information "[INFO] `n[*] SOFTWARE INSTALLATION:" -InformationAction Continue
                Write-Information "[INFO] Beliebte Software zum Installieren:" -InformationAction Continue
                Write-Information "[INFO]   - Google Chrome, Firefox, VLC, 7-Zip" -InformationAction Continue
                Write-Information "[INFO]   - Visual Studio Code, Git, Python" -InformationAction Continue
                Write-Information "[INFO]   - Discord, Spotify, Steam" -InformationAction Continue
                
                $softwareName = Read-Host "`nSoftware-Name oder Winget-ID eingeben"
                
                if ($softwareName) {
                    Write-Log "[*] Installiere: $softwareName..." -Color Blue
                    & winget install $softwareName --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                    
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
