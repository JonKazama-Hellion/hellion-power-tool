# ===================================================================
# BLOATWARE DETECTION MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Get-BloatwareDatabase {
    <#
    .SYNOPSIS
    Liefert eine umfassende Datenbank bekannter Bloatware-Programme
    
    .DESCRIPTION
    Diese Funktion definiert bekannte Bloatware, Toolbars, Trial-Software und 
    unerwuenschte OEM-Software basierend auf Programmnamen-Patterns.
    Antiviren-Software wird NICHT als Bloatware klassifiziert (User-Choice).
    #>
    
    return @{
        # Browser-Hijacker und Toolbars (hohe Prioritaet)
        "BrowserHijacker" = @(
            "*toolbar*", "*search*protect*", "*browser*hijack*", "*searchassist*", 
            "*conduit*", "*babylon*", "*ask toolbar*", "*mystart*", "*websearcher*",
            "*search*bar*", "*findwide*", "*chromium*", "*sweet*page*"
        )
        
        # Adware und PUPs (Potentially Unwanted Programs)
        "Adware" = @(
            "*adware*", "*spyware*", "*malware*", "*bundlore*", "*installcore*",
            "*softonic*", "*opencandy*", "*crossrider*", "*multiplug*", "*adpeak*",
            "*superfish*", "*shopperz*", "*couponbar*", "*pricegong*", "*savings*bull*"
        )
        
        # Bekannte Bloatware/Junkware
        "Junkware" = @(
            "*registry*clean*", "*pc*speed*", "*driver*update*", "*system*care*",
            "*advanced*system*", "*pc*optimizer*", "*registry*fix*", "*speed*up*",
            "*pc*clean*", "*tune*up*", "*boost*", "*repair*tool*", "*pc*maintenance*",
            "*ccleaner*toolbar*", "*wise*care*", "*iobit*", "*glary*", "*auslogics*",
            "*clean*master*", "*registry*mechanic*", "*system*mechanic*"
        )
        
        # Trial/Demo Software (zeitbegrenzt)
        "TrialSoftware" = @(
            "*trial*", "*demo*", "*evaluation*", "*30*day*", "*free*trial*"
        )
        
        # OEM Bloatware (Hersteller-Software)
        "OEMBloatware" = @(
            "*dell*toolbar*", "*hp*smart*", "*lenovo*", "*acer*", "*asus*",
            "*toshiba*", "*sony*", "*gateway*", "*packard*bell*", "*fujitsu*"
        )
        
        # Gaming/Streaming Bloatware
        "GamingBloatware" = @(
            "*wildtangent*", "*gamelauncher*", "*bigfish*", "*real*arcade*"
        )
        
        # Office/Productivity Bloatware
        "OfficeBloatware" = @(
            "*office*trial*", "*office*starter*", "*works*", "*microsoft*office*60*"
        )
    }
}

function Test-IsBloatware {
    <#
    .SYNOPSIS
    Prueft ob ein Programm als Bloatware klassifiziert werden sollte
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProgramName
    )
    
    $result = @{
        "IsBloatware" = $false
        "Category" = ""
        "Reason" = ""
        "Severity" = "Low"
    }
    
    # Wichtige Software NICHT als Bloatware behandeln
    $essentialSoftware = @(
        "*windows*", "*microsoft*visual*", "*net*framework*", "*runtime*",
        "*driver*", "*intel*", "*nvidia*", "*amd*", "*realtek*", "*audio*",
        "*chipset*", "*directx*", "*redistributable*", "*security*update*",
        "*mozilla*maintenance*", "*firefox*", "*chrome*maintenance*", "*edge*",
        "*powertoys*", "*microsoft*power*", "*windows*terminal*", "*vscode*", "*vs*code*"
    )
    
    foreach ($essential in $essentialSoftware) {
        if ($ProgramName -like $essential) {
            return $result  # Nicht als Bloatware klassifizieren
        }
    }
    
    # Antiviren-Software explizit NICHT als Bloatware - User Choice!
    $antivirusSoftware = @(
        "*antivir*", "*avast*", "*avg*", "*avira*", "*kaspersky*", "*norton*",
        "*mcafee*", "*bitdefender*", "*trend*micro*", "*eset*", "*malware*bytes*"
    )
    
    foreach ($av in $antivirusSoftware) {
        if ($ProgramName -like $av) {
            return $result  # AV-Software nicht als Bloatware
        }
    }
    
    $bloatwareDB = Get-BloatwareDatabase
    
    # Normalisiere Programmnamen fuer bessere Erkennung
    $normalizedName = $ProgramName.ToLower().Trim()
    
    # Pruefe gegen Bloatware-Kategorien
    foreach ($category in $bloatwareDB.Keys) {
        foreach ($pattern in $bloatwareDB[$category]) {
            if ($normalizedName -like $pattern.ToLower()) {
                Write-Log "Bloatware-Match gefunden: $ProgramName matches $pattern in $category" -Level "DEBUG"
                $result.IsBloatware = $true
                $result.Category = $category
                $result.Reason = "Pattern match: $pattern"
                
                # Schweregrad basierend auf Kategorie
                switch ($category) {
                    "BrowserHijacker" { $result.Severity = "High" }
                    "Adware" { $result.Severity = "High" }
                    "Junkware" { $result.Severity = "Medium" }
                    "TrialSoftware" { $result.Severity = "Low" }
                    "OEMBloatware" { $result.Severity = "Medium" }
                    "GamingBloatware" { $result.Severity = "Low" }
                    "OfficeBloatware" { $result.Severity = "Low" }
                    default { $result.Severity = "Medium" }
                }
                
                break
            }
        }
        if ($result.IsBloatware) { break }
    }
    
    return $result
}

function Get-BloatwarePrograms {
    <#
    .SYNOPSIS
    Analysiert installierte Programme auf Bloatware
    
    .DESCRIPTION
    Diese Funktion durchsucht alle installierten Programme im System und 
    klassifiziert sie als potenzielle Bloatware basierend auf bekannten Mustern.
    #>
    
    Write-Log "`n[*] --- BLOATWARE ERKENNUNG ---" -Color Cyan
    Write-Log "[*] Analysiere installierte Programme auf Bloatware..." -Color Gray
    
    $bloatwarePrograms = @()
    $allPrograms = @()
    
    try {
        # Programme aus verschiedenen Quellen sammeln
        Write-Log "[*] Sammle installierte Programme..." -Color Blue
        
        # 1. Windows Apps (Modern Apps / UWP)
        try {
            $modernApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -notlike "Microsoft.*" -and 
                $_.Name -notlike "Windows.*" -and
                $_.PublisherId -ne "8wekyb3d8bbwe"  # Microsoft Publisher ID
            }
            
            foreach ($app in $modernApps) {
                $allPrograms += [PSCustomObject]@{
                    Name = $app.Name
                    DisplayName = $app.PackageFullName
                    Publisher = $app.PublisherId
                    Version = $app.Version
                    InstallDate = "Unknown"
                    Size = 0
                    Source = "ModernApp"
                }
            }
        } catch {
            Write-Log "[WARNING] Modern Apps konnten nicht abgerufen werden" -Color Yellow
        }
        
        # 2. Registry-basierte Programme (x64)
        try {
            $regPrograms64 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne "" }
            
            foreach ($prog in $regPrograms64) {
                $allPrograms += [PSCustomObject]@{
                    Name = $prog.DisplayName
                    DisplayName = $prog.DisplayName
                    Publisher = $prog.Publisher
                    Version = $prog.DisplayVersion
                    InstallDate = $prog.InstallDate
                    Size = if ($prog.EstimatedSize) { [math]::Round($prog.EstimatedSize / 1024, 2) } else { 0 }
                    Source = "Registry64"
                }
            }
        } catch {
            Write-Log "[WARNING] 64-Bit Programme konnten nicht abgerufen werden" -Color Yellow
        }
        
        # 3. Registry-basierte Programme (x86)
        try {
            if (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\") {
                $regPrograms32 = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne "" }
                
                foreach ($prog in $regPrograms32) {
                    $allPrograms += [PSCustomObject]@{
                        Name = $prog.DisplayName
                        DisplayName = $prog.DisplayName
                        Publisher = $prog.Publisher
                        Version = $prog.DisplayVersion
                        InstallDate = $prog.InstallDate
                        Size = if ($prog.EstimatedSize) { [math]::Round($prog.EstimatedSize / 1024, 2) } else { 0 }
                        Source = "Registry32"
                    }
                }
            }
        } catch {
            Write-Log "[WARNING] 32-Bit Programme konnten nicht abgerufen werden" -Color Yellow
        }
        
        $totalPrograms = $allPrograms.Count
        Write-Log "[*] $totalPrograms Programme gefunden, analysiere auf Bloatware..." -Color Gray
        
        if ($totalPrograms -eq 0) {
            Write-Log "[WARNING] Keine Programme gefunden - moeglicherweise Berechtigungsproblem" -Color Yellow
            return @()
        }
        
        # Duplikate entfernen (basierend auf Name)
        $uniquePrograms = $allPrograms | Sort-Object Name -Unique
        Write-Log "[*] $($uniquePrograms.Count) einzigartige Programme nach Duplikat-Entfernung" -Color Gray
        
        # Analysiere jedes Programm
        $progressCount = 0
        foreach ($program in $uniquePrograms) {
            $progressCount++
            
            if ($progressCount % 50 -eq 0) {
                Write-Log "[PROGRESS] Analysiere Programm $progressCount von $($uniquePrograms.Count)..." -Color Gray
            }
            
            $programName = $program.Name
            if (-not $programName -or $programName.Trim() -eq "") {
                continue
            }
            
            # Bloatware-Test
            $bloatwareTest = Test-IsBloatware -ProgramName $programName
            
            if ($bloatwareTest.IsBloatware) {
                $severityColor = switch ($bloatwareTest.Severity) {
                    "High" { "Red" }
                    "Medium" { "Yellow" }
                    "Low" { "Gray" }
                    default { "White" }
                }
                
                $bloatwareObject = [PSCustomObject]@{
                    "Name" = $programName
                    "Publisher" = $program.Publisher
                    "Version" = $program.Version
                    "Category" = $bloatwareTest.Category
                    "Reason" = $bloatwareTest.Reason
                    "Severity" = $bloatwareTest.Severity
                    "InstallDate" = $program.InstallDate
                    "Size" = $program.Size
                    "Source" = $program.Source
                }
                
                $bloatwarePrograms += $bloatwareObject
                
                Write-Log "Bloatware erkannt: $programName [$($bloatwareTest.Category)] - $($bloatwareTest.Severity)" -Level "DEBUG"
            }
        }
        
        # Ergebnisse verarbeiten und anzeigen
        $bloatwareArray = @($bloatwarePrograms)
        $bloatwareCount = $bloatwareArray.Length
        
        if ($bloatwareCount -eq 0) {
            Write-Log "[OK] Keine offensichtliche Bloatware gefunden" -Color Green
            return @()
        } else {
            # Sortiere nach Schweregrad und Name
            $bloatwareArray = $bloatwareArray | Sort-Object @{
                Expression = {
                    switch ($_.Severity) {
                        "High" { 1 }
                        "Medium" { 2 }
                        "Low" { 3 }
                        default { 4 }
                    }
                }
            }, Name
            
            # Statistiken
            $highSeverityArray = @($bloatwareArray | Where-Object { $_.Severity -eq "High" })
            $mediumSeverityArray = @($bloatwareArray | Where-Object { $_.Severity -eq "Medium" })
            $lowSeverityArray = @($bloatwareArray | Where-Object { $_.Severity -eq "Low" })
            
            $highCount = if ($highSeverityArray) { $highSeverityArray.Length } else { 0 }
            $mediumCount = if ($mediumSeverityArray) { $mediumSeverityArray.Length } else { 0 }
            $lowCount = if ($lowSeverityArray) { $lowSeverityArray.Length } else { 0 }
            
            # Sichere Count-Abfrage
            $bloatwareCount = ($bloatwareArray | Measure-Object).Count
            
            # Ergebnisse anzeigen
            Write-Host "[WARNING] $bloatwareCount Bloatware-Programme gefunden:" -ForegroundColor Yellow
            Write-Host "  [HIGH] $highCount kritische Programme" -ForegroundColor Red
            Write-Host "  [MEDIUM] $mediumCount bedenkliche Programme" -ForegroundColor Yellow
            Write-Host "  [LOW] $lowCount weniger kritische Programme" -ForegroundColor Gray
            
            # Zeige Top 10 Bloatware
            $displayCount = [Math]::Min(10, $bloatwareCount)
            Write-Host "`n[*] Top $displayCount Bloatware-Programme:" -ForegroundColor Cyan
            
            for ($i = 0; $i -lt $displayCount; $i++) {
                $prog = $bloatwareArray[$i]
                
                $severityColor = switch ($prog.Severity) {
                    "High" { "Red" }
                    "Medium" { "Yellow" }
                    "Low" { "Gray" }
                    default { "White" }
                }
                
                $sizeInfo = if ($prog.Size -gt 0) { " ($($prog.Size) MB)" } else { "" }
                $publisherInfo = if ($prog.Publisher) { " by $($prog.Publisher)" } else { "" }
                $versionInfo = if ($prog.Version) { " v$($prog.Version)" } else { "" }
                
                Write-Host "  [$($i+1)] " -ForegroundColor White -NoNewline
                Write-Host "$($prog.Name)" -ForegroundColor $severityColor -NoNewline
                Write-Host "$publisherInfo$versionInfo$sizeInfo" -ForegroundColor Gray
                Write-Host "      Kategorie: $($prog.Category) | Grund: $($prog.Reason)" -ForegroundColor DarkGray
                
                if ($prog.InstallDate -and $prog.InstallDate -ne "Unknown") {
                    try {
                        $installDate = [DateTime]::ParseExact($prog.InstallDate, "yyyyMMdd", $null)
                        Write-Host "      Installiert: $($installDate.ToString('yyyy-MM-dd'))" -ForegroundColor DarkGray
                    } catch {
                        # Ignore date parsing errors
                    }
                }
            }
            
            if ($bloatwareCount -gt $displayCount) {
                $moreCount = $bloatwareCount - $displayCount
                Write-Host "  [INFO] ... und $moreCount weitere Bloatware-Programme" -ForegroundColor Gray
            }
            
            # Geschaetzte Gesamtgroesse berechnen
            $totalBloatSize = 0
            $bloatwareArray | ForEach-Object {
                if ($_.Size -gt 0) {
                    $totalBloatSize += $_.Size
                }
            }
            
            if ($totalBloatSize -gt 0) {
                Write-Host "`n[INFO] Geschaetzte Bloatware-Groesse: $([math]::Round($totalBloatSize, 2)) MB ($([math]::Round($totalBloatSize/1024, 2)) GB)" -ForegroundColor Yellow
            }
            
            # Empfehlungen
            Write-Host "`n[EMPFEHLUNG] Bloatware manuell pruefen und unerwuenschte Programme deinstallieren" -ForegroundColor Cyan
            Write-Host "[HINWEIS] Antiviren-Software wurde NICHT als Bloatware klassifiziert (User Choice)" -ForegroundColor Green
        }
        
        return $bloatwareArray
        
    } catch {
        Add-Error "Bloatware-Erkennung fehlgeschlagen" $_.Exception.Message
        return @()
    }
}

function Get-UnusedPrograms {
    <#
    .SYNOPSIS
    Erweiterte Analyse ungenutzter Programme mit Bloatware-Erkennung
    #>
    
    Write-Log "`n[*] --- UNGENUTZTE PROGRAMME ANALYSIEREN ---" -Color Cyan
    Write-Log "[*] Analysiere installierte Programme auf Nutzung und Bloatware..." -Color Blue
    
    try {
        $unusedPrograms = @()
        $allPrograms = @()
        
        # Programme aus Registry sammeln
        $regKeys = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($regKey in $regKeys) {
            if (Test-Path $regKey.Replace('\*', '')) {
                $programs = Get-ItemProperty $regKey -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne "" }
                $allPrograms += $programs
            }
        }
        
        Write-Log "[*] $($allPrograms.Count) Programme gefunden, analysiere..." -Color Gray
        
        # Bloatware-Patterns fuer schnelle Erkennung
        $bloatwarePatterns = @(
            "*toolbar*", "*search*protect*", "*adware*", "*trial*", "*demo*",
            "*registry*clean*", "*pc*speed*", "*driver*update*", "*system*care*",
            "*advanced*system*", "*pc*optimizer*", "*tune*up*", "*boost*",
            "*wildtangent*", "*gamelauncher*", "*bigfish*", "*ask*"
        )
        
        foreach ($program in $allPrograms) {
            $programName = $program.DisplayName
            $publisher = $program.Publisher
            $installDate = $program.InstallDate
            $size = if ($program.EstimatedSize) { [math]::Round($program.EstimatedSize / 1024, 2) } else { 0 }
            
            # Pruefe auf Bloatware-Patterns
            foreach ($pattern in $bloatwarePatterns) {
                if ($programName -like $pattern) {
                    $reason = "Potentielle Bloatware"
                    $severity = "Medium"
                    break
                }
            }
            
            # Installationsdatum-basierte Analyse
            if ($installDate) {
                try {
                    $installDateTime = [DateTime]::ParseExact($installDate, "yyyyMMdd", $null)
                    $daysSinceInstall = (Get-Date).Subtract($installDateTime).TotalDays
                    
                    if ($daysSinceInstall -gt 180) {  # 6+ Monate alt
                        if (-not $reason) {
                            $reason = "Lange nicht verwendet (>6 Monate)"
                            $severity = "Low"
                        }
                    }
                } catch {
                    # Datum konnte nicht geparst werden - ignorieren
                }
            }
            
            # Groesse-basierte Analyse
            if ($size -gt 500) {  # > 500 MB
                if ($reason -eq "Potentielle Bloatware") {
                    $reason += " (Gross: $size MB)"
                    $severity = "High"
                }
            }
            
            # Fuege zu Ergebnissen hinzu wenn Grund gefunden
            if ($reason) {
                $unusedPrograms += [PSCustomObject]@{
                    Name = $programName
                    Publisher = $publisher
                    Size = $size
                    InstallDate = $installDate
                    Reason = $reason
                    Severity = $severity
                }
            }
        }
        
        # Ergebnisse sortieren und anzeigen
        $unusedPrograms = $unusedPrograms | Sort-Object @{
            Expression = {
                switch ($_.Severity) {
                    "High" { 1 }
                    "Medium" { 2 }
                    "Low" { 3 }
                    default { 4 }
                }
            }
        }, Size -Descending
        
        if ($unusedPrograms.Count -eq 0) {
            Write-Log "[OK] Keine offensichtlich ungenutzten oder bedenklichen Programme gefunden" -Color Green
            return @()
        }
        
        Write-Log "[*] $($unusedPrograms.Count) potentiell problematische Programme gefunden:" -Color Yellow
        
        # Top 15 anzeigen
        $displayCount = [Math]::Min(15, $unusedPrograms.Count)
        for ($i = 0; $i -lt $displayCount; $i++) {
            $prog = $unusedPrograms[$i]
            
            $severityColor = switch ($prog.Severity) {
                "High" { "Red" }
                "Medium" { "Yellow" }
                "Low" { "Gray" }
                default { "White" }
            }
            
            $sizeInfo = if ($prog.Size -gt 0) { " ($($prog.Size) MB)" } else { "" }
            $publisherInfo = if ($prog.Publisher) { " - $($prog.Publisher)" } else { "" }
            
            Write-Host "  [$($i+1)] " -ForegroundColor White -NoNewline
            Write-Host "$($prog.Name)" -ForegroundColor $severityColor -NoNewline
            Write-Host "$publisherInfo$sizeInfo" -ForegroundColor Gray
            Write-Host "      $($prog.Reason)" -ForegroundColor DarkGray
        }
        
        if ($unusedPrograms.Count -gt $displayCount) {
            $moreCount = $unusedPrograms.Count - $displayCount
            Write-Host "  [INFO] ... und $moreCount weitere Programme" -ForegroundColor Gray
        }
        
        # Statistiken
        $totalSize = ($unusedPrograms | Measure-Object -Property Size -Sum).Sum
        $highPriorityCount = ($unusedPrograms | Where-Object { $_.Severity -eq "High" }).Count
        
        Write-Host "`n[INFO] Geschaetzte Gesamtgroesse: $([math]::Round($totalSize, 2)) MB ($([math]::Round($totalSize/1024, 2)) GB)" -ForegroundColor Cyan
        if ($highPriorityCount -gt 0) {
            Write-Host "[WARNING] $highPriorityCount Programme mit hoher Prioritaet zur Deinstallation" -ForegroundColor Red
        }
        
        Write-Host "`n[EMPFEHLUNG] Programme manuell pruefen und unerwuenschte Software deinstallieren" -ForegroundColor Green
        
        return $unusedPrograms
        
    } catch {
        Add-Error "Analyse ungenutzter Programme fehlgeschlagen" $_.Exception.Message
        return @()
    }
}

# Export functions for dot-sourcing
Write-Verbose "Bloatware-Detection Module loaded: Get-BloatwareDatabase, Test-IsBloatware, Get-BloatwarePrograms, Get-UnusedPrograms"