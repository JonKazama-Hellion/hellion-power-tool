# ===================================================================
# NETWORK TOOLS MODULE
# Hellion Power Tool - Modular Version  
# ===================================================================

function Test-EnhancedInternetConnectivity {
    Write-Log "`n[*] --- ERWEITERTE INTERNET-KONNEKTIVITAETS-PRUEFUNG ---" -Color Cyan
    
    $testResults = @{
        DNS = $false
        HTTP = $false
        HTTPS = $false
        CDN = $false
        Overall = $false
        Issues = @()
    }
    
    # Test-Ziele definieren
    $dnsServers = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    $httpSites = @("http://www.google.com", "http://www.bing.com", "http://example.com")
    $httpsSites = @("https://www.microsoft.com", "https://www.google.com", "https://github.com")
    $cdnSites = @("https://cdn.jsdelivr.net", "https://ajax.googleapis.com")
    
    Write-Log "[*] Pruefe DNS-Aufloesung..." -Color Blue
    
    # DNS-Test
    $dnsSuccess = 0
    foreach ($dnsServer in $dnsServers) {
        try {
            $ping = Test-Connection -ComputerName $dnsServer -Count 2 -Quiet -ErrorAction Stop
            if ($ping) {
                Write-Log "  [OK] DNS Server $dnsServer erreichbar" -Color Green
                $dnsSuccess++
            }
        } catch {
            Write-Log "  [FAIL] DNS Server $dnsServer nicht erreichbar" -Color Red
        }
    }
    
    if ($dnsSuccess -gt 0) {
        $testResults.DNS = $true
        Write-Log "[OK] DNS-Konnektivitaet verfuegbar ($dnsSuccess/$($dnsServers.Count) Server)" -Color Green
    } else {
        $testResults.Issues += "Keine DNS-Server erreichbar"
        Write-Log "[ERROR] Keine DNS-Server erreichbar!" -Color Red
    }
    
    # HTTP-Test mit Test-NetConnection (Defender-safe)
    Write-Log "`n[*] Pruefe HTTP-Verbindungen..." -Color Blue
    $httpSuccess = 0
    
    foreach ($site in $httpSites) {
        try {
            $hostName = ([System.Uri]$site).Host
            $testResult = Test-NetConnection -ComputerName $hostName -Port 80 -InformationLevel Quiet -ErrorAction Stop
            if ($testResult.TcpTestSucceeded) {
                Write-Log "  [OK] $site erreichbar" -Color Green
                $httpSuccess++
            } else {
                Write-Log "  [FAIL] $site nicht erreichbar" -Color Red
            }
        } catch {
            Write-Log "  [FAIL] $site - $($_.Exception.Message)" -Color Red
        }
    }
    
    if ($httpSuccess -gt 0) {
        $testResults.HTTP = $true
        Write-Log "[OK] HTTP-Konnektivitaet verfuegbar" -Color Green
    } else {
        $testResults.Issues += "HTTP-Verbindungen fehlgeschlagen"
    }
    
    # HTTPS-Test mit Test-NetConnection (Defender-safe)
    Write-Log "`n[*] Pruefe HTTPS-Verbindungen..." -Color Blue
    $httpsSuccess = 0
    
    foreach ($site in $httpsSites) {
        try {
            $hostName = ([System.Uri]$site).Host
            $testResult = Test-NetConnection -ComputerName $hostName -Port 443 -InformationLevel Quiet -ErrorAction Stop
            if ($testResult.TcpTestSucceeded) {
                Write-Log "  [OK] $site erreichbar" -Color Green
                $httpsSuccess++
            } else {
                Write-Log "  [FAIL] $site nicht erreichbar" -Color Red
            }
        } catch {
            Write-Log "  [FAIL] $site - $($_.Exception.Message)" -Color Red
        }
    }
    
    if ($httpsSuccess -gt 0) {
        $testResults.HTTPS = $true
        Write-Log "[OK] HTTPS-Konnektivitaet verfuegbar" -Color Green
    } else {
        $testResults.Issues += "HTTPS-Verbindungen fehlgeschlagen"
    }
    
    # CDN-Test mit Test-NetConnection (Defender-safe)
    Write-Log "`n[*] Pruefe CDN-Erreichbarkeit..." -Color Blue
    $cdnSuccess = 0
    
    foreach ($site in $cdnSites) {
        try {
            $hostName = ([System.Uri]$site).Host
            $testResult = Test-NetConnection -ComputerName $hostName -Port 443 -InformationLevel Quiet -ErrorAction Stop
            if ($testResult.TcpTestSucceeded) {
                Write-Log "  [OK] $site erreichbar" -Color Green
                $cdnSuccess++
            } else {
                Write-Log "  [FAIL] $site nicht erreichbar" -Color Red
            }
        } catch {
            Write-Log "  [FAIL] $site - $($_.Exception.Message)" -Color Red
        }
    }
    
    if ($cdnSuccess -gt 0) {
        $testResults.CDN = $true
        Write-Log "[OK] CDN-Services erreichbar" -Color Green
    } else {
        $testResults.Issues += "CDN-Services nicht erreichbar"
    }
    
    # Gesamtbewertung
    $successCount = @($testResults.DNS, $testResults.HTTP, $testResults.HTTPS, $testResults.CDN) | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
    
    Write-Log "`n[*] --- KONNEKTIVITAETS-ZUSAMMENFASSUNG ---" -Color Cyan
    Write-Log "DNS: $(if ($testResults.DNS) { '[OK]' } else { '[FAIL]' })" -Color $(if ($testResults.DNS) { 'Green' } else { 'Red' })
    Write-Log "HTTP: $(if ($testResults.HTTP) { '[OK]' } else { '[FAIL]' })" -Color $(if ($testResults.HTTP) { 'Green' } else { 'Red' })
    Write-Log "HTTPS: $(if ($testResults.HTTPS) { '[OK]' } else { '[FAIL]' })" -Color $(if ($testResults.HTTPS) { 'Green' } else { 'Red' })
    Write-Log "CDN: $(if ($testResults.CDN) { '[OK]' } else { '[FAIL]' })" -Color $(if ($testResults.CDN) { 'Green' } else { 'Red' })
    
    if ($successCount -ge 3) {
        $testResults.Overall = $true
        Write-Log "`n[EXCELLENT] Internet-Konnektivitaet ist ausgezeichnet ($successCount/4 Tests erfolgreich)" -Color Green
        Add-Success "Internet-Konnektivitaet erfolgreich getestet"
    } elseif ($successCount -ge 2) {
        $testResults.Overall = $true
        Write-Log "`n[GOOD] Internet-Konnektivitaet ist gut ($successCount/4 Tests erfolgreich)" -Color Yellow
        Add-Warning "Einige Konnektivitaets-Tests fehlgeschlagen"
    } else {
        Write-Log "`n[POOR] Internet-Konnektivitaet hat Probleme ($successCount/4 Tests erfolgreich)" -Color Red
        Write-Log "`nEmpfohlene Loesungsschritte:" -Color Yellow
        Write-Log "  1. Netzwerk-Verbindung pruefen" -Color White
        Write-Log "  2. Router/Modem neustarten" -Color White
        Write-Log "  3. DNS-Einstellungen pruefen (8.8.8.8, 1.1.1.1)" -Color White
        Write-Log "  4. Firewall-/Antivirus-Einstellungen pruefen" -Color White
        
        Add-Error "Internet-Konnektivitaet: Probleme erkannt"
    }
    
    return $testResults
}

function Reset-NetworkConfiguration {
    Write-Log "`n[*] --- NETZWERK-KONFIGURATION ZURUECKSETZEN ---" -Color Cyan
    Write-Log "Setzt verschiedene Netzwerk-Komponenten zurueck" -Color Yellow
    
    Write-Information "[INFO] `n[WARNUNG] Dies wird folgende Aktionen durchfuehren:" -InformationAction Continue
    Write-Information "[INFO]   - TCP/IP Stack zuruecksetzen" -InformationAction Continue
    Write-Information "[INFO]   - DNS Cache leeren" -InformationAction Continue
    Write-Information "[INFO]   - Winsock Catalog zuruecksetzen" -InformationAction Continue
    Write-Information "[INFO]   - IP-Konfiguration erneuern" -InformationAction Continue
    Write-Information "[INFO]   - Netzwerkadapter zuruecksetzen" -InformationAction Continue
    
    $confirm = Read-Host "`nMoechten Sie fortfahren? [j/n]"
    if ($confirm.ToLower() -ne 'j') {
        Write-Log "[SKIP] Netzwerk-Reset abgebrochen" -Color Gray
        return $false
    }
    
    $success = 0
    $failed = 0
    
    # TCP/IP Stack zurücksetzen
    Write-Log "`n[*] Setze TCP/IP Stack zurueck..." -Color Blue
    try {
        & netsh int ip reset 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] TCP/IP Stack zurueckgesetzt" -Color Green
            $success++
        } else {
            Write-Log "[ERROR] TCP/IP Reset fehlgeschlagen" -Color Red
            $failed++
        }
    } catch {
        Write-Log "[ERROR] TCP/IP Reset Fehler: $($_.Exception.Message)" -Color Red
        $failed++
    }
    
    # DNS Cache leeren
    Write-Log "[*] Leere DNS Cache..." -Color Blue
    try {
        & ipconfig /flushdns 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] DNS Cache geleert" -Color Green
            $success++
        } else {
            Write-Log "[ERROR] DNS Cache leeren fehlgeschlagen" -Color Red
            $failed++
        }
    } catch {
        Write-Log "[ERROR] DNS Cache Fehler: $($_.Exception.Message)" -Color Red
        $failed++
    }
    
    # Winsock Catalog zurücksetzen
    Write-Log "[*] Setze Winsock Catalog zurueck..." -Color Blue
    try {
        & netsh winsock reset 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] Winsock Catalog zurueckgesetzt" -Color Green
            $success++
        } else {
            Write-Log "[ERROR] Winsock Reset fehlgeschlagen" -Color Red
            $failed++
        }
    } catch {
        Write-Log "[ERROR] Winsock Reset Fehler: $($_.Exception.Message)" -Color Red
        $failed++
    }
    
    # IP-Konfiguration erneuern
    Write-Log "[*] Erneuere IP-Konfiguration..." -Color Blue
    try {
        & ipconfig /release 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        & ipconfig /renew 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] IP-Konfiguration erneuert" -Color Green
            $success++
        } else {
            Write-Log "[WARNING] IP-Konfiguration teilweise erneuert" -Color Yellow
            $success++
        }
    } catch {
        Write-Log "[ERROR] IP-Konfiguration Fehler: $($_.Exception.Message)" -Color Red
        $failed++
    }
    
    Write-Log "`n[*] NETZWERK-RESET ZUSAMMENFASSUNG:" -Color Cyan
    Write-Log "Erfolgreich: $success" -Color Green
    Write-Log "Fehlgeschlagen: $failed" -Color Red
    
    if ($success -gt 0) {
        Write-Information "[INFO] `n[INFO] Ein Neustart wird empfohlen, um alle Aenderungen zu uebernehmen." -InformationAction Continue
        $script:ActionsPerformed += "Netzwerk-Konfiguration zurueckgesetzt ($success Aktionen)"
        $script:UpdateRecommendations += "Neustart nach Netzwerk-Reset empfohlen"
        Add-Success "Netzwerk-Reset abgeschlossen"
        return $true
    } else {
        Add-Error "Netzwerk-Reset fehlgeschlagen"
        return $false
    }
}

# Export functions for dot-sourcing
Write-Verbose "Network-Tools Module loaded: Test-EnhancedInternetConnectivity, Reset-NetworkConfiguration"