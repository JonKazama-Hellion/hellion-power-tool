# ===================================================================
# CONFIG UTILITIES MODULE
# Hellion Power Tool v7.1.5.3 "Baldur" - Modular Version
# ===================================================================

function Import-Configuration {
    <#
    .SYNOPSIS
    Lädt die Konfiguration aus der settings.json Datei
    
    .DESCRIPTION
    Diese Funktion lädt die Konfigurationsdaten aus config/settings.json
    und macht sie als globale Variablen verfügbar.
    #>
    
    $configPath = Join-Path $script:RootPath "config\settings.json"
    
    if (-not (Test-Path $configPath)) {
        Write-Log "[WARNING] Keine Konfigurationsdatei gefunden: $configPath" -Color Yellow
        Write-Log "[INFO] Verwende Standard-Konfiguration" -Color Gray
        return Get-DefaultConfiguration
    }
    
    try {
        Write-Log "[*] Lade Konfiguration aus: config/settings.json" -Level "DEBUG"
        
        $configContent = Get-Content $configPath -Raw -Encoding UTF8
        $config = $configContent | ConvertFrom-Json
        
        # Validiere Konfiguration
        if (-not $config.version) {
            Write-Log "[WARNING] Ungültige Konfigurationsdatei - keine Version gefunden" -Color Yellow
            return Get-DefaultConfiguration
        }
        
        Write-Log "[OK] Konfiguration geladen - Version: $($config.version) '$($config.codename)'" -Color Green
        
        # Setze globale Variablen basierend auf Konfiguration
        Set-ConfigurationVariables $config
        
        return $config
        
    } catch {
        Write-Log "[ERROR] Fehler beim Laden der Konfiguration: $($_.Exception.Message)" -Color Red
        Write-Log "[INFO] Verwende Standard-Konfiguration als Fallback" -Color Gray
        return Get-DefaultConfiguration
    }
}

function Get-DefaultConfiguration {
    <#
    .SYNOPSIS
    Gibt die Standard-Konfiguration zurück
    #>
    
    return @{
        version = "7.1.5.3"
        codename = "Baldur"
        debug_mode = $false
        auto_update = $true
        log_level = "INFO"
        startup_check = $true
        script_name = "hellion_tool_main.ps1"
        
        user_settings = @{
            explain_mode = $true
            visual_mode = $false
            detailed_logging = $false
            auto_approve_cleanup = $false
        }
        
        features = @{
            sfc_enabled = $false
            dism_enabled = $true
            checkdisk_enabled = $true
            winget_enabled = $true
            system_restore = $true
            driver_analysis = $true
            dll_integrity_check = $true
            bloatware_detection = $true
            unused_programs_analysis = $true
            network_tools = $true
            auto_mode = $true
        }
        
        modules = @{
            enabled = $true
            debug_loading = $false
            load_all = $true
            excluded_modules = @()
        }
        
        powershell = @{
            prefer_pwsh = $true
            execution_policy = "Bypass"
            no_profile = $true
        }
        
        logging = @{
            startup_log = $true
            error_log = $true
            debug_log = $false
            trace_log = $false
            max_log_size_mb = 50
            log_rotation = $true
        }
    }
}

function Set-ConfigurationVariables {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    # Setze Script-Level Variablen basierend auf Konfiguration
    if ($Config.user_settings) {
        if ($Config.user_settings.explain_mode) {
            $script:ExplainMode = $Config.user_settings.explain_mode
        }
        
        if ($Config.user_settings.auto_approve_cleanup) {
            $script:AutoApproveCleanup = $Config.user_settings.auto_approve_cleanup
        }
        
        if ($Config.user_settings.detailed_logging) {
            Write-Log "[CONFIG] Detailed Logging aktiviert" -Level "DEBUG"
        }
    }
    
    # Feature Flags setzen
    if ($Config.features) {
        $script:ConfigFeatures = $Config.features
        Write-Log "[CONFIG] Feature-Flags geladen: $($Config.features.Keys -join ', ')" -Level "DEBUG"
    }
    
    # Modul-Konfiguration
    if ($Config.modules) {
        $script:ConfigModules = $Config.modules
        if ($Config.modules.debug_loading) {
            Write-Log "[CONFIG] Debug-Loading für Module aktiviert" -Level "DEBUG"
        }
    }
    
    Write-Log "[CONFIG] Konfigurationsvariablen gesetzt" -Level "DEBUG"
}

function Test-FeatureEnabled {
    <#
    .SYNOPSIS
    Prüft ob ein Feature aktiviert ist
    
    .PARAMETER FeatureName
    Der Name des Features zu prüfen
    
    .EXAMPLE
    if (Test-FeatureEnabled "winget_enabled") {
        # Winget ist aktiviert
    }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName
    )
    
    if ($script:ConfigFeatures -and $script:ConfigFeatures.$FeatureName) {
        return $script:ConfigFeatures.$FeatureName
    }
    
    # Standard: Features sind aktiviert wenn nicht explizit deaktiviert
    return $true
}

function Get-ConfigValue {
    <#
    .SYNOPSIS
    Holt einen spezifischen Konfigurationswert
    
    .PARAMETER Path
    Der Pfad zum Konfigurationswert (z.B. "user_settings.explain_mode")
    
    .PARAMETER Default
    Standard-Wert wenn Konfiguration nicht gefunden
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        $Default = $null
    )
    
    try {
        $pathParts = $Path -split '\.'
        $current = $script:Config
        
        foreach ($part in $pathParts) {
            if ($current -and $current.PSObject.Properties.Name -contains $part) {
                $current = $current.$part
            } else {
                return $Default
            }
        }
        
        return $current
        
    } catch {
        Write-Log "[WARNING] Fehler beim Abrufen des Konfigurationswerts '$Path': $($_.Exception.Message)" -Level "DEBUG"
        return $Default
    }
}

# Export functions for dot-sourcing
Write-Verbose "Config-Utils Module loaded: Import-Configuration, Get-DefaultConfiguration, Set-ConfigurationVariables, Test-FeatureEnabled, Get-ConfigValue"