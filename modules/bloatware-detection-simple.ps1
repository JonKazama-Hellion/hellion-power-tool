# =============================================================================
# SIMPLE BLOATWARE DETECTION MODULE - KOMPLETT NEU
# Einfach, robust, ohne komplexe Verschachtelung
# =============================================================================

function Get-SimpleBloatwarePrograms {
    Write-Host ""
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "                >>> BLOATWARE ERKENNUNG (SIMPLE) <<<" -ForegroundColor White
    Write-Host "=============================================================================" -ForegroundColor Cyan
    Write-Host "Analysiere installierte Programme..." -ForegroundColor Yellow
    Write-Host ""
    
    # Erweiterte Bloatware-Patterns
    $bloatwarePatterns = @(
        # Browser-Hijacker & Toolbars
        "*toolbar*", "*search*protect*", "*ask*", "*conduit*", "*babylon*",
        
        # Adware & PUPs
        "*adware*", "*spyware*", "*bundlore*", "*softonic*", "*crossrider*",
        
        # System-"Optimizer" Bloatware
        "*registry*clean*", "*pc*speed*", "*driver*update*", "*system*care*",
        "*advanced*system*", "*pc*optimizer*", "*tune*up*", "*boost*",
        "*driver*booster*", "*smart*defrag*", "*uninstaller*pro*",
        
        # IObit Produkte (bekannte Bloatware)
        "*iobit*", "*driver*booster*", "*advanced*systemcare*", "*malware*fighter*",
        "*smart*defrag*", "*start*menu*", "*iobit*uninstaller*",
        
        # Andere bekannte Publisher
        "*glary*", "*auslogics*", "*wise*care*", "*ccleaner*toolbar*",
        "*baidu*", "*360*total*", "*pc*cleaner*", "*registry*mechanic*",
        
        # Trial & Demo Software
        "*trial*", "*demo*", "*evaluation*", "*30*day*", "*free*trial*",
        
        # Gaming Bloatware
        "*wildtangent*", "*gamelauncher*", "*bigfish*", "*real*arcade*"
    )
    
    # Software die NICHT als Bloatware gelten sollte
    $essentialSoftware = @(
        # Windows & Microsoft
        "*windows*", "*microsoft*", "*visual*c++*", "*net*framework*", "*runtime*", "*redistributable*",
        
        # Hardware-Treiber (legitim)
        "*intel*driver*", "*nvidia*driver*", "*amd*driver*", "*realtek*driver*",
        "*intel*graphics*", "*nvidia*graphics*", "*amd*graphics*", "*realtek*audio*",
        "*chipset*driver*", "*intel*management*", "*nvidia*control*", "*amd*software*",
        
        # Beliebte legitime Software
        "*firefox*", "*chrome*", "*edge*", "*7-zip*", "*winrar*", "*vlc*", "*notepad*",
        "steam", "*discord*", "*spotify*", "*obs*studio*", "*gimp*", "*blender*",
        
        # Entwickler-Tools
        "*visual*studio*", "*git*", "*python*", "*node*", "*java*development*"
    )
    
    try {
        Write-Information "[INFO] [*] Sammle Programme aus Registry..." -InformationAction Continue
        
        # Einfache Registry-Abfrage ohne Where-Object
        $allPrograms = @()
        
        # 64-bit Programme (Defender-safe Registry access)
        try {
            $uninstallPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
            if (Test-Path $uninstallPath) {
                $regItems = Get-ChildItem $uninstallPath -ErrorAction SilentlyContinue
                foreach ($item in $regItems) {
                    try {
                        $prog = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
                        if ($prog.DisplayName -and $prog.DisplayName -is [string] -and $prog.DisplayName.Length -gt 2) {
                            $allPrograms += $prog.DisplayName
                        }
                    } catch { }
                }
            }
        } catch { }
        
        # 32-bit Programme (Defender-safe Registry access)
        try {
            $wow64Path = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            if (Test-Path $wow64Path) {
                $regItems32 = Get-ChildItem $wow64Path -ErrorAction SilentlyContinue
                foreach ($item in $regItems32) {
                    try {
                        $prog = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
                        if ($prog.DisplayName -and $prog.DisplayName -is [string] -and $prog.DisplayName.Length -gt 2) {
                            $allPrograms += $prog.DisplayName
                        }
                    } catch { }
                }
            }
        } catch { }
        
        Write-Information "[INFO] [*] $($allPrograms.Count) Programme gefunden" -InformationAction Continue
        
        if ($allPrograms.Count -eq 0) {
            Write-Warning "Keine Programme gefunden"
            return
        }
        
        # Duplikate entfernen (einfach)
        $uniquePrograms = $allPrograms | Sort-Object -Unique
        Write-Information "[INFO] [*] $($uniquePrograms.Count) einzigartige Programme" -InformationAction Continue
        
        # Bloatware erkennen (einfach)
        $bloatwareFound = @()
        $debugMode = $false  # Debug-Modus deaktiviert
        
        foreach ($programName in $uniquePrograms) {
            # Debug: Zeige Programme mit "driver" oder "iobit" im Namen
            if ($debugMode -and ($programName -like "*driver*" -or $programName -like "*iobit*" -or $programName -like "*steam*")) {
                Write-Information "[INFO] [DEBUG] Prüfe: '$programName'" -InformationAction Continue
            }
            
            # Skip essentials
            $isEssential = $false
            foreach ($essential in $essentialSoftware) {
                if ($programName -like $essential) {
                    $isEssential = $true
                    if ($debugMode -and ($programName -like "*driver*" -or $programName -like "*iobit*")) {
                        Write-Information "[INFO] [DEBUG] '$programName' als Essential eingestuft (Pattern: $essential)" -InformationAction Continue
                    }
                    break
                }
            }
            if ($isEssential) { continue }
            
            # Check bloatware
            foreach ($pattern in $bloatwarePatterns) {
                if ($programName -like $pattern) {
                    $bloatwareFound += $programName
                    if ($debugMode) {
                        Write-Information "[INFO] [DEBUG] '$programName' als Bloatware erkannt (Pattern: $pattern)" -InformationAction Continue
                    }
                    break
                }
            }
        }
        
        # Ergebnisse anzeigen
        if ($bloatwareFound.Count -eq 0) {
            Write-Information "[OK] Keine offensichtliche Bloatware gefunden!" -InformationAction Continue
        } else {
            Write-Warning "$($bloatwareFound.Count) potenzielle Bloatware-Programme gefunden:"
            
            $displayCount = [Math]::Min(15, $bloatwareFound.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                Write-Information "[INFO]   [$($i+1)] $($bloatwareFound[$i])" -InformationAction Continue
            }
            
            if ($bloatwareFound.Count -gt $displayCount) {
                Write-Information "[INFO]   ... und $($bloatwareFound.Count - $displayCount) weitere" -InformationAction Continue
            }
            
            Write-Information "[INFO] `n[EMPFEHLUNG] Prüfe diese Programme und deinstalliere unerwünschte Software" -InformationAction Continue
        }
        
        return $bloatwareFound
        
    } catch {
        Write-Error "Bloatware-Erkennung fehlgeschlagen: $($_.Exception.Message)"
        return @()
    }
}

# Einfache Export-Funktion
Write-Verbose "Simple Bloatware-Detection Module loaded: Get-SimpleBloatwarePrograms"
