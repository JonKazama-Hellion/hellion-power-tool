# ===================================================================
# LOGGING UTILITIES MODULE  
# Hellion Power Tool - Modular Version
# ===================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White",
        [switch]$NoConsole,
        [switch]$NoFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # In Log-Buffer schreiben (fuer spaeteren Abruf)
    $script:LogBuffer += $logEntry
    
    # Begrenzung des Log-Buffers auf 1000 Eintraege
    if ($script:LogBuffer.Count -gt 1000) {
        $script:LogBuffer = $script:LogBuffer[-500..-1]
    }
    
    # In Datei schreiben (immer aktiv im neuen System)
    if (-not $NoFile) {
        try {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {
            # Fehler beim Logging stillschweigend ignorieren
        }
    }
    
    # Konsolen-Ausgabe
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR" { 
                Write-Error $Message 
            }
            "WARNING" { 
                Write-Warning $Message 
            }
            "SUCCESS" { 
                Write-Information $Message -InformationAction Continue 
            }
            "DEBUG" { 
                # Only show DEBUG in Debug-Mode (1) or Developer-Mode (2)
                if (($null -ne $script:DebugLevel) -and ([int]$script:DebugLevel -ge 1)) {
                    Write-Information "[INFO] [DEBUG] $Message" -InformationAction Continue
                }
            }
            "VERBOSE" {
                # Only show VERBOSE in Developer-Mode (2)
                if (($null -ne $script:DebugLevel) -and ([int]$script:DebugLevel -ge 2)) {
                    Write-Information "[INFO] [VERBOSE] $Message" -InformationAction Continue
                }
            }
            "DEV" {
                # Only show DEV messages in Developer-Mode (2)
                if (($null -ne $script:DebugLevel) -and ([int]$script:DebugLevel -ge 2)) {
                    Write-Information "[INFO] [DEV] $Message" -InformationAction Continue
                }
            }
            "TRACE" {
                # Only show TRACE in Developer-Mode (2) 
                if ($script:DebugMode -ge 2) {
                    Write-Information "[INFO] [TRACE] $Message" -InformationAction Continue
                }
            }
            default { 
                Write-Information $Message -InformationAction Continue 
            }
        }
    }
}

function Clear-OldLogs {
    try {
        $logFiles = Get-ChildItem "$script:LogPath\*.log" -ErrorAction SilentlyContinue
        $oldLogs = $logFiles | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
        
        if ($oldLogs) {
            $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Log "Alte Logs bereinigt: $($oldLogs.Count) Dateien" -Level "DEBUG"
        }
        
        # Zusaetzlich: Sehr grosse Log-Dateien komprimieren (>10MB)
        $largeLogs = $logFiles | Where-Object { $_.Length -gt 10MB }
        foreach ($largeLog in $largeLogs) {
            try {
                $compressedName = $largeLog.FullName -replace '\.log$', '_compressed.zip'
                Compress-Archive -Path $largeLog.FullName -DestinationPath $compressedName -Force
                Remove-Item $largeLog.FullName -Force
                Write-Log "Grosse Log-Datei komprimiert: $($largeLog.Name)" -Level "DEBUG"
            } catch {
                # Komprimierung fehlgeschlagen - ignorieren
            }
        }
    } catch {
        # Log-Bereinigung fehlgeschlagen - stillschweigend ignorieren
    }
}

function Get-LogSummary {
    $summary = @{
        "LogFile" = $script:LogFile
        "LogSize" = if (Test-Path $script:LogFile) { 
            [math]::Round((Get-Item $script:LogFile).Length / 1KB, 2) 
        } else { 0 }
        "BufferEntries" = $script:LogBuffer.Count
        "ErrorCount" = $script:Errors.Count
        "WarningCount" = $script:Warnings.Count
        "SuccessCount" = $script:SuccessActions.Count
    }
    return $summary
}

function Add-Error {
    param([string]$Message, [string]$Details = "")
    
    $script:Errors += @{
        "Message" = $Message
        "Details" = $Details
        "Timestamp" = Get-Date
        "Function" = (Get-PSCallStack)[1].FunctionName
    }
    
    Write-Log $Message -Level "ERROR"
    if ($Details) {
        Write-Log "    Details: $Details" -Level "ERROR"
    }
}

function Add-Warning {
    param([string]$Message, [string]$Details = "")
    
    $script:Warnings += @{
        "Message" = $Message
        "Details" = $Details
        "Timestamp" = Get-Date
        "Function" = (Get-PSCallStack)[1].FunctionName
    }
    
    Write-Log $Message -Level "WARNING"
    if ($Details) {
        Write-Log "    Details: $Details" -Level "WARNING"
    }
}

function Add-Success {
    param([string]$Message, [string]$Details = "")
    
    $script:SuccessActions += @{
        "Message" = $Message
        "Details" = $Details
        "Timestamp" = Get-Date
        "Function" = (Get-PSCallStack)[1].FunctionName
    }
    
    Write-Log $Message -Level "SUCCESS"
    if ($Details) {
        Write-Log "    Details: $Details" -Level "SUCCESS"
    }
}

function Initialize-Logging {
    param(
        [string]$LogDirectory = "$env:TEMP\HellionPowerTool",
        [switch]$DetailedLogging = $false
    )
    
    # Create log directory if it doesn't exist
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    
    # Set script variables
    $script:LogPath = $LogDirectory
    $script:LogFile = Join-Path $LogDirectory "hellion_tool_$(Get-Date -Format 'yyyy-MM-dd').log"
    $script:DetailedLogging = $DetailedLogging
    
    # Initialize collections if they don't exist
    if (-not $script:LogBuffer) { $script:LogBuffer = @() }
    if (-not $script:Errors) { $script:Errors = @() }
    if (-not $script:Warnings) { $script:Warnings = @() }
    if (-not $script:SuccessActions) { $script:SuccessActions = @() }
    
    Write-Log "Logging initialized: $script:LogFile" -Level "DEBUG"
}

# Export functions for dot-sourcing
Write-Verbose "Logging-Utils Module loaded: Write-Log, Add-Error, Add-Warning, Add-Success, Get-LogSummary, Clear-OldLogs, Initialize-Logging"
