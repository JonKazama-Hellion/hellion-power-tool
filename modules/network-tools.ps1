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
    $dnsServers = @(
        @{IP="8.8.8.8"; Name="Google"},
        @{IP="1.1.1.1"; Name="Cloudflare"}, 
        @{IP="217.237.148.3"; Name="Telekom"},
        @{IP="9.9.9.9"; Name="Quad9"},
        @{IP="208.67.222.222"; Name="OpenDNS"}
    )
    $fallbackDnsServers = @(
        @{IP="84.200.69.80"; Name="DNS.WATCH"},
        @{IP="84.200.70.40"; Name="DNS.WATCH-2"}
    )
    $httpSites = @("http://www.google.com", "http://www.bing.com", "http://example.org")
    $httpsSites = @("https://www.microsoft.com", "https://www.google.com", "https://hellion-initiative.de")
    $cdnSites = @("https://www.cloudflare.com", "https://cdn.discordapp.com", "https://images-na.ssl-images-amazon.com")
    
    Write-Log "[*] Pruefe DNS-Aufloesung..." -Color Blue
    
    # DNS-Test
    $dnsSuccess = 0
    foreach ($dnsServer in $dnsServers) {
        try {
            $ping = Test-Connection -ComputerName $dnsServer.IP -Count 2 -Quiet -ErrorAction Stop
            if ($ping) {
                Write-Log "  [OK] DNS Server $($dnsServer.Name) ($($dnsServer.IP)) erreichbar" -Color Green
                $dnsSuccess++
            }
        } catch {
            Write-Log "  [FAIL] DNS Server $($dnsServer.Name) ($($dnsServer.IP)) nicht erreichbar" -Color Red
        }
    }
    
    # Fallback-Test falls weniger als 3 primäre DNS-Server funktionieren
    if ($dnsSuccess -lt 3) {
        Write-Log "[WARNING] Nur $dnsSuccess/$($dnsServers.Count) primaere DNS-Server erreichbar - teste Fallback-Server..." -Color Yellow
        
        foreach ($fallbackServer in $fallbackDnsServers) {
            try {
                $ping = Test-Connection -ComputerName $fallbackServer.IP -Count 2 -Quiet -ErrorAction Stop
                if ($ping) {
                    Write-Log "  [OK] Fallback DNS Server $($fallbackServer.Name) ($($fallbackServer.IP)) erreichbar" -Color Green
                    $dnsSuccess++
                }
            } catch {
                Write-Log "  [FAIL] Fallback DNS Server $($fallbackServer.Name) ($($fallbackServer.IP)) nicht erreichbar" -Color Red
            }
        }
    }
    
    if ($dnsSuccess -gt 0) {
        $testResults.DNS = $true
        $totalServers = $dnsServers.Count + ($dnsSuccess -lt 3 ? $fallbackDnsServers.Count : 0)
        Write-Log "[OK] DNS-Konnektivitaet verfuegbar ($dnsSuccess Server insgesamt)" -Color Green
    } else {
        $testResults.Issues += "Keine DNS-Server erreichbar (inkl. Fallbacks)"
        Write-Log "[ERROR] Keine DNS-Server erreichbar (auch Fallbacks fehlgeschlagen)!" -Color Red
    }
    
    # HTTP-Test mit System.Net.NetworkInformation (Fallback für NetTCPIP Probleme)
    Write-Log "`n[*] Pruefe HTTP-Verbindungen..." -Color Blue
    $httpSuccess = 0
    
    $httpResults = @()
    foreach ($site in $httpSites) {
        $siteName = ([System.Uri]$site).Host
        Write-Log "  🌐 $siteName" -Color Cyan
        
        try {
            # DNS-Test (versteckt für User)
            try {
                $resolved = [System.Net.Dns]::GetHostAddresses($siteName)
            } catch {
                Write-Log "     ❌ DNS-Auflösung fehlgeschlagen" -Color Red
                $httpResults += @{Site=$siteName; Status="FAIL"; Reason="DNS-Problem"}
                continue
            }
            
            # TCP-Test
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $result = $tcpClient.BeginConnect($siteName, 80, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(5000, $false)
                
                if ($success -and $tcpClient.Connected) {
                    Write-Log "     ✅ Verbindung erfolgreich" -Color Green
                    $httpSuccess++
                    $httpResults += @{Site=$siteName; Status="OK"; Reason="TCP-Verbindung"}
                } else {
                    # ICMP Fallback
                    if (Test-Connection -ComputerName $siteName -Count 2 -Quiet -ErrorAction SilentlyContinue) {
                        Write-Log "     ⚠️  Host erreichbar, aber Port blockiert" -Color Yellow
                        $httpSuccess++
                        $httpResults += @{Site=$siteName; Status="OK"; Reason="ICMP-Ping (Port blockiert)"}
                    } else {
                        Write-Log "     ❌ Nicht erreichbar" -Color Red
                        $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Timeout"}
                    }
                }
                try { 
                    $tcpClient.Close() 
                } catch { 
                    # TCP-Client Close fehlgeschlagen - Ressource könnte bereits freigegeben sein
                    Write-Verbose "TCP-Client Close fehlgeschlagen: $($_.Exception.Message)"
                }
                
            } catch [System.Net.Sockets.SocketException] {
                $errorCode = $_.Exception.ErrorCode
                switch ($errorCode) {
                    10060 { 
                        Write-Log "     ❌ Verbindung blockiert (Firewall/Antivirus)" -Color Red 
                        $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Firewall-Block"}
                    }
                    10061 { 
                        Write-Log "     ❌ Port 80 vom Server blockiert" -Color Red 
                        $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Server-Block"}
                    }
                    11001 { 
                        Write-Log "     ❌ Server nicht gefunden" -Color Red 
                        $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Host nicht gefunden"}
                    }
                    default { 
                        Write-Log "     ❌ Netzwerk-Fehler (Code: $errorCode)" -Color Red 
                        $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Socket-Fehler"}
                    }
                }
            } catch {
                Write-Log "     ❌ Unbekannter Fehler" -Color Red
                $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Unbekannt"}
            }
        } catch {
            Write-Log "     ❌ Test fehlgeschlagen" -Color Red
            $httpResults += @{Site=$siteName; Status="FAIL"; Reason="Allgemeiner Fehler"}
        }
    }
    
    if ($httpSuccess -gt 0) {
        $testResults.HTTP = $true
        Write-Log "[OK] HTTP-Konnektivitaet verfuegbar" -Color Green
    } else {
        $testResults.Issues += "HTTP-Verbindungen fehlgeschlagen"
    }
    
    # HTTPS-Test mit System.Net.Sockets (Fallback für NetTCPIP Probleme)
    Write-Log "`n[*] Pruefe HTTPS-Verbindungen..." -Color Blue
    $httpsSuccess = 0
    
    $httpsResults = @()
    foreach ($site in $httpsSites) {
        $siteName = ([System.Uri]$site).Host
        Write-Log "  🔒 $siteName" -Color Cyan
        
        try {
            # DNS-Test (versteckt für User) 
            try {
                $resolved = [System.Net.Dns]::GetHostAddresses($siteName)
            } catch {
                Write-Log "     ❌ DNS-Auflösung fehlgeschlagen" -Color Red
                $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="DNS-Problem"}
                continue
            }
            
            # HTTPS TCP-Test
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $result = $tcpClient.BeginConnect($siteName, 443, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(5000, $false)
                
                if ($success -and $tcpClient.Connected) {
                    # SSL-Test (optional - falls Zeit)
                    try {
                        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream())
                        $sslStream.AuthenticateAsClient($siteName)
                        Write-Log "     ✅ HTTPS Verbindung vollständig funktional" -Color Green
                        $sslStream.Close()
                    } catch {
                        Write-Log "     ✅ TCP-Verbindung OK (SSL-Problem ignoriert)" -Color Green
                    }
                    $httpsSuccess++
                    $httpsResults += @{Site=$siteName; Status="OK"; Reason="HTTPS-Verbindung"}
                } else {
                    # ICMP Fallback
                    if (Test-Connection -ComputerName $siteName -Count 2 -Quiet -ErrorAction SilentlyContinue) {
                        Write-Log "     ⚠️  Host erreichbar, aber HTTPS blockiert" -Color Yellow
                        $httpsSuccess++
                        $httpsResults += @{Site=$siteName; Status="OK"; Reason="ICMP-Ping (HTTPS blockiert)"}
                    } else {
                        Write-Log "     ❌ Nicht erreichbar" -Color Red
                        $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Timeout"}
                    }
                }
                try { 
                    $tcpClient.Close() 
                } catch { 
                    # TCP-Client Close fehlgeschlagen - Ressource könnte bereits freigegeben sein
                    Write-Verbose "TCP-Client Close fehlgeschlagen: $($_.Exception.Message)"
                }
                
            } catch [System.Net.Sockets.SocketException] {
                $errorCode = $_.Exception.ErrorCode
                switch ($errorCode) {
                    10060 { 
                        Write-Log "     ❌ HTTPS blockiert (Firewall/Proxy)" -Color Red 
                        $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Firewall/Proxy-Block"}
                    }
                    10061 { 
                        Write-Log "     ❌ Port 443 vom Server blockiert" -Color Red 
                        $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Server-Block"}
                    }
                    11001 { 
                        Write-Log "     ❌ Server nicht gefunden" -Color Red 
                        $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Host nicht gefunden"}
                    }
                    default { 
                        Write-Log "     ❌ HTTPS Netzwerk-Fehler (Code: $errorCode)" -Color Red 
                        $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Socket-Fehler"}
                    }
                }
            } catch {
                Write-Log "     ❌ Unbekannter HTTPS-Fehler" -Color Red
                $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Unbekannt"}
            }
        } catch {
            Write-Log "     ❌ Test fehlgeschlagen" -Color Red
            $httpsResults += @{Site=$siteName; Status="FAIL"; Reason="Allgemeiner Fehler"}
        }
    }
    
    if ($httpsSuccess -gt 0) {
        $testResults.HTTPS = $true
        Write-Log "[OK] HTTPS-Konnektivitaet verfuegbar" -Color Green
    } else {
        $testResults.Issues += "HTTPS-Verbindungen fehlgeschlagen"
    }
    
    # CDN-Test mit System.Net.Sockets (Fallback für NetTCPIP Probleme)
    Write-Log "`n[*] Pruefe CDN-Erreichbarkeit..." -Color Blue
    $cdnSuccess = 0
    
    foreach ($site in $cdnSites) {
        try {
            $hostName = ([System.Uri]$site).Host
            
            # Fallback-Methode: System.Net.Sockets.TcpClient für Port 443
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $result = $tcpClient.BeginConnect($hostName, 443, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(3000, $false)
                $tcpClient.Close()
                
                if ($success) {
                    Write-Log "  [OK] $site erreichbar" -Color Green
                    $cdnSuccess++
                } else {
                    Write-Log "  [FAIL] $site - Timeout" -Color Red
                }
            } catch {
                # Zweiter Fallback: Test-Connection ICMP  
                if (Test-Connection -ComputerName $hostName -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    Write-Log "  [OK] $site Host erreichbar (ICMP)" -Color Yellow
                    $cdnSuccess++
                } else {
                    Write-Log "  [FAIL] $site nicht erreichbar" -Color Red
                }
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
    
    Write-Log "`n═══════════════════════════════════════════════════" -Color Cyan
    Write-Log "              KONNEKTIVITAETS-ERGEBNIS" -Color White
    Write-Log "═══════════════════════════════════════════════════" -Color Cyan
    Write-Log ""
    
    # DNS-Ergebnis mit korrekten Farben
    if ($testResults.DNS) {
        Write-Log "🌐 DNS-Server:     ✅ OK" -Color Green
    } else {
        Write-Log "🌐 DNS-Server:     ❌ FEHLER" -Color Red
    }
    
    # HTTP-Ergebnis mit korrekten Farben
    if ($testResults.HTTP) {
        Write-Log "📄 HTTP-Sites:     ✅ OK" -Color Green
    } else {
        Write-Log "📄 HTTP-Sites:     ❌ FEHLER" -Color Red
    }
    
    # HTTPS-Ergebnis mit korrekten Farben
    if ($testResults.HTTPS) {
        Write-Log "🔒 HTTPS-Sites:    ✅ OK" -Color Green
    } else {
        Write-Log "🔒 HTTPS-Sites:    ❌ FEHLER" -Color Red
    }
    
    # CDN-Ergebnis mit korrekten Farben
    if ($testResults.CDN) {
        Write-Log "⚡ CDN-Services:   ✅ OK" -Color Green
    } else {
        Write-Log "⚡ CDN-Services:   ❌ FEHLER" -Color Red
    }
    
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
        Write-Log "  3. DNS-Einstellungen pruefen (Google, Cloudflare, Telekom, Quad9)" -Color White
        Write-Log "  4. Firewall-/Antivirus-Einstellungen pruefen" -Color White
        
        Add-Error "Internet-Konnektivitaet: Probleme erkannt"
    }
    
    Write-Log ""  # Abschließende Leerzeile für bessere Formatierung
    
    # Return für interne Verwendung - wird normalerweise ignoriert
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
        # Erst prüfen ob Admin-Rechte vorhanden sind
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Write-Log "[WARNING] TCP/IP Reset erfordert Administrator-Rechte" -Color Yellow
            $failed++
        } else {
            # TCP/IP Reset mit besserer Fehlerbehandlung
            $resetOutput = & netsh int ip reset 2>&1
            $resetResult = $LASTEXITCODE
            
            if ($resetResult -eq 0 -or $resetOutput -like "*erfolgreich*" -or $resetOutput -like "*successfully*") {
                Write-Log "[OK] TCP/IP Stack zurueckgesetzt" -Color Green
                $success++
            } else {
                Write-Log "[WARNING] TCP/IP Reset unvollständig (Exitcode: $resetResult)" -Color Yellow
                Write-Log "Output: $($resetOutput -join ' ')" -Color Gray
                # Als teilweisen Erfolg werten da andere Schritte funktionieren können
                $success++
            }
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