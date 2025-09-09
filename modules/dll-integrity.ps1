# ===================================================================
# DLL INTEGRITY MODULE
# Hellion Power Tool - Modular Version
# ===================================================================

function Test-DLLIntegrity {
    Write-Log "`n[*] --- DLL INTEGRITAETS-PRUEFUNG ---" -Color Cyan
    Write-Log "Prueft kritische System- und Anwendungs-DLLs auf Vollstaendigkeit" -Color Yellow
    
    # Einfache Arrays für Ergebnisse
    $foundDLLs = @()
    $missingDLLs = @()
    
    # Kritische DLL-Listen (einfache Struktur)
    $vcpp2015_2022 = @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll")
    $vcpp2013 = @("msvcr120.dll", "msvcp120.dll")
    $vcpp2010 = @("msvcr100.dll", "msvcp100.dll")
    $vcpp2008 = @("msvcr90.dll", "msvcp90.dll")
    $vcpp2005 = @("msvcr80.dll", "msvcp80.dll")
    $dotnetCore = @("System.dll", "mscorlib.dll", "System.Core.dll", "System.Xml.dll")
    $directx = @("d3d9.dll", "d3d11.dll", "dxgi.dll", "xinput1_3.dll", "xinput1_4.dll")
    $windowsRuntime = @("kernel32.dll", "user32.dll", "gdi32.dll", "advapi32.dll", "ole32.dll")
    $audioMedia = @("winmm.dll", "dsound.dll", "mf.dll", "mfplat.dll")
    
    # Standard-Suchpfade
    $system32 = "$env:SystemRoot\System32"
    $syswow64 = "$env:SystemRoot\SysWOW64"
    $dotnetPath = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319"
    
    Write-Log "`nPruefe kritische DLL-Dateien..." -Color White
    
    $totalChecked = 0
    $totalFound = 0
    $totalMissing = 0
    
    # Separate Zähler für kritische vs. Low-Priority DLLs
    $criticalMissing = 0
    $lowPriorityMissing = 0
    
    # Visual C++ 2015-2022 (High Priority)
    Write-Log "`n[*] Visual C++ 2015-2022 (High Priority)" -Color Magenta
    foreach ($dll in $vcpp2015_2022) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $criticalMissing++  # VC++ 2015-2022 ist HIGH PRIORITY = Kritisch
            $missingDLLs += "$dll (Visual C++ 2015-2022)"
            Write-Log "    [X] $dll (FEHLT - HIGH PRIORITY)" -Color Red
        }
    }
    
    # Visual C++ 2013 (Low Priority)
    Write-Log "`n[*] Visual C++ 2013 (Low Priority)" -Color Magenta
    foreach ($dll in $vcpp2013) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $lowPriorityMissing++  # VC++ 2013 ist LOW PRIORITY
            $missingDLLs += "$dll (Visual C++ 2013)"
            Write-Log "    [X] $dll (FEHLT - LOW PRIORITY)" -Color Yellow
        }
    }
    
    # Visual C++ 2010 (Low Priority)
    Write-Log "`n[*] Visual C++ 2010 (Low Priority)" -Color Magenta
    foreach ($dll in $vcpp2010) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $lowPriorityMissing++  # VC++ 2010 ist LOW PRIORITY
            $missingDLLs += "$dll (Visual C++ 2010)"
            Write-Log "    [X] $dll (FEHLT - LOW PRIORITY)" -Color Yellow
        }
    }
    
    # .NET Framework (High Priority)
    Write-Log "`n[*] .NET Framework (High Priority)" -Color Magenta
    foreach ($dll in $dotnetCore) {
        $totalChecked++
        $found = $false
        
        $paths = @($dotnetPath, "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319")
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $criticalMissing++  # .NET Framework ist HIGH PRIORITY = Kritisch
            $missingDLLs += "$dll (.NET Framework)"
            Write-Log "    [X] $dll (FEHLT - HIGH PRIORITY)" -Color Red
        }
    }
    
    # DirectX/Gaming (Medium Priority)
    Write-Log "`n[*] DirectX/Gaming (Medium Priority)" -Color Magenta
    foreach ($dll in $directx) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $criticalMissing++  # DirectX ist HIGH PRIORITY = Kritisch
            $missingDLLs += "$dll (DirectX)"
            Write-Log "    [X] $dll (FEHLT - HIGH PRIORITY)" -Color Red
        }
    }
    
    # Windows Runtime (Critical Priority)
    Write-Log "`n[*] Windows Runtime (Critical Priority)" -Color Magenta
    foreach ($dll in $windowsRuntime) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $criticalMissing++  # Windows Runtime ist KRITISCH
            $missingDLLs += "$dll (Windows Runtime)"
            Write-Log "    [X] $dll (FEHLT - KRITISCH)" -Color Red
        }
    }
    
    # Audio/Media (Medium Priority)
    Write-Log "`n[*] Audio/Media (Medium Priority)" -Color Magenta
    foreach ($dll in $audioMedia) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $lowPriorityMissing++  # Audio/Media ist LOW PRIORITY
            $missingDLLs += "$dll (Audio/Media)"
            Write-Log "    [X] $dll (FEHLT - LOW PRIORITY)" -Color Yellow
        }
    }
    
    # Visual C++ 2008 (Low Priority)
    Write-Log "`n[*] Visual C++ 2008 (Low Priority)" -Color Magenta
    foreach ($dll in $vcpp2008) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $lowPriorityMissing++  # VC++ 2008 ist LOW PRIORITY
            $missingDLLs += "$dll (Visual C++ 2008)"
            Write-Log "    [X] $dll (FEHLT - LOW PRIORITY)" -Color Yellow
        }
    }
    
    # Visual C++ 2005 (Low Priority)
    Write-Log "`n[*] Visual C++ 2005 (Low Priority)" -Color Magenta
    foreach ($dll in $vcpp2005) {
        $totalChecked++
        $found = $false
        
        $paths = @($system32, $syswow64)
        foreach ($path in $paths) {
            $fullPath = Join-Path $path $dll
            if (Test-Path $fullPath -PathType Leaf) {
                $found = $true
                $totalFound++
                $foundDLLs += "$dll ($path)"
                Write-Log "    [OK] $dll" -Color Green
                break
            }
        }
        
        if (-not $found) {
            $totalMissing++
            $lowPriorityMissing++  # VC++ 2005 ist LOW PRIORITY
            $missingDLLs += "$dll (Visual C++ 2005)"
            Write-Log "    [X] $dll (FEHLT - LOW PRIORITY)" -Color Yellow
        }
    }
    
    # Zusammenfassung
    Write-Log "`n[*] --- DLL-PRUEFUNG ZUSAMMENFASSUNG ---" -Color Cyan
    Write-Log "Geprueft: $totalChecked DLLs" -Color White
    Write-Log "Gefunden: $totalFound DLLs" -Color Green
    Write-Log "Fehlend:  $totalMissing DLLs" -Color Red
    
    # Empfehlungen
    if ($totalMissing -gt 0) {
        Write-Log "`n[*] --- EMPFEHLUNGEN ---" -Color Yellow
        
        $vcppMissing = $missingDLLs | Where-Object { $_ -like "*Visual C++*" }
        $dotnetMissing = $missingDLLs | Where-Object { $_ -like "*.NET*" }
        $directxMissing = $missingDLLs | Where-Object { $_ -like "*DirectX*" }
        $windowsMissing = $missingDLLs | Where-Object { $_ -like "*Windows Runtime*" }
        
        if ($vcppMissing -and $vcppMissing.Count -gt 0) {
            Write-Log "• Visual C++ Redistributable installieren (https://aka.ms/vs/17/release/vc_redist.x64.exe)" -Color Yellow
            Write-Log "  [INFO] HINWEIS: VC++ 2015-2022 ist abwaerts kompatibel - aeltere Versionen meist unnoetig" -Color Cyan
        }
        
        if ($dotnetMissing -and $dotnetMissing.Count -gt 0) {
            Write-Log "• .NET Framework 4.8 installieren" -Color Yellow
        }
        
        if ($directxMissing -and $directxMissing.Count -gt 0) {
            Write-Log "• DirectX End-User Runtime installieren" -Color Yellow
        }
        
        if ($windowsMissing -and $windowsMissing.Count -gt 0) {
            Write-Log "[WARNING] KRITISCH: Windows-Systemdateien fehlen!" -Color Red
            Write-Log "   Fuehre 'sfc /scannow' als Administrator aus" -Color Red
        }
    }
    
    # Log-Datei erstellen
    try {
        if ($script:GenerateReport -and $script:LogDirectory) {
        $reportPath = Join-Path $script:LogDirectory "dll_integrity_report.txt"
        $report = "DLL INTEGRITAETS-BERICHT`nGeneriert am: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`nZUSAMMENFASSUNG:`n- Geprueft: $totalChecked DLLs`n- Gefunden: $totalFound DLLs`n- Fehlend: $totalMissing DLLs`n"
        
        if ($missingDLLs -and $missingDLLs.Count -gt 0) {
            $report += "`nFEHLENDE DLLs:`n"
            foreach ($missing in $missingDLLs) {
                $report += "- $missing`n"
            }
        }
        
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Log "`nBericht gespeichert: $reportPath" -Color Green
        }
    } catch {
        # GenerateReport Variable nicht verfuegbar - Report wird uebersprungen
    }
    
    # Erweiterte Erfolgsstatus-Bewertung
    if ($totalMissing -eq 0) {
        $script:ActionsPerformed += "DLL-Check (Alle DLLs vollstaendig)"
        Write-Log "`n[SUCCESS] DLL-Integritaetspruefung erfolgreich!" -Color Green
        return $true
    } elseif ($criticalMissing -eq 0) {
        # Nur Low-Priority DLLs fehlen - das ist OK!
        $script:ActionsPerformed += "DLL-Check (Kritische DLLs vollstaendig, $lowPriorityMissing Low-Priority DLLs fehlen)"
        Write-Log "`n[SUCCESS] DLL-Integritaetspruefung erfolgreich!" -Color Green
        Write-Log "[INFO] $lowPriorityMissing Low-Priority DLLs fehlen - System funktioniert normal" -Color Cyan
        if ($lowPriorityMissing -gt 0) {
            Write-Log "[TIPP] Fehlende Low-Priority DLLs werden nur bei speziellen Anwendungen benoetigt" -Color Gray
        }
        return $true
    } else {
        # Kritische DLLs fehlen - das ist ein echtes Problem!
        $script:ActionsPerformed += "DLL-Check ($criticalMissing kritische DLLs fehlend - PROBLEM)"
        Write-Log "`n[ERROR] DLL-Integritaetspruefung FEHLGESCHLAGEN!" -Color Red
        Write-Log "[ERROR] $criticalMissing KRITISCHE DLLs fehlen (System instabil)" -Color Red
        if ($lowPriorityMissing -gt 0) {
            Write-Log "[INFO] Zusaetzlich fehlen $lowPriorityMissing Low-Priority DLLs" -Color Yellow
        }
        return $false
    }
}

# Export functions for dot-sourcing
Write-Verbose "DLL-Integrity Module loaded: Test-DLLIntegrity"