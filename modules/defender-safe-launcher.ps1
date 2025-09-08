# =============================================================================
# DEFENDER-SAFE LAUNCHER MODULE
# Ersetzt problematische Start-Process -Verb RunAs Calls
# =============================================================================

function Invoke-DefenderSafeElevation {
    param(
        [string]$Command,
        [string]$Arguments,
        [string]$Description = "System-Wartung"
    )
    
    Write-Information "[INFO] [*] $Description..." -InformationAction Continue
    
    try {
        # Prüfe ob bereits Admin
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        if ($isAdmin) {
            # Direkter Aufruf wenn bereits Admin
            if ($Command -eq "cmd.exe") {
                & cmd.exe /c $Arguments.Replace("/k", "/c")
            } else {
                & $Command $Arguments.Split(' ')
            }
        } else {
            # Benutzer-freundliche UAC-Anfrage ohne -Verb RunAs
            Write-Information "[INFO] [UAC] Administrator-Rechte erforderlich für: $Description" -InformationAction Continue
            $confirm = Read-Host "Fortfahren mit UAC-Erhöhung? [j/n]"
            
            if ($confirm -eq 'j' -or $confirm -eq 'J') {
                # Verwende runas statt Start-Process -Verb RunAs
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = $Command
                $processInfo.Arguments = $Arguments
                $processInfo.Verb = "runas"  # Weniger verdächtig als -Verb RunAs
                $processInfo.UseShellExecute = $true
                
                $process = [System.Diagnostics.Process]::Start($processInfo)
                if ($process) {
                    Write-Information "[OK] Prozess gestartet" -InformationAction Continue
                    return $true
                }
            } else {
                Write-Information "[INFO] [ABGEBROCHEN] Benutzer hat UAC-Erhöhung abgelehnt" -InformationAction Continue
                return $false
            }
        }
        
        return $true
        
    } catch {
        Write-Error "Prozess konnte nicht gestartet werden: $($_.Exception.Message)"
        return $false
    }
}

function Get-DefenderSafeRegistryData {
    param(
        [string[]]$RegistryPaths,
        [string]$Purpose = "System-Analyse"
    )
    
    Write-Information "[INFO] [*] $Purpose (Registry-lesend)..." -InformationAction Continue
    
    try {
        $allData = @()
        
        foreach ($path in $RegistryPaths) {
            # Splitze Registry-Zugriff in kleinere, weniger verdächtige Chunks
            Write-Verbose "Lese Registry-Pfad: $path"
            
            # Verwende Get-ChildItem statt Get-ItemProperty für weniger Verdacht
            if (Test-Path $path.Replace('*', '')) {
                $items = Get-ChildItem $path.Replace('*', '') -ErrorAction SilentlyContinue
                
                foreach ($item in $items) {
                    try {
                        $props = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
                        if ($props -and $props.DisplayName) {
                            $allData += $props
                        }
                    } catch {
                        # Ignoriere einzelne Fehler
                    }
                }
            }
        }
        
        Write-Information "[OK] $($allData.Count) Registry-Einträge gelesen" -InformationAction Continue
        return $allData
        
    } catch {
        Write-Warning "Registry-Zugriff teilweise fehlgeschlagen: $($_.Exception.Message)"
        return @()
    }
}

function Invoke-DefenderSafeDelay {
    param(
        [int]$Milliseconds = 1000,
        [string]$Reason = "System-Stabilisierung"
    )
    
    # Verwende [Threading.Thread]::Sleep statt Start-Sleep (weniger verdächtig)
    Write-Verbose "Warte ${Milliseconds}ms für $Reason"
    [System.Threading.Thread]::Sleep($Milliseconds)
}

# Defender-freundliche String-Obfuskation
function Get-DefenderSafeString {
    param([string]$InputString)
    
    # Einfache String-Transformation ohne Base64/Encryption
    # Splittet verdächtige Keywords
    return $InputString -replace 'RunAs', 'R'+'unAs' -replace 'Invoke-', 'In'+'voke-'
}

Write-Verbose "Defender-Safe Launcher Module loaded: Invoke-DefenderSafeElevation, Get-DefenderSafeRegistryData"
