# ===================================================================
# SECURITY TOOLS MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Invoke-SafeAdblock {
    <#
    .SYNOPSIS
    Sichere Adblock-Funktion fuer Windows Host-Datei
    
    .DESCRIPTION
    Fuegt eine kleine Auswahl bekannter Werbung/Tracking-Domains zur Host-Datei hinzu.
    Verwendet eine konservative Whitelist fuer maximale Sicherheit.
    #>
    
    Write-Log "`n[*] --- SAFE ADBLOCK VERWALTUNG ---" -Color Cyan
    
    # Host-Datei Pfad
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $backupPath = "$env:SystemRoot\System32\drivers\etc\hosts.hellion.backup"
    
    try {
        # Backup erstellen falls nicht vorhanden
        if (-not (Test-Path $backupPath)) {
            Copy-Item $hostsPath $backupPath -Force
            Write-Log "[OK] Host-Datei Backup erstellt" -Level "SUCCESS"
        }
        
        # Erweiterte Adblock-Liste (sichere Tracking/Werbung-Domains)
        $adblockDomains = @(
            # Google Tracking & Ads
            "doubleclick.net",
            "googleadservices.com", 
            "googlesyndication.com",
            "google-analytics.com",
            "googletagmanager.com",
            "googletagservices.com",
            "adsystem.google.com",
            
            # Facebook/Meta Tracking
            "facebook.com/tr",
            "connect.facebook.net",
            "analytics.facebook.com",
            
            # Microsoft Tracking
            "msads.net",
            "ads.msn.com",
            "rad.msn.com",
            
            # Amazon Tracking
            "amazon-adsystem.com",
            "assoc-amazon.com",
            
            # Allgemeine Tracking-Services
            "scorecardresearch.com",
            "quantserve.com",
            "outbrain.com",
            "taboola.com",
            "adsrvr.org",
            "turn.com",
            "rubiconproject.com",
            
            # Weitere bekannte Tracker
            "2mdn.net",
            "adsafeprotected.com"
        )
        
        # Aktuelle Host-Datei lesen
        $hostsContent = Get-Content $hostsPath -ErrorAction Stop
        
        # Intelligente Domain-Pruefung - nur fehlende Domains hinzufuegen
        $hellionMarker = "# Hellion Safe Adblock"
        $hasHellionSection = $hostsContent -contains $hellionMarker
        $addedDomainsCount = 0
        $newEntries = @()
        
        # Pruefe welche Domains bereits blockiert sind
        $missingDomains = @()
        foreach ($domain in $adblockDomains) {
            $domainBlocked = $hostsContent | Where-Object { $_ -match "127\.0\.0\.1\s+$([regex]::Escape($domain))" }
            if (-not $domainBlocked) {
                $missingDomains += $domain
            }
        }
        
        Write-Host "`n[*] ADBLOCK-OPTIONEN:" -ForegroundColor Cyan
        Write-Host "  [1] Adblock aktivieren ($($missingDomains.Count) neue Domains)" -ForegroundColor Green
        Write-Host "  [2] Adblock-Status anzeigen" -ForegroundColor Blue
        Write-Host "  [3] Adblock deaktivieren (Backup wiederherstellen)" -ForegroundColor Yellow
        Write-Host "  [4] Host-Datei bearbeiten (Notepad)" -ForegroundColor White
        Write-Host "  [x] Abbrechen" -ForegroundColor Red
        
        $choice = Read-Host "`nWahl [1-4/x]"
        
        switch ($choice.ToLower()) {
            '1' {
                if ($missingDomains.Count -gt 0) {
                    Write-Log "[*] Fuege $($missingDomains.Count) neue Adblock-Eintraege hinzu..." -Color Blue
                    
                    # Hellion-Sektion hinzufuegen falls nicht vorhanden
                    if (-not $hasHellionSection) {
                        $newEntries += ""
                        $newEntries += $hellionMarker
                        $newEntries += "# Generiert: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                        $newEntries += "# Domains: $($adblockDomains.Count) sichere Tracking/Werbung-Blocker"
                    } else {
                        # Update-Kommentar hinzufuegen
                        $newEntries += "# Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm') - $($missingDomains.Count) neue Domains"
                    }
                    
                    # Nur fehlende Domains hinzufuegen
                    foreach ($domain in $missingDomains) {
                        $newEntries += "127.0.0.1 $domain"
                        $addedDomainsCount++
                    }
                    
                    # Host-Datei erweitern
                    $newEntries | Add-Content -Path $hostsPath -Encoding UTF8
                    
                    Write-Log "[SUCCESS] $addedDomainsCount Adblock-Eintraege hinzugefuegt!" -Color Green
                    Write-Log "[INFO] DNS-Cache wird geleert..." -Color Blue
                    
                    # DNS-Cache leeren fuer sofortige Wirkung
                    & ipconfig /flushdns | Out-Null
                    
                    Add-Success "Safe Adblock: $addedDomainsCount neue Domains blockiert"
                    $script:ActionsPerformed += "Safe Adblock ($addedDomainsCount neue Eintraege)"
                } else {
                    Write-Log "[OK] Alle Adblock-Domains sind bereits blockiert!" -Color Green
                }
            }
            '2' {
                # Status anzeigen
                Write-Log "`n[*] ADBLOCK-STATUS:" -Color Cyan
                
                $blockedCount = 0
                $unblockedCount = 0
                
                foreach ($domain in $adblockDomains) {
                    $isBlocked = $hostsContent | Where-Object { $_ -match "127\.0\.0\.1\s+$([regex]::Escape($domain))" }
                    if ($isBlocked) {
                        $blockedCount++
                    } else {
                        $unblockedCount++
                        Write-Log "  [UNBLOCKED] $domain" -Color Red
                    }
                }
                
                Write-Log "`nZusammenfassung:" -Color White
                Write-Log "  Blockiert: $blockedCount/$($adblockDomains.Count) Domains" -Color Green
                Write-Log "  Unblockiert: $unblockedCount/$($adblockDomains.Count) Domains" -Color Red
                
                if (Test-Path $backupPath) {
                    Write-Log "  Backup verfuegbar: $backupPath" -Color Blue
                } else {
                    Write-Log "  [WARNING] Kein Backup gefunden!" -Color Yellow
                }
            }
            '3' {
                # Adblock deaktivieren
                if (Test-Path $backupPath) {
                    $confirm = Read-Host "`nHost-Datei auf Original zuruecksetzen? [j/n]"
                    if ($confirm -eq 'j' -or $confirm -eq 'J') {
                        Copy-Item $backupPath $hostsPath -Force
                        & ipconfig /flushdns | Out-Null
                        Write-Log "[OK] Adblock deaktiviert - Original-Hosts wiederhergestellt" -Color Green
                        Add-Success "Safe Adblock: Deaktiviert"
                        $script:ActionsPerformed += "Safe Adblock (Deaktiviert)"
                    }
                } else {
                    Write-Log "[ERROR] Backup-Datei nicht gefunden!" -Color Red
                }
            }
            '4' {
                # Host-Datei in Notepad oeffnen
                Write-Log "[*] Oeffne Host-Datei in Notepad..." -Color Blue
                try {
                    Start-Process notepad.exe -ArgumentList $hostsPath -Verb RunAs
                    Write-Log "[OK] Host-Datei geoeffnet - Manuelle Bearbeitung moeglich" -Color Green
                } catch {
                    Write-Log "[ERROR] Konnte Notepad nicht starten" -Color Red
                }
            }
            'x' {
                Write-Log "[SKIP] Adblock-Verwaltung abgebrochen" -Color Gray
                return $false
            }
            default {
                Write-Log "[ERROR] Ungueltige Auswahl" -Color Red
                return $false
            }
        }
        
        return $true
        
    } catch {
        Add-Error "Safe Adblock fehlgeschlagen" $_.Exception.Message
        return $false
    }
}

function Test-SecurityStatus {
    Write-Log "`n[*] --- SICHERHEITS-STATUS PRUEFUNG ---" -Color Cyan
    
    $securityIssues = @()
    $securityScore = 0
    $maxScore = 5
    
    try {
        # Windows Update-Status pruefen
        Write-Log "[*] Pruefe Windows Update-Status..." -Color Blue
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateupdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Log "  [OK] Windows Updates sind aktuell" -Color Green
                $securityScore++
            } else {
                Write-Log "  [WARNING] $($searchResult.Updates.Count) Windows Updates verfuegbar" -Color Yellow
                $securityIssues += "Windows Updates verfuegbar"
            }
        } catch {
            Write-Log "  [INFO] Windows Update-Status konnte nicht geprueft werden" -Color Gray
        }
        
        # Firewall-Status pruefen
        Write-Log "[*] Pruefe Windows Firewall..." -Color Blue
        try {
            $firewallProfiles = Get-NetFirewallProfile
            $activeFirewalls = $firewallProfiles | Where-Object { $_.Enabled -eq $true }
            
            if ($activeFirewalls.Count -gt 0) {
                Write-Log "  [OK] Windows Firewall aktiv ($($activeFirewalls.Count) Profile)" -Color Green
                $securityScore++
            } else {
                Write-Log "  [WARNING] Windows Firewall deaktiviert!" -Color Red
                $securityIssues += "Windows Firewall deaktiviert"
            }
        } catch {
            Write-Log "  [WARNING] Firewall-Status konnte nicht geprueft werden" -Color Yellow
        }
        
        # UAC-Status pruefen
        Write-Log "[*] Pruefe User Account Control (UAC)..." -Color Blue
        try {
            $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            $uacValue = Get-ItemProperty -Path $uacKey -Name "EnableLUA" -ErrorAction Stop
            
            if ($uacValue.EnableLUA -eq 1) {
                Write-Log "  [OK] UAC ist aktiviert" -Color Green
                $securityScore++
            } else {
                Write-Log "  [WARNING] UAC ist deaktiviert!" -Color Red
                $securityIssues += "UAC deaktiviert"
            }
        } catch {
            Write-Log "  [WARNING] UAC-Status konnte nicht geprueft werden" -Color Yellow
        }
        
        # Antivirus-Status (bereits in system-info.ps1 implementiert)
        if (Get-Command Test-AntivirusStatus -ErrorAction SilentlyContinue) {
            $avStatus = Test-AntivirusStatus
            if ($avStatus.RealTimeProtectionEnabled) {
                $securityScore++
            } else {
                $securityIssues += "Antivirus-Echtzeitschutz inaktiv"
            }
        }
        
        # Automatische Updates pruefen
        Write-Log "[*] Pruefe automatische Updates..." -Color Blue
        try {
            $auKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
            if (Test-Path $auKey) {
                $auValue = Get-ItemProperty -Path $auKey -Name "AUOptions" -ErrorAction SilentlyContinue
                if ($auValue -and $auValue.AUOptions -ge 3) {
                    Write-Log "  [OK] Automatische Updates aktiviert" -Color Green
                    $securityScore++
                } else {
                    Write-Log "  [INFO] Automatische Updates konfigurationsbedürftig" -Color Yellow
                }
            }
        } catch {
            Write-Log "  [INFO] Auto-Update-Status konnte nicht geprueft werden" -Color Gray
        }
        
        # Sicherheits-Bewertung
        $securityPercentage = [math]::Round(($securityScore / $maxScore) * 100, 0)
        
        Write-Log "`n[*] SICHERHEITS-BEWERTUNG:" -Color Cyan
        Write-Log "Score: $securityScore/$maxScore ($securityPercentage%)" -Color White
        
        if ($securityPercentage -ge 80) {
            Write-Log "[EXCELLENT] Sicherheitsstatus ist sehr gut!" -Color Green
        } elseif ($securityPercentage -ge 60) {
            Write-Log "[GOOD] Sicherheitsstatus ist akzeptabel" -Color Yellow
        } else {
            Write-Log "[WARNING] Sicherheitsstatus braucht Verbesserung!" -Color Red
        }
        
        if ($securityIssues.Count -gt 0) {
            Write-Log "`nGefundene Sicherheitsprobleme:" -Color Red
            foreach ($issue in $securityIssues) {
                Write-Log "  - $issue" -Color Yellow
            }
        }
        
        return @{
            Score = $securityScore
            MaxScore = $maxScore
            Percentage = $securityPercentage
            Issues = $securityIssues
        }
        
    } catch {
        Add-Error "Sicherheits-Pruefung fehlgeschlagen" $_.Exception.Message
        return $null
    }
}

function Invoke-AVSafeOperation {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [string]$Description = "Operation",
        [int]$DelayMs = 100
    )
    
    Write-Log "[*] Sichere $Description (Antivirus-kompatibel)..." -Color Blue
    
    try {
        if ($script:AVSafeMode) {
            Write-Log "[INFO] AV-Safe-Modus: Verwende $DelayMs ms Verzoegerung" -Color Gray
            Start-Sleep -Milliseconds $DelayMs
        }
        
        $result = & $Operation
        
        Write-Log "[OK] $Description erfolgreich" -Color Green
        return $result
        
    } catch {
        Write-Log "[ERROR] $Description fehlgeschlagen: $($_.Exception.Message)" -Color Red
        Add-Error "$Description fehlgeschlagen" $_.Exception.Message
        return $null
    }
}

# Export functions for dot-sourcing
Write-Verbose "Security-Tools Module loaded: Invoke-SafeAdblock, Test-SecurityStatus, Invoke-AVSafeOperation"