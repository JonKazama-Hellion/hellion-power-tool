# ===================================================================
# HELLION POWER TOOL - GUI VERSION v8.0.0.0 "Jörmungandr"
# WPF Dark Mode Interface
# Liegt in src/ — START.bat im Root startet die GUI
# ===================================================================

param(
    [switch]$DebugMode,
    [switch]$DevMode,
    [int]$ForceDebugLevel = -1
)

# --- Admin Check ---
# PS2EXE-kompilierte EXE hat eigenes requireAdmin-Manifest, daher Elevation nur im Script-Modus
$script:IsExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName -notmatch '(?i)powershell|pwsh'
if (-not $script:IsExe -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argStr = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$($MyInvocation.MyCommand.Definition)`""
    if ($DebugMode)             { $argStr += " -DebugMode" }
    if ($DevMode)               { $argStr += " -DevMode" }
    if ($ForceDebugLevel -ge 0) { $argStr += " -ForceDebugLevel $ForceDebugLevel" }
    $exe = if (Get-Command pwsh -EA SilentlyContinue) { "pwsh" }
           elseif (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") { "C:\Program Files\PowerShell\7\pwsh.exe" }
           else { "PowerShell" }
    Start-Process $exe -ArgumentList $argStr -Verb RunAs -WindowStyle Hidden
    exit
}

# --- Encoding (noConsole-EXE hat kein Console-Handle, daher try/catch) ---
$OutputEncoding = [System.Text.Encoding]::UTF8
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# --- WPF Assemblies ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
# System.Windows.Shapes (Ellipse, Rectangle etc.) explizit laden
[void][System.Windows.Shapes.Ellipse]

# --- Prerequisite-Check ---
function Test-Prerequisites {
    $results = @{ OK = $true; Messages = @() }

    # .NET Framework 4.8+ Check (Release >= 528040)
    $netRelease = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -EA SilentlyContinue).Release
    if (-not $netRelease -or $netRelease -lt 528040) {
        $results.OK = $false
        $results.Messages += @{ Text = ".NET Framework 4.8 nicht gefunden — GUI benötigt .NET 4.8+"; Level = "ERROR" }
    } else {
        $results.Messages += @{ Text = ".NET Framework 4.8+ vorhanden"; Level = "OK" }
    }

    # PowerShell Version
    $psVer = $PSVersionTable.PSVersion
    $psText = "PowerShell $($psVer.Major).$($psVer.Minor)"
    if ($psVer.Major -ge 7) {
        $psText += " (Core)"
    } else {
        $psText += " (Desktop)"
    }
    $results.Messages += @{ Text = $psText; Level = "OK" }

    # winget (optional — für Software-Installation)
    if (Get-Command winget -EA SilentlyContinue) {
        $results.Messages += @{ Text = "winget verfügbar"; Level = "OK" }
    } else {
        $results.Messages += @{ Text = "winget nicht gefunden — Software-Installation eingeschränkt"; Level = "WARN" }
    }

    # git (optional — für Auto-Update)
    if (Get-Command git -EA SilentlyContinue) {
        $results.Messages += @{ Text = "git verfügbar"; Level = "OK" }
    } else {
        $results.Messages += @{ Text = "git nicht gefunden — Auto-Update nicht verfügbar"; Level = "WARN" }
    }

    return $results
}

# Prüfe .NET 4.8 sofort (vor GUI-Aufbau) — ohne .NET 4.8 funktioniert WPF nicht
$netCheck = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -EA SilentlyContinue).Release
if (-not $netCheck -or $netCheck -lt 528040) {
    [System.Windows.MessageBox]::Show(
        "Dieses Tool benötigt .NET Framework 4.8 oder höher.`n`nBitte installiere .NET 4.8 von:`nhttps://dotnet.microsoft.com/download/dotnet-framework/net48",
        "Hellion Power Tool — Voraussetzung fehlt",
        "OK", "Error"
    ) | Out-Null
    exit 1
}

# --- Globaler Brush-Cache (Performance: ein Converter statt dutzende pro Funktion) ---
$global:BrushConv = [System.Windows.Media.BrushConverter]::new()
$global:HealthBrushes = @{
    Green      = $global:BrushConv.ConvertFromString("#3DD68C")
    Orange     = $global:BrushConv.ConvertFromString("#F5A623")
    Red        = $global:BrushConv.ConvertFromString("#FF5F57")
    GreenBg    = $global:BrushConv.ConvertFromString("#152A15")
    OrangeBg   = $global:BrushConv.ConvertFromString("#2A2010")
    RedBg      = $global:BrushConv.ConvertFromString("#2A1515")
}

# --- Pfade & DebugLevel ---
# PS2EXE: $MyInvocation.MyCommand.Path kann leer sein, daher EXE-Pfad als Fallback
# Script liegt in src/ — RootPath ist eine Ebene höher
if ($script:IsExe) {
    $script:RootPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
} else {
    $script:RootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}
$script:ModulesPath = Join-Path $script:RootPath "src\modules"
$script:DebugLevel  = 0
if ($DebugMode)             { $script:DebugLevel = 1 }
if ($DevMode)               { $script:DebugLevel = 2 }
if ($ForceDebugLevel -ge 0) { $script:DebugLevel = $ForceDebugLevel }

# --- GUI-Settings laden ---
$script:GuiSettingsPath = Join-Path $script:RootPath "config\gui-settings.json"
$script:GuiSettings = @{
    theme     = "dark"
    window    = @{ width=1060; height=680; left=-1; top=-1 }
    healthBar = @{ enabled=$true; intervalMs=2000 }
    log       = @{ autoScroll=$true; maxDisplayLines=500; retentionDays=30 }
    privacy   = @{ checkForUpdates=$false }
    safety    = @{ autoRestorePoint=$true }
    language  = "de"
}
if (Test-Path $script:GuiSettingsPath) {
    try {
        $loaded = Get-Content $script:GuiSettingsPath -Raw -EA Stop | ConvertFrom-Json
        foreach ($prop in $loaded.PSObject.Properties) {
            $script:GuiSettings[$prop.Name] = $prop.Value
        }
    } catch { Write-Warning "gui-settings.json ungültig, verwende Defaults" }
}

function Save-GuiSettings {
    $guiDir = Join-Path $script:RootPath "config"
    if (-not (Test-Path $guiDir)) { New-Item -Path $guiDir -ItemType Directory -Force | Out-Null }
    $script:GuiSettings | ConvertTo-Json -Depth 3 | Set-Content $script:GuiSettingsPath -Encoding UTF8 -EA SilentlyContinue
}

# --- Theme-System ---
$script:CurrentTheme  = if ($script:GuiSettings.theme) { $script:GuiSettings.theme } else { "dark" }
$script:CurrentFilter = "all"

$script:Themes = @{
    dark = @{
        BgMain='#0F0F0F'; BgHeader='#111111'; BgSidebar='#141414'
        BgPanel='#161616'; BgHealth='#131313'; BgStatus='#0D0D0D'; BgCard='#1A1A1A'
        BorderMain='#2A2A2A'; BorderSub='#252525'; BorderDivide='#222222'
        TxtPrimary='#E0E0E0'; TxtSecondary='#AAAAAA'; TxtDim='#777777'
        TxtFaded='#777777'; TxtMuted='#555555'
        AccentGreen='#448f45'; AccentGreenBg='#1A3A1A'; NavActiveBg='#1A2E1A'
        HoverBg='#1E1E1E'; SecBtnBg='#222222'; SecBtnBorder='#333333'
        ScrollThumb='#555555'; VersionBadge='#1A3A1A'
        LogDefault='#888888'; CardBorder='#2A2A2A'; CardTitle='#E0E0E0'
        CardDesc='#999999'; CardDotIdle='#555555'; CardStatusIdle='#777777'
    }
    light = @{
        BgMain='#F3F2EF'; BgHeader='#FAF9F7'; BgSidebar='#F7F6F3'
        BgPanel='#EEEDEA'; BgHealth='#FAF9F7'; BgStatus='#EBEAE7'; BgCard='#FAF9F7'
        BorderMain='#D5D3CE'; BorderSub='#DDDBD7'; BorderDivide='#E2E0DC'
        TxtPrimary='#1C1C1A'; TxtSecondary='#555550'; TxtDim='#7A7A75'
        TxtFaded='#9A9A95'; TxtMuted='#BDBDB8'
        AccentGreen='#367a37'; AccentGreenBg='#D6F0D6'; NavActiveBg='#E3F0E3'
        HoverBg='#EBEAE7'; SecBtnBg='#E5E4E1'; SecBtnBorder='#CFCEC9'
        ScrollThumb='#BBBBB6'; VersionBadge='#D6F0D6'
        LogDefault='#444440'; CardBorder='#D5D3CE'; CardTitle='#1C1C1A'
        CardDesc='#666660'; CardDotIdle='#CCCCC7'; CardStatusIdle='#9A9A95'
    }
}

function Get-ThemeColor {
    param([string]$Key)
    $t = $script:Themes[$script:CurrentTheme]
    if ($t -and $t[$Key]) { return $t[$Key] }
    return $script:Themes['dark'][$Key]
}

# --- Log-Verlauf Setup ---
$script:GuiLogDir  = Join-Path $script:RootPath "logs\gui"
$script:GuiLogFile = Join-Path $script:GuiLogDir "gui-$(Get-Date -Format 'yyyy-MM-dd').log"
if (-not (Test-Path $script:GuiLogDir)) { New-Item -Path $script:GuiLogDir -ItemType Directory -Force | Out-Null }
# Log-Rotation: alte Logs entfernen
$retDays = 30
if ($script:GuiSettings.log -and $script:GuiSettings.log.retentionDays) { $retDays = $script:GuiSettings.log.retentionDays }
Get-ChildItem $script:GuiLogDir -Filter "gui-*.log" -EA SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retDays) } |
    Remove-Item -Force -EA SilentlyContinue

# --- Script-Variablen (wie Original) ---
$script:LogBuffer          = @()
$script:Errors             = @()
$script:Warnings           = @()
$script:SuccessActions     = @()
$script:ActionsPerformed   = @()
$script:AutoApproveCleanup = $true
$script:TotalFreedSpace    = 0
$script:AVSafeMode         = $true

# --- Module laden ---
if (Test-Path $script:ModulesPath) {
    Get-ChildItem "$script:ModulesPath\*.ps1" -EA SilentlyContinue | ForEach-Object {
        try { . $_.FullName } catch { Write-Warning "Modul-Fehler $($_.Name): $($_.Exception.Message)" }
    }
}
if (Get-Command Initialize-Logging -EA SilentlyContinue) {
    Initialize-Logging -LogDirectory "$env:TEMP\HellionPowerTool" -DetailedLogging
}

# ===================================================================
# XAML  — KEIN LetterSpacing, KEIN CharacterSpacing (nicht in WPF)
# ===================================================================
# --- XAML aus externer Datei laden ---
$xamlPath = Join-Path $script:RootPath "src\gui\window.xaml"
if (-not (Test-Path $xamlPath)) {
    [System.Windows.MessageBox]::Show("gui\window.xaml nicht gefunden!`n`nErwartet: $xamlPath", "Hellion Power Tool", 'OK', 'Error')
    exit 1
}
[xml]$xaml = Get-Content $xamlPath -Raw -Encoding UTF8


# ===================================================================
# WINDOW LADEN
# ===================================================================
try {
    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show(
        "XAML-Ladefehler:`n`n$($_.Exception.Message)",
        "Hellion GUI - Startfehler",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
    exit 1
}

# Controls referenzieren
$ctrl = @{}
foreach ($n in @(
    'TitleBar','BtnMinimize','BtnMaximize','BtnClose',
    'NavDashboard','NavRepair','NavClean','NavDiagnose','NavManage','NavSecurity','NavSettings',
    'PageTitle','CardPanel','LogOutput','LogScroller',
    'PsVersionText','OsText','StatusText','StatusModules',
    'BtnAutoMode','BtnQuickClean','BtnClearLog',
    'ActiveModulePanel','ActiveModuleName','ActiveModulePercent','ActiveProgress','BtnStopModule','LiveDot',
    'HealthBarPanel','HealthCPU','HealthCPUText','HealthRAM','HealthRAMText','HealthDisk','HealthDiskText',
    'OptionsOverlay','OptionsTitle','OptionsSubtitle','OptionsWarnText','OptionsStack','BtnOptionsCancel',
    'HeaderLogo','NavLegal','NavSystem','NavSoftware','StatusDebugBadge'
)) { $ctrl[$n] = $window.FindName($n) }

# ===================================================================
# SET-THEME (XAML-Brush-Resourcen zur Runtime aktualisieren)
# ===================================================================
function Set-Theme {
    param([string]$ThemeName)
    $colors = $script:Themes[$ThemeName]
    if (-not $colors) { return }
    # WPF friert XAML-Brushes ein (read-only) — neue Brush-Objekte erstellen statt .Color ändern
    foreach ($key in @('BgMain','BgHeader','BgSidebar','BgPanel','BgHealth',
        'BgStatus','BgCard','BorderMain','BorderSub','BorderDivide',
        'TxtPrimary','TxtSecondary','TxtDim','TxtFaded','TxtMuted',
        'AccentGreen','AccentGreenBg','NavActiveBg','HoverBg','SecBtnBg',
        'SecBtnBorder','ScrollThumb','VersionBadge')) {
        $newColor = [System.Windows.Media.ColorConverter]::ConvertFromString($colors[$key])
        $window.Resources[$key] = [System.Windows.Media.SolidColorBrush]::new($newColor)
    }
    $script:CurrentTheme = $ThemeName
    $script:GuiSettings.theme = $ThemeName
    Save-GuiSettings
    # Logo und Header-Gradient für Theme aktualisieren
    if (Get-Command Load-HeaderLogo -EA SilentlyContinue) { Load-HeaderLogo }
    if (Get-Command Set-HeaderGradient -EA SilentlyContinue) { Set-HeaderGradient }
    # Page-Caching: Alle gecachten Seiten invalidieren (Farben haben sich geändert)
    # Dashboard muss immer neu gebaut werden (Karten-Brushes sind Frozen und theme-abhängig)
    Build-Cards -Filter "all"
    $global:PageBuilt['Dashboard'] = $true
    # Andere Seiten nur invalidieren — werden beim nächsten Aufruf lazy neu gebaut
    foreach ($p in @('Settings','Legal','System','Software')) {
        $global:PageBuilt[$p] = $false
        $global:Pages[$p].Children.Clear()
    }
    # Aktuelle Seite bei Bedarf sofort neu bauen
    if ($script:CurrentFilter -eq "settings") {
        Build-SettingsPage; Switch-Page "Settings"
    } elseif ($script:CurrentFilter -eq "legal") {
        Build-LegalPage; Switch-Page "Legal"
    } elseif ($script:CurrentFilter -eq "system") {
        Build-SystemPage; Switch-Page "System"
    } elseif ($script:CurrentFilter -eq "software") {
        Build-SoftwarePage; Switch-Page "Software"
    } else {
        Switch-Page "Dashboard"
        Filter-DashboardCards -Filter $script:CurrentFilter
    }
}

# ===================================================================
# HEADER GRADIENT
# ===================================================================
function Set-HeaderGradient {
    $colors = $script:Themes[$script:CurrentTheme]
    $grad = [System.Windows.Media.LinearGradientBrush]::new()
    $grad.StartPoint = [System.Windows.Point]::new(0, 0.5)
    $grad.EndPoint   = [System.Windows.Point]::new(1, 0.5)
    $c1 = [System.Windows.Media.ColorConverter]::ConvertFromString($colors['BgHeader'])
    $c2 = [System.Windows.Media.ColorConverter]::ConvertFromString($colors['BgSidebar'])
    $grad.GradientStops.Add([System.Windows.Media.GradientStop]::new($c1, 0))
    $grad.GradientStops.Add([System.Windows.Media.GradientStop]::new($c2, 1))
    $ctrl['TitleBar'].Background = $grad
}

# ===================================================================
# SYSTEM-INFO
# ===================================================================
$ctrl['PsVersionText'].Text = "v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
try {
    $os = (Get-CimInstance Win32_OperatingSystem -EA Stop).Caption
    $ctrl['OsText'].Text = $os -replace "Microsoft ", ""
} catch { $ctrl['OsText'].Text = "Windows" }

# ===================================================================
# FENSTER-VERHALTEN
# ===================================================================
# Titelleiste: Drag + Doppelklick zum Maximieren/Wiederherstellen
$ctrl['TitleBar'].Add_MouseLeftButtonDown({
    if ($_.ClickCount -eq 2) {
        # Doppelklick: Toggle Maximize/Normal
        $window.WindowState = if ($window.WindowState -eq "Maximized") { "Normal" } else { "Maximized" }
    } else {
        if ($window.WindowState -eq "Maximized") {
            # Aus Maximiert lösen und Fenster unter die Maus positionieren
            $mousePos = [System.Windows.Input.Mouse]::GetPosition($window)
            $window.WindowState = "Normal"
            $window.Left = $mousePos.X - ($window.Width / 2)
            $window.Top  = $mousePos.Y - 15
        }
        $window.DragMove()
    }
})
$ctrl['BtnMinimize'].Add_Click({ $window.WindowState = "Minimized" })
$ctrl['BtnMaximize'].Add_Click({
    $window.WindowState = if ($window.WindowState -eq "Maximized") { "Normal" } else { "Maximized" }
})
$ctrl['BtnClose'].Add_Click({ $window.Close() })

# ===================================================================
# LOG-HELPER  (RichTextBox — keine Inlines-Probleme)
# ===================================================================
$script:dispatcher = $window.Dispatcher

function Add-LogLine {
    param([string]$Message, [string]$Color = "#888888")
    $ts   = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] $Message"
    $col  = $Color

    $script:dispatcher.Invoke([action]{
        $para = [System.Windows.Documents.Paragraph]::new()
        $para.Margin = [System.Windows.Thickness]::new(0)
        $run = [System.Windows.Documents.Run]::new($line)
        try {
            $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($col)
        } catch {}
        $run.FontSize = 11
        $para.Inlines.Add($run)
        $ctrl['LogOutput'].Document.Blocks.Add($para)
        if ($script:GuiSettings.log.autoScroll -ne $false) {
            $ctrl['LogScroller'].ScrollToEnd()
        }
    })

    # Log-Verlauf auf Disk schreiben
    try { $line | Out-File -FilePath $script:GuiLogFile -Append -Encoding UTF8 -EA SilentlyContinue } catch {}
}

# ===================================================================
# TOAST-BENACHRICHTIGUNGEN (Windows WinRT API, kein externes Modul)
# ===================================================================
function Show-ToastNotification {
    param([string]$Title, [string]$Message)
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
        $escapedTitle = [System.Security.SecurityElement]::Escape($Title)
        $escapedMsg   = [System.Security.SecurityElement]::Escape($Message)
        $toastXml = "<toast><visual><binding template=`"ToastText02`"><text id=`"1`">$escapedTitle</text><text id=`"2`">$escapedMsg</text></binding></visual></toast>"
        $xmlDoc = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $xmlDoc.LoadXml($toastXml)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(10)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Hellion.PowerTool").Show($toast)
    } catch {}
}

# ===================================================================
# AUTO-UPDATE-CHECKER (async via Runspace, blockiert GUI nicht)
# ===================================================================
function Check-ForUpdate {
    param([switch]$Manual)
    # DSGVO: Update-Check nur wenn Nutzer explizit zugestimmt hat oder manuell auslöst
    if (-not $Manual) {
        $privSettings = $script:GuiSettings.privacy
        if (-not $privSettings -or -not $privSettings.checkForUpdates) { return }
    }

    $localVersionFile = Join-Path $script:RootPath "config\version.txt"
    if (-not (Test-Path $localVersionFile)) { return }

    $localLines = Get-Content $localVersionFile -EA SilentlyContinue
    if ($localLines.Count -lt 4) { return }
    $localTimestamp = $localLines[3].Trim()

    $repoUrl = "https://raw.githubusercontent.com/JonKazama-Hellion/hellion-power-tool/main/config/version.txt"

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs

    $ps.AddScript({
        param($url, $localTs)
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -EA Stop
            $lines = $response.Content -split "`n"
            if ($lines.Count -ge 4) {
                $remoteVersion  = $lines[0].Trim()
                $remoteCodename = $lines[1].Trim()
                $remoteTs       = $lines[3].Trim()
                if ([long]$remoteTs -gt [long]$localTs) {
                    return @{ Available=$true; Version=$remoteVersion; Codename=$remoteCodename }
                }
            }
            return @{ Available=$false }
        } catch {
            return @{ Available=$false }
        }
    }).AddArgument($repoUrl).AddArgument($localTimestamp) | Out-Null

    $handle = $ps.BeginInvoke()

    $updateState = @{ PS=$ps; RS=$rs; Handle=$handle; Timer=$null }
    $updateState.Timer = [System.Windows.Threading.DispatcherTimer]::new()
    $updateState.Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $updateState.Timer.Add_Tick({
        if (-not $updateState.Handle.IsCompleted) { return }
        $updateState.Timer.Stop()
        try {
            $result = $updateState.PS.EndInvoke($updateState.Handle)
            if ($result -and $result.Count -gt 0) {
                $r = $result[0]
                if ($r.Available) {
                    Add-LogLine "Update verfügbar: v$($r.Version) $($r.Codename)" "#448f45"
                    Add-LogLine "  Download: https://github.com/JonKazama-Hellion/hellion-power-tool" "#777777"
                    Show-ToastNotification -Title "Hellion Power Tool" -Message "Update verfügbar: v$($r.Version) $($r.Codename)"
                }
            }
        } catch {}
        try { $updateState.PS.Dispose() } catch {}
        try { $updateState.RS.Dispose() } catch {}
    }.GetNewClosure())
    $updateState.Timer.Start()
}

# ===================================================================
# MODUL-KONFIGURATION
# ===================================================================
# --- Module aus gui/modules.json laden ---
$modulesJsonPath = Join-Path $script:RootPath "config\modules.json"
if (Test-Path $modulesJsonPath) {
    $script:Modules = Get-Content $modulesJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    Write-Warning "gui\modules.json nicht gefunden — keine Modul-Karten verfügbar"
    $script:Modules = @()
}

# ===================================================================
# KARTEN BAUEN
# ===================================================================
$global:CardRefs = [System.Collections.Hashtable]::new()

# Laufender Runspace: Referenz für Stop-Button
$global:RunningModule = @{
    PowerShell  = $null
    Runspace    = $null
    CheckTimer  = $null
    ProgTimer   = $null
    ModId       = $null
}

function Build-Cards {
    param([string]$Filter = "all")
    # Page-Caching: Baue ins Dashboard-Panel (nicht direkt in CardPanel)
    $targetPanel = $global:Pages['Dashboard']
    $targetPanel.Children.Clear()
    $global:CardRefs = [System.Collections.Hashtable]::new()

    $list = if ($Filter -eq "all") { $script:Modules }
            else { $script:Modules | Where-Object { $_.Group -eq $Filter } }

    $conv = [System.Windows.Media.BrushConverter]::new()

    # --- Performance: Frozen Brushes vorab erstellen (kein Change-Notification-Overhead) ---
    $frozenBrushCache = @{}
    $brushKeys = @('BgCard','CardBorder','BorderSub','TxtPrimary','TxtSecondary',
                   'CardTitle','CardDesc','CardDotIdle','CardStatusIdle')
    foreach ($bk in $brushKeys) {
        $b = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString((Get-ThemeColor $bk)))
        $b.Freeze()
        $frozenBrushCache[$bk] = $b
    }
    $whiteBrush = [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.Colors]::White)
    $whiteBrush.Freeze()

    # Performance: Wiederverwendbare Animationen (Hover)
    $script:HoverEnterAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $script:HoverEnterAnim.To = 1.02
    $script:HoverEnterAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(150))
    $script:HoverEnterAnim.EasingFunction = [System.Windows.Media.Animation.QuadraticEase]::new()
    $script:HoverEnterAnim.Freeze()

    $script:HoverLeaveAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $script:HoverLeaveAnim.To = 1.0
    $script:HoverLeaveAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
    $script:HoverLeaveAnim.EasingFunction = [System.Windows.Media.Animation.QuadraticEase]::new()
    $script:HoverLeaveAnim.Freeze()

    # Performance: Wiederverwendbare Einblend-Animationen
    $script:FadeInAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $script:FadeInAnim.From = 0; $script:FadeInAnim.To = 1
    $script:FadeInAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
    $script:FadeInAnim.EasingFunction = [System.Windows.Media.Animation.QuadraticEase]::new()
    $script:FadeInAnim.Freeze()

    $script:SlideUpAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $script:SlideUpAnim.From = 12; $script:SlideUpAnim.To = 0
    $script:SlideUpAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
    $script:SlideUpAnim.EasingFunction = [System.Windows.Media.Animation.QuadraticEase]::new()
    $script:SlideUpAnim.Freeze()

    # --- Kategorie-Maps ---
    $categoryNames = @{
        repair   = "System-Reparatur"
        clean    = "Bereinigung & Optimierung"
        diagnose = "Diagnose & Analyse"
        manage   = "Verwaltung"
        security = "Sicherheit"
    }
    $categoryIcons = @{
        repair   = [char]0xE90F
        clean    = [char]0xE74D
        diagnose = [char]0xE9D9
        manage   = [char]0xE115
        security = [char]0xE72E
    }

    # Shared FontFamily (einmal erstellen statt pro Karte)
    $mdl2Font = [System.Windows.Media.FontFamily]::new("Segoe MDL2 Assets")

    # --- Willkommens-Header (nur im Dashboard) ---
    if ($Filter -eq "all") {
        $welcomePanel = [System.Windows.Controls.Border]::new()
        $welcomePanel.Background      = $frozenBrushCache['BgCard']
        $welcomePanel.BorderBrush     = $frozenBrushCache['BorderSub']
        $welcomePanel.BorderThickness = [System.Windows.Thickness]::new(1)
        $welcomePanel.CornerRadius    = [System.Windows.CornerRadius]::new(10)
        $welcomePanel.Padding  = [System.Windows.Thickness]::new(20,16,20,16)
        $welcomePanel.Margin   = [System.Windows.Thickness]::new(0,0,0,8)
        $welcomePanel.HorizontalAlignment = "Stretch"
        # BitmapCache — DropShadow wird als Bitmap gecacht (GPU-beschleunigt)
        $welcomePanel.CacheMode = [System.Windows.Media.BitmapCache]::new()
        $shadow = [System.Windows.Media.Effects.DropShadowEffect]::new()
        $shadow.BlurRadius = 8; $shadow.ShadowDepth = 1; $shadow.Opacity = 0.2
        $shadow.Color = [System.Windows.Media.Colors]::Black; $shadow.Direction = 270
        $welcomePanel.Effect = $shadow

        $wStack = [System.Windows.Controls.StackPanel]::new()

        $greeting = [System.Windows.Controls.TextBlock]::new()
        $greeting.FontSize = 18
        $greeting.FontWeight = "SemiBold"
        $greeting.Foreground = $frozenBrushCache['TxtPrimary']
        $hour = (Get-Date).Hour
        $greetText = if ($hour -lt 12) { "Guten Morgen" } elseif ($hour -lt 18) { "Guten Tag" } else { "Guten Abend" }
        $greeting.Text = "$greetText!"
        $wStack.Children.Add($greeting) | Out-Null

        $subtitle = [System.Windows.Controls.TextBlock]::new()
        $subtitle.Text = "$($script:Modules.Count) Module bereit. Wähle eine Kategorie oder klicke direkt auf eine Karte."
        $subtitle.FontSize = 12
        $subtitle.Foreground = $frozenBrushCache['TxtSecondary']
        $subtitle.Margin = [System.Windows.Thickness]::new(0,4,0,0)
        $wStack.Children.Add($subtitle) | Out-Null

        $welcomePanel.Child = $wStack
        $targetPanel.Children.Add($welcomePanel) | Out-Null
    }

    # --- Hilfsfunktion: Einzelne Karte erstellen ---
    $cardIndex = 0
    # Animations-Queue: Karten sammeln, ein Timer blendet sie gestaffelt ein
    $script:AnimQueue = [System.Collections.ArrayList]::new()

    function New-ModuleCard {
        param($mod, [ref]$cardIdx)
        $card = [System.Windows.Controls.Border]::new()
        $card.Width           = 205
        $card.MinHeight       = 108
        $card.Margin          = [System.Windows.Thickness]::new(0,0,10,10)
        $card.CornerRadius    = [System.Windows.CornerRadius]::new(10)
        $card.Padding         = [System.Windows.Thickness]::new(13)
        $card.Cursor          = "Hand"
        $card.Background      = $frozenBrushCache['BgCard']
        $card.BorderBrush     = $frozenBrushCache['CardBorder']
        $card.BorderThickness = [System.Windows.Thickness]::new(1)

        # BitmapCache — DropShadow als Bitmap cachen (Performance-kritisch!)
        $card.CacheMode = [System.Windows.Media.BitmapCache]::new()

        # DropShadow-Effekt
        $shadow = [System.Windows.Media.Effects.DropShadowEffect]::new()
        $shadow.BlurRadius  = 12
        $shadow.ShadowDepth = 2
        $shadow.Opacity     = if ($script:CurrentTheme -eq 'light') { 0.10 } else { 0.35 }
        $shadow.Color       = [System.Windows.Media.Colors]::Black
        $shadow.Direction   = 270
        $card.Effect = $shadow

        # TransformGroup für Hover-Zoom + Einblend-Slide
        $tg = [System.Windows.Media.TransformGroup]::new()
        $tg.Children.Add([System.Windows.Media.ScaleTransform]::new(1.0, 1.0))
        $tg.Children.Add([System.Windows.Media.TranslateTransform]::new(0, 12))
        $card.RenderTransform = $tg
        $card.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $card.Opacity = 0

        $stack = [System.Windows.Controls.StackPanel]::new()

        # Akzent-Linie oben (3px) — Frozen Brush
        $accentBrush = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString($mod.AccColor))
        $accentBrush.Freeze()

        $accentLine = [System.Windows.Shapes.Rectangle]::new()
        $accentLine.Height = 3
        $accentLine.RadiusX = 2; $accentLine.RadiusY = 2
        $accentLine.Fill = $accentBrush
        $accentLine.Margin = [System.Windows.Thickness]::new(-2,-2,-2,10)
        $accentLine.HorizontalAlignment = "Stretch"
        $stack.Children.Add($accentLine) | Out-Null

        # Header: Titel + Kategorie-Icon
        $headerPanel = [System.Windows.Controls.DockPanel]::new()

        $catIcon = [System.Windows.Controls.TextBlock]::new()
        $catIcon.Text = $categoryIcons[$mod.Group]
        $catIcon.FontFamily = $mdl2Font
        $catIcon.FontSize = 16
        $catIcon.Foreground = $accentBrush
        $catIcon.Opacity = 0.35
        $catIcon.VerticalAlignment = "Top"
        [System.Windows.Controls.DockPanel]::SetDock($catIcon, "Right")
        $headerPanel.Children.Add($catIcon) | Out-Null

        $titleTb = [System.Windows.Controls.TextBlock]::new()
        $titleTb.Text = $mod.Title
        $titleTb.FontSize = 12
        $titleTb.FontWeight = "SemiBold"
        $titleTb.Foreground = $frozenBrushCache['CardTitle']
        $titleTb.TextWrapping = "Wrap"
        $titleTb.Margin = [System.Windows.Thickness]::new(0,0,0,6)
        $headerPanel.Children.Add($titleTb) | Out-Null

        $stack.Children.Add($headerPanel) | Out-Null

        # Beschreibung
        $descTb = [System.Windows.Controls.TextBlock]::new()
        $descTb.Text = $mod.Desc
        $descTb.FontSize = 10
        $descTb.Foreground = $frozenBrushCache['CardDesc']
        $descTb.TextWrapping = "Wrap"
        $descTb.Margin = [System.Windows.Thickness]::new(0,0,0,9)
        $descTb.LineHeight = 15
        $stack.Children.Add($descTb) | Out-Null

        # Status-Zeile
        $statusSp = [System.Windows.Controls.StackPanel]::new()
        $statusSp.Orientation = "Horizontal"
        $statusSp.Margin = [System.Windows.Thickness]::new(0,0,0,5)

        $dot = [System.Windows.Shapes.Ellipse]::new()
        $dot.Width  = 7
        $dot.Height = 7
        $dot.Fill   = $frozenBrushCache['CardDotIdle']
        $dot.VerticalAlignment = "Center"
        $dot.Margin = [System.Windows.Thickness]::new(0,0,6,0)

        $statusLbl = [System.Windows.Controls.TextBlock]::new()
        $statusLbl.Text = "Bereit"
        $statusLbl.FontSize = 10
        $statusLbl.Foreground = $frozenBrushCache['CardStatusIdle']
        $statusLbl.VerticalAlignment = "Center"

        $statusSp.Children.Add($dot)       | Out-Null
        $statusSp.Children.Add($statusLbl) | Out-Null
        $stack.Children.Add($statusSp) | Out-Null

        # Progressbar
        $prog = [System.Windows.Controls.ProgressBar]::new()
        $prog.Style   = $window.Resources['HellionProg']
        $prog.Value   = 0
        $prog.Maximum = 100
        $stack.Children.Add($prog) | Out-Null

        $card.Child = $stack

        # Referenz speichern
        $modId  = $mod.Id
        $accHex = $mod.AccColor
        $ref = @{
            Card      = $card
            Dot       = $dot
            Status    = $statusLbl
            Prog      = $prog
            Acc       = $accHex
            AccBrush  = $accentBrush
            Func      = $mod.Func
            GuiArgs   = if ($mod.GuiArgs) { $mod.GuiArgs } else { "" }
            Title     = $mod.Title
            Id        = $modId
        }
        $global:CardRefs[$modId] = $ref

        # --- Hover: Frozen Animations wiederverwenden (kein Objekt-Erstellen pro Event) ---
        $card.Add_MouseEnter({
            try {
                $ref.Card.BorderBrush = $ref.AccBrush
                $ref.Card.Effect.ShadowDepth = 4
                $ref.Card.Effect.BlurRadius  = 20
                $ref.Card.Effect.Opacity     = if ($script:CurrentTheme -eq 'light') { 0.15 } else { 0.5 }
                $tg = $ref.Card.RenderTransform
                if ($null -ne $tg -and $null -ne $tg.Children -and $tg.Children.Count -gt 0) {
                    $tg.Children[0].BeginAnimation(
                        [System.Windows.Media.ScaleTransform]::ScaleXProperty, $script:HoverEnterAnim)
                    $tg.Children[0].BeginAnimation(
                        [System.Windows.Media.ScaleTransform]::ScaleYProperty, $script:HoverEnterAnim)
                }
            } catch {}
        }.GetNewClosure())

        $card.Add_MouseLeave({
            try {
                $ref.Card.BorderBrush = $frozenBrushCache['CardBorder']
                $ref.Card.Effect.ShadowDepth = 2
                $ref.Card.Effect.BlurRadius  = 12
                $ref.Card.Effect.Opacity     = if ($script:CurrentTheme -eq 'light') { 0.10 } else { 0.35 }
                $tg = $ref.Card.RenderTransform
                if ($null -ne $tg -and $null -ne $tg.Children -and $tg.Children.Count -gt 0) {
                    $tg.Children[0].BeginAnimation(
                        [System.Windows.Media.ScaleTransform]::ScaleXProperty, $script:HoverLeaveAnim)
                    $tg.Children[0].BeginAnimation(
                        [System.Windows.Media.ScaleTransform]::ScaleYProperty, $script:HoverLeaveAnim)
                }
            } catch {}
        }.GetNewClosure())

        $card.Add_MouseLeftButtonDown({
            Show-ModuleOptions -ModId $ref.Id
        }.GetNewClosure())

        # In Animations-Queue einreihen (statt eigenen Timer pro Karte)
        $script:AnimQueue.Add(@{ Card=$card; TG=$tg }) | Out-Null

        return $card
    }

    # --- Dashboard-Ansicht: Kategorie-Sektionen mit eigenen WrapPanels ---
    if ($Filter -eq "all") {
        $groups = $list | Group-Object -Property Group
        foreach ($grp in $groups) {
            $groupName = $grp.Name

            # Kategorie-Header
            $catHeader = [System.Windows.Controls.StackPanel]::new()
            $catHeader.Orientation = "Horizontal"
            $catHeader.Margin = [System.Windows.Thickness]::new(0,12,0,6)

            $catIconTb = [System.Windows.Controls.TextBlock]::new()
            $catIconTb.Text = $categoryIcons[$groupName]
            $catIconTb.FontFamily = $mdl2Font
            $catIconTb.FontSize = 13
            $grpAccBrush = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.ColorConverter]::ConvertFromString($grp.Group[0].AccColor))
            $grpAccBrush.Freeze()
            $catIconTb.Foreground = $grpAccBrush
            $catIconTb.Margin = [System.Windows.Thickness]::new(0,0,8,0)
            $catIconTb.VerticalAlignment = "Center"
            $catHeader.Children.Add($catIconTb) | Out-Null

            $catLabel = [System.Windows.Controls.TextBlock]::new()
            $catLabel.Text = $categoryNames[$groupName]
            $catLabel.FontSize = 13
            $catLabel.FontWeight = "SemiBold"
            $catLabel.Foreground = $frozenBrushCache['TxtSecondary']
            $catLabel.VerticalAlignment = "Center"
            $catHeader.Children.Add($catLabel) | Out-Null

            $countBadge = [System.Windows.Controls.Border]::new()
            $countBadge.Background  = $grpAccBrush
            $countBadge.CornerRadius = [System.Windows.CornerRadius]::new(8)
            $countBadge.Padding = [System.Windows.Thickness]::new(6,1,6,1)
            $countBadge.Margin  = [System.Windows.Thickness]::new(8,0,0,0)
            $countBadge.Opacity = 0.7
            $countBadge.VerticalAlignment = "Center"
            $countTb = [System.Windows.Controls.TextBlock]::new()
            $countTb.Text = "$($grp.Count)"
            $countTb.FontSize = 10
            $countTb.FontWeight = "Bold"
            $countTb.Foreground = $whiteBrush
            $countBadge.Child = $countTb
            $catHeader.Children.Add($countBadge) | Out-Null

            $targetPanel.Children.Add($catHeader) | Out-Null

            # WrapPanel für diese Kategorie — Tag speichert Gruppen-ID für Filter
            $catWrap = [System.Windows.Controls.WrapPanel]::new()
            $catWrap.Orientation = "Horizontal"
            $catWrap.Tag = "group:$groupName"

            foreach ($mod in $grp.Group) {
                $card = New-ModuleCard -mod $mod -cardIdx ([ref]$cardIndex)
                $catWrap.Children.Add($card) | Out-Null
            }

            $targetPanel.Children.Add($catWrap) | Out-Null
            # Kategorie-Header bekommt auch Tag für Filter
            $catHeader.Tag = "header:$groupName"
        }
    }
    else {
        # --- Einzelkategorie: ein WrapPanel für alle Karten ---
        $catWrap = [System.Windows.Controls.WrapPanel]::new()
        $catWrap.Orientation = "Horizontal"

        foreach ($mod in $list) {
            $card = New-ModuleCard -mod $mod -cardIdx ([ref]$cardIndex)
            $catWrap.Children.Add($card) | Out-Null
        }

        $targetPanel.Children.Add($catWrap) | Out-Null
    }

    # --- Performance: EIN Timer für alle Einblend-Animationen (statt N Timer) ---
    if ($script:AnimQueue.Count -gt 0) {
        $script:AnimIdx = 0
        # Vorherigen AnimTimer stoppen (verhindert Race-Condition bei schnellem Seitenwechsel)
        if ($null -ne $script:AnimTimer) { try { $script:AnimTimer.Stop() } catch {} }
        $script:AnimTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:AnimTimer.Interval = [TimeSpan]::FromMilliseconds(15)
        $script:AnimTimer.Add_Tick({
            $q = $script:AnimQueue
            # 3 Cards pro Tick animieren (statt 1) — 90ms statt 510ms für 17 Cards
            for ($i = 0; $i -lt 3; $i++) {
                if ($null -eq $q -or $script:AnimIdx -ge $q.Count) {
                    $this.Stop()
                    return
                }
                $item = $q[$script:AnimIdx]
                $script:AnimIdx++
                try {
                    $item.Card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $script:FadeInAnim)
                    $item.TG.Children[1].BeginAnimation(
                        [System.Windows.Media.TranslateTransform]::YProperty, $script:SlideUpAnim)
                } catch {}
            }
        })
        $script:AnimTimer.Start()
    }
}

# ===================================================================
# BESTÄTIGUNGS-DIALOG (vor destruktiven Aktionen)
# ===================================================================
function Show-ConfirmDialog {
    param(
        [string]$Title,
        [string]$WarnText,
        [string]$ModId,
        [string]$Args
    )
    $ctrl['OptionsOverlay'].Visibility = 'Visible'
    $ctrl['OptionsTitle'].Text = $Title
    $ctrl['OptionsSubtitle'].Text = ""
    $ctrl['OptionsSubtitle'].Visibility = "Collapsed"
    $ctrl['OptionsWarnText'].Visibility = "Visible"
    $ctrl['OptionsWarnText'].Text = $WarnText
    $ctrl['OptionsStack'].Children.Clear()

    $convD = [System.Windows.Media.BrushConverter]::new()

    # Warn-Icon + Hinweis
    $warnRow = [System.Windows.Controls.StackPanel]::new()
    $warnRow.Orientation = "Horizontal"
    $warnRow.Margin = [System.Windows.Thickness]::new(0,0,0,6)
    $warnIcon = [System.Windows.Controls.TextBlock]::new()
    $warnIcon.Text = [char]0xE7BA
    $warnIcon.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe MDL2 Assets")
    $warnIcon.FontSize = 14
    $warnIcon.Foreground = $convD.ConvertFromString("#F5A623")
    $warnIcon.Margin = [System.Windows.Thickness]::new(0,0,8,0)
    $warnIcon.VerticalAlignment = "Center"
    $warnRow.Children.Add($warnIcon) | Out-Null
    $warnLabel = [System.Windows.Controls.TextBlock]::new()
    $warnLabel.Text = "Diese Aktion verändert dein System."
    $warnLabel.FontSize = 11
    $warnLabel.Foreground = $convD.ConvertFromString("#F5A623")
    $warnLabel.VerticalAlignment = "Center"
    $warnRow.Children.Add($warnLabel) | Out-Null
    $ctrl['OptionsStack'].Children.Add($warnRow) | Out-Null

    # Fortfahren-Button
    $confirmBtn = [System.Windows.Controls.Button]::new()
    $confirmBtn.Content = "Fortfahren"
    $confirmBtn.Style = $window.FindResource('PrimaryBtn')
    $confirmBtn.Margin = [System.Windows.Thickness]::new(0,8,0,0)
    $confirmBtn.Padding = [System.Windows.Thickness]::new(14,10,14,10)
    $confirmBtn.HorizontalAlignment = 'Stretch'
    $confirmBtn.FontSize = 12
    $capturedModId = $ModId
    $capturedArgs  = $Args
    $confirmBtn.Add_Click({
        $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
        $ctrl['OptionsWarnText'].Visibility = "Collapsed"
        Start-ModuleAsync -ModId $capturedModId -OverrideArgs $capturedArgs
    }.GetNewClosure())
    $ctrl['OptionsStack'].Children.Add($confirmBtn) | Out-Null
}

# ===================================================================
# MODUL-VORAUSWAHL (Options-Overlay)
# ===================================================================
function Show-ModuleOptions {
    param([string]$ModId)
    $mod = $script:Modules | Where-Object { $_.Id -eq $ModId }
    if (-not $mod) { Start-ModuleAsync -ModId $ModId; return }

    $options = $mod.Options
    if (-not $options -or $options.Count -eq 0) {
        # Kein Menü — prüfe ob Modul-Level WarnText existiert
        $modWarn = if ($mod.WarnText) { [string]$mod.WarnText } else { "" }
        if ($modWarn -ne "") {
            Show-ConfirmDialog -Title $mod.Title -WarnText $modWarn -ModId $ModId -Args ""
            return
        }
        Start-ModuleAsync -ModId $ModId
        return
    }

    # Overlay sichtbar machen
    $ctrl['OptionsOverlay'].Visibility = 'Visible'
    $ctrl['OptionsOverlay'].Tag = $ModId
    $ctrl['OptionsTitle'].Text = $mod.Title
    $ctrl['OptionsSubtitle'].Text = "Aktion wählen:"
    $ctrl['OptionsSubtitle'].Visibility = "Visible"
    $ctrl['OptionsWarnText'].Visibility = "Collapsed"

    # Bestehende Buttons entfernen
    $ctrl['OptionsStack'].Children.Clear()

    foreach ($opt in $options) {
        $capturedModId = $ModId
        $capturedTitle = $mod.Title
        $optWarn = if ($opt.WarnText) { [string]$opt.WarnText } else { "" }
        $capturedArgs = [string]$opt.Args

        # DrivePicker-Option: Zeigt nach Klick die Laufwerksauswahl
        $hasDrivePicker = ($opt.DrivePicker -eq $true)

        $btn = [System.Windows.Controls.Button]::new()
        $btn.Content = $opt.Label
        $btn.Tag = $capturedArgs
        $btn.Style = $window.FindResource('SecBtn')
        $btn.Margin = [System.Windows.Thickness]::new(0,4,0,0)
        $btn.Padding = [System.Windows.Thickness]::new(14,10,14,10)
        $btn.HorizontalAlignment = 'Stretch'
        $btn.FontSize = 12

        if ($hasDrivePicker) {
            # Zweistufig: Erst Modus gewählt, dann Laufwerk wählen
            $capturedWarn = $optWarn
            $btn.Add_Click({
                $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
                Show-DriveSelector -ModId $capturedModId -Title $capturedTitle -BaseArgs $capturedArgs -WarnText $capturedWarn
            }.GetNewClosure())
        } elseif ($optWarn -ne "") {
            $capturedWarn = $optWarn
            $btn.Add_Click({
                $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
                Show-ConfirmDialog -Title $capturedTitle -WarnText $capturedWarn -ModId $capturedModId -Args $capturedArgs
            }.GetNewClosure())
        } else {
            $btn.Add_Click({
                $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
                Start-ModuleAsync -ModId $capturedModId -OverrideArgs $capturedArgs
            }.GetNewClosure())
        }
        $ctrl['OptionsStack'].Children.Add($btn) | Out-Null
    }
}

# ===================================================================
# LAUFWERKS-AUSWAHL (für CheckDisk und ähnliche Module)
# ===================================================================

# Helper: Erzeugt Click-Handler in eigenem Funktions-Scope
# Funktionsaufruf = neuer Scope → .GetNewClosure() captured korrekte Werte
function New-DriveClickHandler {
    param([string]$HandlerModId, [string]$HandlerArgs, [string]$HandlerTitle, [string]$HandlerWarn)
    if ($HandlerWarn -ne "") {
        return {
            $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
            Show-ConfirmDialog -Title $HandlerTitle -WarnText $HandlerWarn -ModId $HandlerModId -Args $HandlerArgs
        }.GetNewClosure()
    } else {
        return {
            $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
            Start-ModuleAsync -ModId $HandlerModId -OverrideArgs $HandlerArgs
        }.GetNewClosure()
    }
}

function Show-DriveSelector {
    param(
        [string]$ModId,
        [string]$Title,
        [string]$BaseArgs,
        [string]$WarnText
    )

    # Laufwerke zur Laufzeit ermitteln
    $drives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -EA SilentlyContinue)
    if ($drives.Count -eq 0) {
        Add-LogLine "Keine Laufwerke gefunden" "#F5A623"
        return
    }

    # Overlay mit Laufwerk-Buttons füllen
    $ctrl['OptionsOverlay'].Visibility = 'Visible'
    $ctrl['OptionsOverlay'].Tag = $ModId
    $ctrl['OptionsTitle'].Text = "$Title — Laufwerk wählen"
    $ctrl['OptionsSubtitle'].Text = "Welches Laufwerk soll geprüft werden?"
    $ctrl['OptionsSubtitle'].Visibility = "Visible"
    $ctrl['OptionsWarnText'].Visibility = "Collapsed"
    $ctrl['OptionsStack'].Children.Clear()

    foreach ($drv in $drives) {
        $letter = $drv.DeviceID.TrimEnd(':')
        $totalGB = [math]::Round($drv.Size / 1GB, 1)
        $freeGB  = [math]::Round($drv.FreeSpace / 1GB, 1)
        $usedPct = [int](($drv.Size - $drv.FreeSpace) / $drv.Size * 100)
        $label   = "$($drv.DeviceID)  —  $freeGB GB frei / $totalGB GB ($usedPct% belegt)"

        # Args zusammenbauen: BaseArgs enthält z.B. "-Mode 1 -Force", DriveLetter wird ersetzt/eingefügt
        $driveArgs = ($BaseArgs -replace '-DriveLetter \S+', '').Trim()
        $driveArgs = "-DriveLetter $letter $driveArgs".Trim()

        $btn = [System.Windows.Controls.Button]::new()
        $btn.Content = $label
        $btn.Style = $window.FindResource('SecBtn')
        $btn.Margin = [System.Windows.Thickness]::new(0,4,0,0)
        $btn.Padding = [System.Windows.Thickness]::new(14,10,14,10)
        $btn.HorizontalAlignment = 'Stretch'
        $btn.FontSize = 12

        # Handler via Helper-Funktion: Jeder Aufruf = eigener Scope = korrekte Werte
        $handler = New-DriveClickHandler -HandlerModId $ModId -HandlerArgs $driveArgs -HandlerTitle $Title -HandlerWarn $WarnText
        $btn.Add_Click($handler)
        $ctrl['OptionsStack'].Children.Add($btn) | Out-Null
    }
}

# Options-Overlay: Abbrechen-Button
$ctrl['BtnOptionsCancel'].Add_Click({
    $wasDevDisclaimer = ($ctrl['OptionsOverlay'].Tag -eq '__dev_disclaimer__')
    $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
    # Dev-Disclaimer abgebrochen: Settings-Seite neu bauen damit RadioButton zurückgesetzt wird
    if ($wasDevDisclaimer -and $script:CurrentFilter -eq 'settings') {
        Build-SettingsPage
    }
})

# Options-Overlay: Klick auf dunklen Hintergrund schliesst auch
$ctrl['OptionsOverlay'].Add_MouseLeftButtonDown({
    param($sender, $e)
    if ($e.OriginalSource -eq $ctrl['OptionsOverlay']) {
        $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
    }
})

# ===================================================================
# MODUL ASYNCHRON STARTEN
# ===================================================================
function Start-ModuleAsync {
    param(
        [string]$ModId,
        [string]$OverrideArgs = '',
        [scriptblock]$OnComplete = $null,
        [switch]$Destructive
    )

    $ref = $global:CardRefs[$ModId]
    if ($null -eq $ref) { Add-LogLine "Modul '$ModId' nicht gefunden" "#FF5F57"; return }

    $funcName = $ref.Func
    $guiArgs  = if ($OverrideArgs) { $OverrideArgs } else { $ref.GuiArgs }

    # Destruktiv-Flag: aus WarnText des Moduls ableiten wenn nicht explizit gesetzt
    # Automatischer Wiederherstellungspunkt nur wenn in Settings aktiviert (Default: an)
    $isDestructive = $false
    $safetySettings = $script:GuiSettings.safety
    $autoRestoreEnabled = ($safetySettings -and $safetySettings.autoRestorePoint -ne $false)
    if ($autoRestoreEnabled) {
        if ($Destructive.IsPresent) {
            $isDestructive = $true
        } else {
            $modDef = $script:Modules | Where-Object { $_.Id -eq $ModId }
            if ($modDef -and $modDef.WarnText -and [string]$modDef.WarnText -ne "") { $isDestructive = $true }
        }
    }

    # Funktions-Override: Args mit "__func:FuncName" überschreiben die aufgerufene Funktion
    if ($guiArgs -match '^__func:(\S+)(.*)$') {
        $funcName = $Matches[1]
        $guiArgs  = $Matches[2].Trim()
    }

    if (-not (Get-Command $funcName -EA SilentlyContinue)) {
        Add-LogLine "Funktion nicht gefunden: $funcName" "#F5A623"
        Add-LogLine "  Alle Module müssen in /modules/ liegen" "#777777"
        return
    }

    $acc  = $ref.Acc
    $conv = [System.Windows.Media.BrushConverter]::new()

    # UI: laufend
    $script:dispatcher.Invoke([action]{
        $ref.Dot.Fill       = $conv.ConvertFromString($acc)
        $ref.Status.Text    = "Läuft..."
        $ref.Status.Foreground = $conv.ConvertFromString($acc)
        $ref.Prog.Value     = 0
        $ref.Prog.Foreground = $conv.ConvertFromString($acc)
        $ctrl['ActiveModulePanel'].Visibility = "Visible"
        $ctrl['ActiveModuleName'].Text  = $ref.Title
        $ctrl['ActiveModulePercent'].Text = "0%"
        $ctrl['ActiveProgress'].Value   = 0
        $ctrl['ActiveProgress'].Foreground = $conv.ConvertFromString($acc)
    })

    Add-LogLine "Starte: $($ref.Title)" $acc

    # LiveDot pulsieren lassen
    $pulseAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $pulseAnim.From = 1.0
    $pulseAnim.To = 0.3
    $pulseAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(800))
    $pulseAnim.AutoReverse = $true
    $pulseAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulseAnim)

    $rootPath    = $script:RootPath
    $modulesPath = $script:ModulesPath
    $dbgLevel    = $script:DebugLevel

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs

    $ps.AddScript({
        param($rootPath, $modulesPath, $funcName, $guiArgs, $dbgLevel, $autoRestore)

        # --- Automatischer Wiederherstellungspunkt vor destruktiven Operationen ---
        if ($autoRestore) {
            try {
                $srEnabled = (Get-CimInstance -ClassName Win32_OperatingSystem -EA SilentlyContinue)
                $srStatus = Get-ComputerRestorePoint -EA SilentlyContinue
                # Prüfe ob System Restore aktiviert ist
                $srConfig = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -EA SilentlyContinue
                if ($srConfig -and $srConfig.RPSessionInterval -ne $null) {
                    $desc = "Hellion Power Tool - Vor $funcName"
                    Write-Information "Wiederherstellungspunkt wird erstellt..." -InformationAction Continue
                    if (Get-Command Checkpoint-Computer -EA SilentlyContinue) {
                        Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -EA Stop
                        Write-Information "Wiederherstellungspunkt erstellt." -InformationAction Continue
                    } else {
                        # PS7 Fallback via WMI
                        $sr = [wmiclass]"\\localhost\root\default:SystemRestore"
                        $sr.CreateRestorePoint($desc, 12, 100) | Out-Null
                        Write-Information "Wiederherstellungspunkt erstellt (WMI)." -InformationAction Continue
                    }
                }
            } catch {
                Write-Information "Wiederherstellungspunkt konnte nicht erstellt werden: $($_.Exception.Message)" -InformationAction Continue
            }
        }

        # --- Read-Host Override: Shadowed das Cmdlet im Runspace ---
        # Module werden NICHT verändert. Stattdessen gibt diese Funktion
        # intelligente Standard-Antworten zurück statt den Thread zu blockieren.
        function Read-Host {
            param([Parameter(Position=0)][string]$Prompt)

            # Neustart/Reboot-Fragen: IMMER ablehnen (Sicherheit!)
            if ($Prompt -match 'NEU\s*STARTEN|RESTART|REBOOT') {
                Write-Information "GUI: Neustart-Abfrage abgelehnt (Sicherheit) - '$Prompt'" -InformationAction Continue
                return "n"
            }

            # CONFIRM-Abfragen bei gefährlichen Operationen: ablehnen
            if ($Prompt -match 'CONFIRM' -and $Prompt -match 'entfern|loeschen|löschen|force|delete') {
                Write-Information "GUI: Gefährliche Operation abgelehnt - '$Prompt'" -InformationAction Continue
                return "n"
            }

            # Ja/Nein-Abfragen: bestätigen
            if ($Prompt -match '\[j/n\]|\[J/N\]|\(j/n\)|\(J/N\)') {
                Write-Information "GUI: Automatisch bestätigt (j) - '$Prompt'" -InformationAction Continue
                return "j"
            }

            # CONFIRM-Abfragen (nicht-gefährlich): bestätigen
            if ($Prompt -match 'CONFIRM') {
                Write-Information "GUI: Automatisch bestätigt (CONFIRM) - '$Prompt'" -InformationAction Continue
                return "CONFIRM"
            }

            # Nummern-Auswahl [1-X]: erste/sicherste Option
            if ($Prompt -match '\[1-\d') {
                Write-Information "GUI: Standard-Auswahl (1) - '$Prompt'" -InformationAction Continue
                return "1"
            }

            # Enter zum Fortfahren
            if ($Prompt -match 'Enter|Weiter|Continue|fortfahren') {
                Write-Information "GUI: Enter zum Fortfahren - '$Prompt'" -InformationAction Continue
                return ""
            }

            # Fallback: erste Option oder leer
            Write-Information "GUI: Fallback-Antwort (1) - '$Prompt'" -InformationAction Continue
            return "1"
        }

        # --- Variablen setzen ---
        $script:RootPath          = $rootPath
        $script:ModulesPath       = $modulesPath
        $script:DebugLevel        = $dbgLevel
        $script:AutoApproveCleanup= $true
        $script:LogBuffer         = @()
        $script:Errors            = @()
        $script:Warnings          = @()
        $script:TotalFreedSpace   = 0
        $script:AVSafeMode        = $true

        # --- Module laden ---
        if (Test-Path $modulesPath) {
            Get-ChildItem "$modulesPath\*.ps1" -EA SilentlyContinue | ForEach-Object {
                try { . $_.FullName } catch {
                    if ($dbgLevel -ge 1) { Write-Information "Modul-Ladefehler ($($_.Exception.TargetObject)): $($_.Exception.Message)" -InformationAction Continue }
                }
            }
        }
        if (Get-Command Initialize-Logging -EA SilentlyContinue) {
            Initialize-Logging -LogDirectory "$env:TEMP\HellionPowerTool" -DetailedLogging
        }

        # --- Modul ausführen (sicheres Parameter-Splatting statt Invoke-Expression) ---
        try {
            if ($guiArgs -and $guiArgs.Trim() -ne '') {
                # Args-String in Parameter-Hashtable parsen (kein Code-Injection-Risiko)
                $params = @{}
                $tokens = $guiArgs -split '\s+'
                $ti = 0
                while ($ti -lt $tokens.Count) {
                    $tok = $tokens[$ti]
                    if ($tok -match '^-(\w+)$') {
                        $pName = $Matches[1]
                        if ($ti + 1 -lt $tokens.Count -and $tokens[$ti+1] -notmatch '^-') {
                            $params[$pName] = $tokens[$ti+1]
                            $ti += 2
                        } else {
                            $params[$pName] = $true
                            $ti++
                        }
                    } else {
                        $ti++
                    }
                }
                & $funcName @params
            } else {
                & $funcName
            }
        }
        catch { Write-Information "FEHLER: $($_.Exception.Message)" -InformationAction Continue }
    }).AddArgument($rootPath).AddArgument($modulesPath).AddArgument($funcName).AddArgument($guiArgs).AddArgument($dbgLevel).AddArgument($isDestructive) | Out-Null

    # Gemeinsamer State-Hashtable für alle Timer-Closures
    # Hashtable ist ein Reference-Type und funktioniert zuverlässig in Closures
    # (im Gegensatz zu [ref] das in DispatcherTimer-Handlern Probleme macht)
    $s = @{
        ProgVal    = 0.0
        TickCount  = 0
        MaxTicks   = 1500
        Ref        = $ref
        Acc        = $acc
        PS         = $ps
        RS         = $rs
        Handle     = $null
        ProgTimer  = $null
        CheckTimer = $null
        HideTimer  = $null
        OnComplete = $OnComplete
        ModId      = $ModId
        InfoIdx    = 0
        WarnIdx    = 0
        ErrIdx     = 0
        StartTime  = Get-Date
        InfoCount  = 0
        WarnCount  = 0
        ErrCount   = 0
        LastStreamTick = 0
        HeartbeatShown = $false
    }

    # Progress-Simulation
    $s.ProgTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $s.ProgTimer.Interval = [TimeSpan]::FromMilliseconds(350)
    $s.ProgTimer.Add_Tick({
        if ($s.ProgVal -lt 88) {
            $step = [System.Math]::Max(1.0, 8.0 - $s.ProgVal / 12.0)
            $s.ProgVal = [System.Math]::Min(88.0, $s.ProgVal + $step)
            $pv = [int]$s.ProgVal
            $ctrl['ActiveProgress'].Value = $pv
            $ctrl['ActiveModulePercent'].Text = "$pv%"
            if ($null -ne $s.Ref -and $null -ne $s.Ref.Prog) { $s.Ref.Prog.Value = $pv }
        }
    }.GetNewClosure())
    $s.ProgTimer.Start()

    # Streams werden NICHT via DataAdded-Events gelesen (feuern auf Hintergrund-Thread,
    # .GetNewClosure() funktioniert dort nicht zuverlässig). Stattdessen pollt der
    # CheckTimer alle 400ms die Streams und schreibt neue Einträge ins Log.

    $s.Handle = $ps.BeginInvoke()

    # Referenzen global speichern für Stop-Button
    $global:RunningModule.PowerShell  = $ps
    $global:RunningModule.Runspace    = $rs
    $global:RunningModule.ModId       = $ModId
    $global:RunningModule.State       = $s

    # Completion + Timeout + Stream-Polling
    $s.CheckTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $s.CheckTimer.Interval = [TimeSpan]::FromMilliseconds(400)
    $s.CheckTimer.Add_Tick({
        $s.TickCount++

        # --- Stream-Polling: neue Einträge aus dem Runspace ins Log schreiben ---
        # Läuft auf dem UI-Thread (DispatcherTimer), daher sicher für GUI-Zugriff.
        # Write-Host erzeugt HostInformationMessage (mit Farbe), Write-Information erzeugt String.
        try {
            while ($s.InfoIdx -lt $s.PS.Streams.Information.Count) {
                $rec = $s.PS.Streams.Information[$s.InfoIdx]
                $msgData = $rec.MessageData
                $msgText  = $null
                $msgColor = "#AAAAAA"
                if ($msgData -is [System.Management.Automation.HostInformationMessage]) {
                    $msgText = $msgData.Message
                    $fc = $msgData.ForegroundColor
                    if ($null -ne $fc) {
                        switch ([string]$fc) {
                            'Cyan'    { $msgColor = "#2DD4BF" }
                            'Yellow'  { $msgColor = "#F5A623" }
                            'Green'   { $msgColor = "#3DD68C" }
                            'Red'     { $msgColor = "#FF5F57" }
                            'Magenta' { $msgColor = "#A78BFA" }
                            'White'   { $msgColor = "#CCCCCC" }
                            'Gray'    { $msgColor = "#888888" }
                            'DarkGray'{ $msgColor = "#666666" }
                        }
                    }
                } else {
                    $msgText = "$msgData"
                }
                if ($msgText) { Add-LogLine "  $msgText" $msgColor }
                $s.InfoIdx++
                $s.InfoCount++
            }
            while ($s.WarnIdx -lt $s.PS.Streams.Warning.Count) {
                $msg = $s.PS.Streams.Warning[$s.WarnIdx].Message
                if ($msg) { Add-LogLine "  $msg" "#F5A623" }
                $s.WarnIdx++
                $s.WarnCount++
            }
            while ($s.ErrIdx -lt $s.PS.Streams.Error.Count) {
                $e = $s.PS.Streams.Error[$s.ErrIdx]
                if ($e) { Add-LogLine "  $($e.Exception.Message)" "#FF5F57" }
                $s.ErrIdx++
                $s.ErrCount++
            }
        } catch {
            if ($script:DebugLevel -ge 2) { Add-LogLine "  [DEV] Stream-Poll Fehler: $($_.Exception.Message)" "#666666" }
        }

        # --- Heartbeat: Laufzeit-Anzeige wenn keine neuen Streams kommen ---
        $currentTotal = $s.InfoCount + $s.WarnCount + $s.ErrCount
        if (-not $s.ContainsKey('PrevTotal')) { $s.PrevTotal = 0 }
        if ($currentTotal -gt $s.PrevTotal) {
            $s.LastStreamTick = $s.TickCount
            $s.PrevTotal = $currentTotal
            $s.HeartbeatShown = $false
        }
        $silentTicks = $s.TickCount - $s.LastStreamTick
        # Nach 12 Sekunden Stille (30 Ticks * 400ms) Laufzeit im Panel anzeigen
        if ($silentTicks -ge 30 -and -not $s.Handle.IsCompleted) {
            $elapsed = [int]((Get-Date) - $s.StartTime).TotalSeconds
            $min = [int]($elapsed / 60)
            $sec = $elapsed % 60
            $timeStr = if ($min -gt 0) { "${min}m ${sec}s" } else { "${sec}s" }
            $ctrl['ActiveModulePercent'].Text = $timeStr
            # Einmalig Hinweis im Log
            if (-not $s.HeartbeatShown) {
                Add-LogLine "  Modul arbeitet im Hintergrund..." "#777777"
                $s.HeartbeatShown = $true
            }
        }

        # Timeout: Runspace nach 10 Minuten abbrechen
        if (-not $s.Handle.IsCompleted -and $s.TickCount -ge $s.MaxTicks) {
            $s.CheckTimer.Stop()
            $s.ProgTimer.Stop()
            try { $s.PS.Stop()    } catch {}
            try { $s.PS.Dispose() } catch {}
            try { $s.RS.Dispose() } catch {}
            $convT = [System.Windows.Media.BrushConverter]::new()
            if ($null -ne $s.Ref -and $null -ne $s.Ref.Dot) {
                $s.Ref.Dot.Fill          = $convT.ConvertFromString("#F5A623")
                $s.Ref.Status.Text       = "Timeout"
                $s.Ref.Status.Foreground = $convT.ConvertFromString("#F5A623")
                $s.Ref.Prog.Value        = 0
            }
            $ctrl['ActiveModulePanel'].Visibility = "Collapsed"
            # LiveDot-Puls stoppen
            $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
            $ctrl['LiveDot'].Opacity = 1.0
            Add-LogLine "[TIMEOUT] $($s.Ref.Title) nach 10 Min abgebrochen" "#F5A623"
            $global:RunningModule.PowerShell = $null
            $global:RunningModule.Runspace   = $null
            $global:RunningModule.ModId      = $null
            $global:RunningModule.State      = $null
            if ($null -ne $s.OnComplete) { try { & $s.OnComplete } catch {} }
            return
        }

        if (-not $s.Handle.IsCompleted) { return }

        # --- Modul fertig: restliche Streams noch einmal drainieren ---
        $s.CheckTimer.Stop()
        $s.ProgTimer.Stop()
        try { $s.PS.EndInvoke($s.Handle) } catch {}

        try {
            while ($s.InfoIdx -lt $s.PS.Streams.Information.Count) {
                $rec = $s.PS.Streams.Information[$s.InfoIdx]
                $msgData = $rec.MessageData
                $msgText  = $null
                $msgColor = "#AAAAAA"
                if ($msgData -is [System.Management.Automation.HostInformationMessage]) {
                    $msgText = $msgData.Message
                    $fc = $msgData.ForegroundColor
                    if ($null -ne $fc) {
                        switch ([string]$fc) {
                            'Cyan'    { $msgColor = "#2DD4BF" }
                            'Yellow'  { $msgColor = "#F5A623" }
                            'Green'   { $msgColor = "#3DD68C" }
                            'Red'     { $msgColor = "#FF5F57" }
                            'Magenta' { $msgColor = "#A78BFA" }
                            'White'   { $msgColor = "#CCCCCC" }
                            'Gray'    { $msgColor = "#888888" }
                            'DarkGray'{ $msgColor = "#666666" }
                        }
                    }
                } else {
                    $msgText = "$msgData"
                }
                if ($msgText) { Add-LogLine "  $msgText" $msgColor }
                $s.InfoIdx++
                $s.InfoCount++
            }
            while ($s.WarnIdx -lt $s.PS.Streams.Warning.Count) {
                $msg = $s.PS.Streams.Warning[$s.WarnIdx].Message
                if ($msg) { Add-LogLine "  $msg" "#F5A623" }
                $s.WarnIdx++
                $s.WarnCount++
            }
            while ($s.ErrIdx -lt $s.PS.Streams.Error.Count) {
                $e = $s.PS.Streams.Error[$s.ErrIdx]
                if ($e) { Add-LogLine "  $($e.Exception.Message)" "#FF5F57" }
                $s.ErrIdx++
                $s.ErrCount++
            }
        } catch {
            if ($script:DebugLevel -ge 2) { Add-LogLine "  [DEV] Stream-Drain Fehler: $($_.Exception.Message)" "#666666" }
        }

        $ok        = $s.PS.Streams.Error.Count -eq 0
        $doneColor = if ($ok) { "#3DD68C" } else { "#FF5F57" }
        $doneText  = if ($ok) { "Abgeschlossen" } else { "Fehler" }
        $doneIcon  = if ($ok) { "[OK]" } else { "[FEHLER]" }
        $convD     = [System.Windows.Media.BrushConverter]::new()

        if ($null -ne $s.Ref -and $null -ne $s.Ref.Dot) {
            $s.Ref.Dot.Fill          = $convD.ConvertFromString($doneColor)
            $s.Ref.Status.Text       = $doneText
            $s.Ref.Status.Foreground = $convD.ConvertFromString($doneColor)
            $s.Ref.Prog.Value        = 100
            $s.Ref.Prog.Foreground   = $convD.ConvertFromString($doneColor)
        }
        $ctrl['ActiveProgress'].Value = 100
        $ctrl['ActiveModulePercent'].Text = "100%"

        Add-LogLine "$doneIcon $($s.Ref.Title) $doneText" $doneColor

        # Debug-Logging bei Modul-Abschluss
        if ($script:DebugLevel -ge 1) {
            $elapsed = ((Get-Date) - $s.StartTime).TotalSeconds
            Add-LogLine "  Laufzeit: $([math]::Round($elapsed, 1))s" "#777777"
        }
        if ($script:DebugLevel -ge 2) {
            Add-LogLine "  Streams: $($s.InfoCount) Info, $($s.WarnCount) Warn, $($s.ErrCount) Error" "#777777"
        }

        # Toast-Benachrichtigung bei Modul-Abschluss
        Show-ToastNotification -Title "Hellion Power Tool" -Message "$($s.Ref.Title) $doneText"

        # LiveDot-Puls stoppen
        $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $ctrl['LiveDot'].Opacity = 1.0

        # hideTimer: $this ist der Event-Sender (der Timer selbst)
        # Keine .GetNewClosure() nötig — $this wird vom Event-System gesetzt,
        # $ctrl ist aus dem äußeren Closure-Scope erreichbar
        $s.HideTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $s.HideTimer.Interval = [TimeSpan]::FromSeconds(4)
        $s.HideTimer.Add_Tick({
            $this.Stop()
            $ctrl['ActiveModulePanel'].Visibility = "Collapsed"
        })
        $s.HideTimer.Start()

        try { $s.PS.Dispose() } catch {}
        try { $s.RS.Dispose() } catch {}

        # Globale Referenzen löschen
        $global:RunningModule.PowerShell = $null
        $global:RunningModule.Runspace   = $null
        $global:RunningModule.ModId      = $null
        $global:RunningModule.State      = $null

        # OnComplete-Callback für Queue-Verkettung
        if ($null -ne $s.OnComplete) {
            try { & $s.OnComplete } catch {}
        }
    }.GetNewClosure())
    $s.CheckTimer.Start()

    $global:RunningModule.ProgTimer  = $s.ProgTimer
    $global:RunningModule.CheckTimer = $s.CheckTimer
}

# ===================================================================
# MODUL-QUEUE (Sequentielle Ausführung für Auto-Modus)
# ===================================================================
function Start-ModuleQueue {
    param([string[]]$ModuleIds)
    if ($ModuleIds.Count -eq 0) {
        Add-LogLine "=== AUTO-MODUS ABGESCHLOSSEN ===" "#3DD68C"
        Show-ToastNotification -Title "Hellion Power Tool" -Message "Auto-Modus abgeschlossen"
        return
    }

    $currentId   = $ModuleIds[0]
    $remainingIds = @($ModuleIds | Select-Object -Skip 1)

    $callback = {
        Start-ModuleQueue -ModuleIds $remainingIds
    }.GetNewClosure()

    Start-ModuleAsync -ModId $currentId -OnComplete $callback
}

# ===================================================================
# HILFSFUNKTIONEN FÜR SETTINGS & LEGAL
# ===================================================================
function New-SettingsRow {
    param([string]$Label, [string]$Value, [string]$ValueColor = "")
    $conv = [System.Windows.Media.BrushConverter]::new()
    if (-not $ValueColor) { $ValueColor = Get-ThemeColor 'TxtPrimary' }
    $row = [System.Windows.Controls.DockPanel]::new()
    $row.Margin = [System.Windows.Thickness]::new(0,0,0,6)

    $lbl = [System.Windows.Controls.TextBlock]::new()
    $lbl.Text = $Label
    $lbl.FontSize = 12
    $lbl.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
    $lbl.Width = 180
    [System.Windows.Controls.DockPanel]::SetDock($lbl, "Left")

    $val = [System.Windows.Controls.TextBlock]::new()
    $val.Text = $Value
    $val.FontSize = 12
    $val.FontWeight = "SemiBold"
    $val.Foreground = $conv.ConvertFromString($ValueColor)

    $row.Children.Add($lbl) | Out-Null
    $row.Children.Add($val) | Out-Null
    return $row
}

function New-SettingsGroup {
    param([string]$Title, [scriptblock]$Content)
    $conv = [System.Windows.Media.BrushConverter]::new()
    $border = [System.Windows.Controls.Border]::new()
    $border.Background = $conv.ConvertFromString((Get-ThemeColor 'BgCard'))
    $border.BorderBrush = $conv.ConvertFromString((Get-ThemeColor 'BorderSub'))
    $border.BorderThickness = [System.Windows.Thickness]::new(1)
    $border.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $border.Padding = [System.Windows.Thickness]::new(16,12,16,14)
    $border.Margin = [System.Windows.Thickness]::new(0,0,0,12)

    $stack = [System.Windows.Controls.StackPanel]::new()

    $titleTb = [System.Windows.Controls.TextBlock]::new()
    $titleTb.Text = $Title
    $titleTb.FontSize = 13
    $titleTb.FontWeight = "SemiBold"
    $titleTb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'AccentGreen'))
    $titleTb.Margin = [System.Windows.Thickness]::new(0,0,0,10)
    $stack.Children.Add($titleTb) | Out-Null

    & $Content $stack

    $border.Child = $stack
    return $border
}

function New-HintText {
    param([string]$Text)
    $conv = [System.Windows.Media.BrushConverter]::new()
    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text = $Text
    $tb.FontSize = 11
    $tb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtFaded'))
    $tb.Margin = [System.Windows.Thickness]::new(0,4,0,0)
    $tb.TextWrapping = "Wrap"
    return $tb
}

function New-StyledButton {
    param([string]$Text, [scriptblock]$OnClick)
    $btn = [System.Windows.Controls.Button]::new()
    $btn.Style = $window.Resources['SecBtn']
    $btn.Content = $Text
    $btn.Padding = [System.Windows.Thickness]::new(12,5,12,5)
    $btn.FontSize = 11
    $btn.Margin = [System.Windows.Thickness]::new(0,6,0,0)
    $btn.HorizontalAlignment = "Left"
    $btn.Add_Click($OnClick)
    return $btn
}

function New-RadioOption {
    param([string]$Label, [string]$GroupName, [bool]$IsChecked = $false)
    $conv = [System.Windows.Media.BrushConverter]::new()
    $rb = [System.Windows.Controls.RadioButton]::new()
    $rb.Content = $Label
    $rb.GroupName = $GroupName
    $rb.IsChecked = $IsChecked
    $rb.FontSize = 12
    $rb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
    $rb.Margin = [System.Windows.Thickness]::new(0,3,0,0)
    return $rb
}

# ===================================================================
# EINSTELLUNGEN-SEITE (nur echte Settings)
# ===================================================================
function Build-SettingsPage {
    $global:Pages['Settings'].Children.Clear()
    $conv = [System.Windows.Media.BrushConverter]::new()

    $container = [System.Windows.Controls.StackPanel]::new()
    $container.Width = 520
    $container.HorizontalAlignment = "Left"

    # --- Design ---
    $container.Children.Add((New-SettingsGroup "Design" {
        param($s)
        $themeLabel = if ($script:CurrentTheme -eq "light") { "Light Mode" } else { "Dark Mode" }
        $s.Children.Add((New-SettingsRow "Aktuelles Theme:" $themeLabel (Get-ThemeColor 'AccentGreen'))) | Out-Null

        $s.Children.Add((New-StyledButton $(if ($script:CurrentTheme -eq "light") { "Dark Mode aktivieren" } else { "Light Mode aktivieren" }) {
            $newTheme = if ($script:CurrentTheme -eq "dark") { "light" } else { "dark" }
            Set-Theme -ThemeName $newTheme
            Build-SettingsPage
        })) | Out-Null
    })) | Out-Null

    # --- System-Health ---
    $container.Children.Add((New-SettingsGroup "System-Health" {
        param($s)
        $healthOn = ($null -ne $script:HealthTimer -and $script:HealthTimer.IsEnabled)

        # Toggle
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Content = "Health-Bar aktiviert"
        $cb.IsChecked = $healthOn
        $cb.FontSize = 12
        $cb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
        $cb.Add_Checked({
            $script:HealthTimer.Start()
            $ctrl['HealthBarPanel'].Visibility = "Visible"
            $script:GuiSettings.healthBar.enabled = $true
            Save-GuiSettings
        })
        $cb.Add_Unchecked({
            $script:HealthTimer.Stop()
            $ctrl['HealthBarPanel'].Visibility = "Collapsed"
            $script:GuiSettings.healthBar.enabled = $false
            Save-GuiSettings
        })
        $s.Children.Add($cb) | Out-Null

        # Intervall
        $intLabel = [System.Windows.Controls.TextBlock]::new()
        $intLabel.Text = "Aktualisierungs-Intervall:"
        $intLabel.FontSize = 12
        $intLabel.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
        $intLabel.Margin = [System.Windows.Thickness]::new(0,10,0,4)
        $s.Children.Add($intLabel) | Out-Null

        $currentMs = [int]$script:HealthTimer.Interval.TotalMilliseconds

        $rbSlow   = New-RadioOption "Sparsam (5 Sekunden)"  "HealthInterval" ($currentMs -ge 4000)
        $rbNormal = New-RadioOption "Normal (2 Sekunden)"   "HealthInterval" ($currentMs -ge 1500 -and $currentMs -lt 4000)
        $rbFast   = New-RadioOption "Echtzeit (1 Sekunde)"  "HealthInterval" ($currentMs -lt 1500)

        $rbSlow.Add_Checked({
            $script:HealthTimer.Interval = [TimeSpan]::FromMilliseconds(5000)
            $script:GuiSettings.healthBar.intervalMs = 5000
            Save-GuiSettings
        })
        $rbNormal.Add_Checked({
            $script:HealthTimer.Interval = [TimeSpan]::FromMilliseconds(2000)
            $script:GuiSettings.healthBar.intervalMs = 2000
            Save-GuiSettings
        })
        $rbFast.Add_Checked({
            $script:HealthTimer.Interval = [TimeSpan]::FromMilliseconds(1000)
            $script:GuiSettings.healthBar.intervalMs = 1000
            Save-GuiSettings
        })

        $s.Children.Add($rbSlow) | Out-Null
        $s.Children.Add($rbNormal) | Out-Null
        $s.Children.Add($rbFast) | Out-Null
        $s.Children.Add((New-HintText "Wie oft CPU, RAM und Disk aktualisiert werden. 'Sparsam' schont die CPU.")) | Out-Null
    })) | Out-Null

    # --- Log ---
    $container.Children.Add((New-SettingsGroup "Log-Verlauf" {
        param($s)

        # Auto-Scroll
        $asCb = [System.Windows.Controls.CheckBox]::new()
        $asCb.Content = "Log automatisch scrollen"
        $asCb.IsChecked = ($script:GuiSettings.log.autoScroll -eq $true)
        $asCb.FontSize = 12
        $asCb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
        $asCb.Add_Checked({
            $script:GuiSettings.log.autoScroll = $true
            Save-GuiSettings
        })
        $asCb.Add_Unchecked({
            $script:GuiSettings.log.autoScroll = $false
            Save-GuiSettings
        })
        $s.Children.Add($asCb) | Out-Null

        # Aufbewahrung
        $retLabel = [System.Windows.Controls.TextBlock]::new()
        $retLabel.Text = "Log-Aufbewahrung:"
        $retLabel.FontSize = 12
        $retLabel.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
        $retLabel.Margin = [System.Windows.Thickness]::new(0,10,0,4)
        $s.Children.Add($retLabel) | Out-Null

        $curRet = 30
        if ($script:GuiSettings.log -and $script:GuiSettings.log.retentionDays) {
            $curRet = [int]$script:GuiSettings.log.retentionDays
        }

        $rb7  = New-RadioOption "7 Tage"  "LogRetention" ($curRet -le 7)
        $rb30 = New-RadioOption "30 Tage" "LogRetention" ($curRet -gt 7 -and $curRet -le 30)
        $rb90 = New-RadioOption "90 Tage" "LogRetention" ($curRet -gt 30)

        $rb7.Add_Checked({
            $script:GuiSettings.log.retentionDays = 7
            Save-GuiSettings
        })
        $rb30.Add_Checked({
            $script:GuiSettings.log.retentionDays = 30
            Save-GuiSettings
        })
        $rb90.Add_Checked({
            $script:GuiSettings.log.retentionDays = 90
            Save-GuiSettings
        })

        $s.Children.Add($rb7)  | Out-Null
        $s.Children.Add($rb30) | Out-Null
        $s.Children.Add($rb90) | Out-Null
        $s.Children.Add((New-HintText "Ältere Logdateien werden beim Start automatisch gelöscht.")) | Out-Null
    })) | Out-Null

    # --- Sicherheit ---
    $container.Children.Add((New-SettingsGroup "Sicherheit" {
        param($s)
        $arpCb = [System.Windows.Controls.CheckBox]::new()
        $arpCb.Content = "Automatischer Wiederherstellungspunkt vor Systemänderungen"
        $arpCb.FontSize = 12
        $arpCb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
        $safetyS = $script:GuiSettings.safety
        $arpCb.IsChecked = ($safetyS -and $safetyS.autoRestorePoint -ne $false)
        $arpCb.Add_Checked({
            if (-not $script:GuiSettings.safety) { $script:GuiSettings.safety = @{} }
            $script:GuiSettings.safety.autoRestorePoint = $true
            Save-GuiSettings
        })
        $arpCb.Add_Unchecked({
            if (-not $script:GuiSettings.safety) { $script:GuiSettings.safety = @{} }
            $script:GuiSettings.safety.autoRestorePoint = $false
            Save-GuiSettings
        })
        $s.Children.Add($arpCb) | Out-Null
        $s.Children.Add((New-HintText "Erstellt automatisch einen Windows-Wiederherstellungspunkt bevor Module ausgeführt werden, die Systemdateien verändern können.")) | Out-Null
    })) | Out-Null

    # --- Fenster ---
    $container.Children.Add((New-SettingsGroup "Fenster" {
        param($s)
        $s.Children.Add((New-SettingsRow "Größe:" "$([int]$window.Width) x $([int]$window.Height)")) | Out-Null
        $s.Children.Add((New-SettingsRow "Position:" "Links=$([int]$window.Left), Oben=$([int]$window.Top)")) | Out-Null
        $s.Children.Add((New-StyledButton "Position zurücksetzen" {
            $window.Left = ([System.Windows.SystemParameters]::WorkArea.Width - $window.Width) / 2
            $window.Top  = ([System.Windows.SystemParameters]::WorkArea.Height - $window.Height) / 2
            Build-SettingsPage
        })) | Out-Null
    })) | Out-Null

    # --- Updates & Datenschutz ---
    $container.Children.Add((New-SettingsGroup "Updates & Datenschutz" {
        param($s)
        $localVerFile = Join-Path $script:RootPath "config\version.txt"
        if (Test-Path $localVerFile) {
            $verLines = Get-Content $localVerFile -EA SilentlyContinue
            if ($verLines.Count -ge 3) {
                $s.Children.Add((New-SettingsRow "Installiert:" "v$($verLines[0]) $($verLines[1])" "#3DD68C")) | Out-Null
                $s.Children.Add((New-SettingsRow "Datum:" $verLines[2])) | Out-Null
            }
        }

        # Automatischer Update-Check Toggle (DSGVO-konform: Default AUS)
        $convU = [System.Windows.Media.BrushConverter]::new()
        $updateToggle = [System.Windows.Controls.CheckBox]::new()
        $updateToggle.Content = "Automatisch auf Updates prüfen"
        $updateToggle.FontSize = 12
        $updateToggle.Foreground = $convU.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
        $updateToggle.Margin = [System.Windows.Thickness]::new(0,6,0,2)
        $privSettings = $script:GuiSettings.privacy
        $updateToggle.IsChecked = ($privSettings -and $privSettings.checkForUpdates -eq $true)
        $updateToggle.Add_Checked({
            if (-not $script:GuiSettings.privacy) { $script:GuiSettings.privacy = @{} }
            $script:GuiSettings.privacy.checkForUpdates = $true
            Save-GuiSettings
        })
        $updateToggle.Add_Unchecked({
            if (-not $script:GuiSettings.privacy) { $script:GuiSettings.privacy = @{} }
            $script:GuiSettings.privacy.checkForUpdates = $false
            Save-GuiSettings
        })
        $s.Children.Add($updateToggle) | Out-Null

        # DSGVO-Hinweis
        $privacyNote = [System.Windows.Controls.TextBlock]::new()
        $privacyNote.Text = "Beim Update-Check wird eine Verbindung zu GitHub (github.com) hergestellt. Dabei wird Ihre IP-Adresse an GitHub/Cloudflare übermittelt. Es werden keine weiteren Daten gesendet oder gespeichert."
        $privacyNote.FontSize = 10
        $privacyNote.Foreground = $convU.ConvertFromString((Get-ThemeColor 'TxtDim'))
        $privacyNote.TextWrapping = "Wrap"
        $privacyNote.Margin = [System.Windows.Thickness]::new(0,2,0,8)
        $s.Children.Add($privacyNote) | Out-Null

        $s.Children.Add((New-StyledButton "Auf Updates prüfen" { Check-ForUpdate -Manual })) | Out-Null
    })) | Out-Null

    # --- Entwickler ---
    $container.Children.Add((New-SettingsGroup "Entwickler" {
        param($s)

        $intLabel = [System.Windows.Controls.TextBlock]::new()
        $intLabel.Text = "Debug-Level:"
        $intLabel.FontSize = 12
        $intLabel.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
        $intLabel.Margin = [System.Windows.Thickness]::new(0,0,0,4)
        $s.Children.Add($intLabel) | Out-Null

        $rbNormal = New-RadioOption "Normal"    "DebugLevel" ($script:DebugLevel -eq 0)
        $rbDebug  = New-RadioOption "Debug"     "DebugLevel" ($script:DebugLevel -eq 1)
        $rbDev    = New-RadioOption "Developer" "DebugLevel" ($script:DebugLevel -eq 2)

        $rbNormal.Add_Checked({
            $script:DebugLevel = 0
            Update-DebugBadge
            Add-LogLine "Debug-Level: Normal" "#777777"
            Build-SettingsPage
        })
        $rbDebug.Add_Checked({
            $script:DebugLevel = 1
            Update-DebugBadge
            Add-LogLine "Debug-Level: Debug (erweiterte Infos)" "#F5A623"
            Build-SettingsPage
        })
        $rbDev.Add_Checked({
            # Developer-Modus mit Disclaimer-Overlay
            Show-DevDisclaimer
        })

        $s.Children.Add($rbNormal) | Out-Null
        $s.Children.Add($rbDebug)  | Out-Null
        $s.Children.Add($rbDev)    | Out-Null
        $s.Children.Add((New-HintText "Debug und Developer zeigen zusätzliche technische Informationen im Log-Panel. Developer-Modus wird bei Neustart zurückgesetzt.")) | Out-Null
    })) | Out-Null

    $global:Pages['Settings'].Children.Add($container) | Out-Null
    $global:PageBuilt['Settings'] = $true
}

# ===================================================================
# DEV-MODE FUNKTIONEN
# ===================================================================
function Update-DebugBadge {
    $convD = [System.Windows.Media.BrushConverter]::new()
    switch ($script:DebugLevel) {
        1 {
            $ctrl['StatusDebugBadge'].Text = "[DEBUG]"
            $ctrl['StatusDebugBadge'].Foreground = $convD.ConvertFromString("#F5A623")
            $ctrl['StatusDebugBadge'].Visibility = "Visible"
        }
        2 {
            $ctrl['StatusDebugBadge'].Text = "[DEV]"
            $ctrl['StatusDebugBadge'].Foreground = $convD.ConvertFromString("#FF5F57")
            $ctrl['StatusDebugBadge'].Visibility = "Visible"
        }
        default {
            $ctrl['StatusDebugBadge'].Visibility = "Collapsed"
        }
    }
}

function Show-DevDisclaimer {
    $ctrl['OptionsOverlay'].Visibility = 'Visible'
    $ctrl['OptionsOverlay'].Tag = '__dev_disclaimer__'
    $ctrl['OptionsTitle'].Text = "Developer-Modus"

    $ctrl['OptionsStack'].Children.Clear()

    $convD = [System.Windows.Media.BrushConverter]::new()

    $warnText = [System.Windows.Controls.TextBlock]::new()
    $warnText.Text = "Dieser Modus zeigt alle Debug-Informationen und erweiterte Diagnose-Daten an.`n`nNur für Entwickler und technisch versierte Nutzer empfohlen."
    $warnText.FontSize = 12
    $warnText.Foreground = $convD.ConvertFromString((Get-ThemeColor 'TxtSecondary'))
    $warnText.TextWrapping = "Wrap"
    $warnText.Margin = [System.Windows.Thickness]::new(0,0,0,12)
    $ctrl['OptionsStack'].Children.Add($warnText) | Out-Null

    $activateBtn = [System.Windows.Controls.Button]::new()
    $activateBtn.Style = $window.Resources['SecBtn']
    $activateBtn.Content = "Aktivieren"
    $activateBtn.Padding = [System.Windows.Thickness]::new(14,8,14,8)
    $activateBtn.HorizontalAlignment = "Stretch"
    $activateBtn.Add_Click({
        $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
        $script:DebugLevel = 2
        Update-DebugBadge
        Add-LogLine "Debug-Level: Developer (alle Debug-Infos)" "#FF5F57"
        Build-SettingsPage
    }.GetNewClosure())
    $ctrl['OptionsStack'].Children.Add($activateBtn) | Out-Null
}

# ===================================================================
# RECHTLICHES & INFO-SEITE
# ===================================================================
function Build-LegalPage {
    $global:Pages['Legal'].Children.Clear()

    $container = [System.Windows.Controls.StackPanel]::new()
    $container.Width = 520
    $container.HorizontalAlignment = "Left"

    $conv = [System.Windows.Media.BrushConverter]::new()

    # --- Tool-Informationen ---
    $container.Children.Add((New-SettingsGroup "Tool-Informationen" {
        param($s)
        $s.Children.Add((New-SettingsRow "Version:" "v8.0.0.0" "#3DD68C")) | Out-Null
        $s.Children.Add((New-SettingsRow "Codename:" "Jörmungandr" "#A78BFA")) | Out-Null
        $s.Children.Add((New-SettingsRow "GUI Version:" "v1.0.0" "#F5A623")) | Out-Null

        $psVer = "v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)"
        $edition = "Desktop"
        if ($PSVersionTable.ContainsKey('PSEdition')) { $edition = [string]$PSVersionTable.PSEdition }
        $s.Children.Add((New-SettingsRow "PowerShell:" "$psVer ($edition)")) | Out-Null

        $osCaption = (Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).Caption
        if (-not $osCaption) { $osCaption = "Windows" }
        $s.Children.Add((New-SettingsRow "Betriebssystem:" $osCaption)) | Out-Null

        $modCount = (Get-ChildItem "$script:ModulesPath\*.ps1" -EA SilentlyContinue).Count
        $s.Children.Add((New-SettingsRow "Geladene Module:" "$modCount" "#3DD68C")) | Out-Null
    })) | Out-Null

    # --- Herausgeber ---
    $container.Children.Add((New-SettingsGroup "Herausgeber" {
        param($s)
        $s.Children.Add((New-SettingsRow "Firma:" "Hellion Online Media" "#448f45")) | Out-Null
        $s.Children.Add((New-SettingsRow "Inhaber:" "Florian Wathling")) | Out-Null
        $s.Children.Add((New-SettingsRow "Rechtsform:" "Einzelunternehmen")) | Out-Null
        $s.Children.Add((New-SettingsRow "Website:" "hellion-media.de" "#448f45")) | Out-Null
        $s.Children.Add((New-SettingsRow "Kontakt:" "kontakt@hellion-media.de")) | Out-Null
        $s.Children.Add((New-StyledButton "Website öffnen" {
            Start-Process "https://hellion-media.de"
        })) | Out-Null
    })) | Out-Null

    # --- Entwicklung ---
    $container.Children.Add((New-SettingsGroup "Entwicklung" {
        param($s)
        $s.Children.Add((New-SettingsRow "Entwickler:" "Florian Wathling (Jon)")) | Out-Null
        $s.Children.Add((New-SettingsRow "Sprache:" "PowerShell / WPF (XAML)")) | Out-Null
        $s.Children.Add((New-SettingsRow "Plattform:" "Windows 10/11 (x64)")) | Out-Null
        $s.Children.Add((New-SettingsRow "Repository:" "GitHub" "#448f45")) | Out-Null
        $s.Children.Add((New-StyledButton "GitHub-Repository öffnen" {
            Start-Process "https://github.com/JonKazama-Hellion/hellion-power-tool"
        })) | Out-Null
    })) | Out-Null

    # --- Rechtliches ---
    $container.Children.Add((New-SettingsGroup "Rechtliches" {
        param($s)
        $s.Children.Add((New-StyledButton "Datenschutzerklärung öffnen" {
            Start-Process "https://hellion-media.de/de/datenschutz"
        })) | Out-Null
        $s.Children.Add((New-StyledButton "Impressum öffnen" {
            Start-Process "https://hellion-media.de/de/impressum"
        })) | Out-Null
        $s.Children.Add((New-StyledButton "Haftungsausschluss (DISCLAIMER.md)" {
            $dPath = Join-Path $script:RootPath "DISCLAIMER.md"
            if (Test-Path $dPath) { Start-Process $dPath }
        })) | Out-Null
        $s.Children.Add((New-StyledButton "Lizenz (LICENSE)" {
            $lPath = Join-Path $script:RootPath "LICENSE"
            if (Test-Path $lPath) { Start-Process $lPath }
        })) | Out-Null
    })) | Out-Null

    # --- Fußnote: AI-Hinweis + Copyright ---
    $footerPanel = [System.Windows.Controls.StackPanel]::new()
    $footerPanel.Margin = [System.Windows.Thickness]::new(0,20,0,10)

    $divider = [System.Windows.Shapes.Rectangle]::new()
    $divider.Height = 1
    $divider.Fill = $conv.ConvertFromString((Get-ThemeColor 'BorderDivide'))
    $divider.Margin = [System.Windows.Thickness]::new(0,0,0,12)
    $footerPanel.Children.Add($divider) | Out-Null

    $aiNote = [System.Windows.Controls.TextBlock]::new()
    $aiNote.Text = "* Bei der Entwicklung dieser Software wurde KI-gestützte Programmierung eingesetzt (Claude Code Opus 4.6, Anthropic)."
    $aiNote.FontSize = 10
    $aiNote.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
    $aiNote.TextWrapping = "Wrap"
    $aiNote.Margin = [System.Windows.Thickness]::new(0,0,0,6)
    $footerPanel.Children.Add($aiNote) | Out-Null

    $copyright = [System.Windows.Controls.TextBlock]::new()
    $copyright.FontSize = 10
    $copyright.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtDim'))
    $copyright.TextWrapping = "Wrap"
    $copyright.Margin = [System.Windows.Thickness]::new(0,0,0,4)
    $year = (Get-Date).Year
    $copyright.Text = [char]0x00A9 + " $year Hellion Online Media. Alle Rechte vorbehalten."
    $footerPanel.Children.Add($copyright) | Out-Null

    $madeWith = [System.Windows.Controls.TextBlock]::new()
    $madeWith.Text = "Made in Germany mit PowerShell & WPF"
    $madeWith.FontSize = 10
    $madeWith.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtMuted'))
    $madeWith.Margin = [System.Windows.Thickness]::new(0,0,0,0)
    $footerPanel.Children.Add($madeWith) | Out-Null

    $container.Children.Add($footerPanel) | Out-Null

    $global:Pages['Legal'].Children.Add($container) | Out-Null
    $global:PageBuilt['Legal'] = $true
}

# ===================================================================
# BUILD-SYSTEM-PAGE — Hardware-/OS-Informationen
# ===================================================================
function Build-SystemPage {
    $global:Pages['System'].Children.Clear()
    $global:PageBuilt['System'] = $true

    # --- Loading-State sofort anzeigen ---
    $loadingPanel = [System.Windows.Controls.StackPanel]::new()
    $loadingPanel.HorizontalAlignment = "Center"
    $loadingPanel.Margin = [System.Windows.Thickness]::new(0,80,0,0)
    $loadingDot = [System.Windows.Shapes.Ellipse]::new()
    $loadingDot.Width = 12; $loadingDot.Height = 12
    $loadingDot.Fill = $global:HealthBrushes['Green']
    $loadingDot.HorizontalAlignment = "Center"
    $loadingDot.Margin = [System.Windows.Thickness]::new(0,0,0,12)
    $pulseAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $pulseAnim.From = 1.0; $pulseAnim.To = 0.2
    $pulseAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(500))
    $pulseAnim.AutoReverse = $true
    $pulseAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $loadingDot.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulseAnim)
    $loadingPanel.Children.Add($loadingDot) | Out-Null
    $loadingText = [System.Windows.Controls.TextBlock]::new()
    $loadingText.Text = "Systemdaten werden geladen..."
    $loadingText.FontSize = 13
    $loadingText.Foreground = $global:BrushConv.ConvertFromString("#777777")
    $loadingText.HorizontalAlignment = "Center"
    $loadingPanel.Children.Add($loadingText) | Out-Null
    $global:Pages['System'].Children.Add($loadingPanel) | Out-Null

    # --- CIM-Queries async im Runspace ---
    $sysPs = [PowerShell]::Create()
    $sysPs.AddScript({
        $cpu  = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
        $os   = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $cs   = Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue
        $mb   = Get-CimInstance Win32_BaseBoard -EA SilentlyContinue
        $gpu  = Get-CimInstance Win32_VideoController -EA SilentlyContinue
        $ram  = Get-CimInstance Win32_PhysicalMemory -EA SilentlyContinue
        $disk = Get-CimInstance Win32_DiskDrive -EA SilentlyContinue
        $bios = Get-CimInstance Win32_BIOS -EA SilentlyContinue
        $logDisks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -EA SilentlyContinue
        $memArray = Get-CimInstance Win32_PhysicalMemoryArray -EA SilentlyContinue
        @{ CPU=$cpu; OS=$os; CS=$cs; MB=$mb; GPU=$gpu; RAM=$ram; Disk=$disk; BIOS=$bios; LogDisks=$logDisks; MemArray=$memArray }
    }) | Out-Null
    $sysHandle = $sysPs.BeginInvoke()

    # Poll-Timer: Wartet auf CIM-Ergebnis, baut dann die echte Seite
    $sysCheckTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $sysCheckTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $sysCheckState = @{ PS=$sysPs; Handle=$sysHandle; Timer=$sysCheckTimer }
    $sysCheckTimer.Add_Tick({
        if (-not $sysCheckState.Handle.IsCompleted) { return }
        $sysCheckState.Timer.Stop()
        try {
            $result = $sysCheckState.PS.EndInvoke($sysCheckState.Handle)
            $d = $result[0]
            Build-SystemContent -cpu $d.CPU -os $d.OS -cs $d.CS -mb $d.MB -gpu $d.GPU -ram $d.RAM -disk $d.Disk -bios $d.BIOS -logDisks $d.LogDisks -memArray $d.MemArray
        } catch {
            $global:Pages['System'].Children.Clear()
            $errTxt = [System.Windows.Controls.TextBlock]::new()
            $errTxt.Text = "Fehler beim Laden der Systemdaten: $($_.Exception.Message)"
            $errTxt.Foreground = $global:BrushConv.ConvertFromString("#FF5F57")
            $errTxt.Margin = [System.Windows.Thickness]::new(20)
            $global:Pages['System'].Children.Add($errTxt) | Out-Null
        }
        try { $sysCheckState.PS.Dispose() } catch {}
    }.GetNewClosure())
    $sysCheckTimer.Start()
}

# Baut die eigentliche System-Seite mit bereits geladenen CIM-Daten
function Build-SystemContent {
    param($cpu, $os, $cs, $mb, $gpu, $ram, $disk, $bios, $logDisks, $memArray)
    $global:Pages['System'].Children.Clear()
    $conv = [System.Windows.Media.BrushConverter]::new()

    $container = [System.Windows.Controls.StackPanel]::new()
    $container.Width = 560
    $container.HorizontalAlignment = "Left"

    # --- Prozessor ---
    $container.Children.Add((New-SettingsGroup "Prozessor" {
        param($s)
        if ($cpu) {
            $s.Children.Add((New-SettingsRow "Modell:" $cpu.Name.Trim())) | Out-Null
            $s.Children.Add((New-SettingsRow "Kerne / Threads:" "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)")) | Out-Null
            $s.Children.Add((New-SettingsRow "Basistakt:" "$($cpu.MaxClockSpeed) MHz")) | Out-Null
            $arch = switch ($cpu.AddressWidth) { 64 {"x64"} 32 {"x86"} default {"$($cpu.AddressWidth)-bit"} }
            $s.Children.Add((New-SettingsRow "Architektur:" $arch)) | Out-Null
            if ($cpu.LoadPercentage -ne $null) {
                $s.Children.Add((New-SettingsRow "Aktuelle Auslastung:" "$($cpu.LoadPercentage)%")) | Out-Null
            }
        } else {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
    })) | Out-Null

    # --- Grafikkarte ---
    $container.Children.Add((New-SettingsGroup "Grafikkarte" {
        param($s)
        if ($gpu) {
            $gpuList = @($gpu)
            for ($i = 0; $i -lt $gpuList.Count; $i++) {
                $g = $gpuList[$i]
                $prefix = if ($gpuList.Count -gt 1) { "GPU $($i+1) " } else { "" }
                $s.Children.Add((New-SettingsRow "${prefix}Name:" $g.Name)) | Out-Null
                $vram = if ($g.AdapterRAM -and $g.AdapterRAM -gt 0) { "$([math]::Round($g.AdapterRAM / 1MB)) MB" } else { "Unbekannt" }
                $s.Children.Add((New-SettingsRow "${prefix}VRAM:" $vram)) | Out-Null
                if ($g.DriverVersion) { $s.Children.Add((New-SettingsRow "${prefix}Treiber:" $g.DriverVersion)) | Out-Null }
                if ($g.CurrentHorizontalResolution) {
                    $s.Children.Add((New-SettingsRow "${prefix}Auflösung:" "$($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution)")) | Out-Null
                }
                if ($i -lt $gpuList.Count - 1) {
                    $div = [System.Windows.Shapes.Rectangle]::new()
                    $div.Height = 1
                    $div.Fill = $conv.ConvertFromString((Get-ThemeColor 'BorderDivide'))
                    $div.Margin = [System.Windows.Thickness]::new(0,6,0,6)
                    $s.Children.Add($div) | Out-Null
                }
            }
        } else {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
    })) | Out-Null

    # --- Arbeitsspeicher ---
    $container.Children.Add((New-SettingsGroup "Arbeitsspeicher" {
        param($s)
        if ($ram) {
            $totalGB = [math]::Round(($ram | Measure-Object Capacity -Sum).Sum / 1GB, 1)
            $s.Children.Add((New-SettingsRow "Gesamt:" "$totalGB GB")) | Out-Null
            if ($os) {
                $usedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
                $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
                $pct = [int](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100)
                $s.Children.Add((New-SettingsRow "Belegt:" "$usedGB GB ($pct%)")) | Out-Null
                $s.Children.Add((New-SettingsRow "Verfügbar:" "$freeGB GB")) | Out-Null
            }
            $sticks = @($ram)
            $totalSlots = if ($memArray) { $memArray.MemoryDevices } else { $null }
            if ($totalSlots) { $s.Children.Add((New-SettingsRow "Steckplätze:" "$($sticks.Count) von $totalSlots belegt")) | Out-Null }
            $speed = ($sticks | Select-Object -First 1).Speed
            $memType = switch (($sticks | Select-Object -First 1).SMBIOSMemoryType) {
                26 {"DDR4"} 34 {"DDR5"} 24 {"DDR3"} default {"DDR"}
            }
            if ($speed) { $s.Children.Add((New-SettingsRow "Typ:" "$memType @ $speed MHz")) | Out-Null }
        } else {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
    })) | Out-Null

    # --- Mainboard & BIOS ---
    $container.Children.Add((New-SettingsGroup "Mainboard" {
        param($s)
        if ($mb) {
            $s.Children.Add((New-SettingsRow "Hersteller:" $mb.Manufacturer)) | Out-Null
            $s.Children.Add((New-SettingsRow "Modell:" $mb.Product)) | Out-Null
        }
        if ($bios) {
            $s.Children.Add((New-SettingsRow "BIOS:" $bios.Manufacturer)) | Out-Null
            $s.Children.Add((New-SettingsRow "BIOS-Version:" $bios.SMBIOSBIOSVersion)) | Out-Null
        }
        if (-not $mb -and -not $bios) {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
    })) | Out-Null

    # --- Festplatten ---
    $container.Children.Add((New-SettingsGroup "Festplatten" {
        param($s)
        if ($disk) {
            foreach ($d in @($disk)) {
                $sizeGB = [math]::Round($d.Size / 1GB)
                $dType = if ($d.MediaType -match 'SSD|Solid') { "SSD" } elseif ($d.MediaType -match 'Fixed') { "HDD" } else { $d.MediaType }
                $devId = $d.DeviceID -replace '^\\\\\.\\'
                $s.Children.Add((New-SettingsRow "${devId}:" "$($d.Model) ($sizeGB GB, $dType)")) | Out-Null
            }
            # Logische Laufwerke (aus Runspace-Cache)
            if ($logDisks) {
                $div = [System.Windows.Shapes.Rectangle]::new()
                $div.Height = 1
                $div.Fill = $conv.ConvertFromString((Get-ThemeColor 'BorderDivide'))
                $div.Margin = [System.Windows.Thickness]::new(0,6,0,6)
                $s.Children.Add($div) | Out-Null
                foreach ($ld in @($logDisks)) {
                    $freeGB = [math]::Round($ld.FreeSpace / 1GB, 1)
                    $totalGB = [math]::Round($ld.Size / 1GB, 1)
                    $s.Children.Add((New-SettingsRow "$($ld.DeviceID)" "$freeGB GB frei / $totalGB GB")) | Out-Null
                }
            }
        } else {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
    })) | Out-Null

    # --- Betriebssystem ---
    $container.Children.Add((New-SettingsGroup "Betriebssystem" {
        param($s)
        if ($os) {
            $s.Children.Add((New-SettingsRow "Name:" ($os.Caption -replace "Microsoft ", ""))) | Out-Null
            $s.Children.Add((New-SettingsRow "Version:" $os.Version)) | Out-Null
            $s.Children.Add((New-SettingsRow "Build:" $os.BuildNumber)) | Out-Null
            $s.Children.Add((New-SettingsRow "Architektur:" $os.OSArchitecture)) | Out-Null
            if ($os.LastBootUpTime) {
                $uptime = (Get-Date) - $os.LastBootUpTime
                $uptimeStr = if ($uptime.Days -gt 0) { "$($uptime.Days) Tage, $($uptime.Hours)h" } else { "$($uptime.Hours)h $($uptime.Minutes)m" }
                $s.Children.Add((New-SettingsRow "Letzter Start:" "$($os.LastBootUpTime.ToString('dd.MM.yyyy HH:mm')) (vor $uptimeStr)")) | Out-Null
            }
        } else {
            $s.Children.Add((New-SettingsRow "Status:" "Nicht verfügbar" "#F5A623")) | Out-Null
        }
        if ($cs) {
            $s.Children.Add((New-SettingsRow "Computername:" $cs.Name)) | Out-Null
        }
    })) | Out-Null

    # --- Export-Button ---
    $container.Children.Add((New-StyledButton "System-Info in Zwischenablage kopieren" {
        $cpuD  = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
        $osD   = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $csD   = Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue
        $mbD   = Get-CimInstance Win32_BaseBoard -EA SilentlyContinue
        $gpuD  = Get-CimInstance Win32_VideoController -EA SilentlyContinue
        $ramD  = Get-CimInstance Win32_PhysicalMemory -EA SilentlyContinue
        $diskD = Get-CimInstance Win32_DiskDrive -EA SilentlyContinue
        $logD  = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -EA SilentlyContinue

        $lines = @("=== Hellion Power Tool — System-Information ===", "")
        if ($cpuD) { $lines += "CPU: $($cpuD.Name.Trim()) ($($cpuD.NumberOfCores) Kerne / $($cpuD.NumberOfLogicalProcessors) Threads, $($cpuD.MaxClockSpeed) MHz)" }
        if ($gpuD) { foreach ($g in @($gpuD)) { $lines += "GPU: $($g.Name)" } }
        if ($ramD) {
            $totalGB = [math]::Round(($ramD | Measure-Object Capacity -Sum).Sum / 1GB, 1)
            $lines += "RAM: $totalGB GB"
        }
        if ($mbD) { $lines += "Mainboard: $($mbD.Manufacturer) $($mbD.Product)" }
        if ($osD) { $lines += "OS: $($osD.Caption) (Build $($osD.BuildNumber))" }
        if ($csD) { $lines += "Computer: $($csD.Name)" }
        if ($diskD) { foreach ($d in @($diskD)) { $lines += "Disk: $($d.Model) ($([math]::Round($d.Size / 1GB)) GB)" } }
        if ($logD) { foreach ($ld in @($logD)) { $lines += "Laufwerk $($ld.DeviceID) $([math]::Round($ld.FreeSpace / 1GB, 1)) GB frei / $([math]::Round($ld.Size / 1GB, 1)) GB" } }

        [System.Windows.Clipboard]::SetText($lines -join "`r`n")
        Add-LogLine "System-Info in Zwischenablage kopiert" "#3DD68C"
    })) | Out-Null

    $global:Pages['System'].Children.Add($container) | Out-Null
}

# ===================================================================
# SOFTWARE-INSTALLER (Ninite-Style via Winget)
# ===================================================================

# Closure-sicherer Helper für Checkbox-Erstellung
function New-SoftwareCheckbox {
    param([string]$PkgId, [string]$PkgName, [string]$PkgDesc, [bool]$IsRecommended)
    $convCb = [System.Windows.Media.BrushConverter]::new()

    $cb = [System.Windows.Controls.CheckBox]::new()
    $cb.IsChecked = $false
    $cb.Margin = [System.Windows.Thickness]::new(0,4,0,4)
    $cb.Foreground = $convCb.ConvertFromString((Get-ThemeColor 'TxtPrimary'))

    $cbStack = [System.Windows.Controls.StackPanel]::new()

    # Name-Zeile: DockPanel für Name links + Badge rechts
    $nameRow = [System.Windows.Controls.DockPanel]::new()
    $nameTb = [System.Windows.Controls.TextBlock]::new()
    $nameTb.Text = $PkgName
    $nameTb.FontSize = 12
    $nameTb.FontWeight = "SemiBold"
    $nameTb.Foreground = $convCb.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
    $nameRow.Children.Add($nameTb) | Out-Null
    $cbStack.Children.Add($nameRow) | Out-Null

    $descTb = [System.Windows.Controls.TextBlock]::new()
    $descTb.Text = $PkgDesc
    $descTb.FontSize = 10
    $descTb.TextWrapping = "Wrap"
    $descTb.Foreground = $convCb.ConvertFromString((Get-ThemeColor 'TxtSecondary'))
    $cbStack.Children.Add($descTb) | Out-Null

    $cb.Content = $cbStack

    $global:SoftwareChecks[$PkgId] = @{
        Checkbox    = $cb
        Name        = $PkgName
        Recommended = $IsRecommended
        NameRow     = $nameRow
    }

    return $cb
}

function Build-SoftwarePage {
    $global:Pages['Software'].Children.Clear()
    $conv = [System.Windows.Media.BrushConverter]::new()

    # Katalog laden
    $catalogPath = Join-Path $script:RootPath "config\software-catalog.json"
    if (-not (Test-Path $catalogPath)) {
        Add-LogLine "software-catalog.json nicht gefunden!" "#FF5F57"
        return
    }
    $catalog = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $container = [System.Windows.Controls.StackPanel]::new()
    $container.Width = 560
    $container.HorizontalAlignment = "Left"

    # Checkbox-Sammlung für spätere Auswertung
    $global:SoftwareChecks = @{}

    # --- Disclaimer ---
    $container.Children.Add((New-SettingsGroup "Hinweise" {
        param($s)
        $convD = [System.Windows.Media.BrushConverter]::new()
        $disclaimerTb = [System.Windows.Controls.TextBlock]::new()
        $disclaimerTb.Text = $catalog.disclaimer
        $disclaimerTb.TextWrapping = "Wrap"
        $disclaimerTb.FontSize = 11
        $disclaimerTb.Foreground = $convD.ConvertFromString((Get-ThemeColor 'TxtSecondary'))
        $disclaimerTb.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $s.Children.Add($disclaimerTb) | Out-Null

        foreach ($warn in $catalog.warnings) {
            $warnPanel = [System.Windows.Controls.StackPanel]::new()
            $warnPanel.Orientation = "Horizontal"
            $warnPanel.Margin = [System.Windows.Thickness]::new(0,2,0,2)

            $warnIcon = [System.Windows.Controls.TextBlock]::new()
            $warnIcon.Text = [char]0xE7BA
            $warnIcon.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe MDL2 Assets")
            $warnIcon.FontSize = 11
            $warnIcon.Foreground = $convD.ConvertFromString("#F5A623")
            $warnIcon.Margin = [System.Windows.Thickness]::new(0,0,6,0)
            $warnIcon.VerticalAlignment = "Top"
            $warnPanel.Children.Add($warnIcon) | Out-Null

            $warnTb = [System.Windows.Controls.TextBlock]::new()
            $warnTb.Text = $warn
            $warnTb.TextWrapping = "Wrap"
            $warnTb.FontSize = 11
            $warnTb.Foreground = $convD.ConvertFromString("#F5A623")
            $warnPanel.Children.Add($warnTb) | Out-Null

            $s.Children.Add($warnPanel) | Out-Null
        }
    })) | Out-Null

    # --- Quick-Select Buttons ---
    $quickPanel = [System.Windows.Controls.StackPanel]::new()
    $quickPanel.Orientation = "Horizontal"
    $quickPanel.Margin = [System.Windows.Thickness]::new(0,8,0,12)

    foreach ($qItem in @(
        @{ Label="Empfohlen"; Action="recommended" },
        @{ Label="Alle"; Action="all" },
        @{ Label="Keine"; Action="none" }
    )) {
        $qBtn = [System.Windows.Controls.Button]::new()
        $qBtn.Content = $qItem.Label
        $qBtn.Style = $window.FindResource('SecBtn')
        $qBtn.Padding = [System.Windows.Thickness]::new(14,6,14,6)
        $qBtn.Margin = [System.Windows.Thickness]::new(0,0,8,0)
        $capturedAction = $qItem.Action
        $qBtn.Add_Click({
            foreach ($entry in $global:SoftwareChecks.GetEnumerator()) {
                $cbRef = $entry.Value.Checkbox
                if ($capturedAction -eq "all") { $cbRef.IsChecked = $true }
                elseif ($capturedAction -eq "none") { $cbRef.IsChecked = $false }
                elseif ($capturedAction -eq "recommended") { $cbRef.IsChecked = $entry.Value.Recommended }
            }
        }.GetNewClosure())
        $quickPanel.Children.Add($qBtn) | Out-Null
    }

    $container.Children.Add($quickPanel) | Out-Null

    # --- Kategorie-Gruppen mit Checkboxen ---
    foreach ($cat in $catalog.categories) {
        $catNameCapt = $cat.name
        $catPkgs = $cat.packages
        $container.Children.Add((New-SettingsGroup "$catNameCapt" {
            param($s)
            foreach ($pkg in $catPkgs) {
                $isRec = if ($pkg.recommended) { $true } else { $false }
                $cbItem = New-SoftwareCheckbox -PkgId $pkg.id -PkgName $pkg.name -PkgDesc $pkg.desc -IsRecommended $isRec
                $s.Children.Add($cbItem) | Out-Null
            }
        })) | Out-Null
    }

    # --- Installieren-Button ---
    $installBtn = [System.Windows.Controls.Button]::new()
    $installBtn.Style = $window.FindResource('PrimaryBtn')
    $installBtn.Margin = [System.Windows.Thickness]::new(0,16,0,8)
    $installBtn.Padding = [System.Windows.Thickness]::new(20,12,20,12)
    $installBtn.HorizontalAlignment = "Stretch"

    $installBtnStack = [System.Windows.Controls.StackPanel]::new()
    $installBtnStack.Orientation = "Horizontal"
    $installBtnStack.HorizontalAlignment = "Center"
    $installIcon = [System.Windows.Controls.TextBlock]::new()
    $installIcon.Text = [char]0xE896
    $installIcon.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe MDL2 Assets")
    $installIcon.FontSize = 14
    $installIcon.VerticalAlignment = "Center"
    $installIcon.Margin = [System.Windows.Thickness]::new(0,0,8,0)
    $installBtnStack.Children.Add($installIcon) | Out-Null
    $installLabel = [System.Windows.Controls.TextBlock]::new()
    $installLabel.Text = "Ausgewählte Software installieren"
    $installLabel.FontSize = 13
    $installLabel.VerticalAlignment = "Center"
    $installBtnStack.Children.Add($installLabel) | Out-Null
    $installBtn.Content = $installBtnStack

    $installBtn.Add_Click({ Start-SoftwareInstall })
    $container.Children.Add($installBtn) | Out-Null

    $global:Pages['Software'].Children.Add($container) | Out-Null
    $global:PageBuilt['Software'] = $true

    # --- Loading-Hinweis für Winget-Check ---
    $softLoadingBanner = [System.Windows.Controls.Border]::new()
    $softLoadingBanner.Background = $global:BrushConv.ConvertFromString("#1A2A1A")
    $softLoadingBanner.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $softLoadingBanner.Padding = [System.Windows.Thickness]::new(12,8,12,8)
    $softLoadingBanner.Margin = [System.Windows.Thickness]::new(0,8,0,0)
    $softLoadingBanner.HorizontalAlignment = "Left"
    $softLoadingStack = [System.Windows.Controls.StackPanel]::new()
    $softLoadingStack.Orientation = "Horizontal"
    $softLoadingDot = [System.Windows.Shapes.Ellipse]::new()
    $softLoadingDot.Width = 8; $softLoadingDot.Height = 8
    $softLoadingDot.Fill = $global:HealthBrushes['Green']
    $softLoadingDot.VerticalAlignment = "Center"
    $softLoadingDot.Margin = [System.Windows.Thickness]::new(0,0,8,0)
    # Pulsier-Animation
    $pulseAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $pulseAnim.From = 1.0; $pulseAnim.To = 0.3
    $pulseAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(600))
    $pulseAnim.AutoReverse = $true
    $pulseAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $softLoadingDot.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulseAnim)
    $softLoadingStack.Children.Add($softLoadingDot) | Out-Null
    $softLoadingTxt = [System.Windows.Controls.TextBlock]::new()
    $softLoadingTxt.Text = "Installierte Software wird erkannt..."
    $softLoadingTxt.FontSize = 11
    $softLoadingTxt.Foreground = $global:BrushConv.ConvertFromString("#888888")
    $softLoadingTxt.VerticalAlignment = "Center"
    $softLoadingStack.Children.Add($softLoadingTxt) | Out-Null
    $softLoadingBanner.Child = $softLoadingStack
    $container.Children.Add($softLoadingBanner) | Out-Null

    # --- Async: Bereits installierte Software erkennen ---
    $checkRs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $checkRs.Open()
    $checkPs = [System.Management.Automation.PowerShell]::Create()
    $checkPs.Runspace = $checkRs
    $checkPs.AddScript({
        $output = & winget list --accept-source-agreements 2>&1
        return ($output -join "`n")
    }) | Out-Null
    $checkHandle = $checkPs.BeginInvoke()

    $instCheckTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $instCheckTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $instCheckState = @{ PS=$checkPs; RS=$checkRs; Handle=$checkHandle; Timer=$instCheckTimer }
    $instCheckTimer.Add_Tick({
        if (-not $instCheckState.Handle.IsCompleted) { return }
        $instCheckState.Timer.Stop()
        try {
            $result = $instCheckState.PS.EndInvoke($instCheckState.Handle)
            $installedText = "$result"
            $convInst = [System.Windows.Media.BrushConverter]::new()
            foreach ($entry in $global:SoftwareChecks.GetEnumerator()) {
                if ($installedText -match [regex]::Escape($entry.Key)) {
                    $entry.Value.Checkbox.ToolTip = "Bereits installiert"
                    # Gruenes "Installiert" Badge neben dem Namen
                    $nameRow = $entry.Value.NameRow
                    if ($null -ne $nameRow) {
                        $badge = [System.Windows.Controls.Border]::new()
                        $badge.Background = $convInst.ConvertFromString("#152A15")
                        $badge.CornerRadius = [System.Windows.CornerRadius]::new(8)
                        $badge.Padding = [System.Windows.Thickness]::new(6,1,6,1)
                        $badge.Margin = [System.Windows.Thickness]::new(8,0,0,0)
                        $badge.VerticalAlignment = "Center"
                        [System.Windows.Controls.DockPanel]::SetDock($badge, "Right")
                        $badgeTb = [System.Windows.Controls.TextBlock]::new()
                        $badgeTb.Text = "Installiert"
                        $badgeTb.FontSize = 9
                        $badgeTb.FontWeight = "Bold"
                        $badgeTb.Foreground = $convInst.ConvertFromString("#3DD68C")
                        $badge.Child = $badgeTb
                        $nameRow.Children.Insert(0, $badge)
                    }
                }
            }
        } catch {}
        # Loading-Banner ausblenden
        try { $softLoadingBanner.Visibility = "Collapsed" } catch {}
        try { $instCheckState.PS.Dispose() } catch {}
        try { $instCheckState.RS.Dispose() } catch {}
    }.GetNewClosure())
    $instCheckTimer.Start()
}

function Start-SoftwareInstall {
    $conv = [System.Windows.Media.BrushConverter]::new()

    # Ausgewaehlte Pakete sammeln
    $selected = @()
    foreach ($entry in $global:SoftwareChecks.GetEnumerator()) {
        if ($entry.Value.Checkbox.IsChecked) {
            $selected += @{ Id = $entry.Key; Name = $entry.Value.Name }
        }
    }

    if ($selected.Count -eq 0) {
        Add-LogLine "Keine Software ausgewählt." "#F5A623"
        return
    }

    # Prüfen ob bereits ein Modul laeuft
    if ($null -ne $global:RunningModule -and $null -ne $global:RunningModule.PowerShell) {
        Add-LogLine "Es läuft bereits ein Modul. Bitte warten." "#F5A623"
        return
    }

    # Bestaetigungs-Overlay anzeigen
    $ctrl['OptionsOverlay'].Visibility = 'Visible'
    $ctrl['OptionsTitle'].Text = "Software installieren"
    if ($null -ne $ctrl['OptionsSubtitle']) { $ctrl['OptionsSubtitle'].Text = "Bitte bestätigen" }
    if ($null -ne $ctrl['OptionsWarnText']) { $ctrl['OptionsWarnText'].Visibility = 'Collapsed' }
    $ctrl['OptionsStack'].Children.Clear()

    # Info-Text
    $infoTb = [System.Windows.Controls.TextBlock]::new()
    $infoTb.Text = "$($selected.Count) Programm(e) werden installiert:"
    $infoTb.FontSize = 12
    $infoTb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtSecondary'))
    $infoTb.Margin = [System.Windows.Thickness]::new(0,0,0,8)
    $ctrl['OptionsStack'].Children.Add($infoTb) | Out-Null

    # Scrollbare Liste der ausgewaehlten Programme
    $listScroll = [System.Windows.Controls.ScrollViewer]::new()
    $listScroll.MaxHeight = 200
    $listScroll.VerticalScrollBarVisibility = "Auto"
    $listStack = [System.Windows.Controls.StackPanel]::new()
    foreach ($pkg in ($selected | Sort-Object Name)) {
        $pkgTb = [System.Windows.Controls.TextBlock]::new()
        $pkgTb.Text = "  $([char]0x2022) $($pkg.Name)"
        $pkgTb.FontSize = 11
        $pkgTb.Foreground = $conv.ConvertFromString((Get-ThemeColor 'TxtPrimary'))
        $pkgTb.Margin = [System.Windows.Thickness]::new(0,1,0,1)
        $listStack.Children.Add($pkgTb) | Out-Null
    }
    $listScroll.Content = $listStack
    $ctrl['OptionsStack'].Children.Add($listScroll) | Out-Null

    # Warnung
    $warnTb = [System.Windows.Controls.TextBlock]::new()
    $warnTb.Text = "Einige Installer öffnen ein Fenster im Hintergrund. Bitte prüfe die Taskleiste falls eine Installation länger dauert."
    $warnTb.TextWrapping = "Wrap"
    $warnTb.FontSize = 11
    $warnTb.Foreground = $conv.ConvertFromString("#F5A623")
    $warnTb.Margin = [System.Windows.Thickness]::new(0,10,0,0)
    $ctrl['OptionsStack'].Children.Add($warnTb) | Out-Null

    # Bestaetigungs-Button
    $confirmBtn = [System.Windows.Controls.Button]::new()
    $confirmBtn.Content = "Jetzt installieren"
    $confirmBtn.Style = $window.FindResource('PrimaryBtn')
    $confirmBtn.Margin = [System.Windows.Thickness]::new(0,12,0,0)
    $confirmBtn.Padding = [System.Windows.Thickness]::new(14,8,14,8)
    $confirmBtn.HorizontalAlignment = "Stretch"
    $capturedSelected = $selected
    $confirmBtn.Add_Click({
        $ctrl['OptionsOverlay'].Visibility = 'Collapsed'
        Start-SoftwareInstallAsync -Packages $capturedSelected
    }.GetNewClosure())
    $ctrl['OptionsStack'].Children.Add($confirmBtn) | Out-Null
}

function Start-SoftwareInstallAsync {
    param([array]$Packages)

    # Runspace erstellen
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs

    $ps.AddScript({
        param($pkgList)

        $total = $pkgList.Count
        $current = 0
        $okCount = 0
        $failCount = 0
        $skipCount = 0

        foreach ($pkg in $pkgList) {
            $current++
            $pct = [int](($current - 1) / $total * 100)
            Write-Information "__PROGRESS:$pct"
            Write-Information "[$current/$total] Installiere $($pkg.Name) ($($pkg.Id))..."

            # Prüfen ob bereits installiert
            $listCheck = & winget list --id $pkg.Id --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0 -and ($listCheck -join "`n") -match [regex]::Escape($pkg.Id)) {
                Write-Information "__PKG_SKIP:$($pkg.Name)"
                Write-Information "  $($pkg.Name) ist bereits installiert - übersprungen."
                $skipCount++
                continue
            }

            # Installieren (silent, auto-accept)
            $output = & winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements 2>&1
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                Write-Information "__PKG_OK:$($pkg.Name)"
                Write-Information "  $($pkg.Name) erfolgreich installiert."
                $okCount++
            } else {
                $errMsg = ($output | Where-Object { $_ -match 'error|fail|blocked' } | Select-Object -First 1)
                if (-not $errMsg) { $errMsg = "Exit-Code $exitCode" }
                Write-Information "__PKG_FAIL:$($pkg.Name)|$errMsg"
                Write-Warning "$($pkg.Name): Installation fehlgeschlagen - $errMsg"
                $failCount++
            }
        }

        Write-Information "__PROGRESS:100"
        Write-Information ""
        Write-Information "=== Installation abgeschlossen ==="
        Write-Information "  Installiert: $okCount"
        Write-Information "  Übersprungen: $skipCount"
        Write-Information "  Fehlgeschlagen: $failCount"
        Write-Information "__INSTALL_DONE"
    }).AddArgument($Packages) | Out-Null

    $handle = $ps.BeginInvoke()

    # UI-Feedback
    Add-LogLine "Software-Installation gestartet ($($Packages.Count) Pakete)..." (Get-ThemeColor 'AccentGreen')

    # ActiveModulePanel anzeigen
    $ctrl['ActiveModuleName'].Text = "Software-Installation"
    $ctrl['ActiveModulePercent'].Text = "0%"
    $ctrl['ActiveProgress'].Value = 0
    $ctrl['ActiveModulePanel'].Visibility = "Visible"

    # LiveDot Puls starten
    $pulseAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $pulseAnim.From = 1.0; $pulseAnim.To = 0.3
    $pulseAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(800))
    $pulseAnim.AutoReverse = $true
    $pulseAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulseAnim)

    # Globale Referenz für Stop-Button
    $global:RunningModule = @{
        PowerShell = $ps
        Runspace   = $rs
        ModId      = "swinstall"
        State      = "running"
        CheckTimer = $null
        ProgTimer  = $null
    }

    # Eigener CheckTimer für Software-Installation (Marker-Erkennung)
    $swState = @{
        PS         = $ps
        RS         = $rs
        Handle     = $handle
        InfoIdx    = 0
        WarnIdx    = 0
        ErrIdx     = 0
        TickCount  = 0
        StartTime  = Get-Date
        MaxTicks   = [int](([math]::Max(1800, $Packages.Count * 180)) / 0.4)
    }

    $swTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $swTimer.Interval = [TimeSpan]::FromMilliseconds(400)
    $swTimer.Add_Tick({
        $swState.TickCount++

        # --- Stream-Polling ---
        try {
            while ($swState.InfoIdx -lt $swState.PS.Streams.Information.Count) {
                $rec = $swState.PS.Streams.Information[$swState.InfoIdx]
                $msgData = $rec.MessageData
                $msgText = $null
                $msgColor = "#AAAAAA"
                if ($msgData -is [System.Management.Automation.HostInformationMessage]) {
                    $msgText = $msgData.Message
                } else {
                    $msgText = "$msgData"
                }
                $swState.InfoIdx++

                if (-not $msgText) { continue }

                # Marker-Erkennung
                if ($msgText -match '^__PROGRESS:(\d+)$') {
                    $pct = [int]$Matches[1]
                    $ctrl['ActiveProgress'].Value = $pct
                    $ctrl['ActiveModulePercent'].Text = "$pct%"
                    continue
                }
                if ($msgText -match '^__PKG_SKIP:') { continue }
                if ($msgText -match '^__PKG_OK:') { continue }
                if ($msgText -match '^__PKG_FAIL:') { continue }
                if ($msgText -match '^__INSTALL_DONE') { continue }

                # Normaler Log-Eintrag (mit Farberkennung)
                if ($msgText -match 'erfolgreich') { $msgColor = "#3DD68C" }
                elseif ($msgText -match 'übersprungen|bereits') { $msgColor = "#777777" }
                elseif ($msgText -match 'fehlgeschlagen') { $msgColor = "#FF5F57" }
                elseif ($msgText -match '^\[') { $msgColor = (Get-ThemeColor 'AccentGreen') }
                elseif ($msgText -match '^===') { $msgColor = "#2DD4BF" }

                Add-LogLine "  $msgText" $msgColor
            }
            while ($swState.WarnIdx -lt $swState.PS.Streams.Warning.Count) {
                $msg = $swState.PS.Streams.Warning[$swState.WarnIdx].Message
                if ($msg) { Add-LogLine "  $msg" "#F5A623" }
                $swState.WarnIdx++
            }
            while ($swState.ErrIdx -lt $swState.PS.Streams.Error.Count) {
                $e = $swState.PS.Streams.Error[$swState.ErrIdx]
                if ($e) { Add-LogLine "  $($e.Exception.Message)" "#FF5F57" }
                $swState.ErrIdx++
            }
        } catch {}

        # Timeout
        if (-not $swState.Handle.IsCompleted -and $swState.TickCount -ge $swState.MaxTicks) {
            $swTimer.Stop()
            try { $swState.PS.Stop()    } catch {}
            try { $swState.PS.Dispose() } catch {}
            try { $swState.RS.Dispose() } catch {}
            $ctrl['ActiveModulePanel'].Visibility = "Collapsed"
            $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
            $ctrl['LiveDot'].Opacity = 1.0
            Add-LogLine "[TIMEOUT] Software-Installation abgebrochen" "#F5A623"
            $global:RunningModule.PowerShell = $null
            $global:RunningModule.Runspace   = $null
            return
        }

        if (-not $swState.Handle.IsCompleted) { return }

        # --- Fertig: restliche Streams drainieren ---
        $swTimer.Stop()
        try { $swState.PS.EndInvoke($swState.Handle) } catch {}

        try {
            while ($swState.InfoIdx -lt $swState.PS.Streams.Information.Count) {
                $rec = $swState.PS.Streams.Information[$swState.InfoIdx]
                $msgData = $rec.MessageData
                $msgText = if ($msgData -is [System.Management.Automation.HostInformationMessage]) { $msgData.Message } else { "$msgData" }
                $swState.InfoIdx++
                if (-not $msgText -or $msgText -match '^__') { continue }
                $logColor = "#AAAAAA"
                if ($msgText -match 'erfolgreich') { $logColor = "#3DD68C" }
                elseif ($msgText -match 'übersprungen|bereits') { $logColor = "#777777" }
                elseif ($msgText -match 'fehlgeschlagen') { $logColor = "#FF5F57" }
                elseif ($msgText -match '^===') { $logColor = "#2DD4BF" }
                Add-LogLine "  $msgText" $logColor
            }
            while ($swState.WarnIdx -lt $swState.PS.Streams.Warning.Count) {
                $msg = $swState.PS.Streams.Warning[$swState.WarnIdx].Message
                if ($msg) { Add-LogLine "  $msg" "#F5A623" }
                $swState.WarnIdx++
            }
        } catch {}

        $ctrl['ActiveProgress'].Value = 100
        $ctrl['ActiveModulePercent'].Text = "100%"

        Add-LogLine "[OK] Software-Installation abgeschlossen" "#3DD68C"
        Show-ToastNotification -Title "Hellion Power Tool" -Message "Software-Installation abgeschlossen"

        # LiveDot-Puls stoppen
        $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $ctrl['LiveDot'].Opacity = 1.0

        # Panel nach 4s ausblenden
        $swHideTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $swHideTimer.Interval = [TimeSpan]::FromSeconds(4)
        $swHideTimer.Add_Tick({
            $this.Stop()
            $ctrl['ActiveModulePanel'].Visibility = "Collapsed"
        })
        $swHideTimer.Start()

        try { $swState.PS.Dispose() } catch {}
        try { $swState.RS.Dispose() } catch {}

        $global:RunningModule.PowerShell = $null
        $global:RunningModule.Runspace   = $null
        $global:RunningModule.ModId      = $null
        $global:RunningModule.State      = $null
    }.GetNewClosure())
    $swTimer.Start()

    $global:RunningModule.CheckTimer = $swTimer
}

# ===================================================================
# NAVIGATION — Page-Caching mit Visibility Toggle
# ===================================================================
$navMap = @{
    NavDashboard = "all"
    NavRepair    = "repair"
    NavClean     = "clean"
    NavDiagnose  = "diagnose"
    NavManage    = "manage"
    NavSecurity  = "security"
}
$titleMap = @{
    all      = "Dashboard"
    repair   = "System-Reparatur"
    clean    = "Bereinigung"
    diagnose = "Diagnose"
    manage   = "Verwaltung"
    security = "Sicherheit"
}

# --- Switch-Page: Visibility-basierter Seitenwechsel (< 1ms statt 800-1500ms) ---
function Switch-Page {
    param([string]$PageName)
    foreach ($p in @('Dashboard','Settings','Legal','System','Software')) {
        $global:Pages[$p].Visibility = if ($p -eq $PageName) { "Visible" } else { "Collapsed" }
    }
}

# --- Filter-Cards: Zeigt nur Karten einer Kategorie per Visibility (kein Rebuild) ---
function Filter-DashboardCards {
    param([string]$Filter)
    $panel = $global:Pages['Dashboard']
    foreach ($child in $panel.Children) {
        if ($Filter -eq "all") {
            $child.Visibility = "Visible"
        } else {
            $tag = if ($child.Tag) { $child.Tag } else { "" }
            if ($tag -eq "group:$Filter" -or $tag -eq "header:$Filter") {
                $child.Visibility = "Visible"
            } elseif ($tag -match "^(group:|header:)") {
                $child.Visibility = "Collapsed"
            } else {
                # Willkommens-Header nur im "all"-Filter
                $child.Visibility = "Collapsed"
            }
        }
    }
}

# --- Nav-Hilfsfunktion: Alle Nav-Buttons deaktivieren ---
function Reset-NavButtons {
    foreach ($b in $navMap.Keys) { $nb = $ctrl[$b]; if ($nb) { $nb.Tag = "" } }
    $ctrl['NavSettings'].Tag = ""
    $ctrl['NavLegal'].Tag    = ""
    $ctrl['NavSystem'].Tag   = ""
    $ctrl['NavSoftware'].Tag = ""
}

# --- Dashboard-Kategorie-Buttons ---
foreach ($btnName in $navMap.Keys) {
    $capturedFilter = $navMap[$btnName]
    $capturedBtn    = $ctrl[$btnName]
    if ($null -eq $capturedBtn) { continue }
    $capturedBtn.Add_Click({
        Reset-NavButtons
        $capturedBtn.Tag = "active"
        $ctrl['PageTitle'].Text = $titleMap[$capturedFilter]
        $ctrl['BtnAutoMode'].Visibility   = "Visible"
        $ctrl['BtnQuickClean'].Visibility = "Visible"
        $script:CurrentFilter = $capturedFilter
        Switch-Page "Dashboard"
        Filter-DashboardCards -Filter $capturedFilter
    }.GetNewClosure())
}

# --- Settings-Seite (Lazy-Build: erst beim ersten Klick erstellen) ---
$ctrl['NavSettings'].Add_Click({
    Reset-NavButtons
    $ctrl['NavSettings'].Tag = "active"
    $ctrl['PageTitle'].Text = "Einstellungen"
    $ctrl['BtnAutoMode'].Visibility   = "Collapsed"
    $ctrl['BtnQuickClean'].Visibility = "Collapsed"
    $script:CurrentFilter = "settings"
    if (-not $global:PageBuilt['Settings']) { Build-SettingsPage }
    Switch-Page "Settings"
})

# --- Rechtliches-Seite (Lazy-Build) ---
$ctrl['NavLegal'].Add_Click({
    Reset-NavButtons
    $ctrl['NavLegal'].Tag = "active"
    $ctrl['PageTitle'].Text = "Rechtliches & Info"
    $ctrl['BtnAutoMode'].Visibility   = "Collapsed"
    $ctrl['BtnQuickClean'].Visibility = "Collapsed"
    $script:CurrentFilter = "legal"
    if (-not $global:PageBuilt['Legal']) { Build-LegalPage }
    Switch-Page "Legal"
})

# --- System-Seite (Lazy-Build) ---
$ctrl['NavSystem'].Add_Click({
    Reset-NavButtons
    $ctrl['NavSystem'].Tag = "active"
    $ctrl['PageTitle'].Text = "System-Information"
    $ctrl['BtnAutoMode'].Visibility   = "Collapsed"
    $ctrl['BtnQuickClean'].Visibility = "Collapsed"
    $script:CurrentFilter = "system"
    if (-not $global:PageBuilt['System']) { Build-SystemPage }
    Switch-Page "System"
})

# --- Software-Seite (Lazy-Build) ---
$ctrl['NavSoftware'].Add_Click({
    Reset-NavButtons
    $ctrl['NavSoftware'].Tag = "active"
    $ctrl['PageTitle'].Text = "Software installieren"
    $ctrl['BtnAutoMode'].Visibility   = "Collapsed"
    $ctrl['BtnQuickClean'].Visibility = "Collapsed"
    $script:CurrentFilter = "software"
    if (-not $global:PageBuilt['Software']) { Build-SoftwarePage }
    Switch-Page "Software"
})

# ===================================================================
# STOP-BUTTON
# ===================================================================
$ctrl['BtnStopModule'].Add_Click({
    $rm = $global:RunningModule
    if ($null -eq $rm.PowerShell) {
        Add-LogLine "Kein Modul aktiv" "#777777"
        return
    }

    $modTitle = "Unbekannt"
    $modRef   = $global:CardRefs[$rm.ModId]

    # Timer stoppen
    if ($null -ne $rm.CheckTimer) { try { $rm.CheckTimer.Stop() } catch {} }
    if ($null -ne $rm.ProgTimer)  { try { $rm.ProgTimer.Stop()  } catch {} }

    # Runspace abbrechen und aufräumen
    try { $rm.PowerShell.Stop()    } catch {}
    try { $rm.PowerShell.Dispose() } catch {}
    try { $rm.Runspace.Dispose()   } catch {}

    # UI zurücksetzen
    $convS = [System.Windows.Media.BrushConverter]::new()
    if ($null -ne $modRef -and $null -ne $modRef.Dot) {
        $modTitle = $modRef.Title
        $modRef.Dot.Fill          = $convS.ConvertFromString("#F5A623")
        $modRef.Status.Text       = "Abgebrochen"
        $modRef.Status.Foreground = $convS.ConvertFromString("#F5A623")
        $modRef.Prog.Value        = 0
    }
    $ctrl['ActiveModulePanel'].Visibility = "Collapsed"
    # LiveDot-Puls stoppen
    $ctrl['LiveDot'].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $ctrl['LiveDot'].Opacity = 1.0

    Add-LogLine "[STOP] $modTitle manuell abgebrochen" "#F5A623"

    # Referenzen löschen
    $global:RunningModule.PowerShell = $null
    $global:RunningModule.Runspace   = $null
    $global:RunningModule.CheckTimer = $null
    $global:RunningModule.ProgTimer  = $null
    $global:RunningModule.ModId      = $null
    $global:RunningModule.State      = $null
})

# ===================================================================
# TOOLBAR
# ===================================================================
$ctrl['BtnAutoMode'].Add_Click({
    Add-LogLine "=== AUTO-MODUS ===" "#448f45"
    Add-LogLine "Module werden nacheinander ausgeführt..." "#777777"
    Start-ModuleQueue -ModuleIds @('sfc','dism','clean','perf')
})
$ctrl['BtnQuickClean'].Add_Click({
    Add-LogLine "=== QUICK-CLEAN ===" "#F5A623"
    Start-ModuleAsync -ModId 'clean'
})
$ctrl['BtnClearLog'].Add_Click({
    $ctrl['LogOutput'].Document.Blocks.Clear()
    Add-LogLine "Log geleert" "#555555"
})

# ===================================================================
# SYSTEM-HEALTH-TIMER (CPU/RAM/Disk alle 2 Sekunden)
# ===================================================================
$script:HealthTimer = [System.Windows.Threading.DispatcherTimer]::new()
$healthMs = 2000
if ($script:GuiSettings.healthBar -and $script:GuiSettings.healthBar.intervalMs) {
    $healthMs = [int]$script:GuiSettings.healthBar.intervalMs
}
$script:HealthTimer.Interval = [TimeSpan]::FromMilliseconds($healthMs)
$script:HealthRunning = $false

# Hilfsfunktion: Health-Bar UI aktualisieren (läuft im UI-Thread)
function Update-HealthBars {
    param($data)
    try {
        $ctrl['HealthCPU'].Value     = $data.CPU
        $ctrl['HealthCPUText'].Text  = "$($data.CPU)%"
        $ctrl['HealthRAM'].Value     = $data.RAMPct
        $ctrl['HealthRAMText'].Text  = "$($data.RAMPct)%"
        $ctrl['HealthDisk'].Value    = $data.DiskPct
        $ctrl['HealthDiskText'].Text = "$($data.DiskPct)%"

        # Farbschwellen mit gecachten Brushes (kein BrushConverter pro Tick)
        foreach ($pair in @(
            @{ Bar=$ctrl['HealthCPU'];  Txt=$ctrl['HealthCPUText']  },
            @{ Bar=$ctrl['HealthRAM'];  Txt=$ctrl['HealthRAMText']  },
            @{ Bar=$ctrl['HealthDisk']; Txt=$ctrl['HealthDiskText'] }
        )) {
            $v = $pair.Bar.Value
            $colorKey = if ($v -ge 85) { "Red" } elseif ($v -ge 60) { "Orange" } else { "Green" }
            $pair.Bar.Foreground = $global:HealthBrushes[$colorKey]
            $pair.Txt.Foreground = $global:HealthBrushes[$colorKey]
            if ($script:CurrentTheme -eq 'dark') {
                $pair.Bar.Background = $global:HealthBrushes["${colorKey}Bg"]
            }
        }
    } catch {}
}

# Health-Timer: WMI-Queries in Runspace auslagern (blockiert UI nicht)
$script:HealthTimer.Add_Tick({
    if ($script:HealthRunning) { return }
    $script:HealthRunning = $true
    $ps = [PowerShell]::Create()
    $ps.AddScript({
        $cpu = (Get-CimInstance Win32_Processor -EA SilentlyContinue).LoadPercentage
        if ($null -eq $cpu) { $cpu = 0 }
        $os   = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -EA SilentlyContinue
        @{
            CPU     = [int]$cpu
            RAMPct  = if ($os) { [int](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100) } else { 0 }
            DiskPct = if ($disk) { [int](($disk.Size - $disk.FreeSpace) / $disk.Size * 100) } else { 0 }
        }
    })
    $handle = $ps.BeginInvoke()
    # Check-Timer wartet auf Ergebnis (läuft im UI-Thread, blockiert nicht)
    $checkTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(50)
    $checkTimer.Add_Tick({
        if ($handle.IsCompleted) {
            try {
                $result = $ps.EndInvoke($handle)
                if ($result -and $result.Count -gt 0) { Update-HealthBars $result[0] }
            } catch {} finally {
                try { $ps.Dispose() } catch {}
                $checkTimer.Stop()
                $script:HealthRunning = $false
            }
        }
    }.GetNewClosure())
    $checkTimer.Start()
}.GetNewClosure())
# Health-Bar nur starten wenn in Settings aktiviert (default: true)
if ($script:GuiSettings.healthBar.enabled -ne $false) {
    $script:HealthTimer.Start()
} else {
    $ctrl['HealthBarPanel'].Visibility = "Collapsed"
}

# ===================================================================
# STARTUP
# ===================================================================

# Theme anwenden (Dark ist XAML-Default, nur bei Light umschalten)
if ($script:CurrentTheme -ne "dark") { Set-Theme -ThemeName $script:CurrentTheme }

# --- Logo laden ---
function Load-HeaderLogo {
    $logoFile = if ($script:CurrentTheme -eq "light") {
        "Hellion-Online-Media_BlackLogoLong.png"
    } else {
        "Hellion-Online-Media_WhiteLogoLong.png"
    }
    $logoPath = Join-Path $script:RootPath "assets\branding\$logoFile"
    if (Test-Path $logoPath) {
        try {
            $bmp = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bmp.BeginInit()
            $bmp.UriSource = [Uri]::new($logoPath)
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $ctrl['HeaderLogo'].Source = $bmp
        } catch {
            if ($script:DebugLevel -ge 1) { Add-LogLine "[DEBUG] Logo-Ladefehler: $($_.Exception.Message)" "#666666" }
        }
    }
}
Load-HeaderLogo
Set-HeaderGradient

# ===================================================================
# PAGE-CACHING: Jede Seite wird einmal gebaut, dann per Visibility umgeschaltet
# ===================================================================
$global:Pages = @{}
$global:PageBuilt = @{}
foreach ($pageName in @('Dashboard','Settings','Legal','System','Software')) {
    $panel = [System.Windows.Controls.StackPanel]::new()
    $panel.Visibility = "Collapsed"
    $ctrl['CardPanel'].Children.Add($panel) | Out-Null
    $global:Pages[$pageName] = $panel
    $global:PageBuilt[$pageName] = $false
}
$global:Pages['Dashboard'].Visibility = "Visible"

# Dashboard initial bauen
Build-Cards -Filter "all"
$global:PageBuilt['Dashboard'] = $true

$ctrl['LogOutput'].Document.Blocks.Clear()
Add-LogLine "Hellion Power Tool v8.0.0.0 Jörmungandr" "#448f45"
Add-LogLine "--------------------------------" "#444444"

# Prerequisite-Check Ergebnisse im Log anzeigen
$prereqResults = Test-Prerequisites
foreach ($msg in $prereqResults.Messages) {
    switch ($msg.Level) {
        "OK"    { Add-LogLine "[OK] $($msg.Text)" "#3DD68C" }
        "WARN"  { Add-LogLine "[!] $($msg.Text)" "#F5A623" }
        "ERROR" { Add-LogLine "[X] $($msg.Text)" "#FF5F57" }
    }
}

$modCount = (Get-ChildItem "$script:ModulesPath\*.ps1" -EA SilentlyContinue).Count
Add-LogLine "Module geladen: $modCount" "#3DD68C"
Add-LogLine "Admin-Rechte: OK" "#3DD68C"
Add-LogLine "--------------------------------" "#444444"
Add-LogLine "Karte anklicken um Modul zu starten." "#777777"

$ctrl['StatusModules'].Text = "$modCount Module geladen"

# Debug-Badge aktualisieren (falls per Parameter gesetzt)
Update-DebugBadge

# Modul-Validierung beim Start (Debug-Level 1+)
if ($script:DebugLevel -ge 1) {
    Add-LogLine "Modul-Validierung..." "#F5A623"
    $syntaxErrors = 0
    $moduleFiles = Get-ChildItem "$script:ModulesPath\*.ps1" -EA SilentlyContinue
    foreach ($mf in $moduleFiles) {
        $parseErrors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $mf.FullName -Raw), [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            Add-LogLine "  Syntax-Fehler in $($mf.Name)" "#FF5F57"
            $syntaxErrors++
        }
    }
    if ($syntaxErrors -eq 0) {
        Add-LogLine "  Alle $($moduleFiles.Count) Module OK" "#3DD68C"
    }
}

# ===================================================================
# FENSTERPOSITION WIEDERHERSTELLEN
# ===================================================================
$winCfg = $script:GuiSettings.window
if ($winCfg) {
    if ($winCfg.left -ge 0 -and $winCfg.top -ge 0) {
        $window.WindowStartupLocation = "Manual"
        $window.Left = $winCfg.left
        $window.Top  = $winCfg.top
    }
    if ($winCfg.width  -gt 0) { $window.Width  = $winCfg.width }
    if ($winCfg.height -gt 0) { $window.Height = $winCfg.height }
}

# Log-Panel-Breite wiederherstellen
if ($script:GuiSettings['logPanelWidth'] -and $script:GuiSettings['logPanelWidth'] -gt 0) {
    try {
        $mainGrid = $ctrl['CardPanel'].Parent.Parent
        if ($mainGrid -and $mainGrid.ColumnDefinitions.Count -ge 4) {
            $savedWidth = [int]$script:GuiSettings['logPanelWidth']
            if ($savedWidth -ge 200 -and $savedWidth -le 600) {
                $mainGrid.ColumnDefinitions[3].Width = [System.Windows.GridLength]::new($savedWidth)
            }
        }
    } catch {}
}

# ===================================================================
# WINDOW CLOSING — Settings speichern, Timer stoppen
# ===================================================================
$window.Add_Closing({
    # Fensterposition speichern
    if ($null -eq $script:GuiSettings.window -or $script:GuiSettings.window -isnot [hashtable]) {
        $script:GuiSettings.window = @{}
    }
    $script:GuiSettings.window.width  = [int]$window.Width
    $script:GuiSettings.window.height = [int]$window.Height
    $script:GuiSettings.window.left   = [int]$window.Left
    $script:GuiSettings.window.top    = [int]$window.Top
    # Log-Panel-Breite speichern (Column 3 im Haupt-Grid)
    try {
        $mainGrid = $ctrl['CardPanel'].Parent.Parent
        if ($mainGrid -and $mainGrid.ColumnDefinitions.Count -ge 4) {
            $script:GuiSettings['logPanelWidth'] = [int]$mainGrid.ColumnDefinitions[3].ActualWidth
        }
    } catch {}
    Save-GuiSettings
    # Health-Timer stoppen
    if ($null -ne $script:HealthTimer) { $script:HealthTimer.Stop() }
})

# ===================================================================
# AUTO-UPDATE-CHECK BEIM START (async, blockiert nicht)
# ===================================================================
Check-ForUpdate

# ===================================================================
# SHOW (mit Crash Recovery)
# ===================================================================
try {
    $window.ShowDialog() | Out-Null
} catch {
    $crashMsg = "Hellion Power Tool ist unerwartet abgestürzt.`n`nFehler: $($_.Exception.Message)`n`nDetails wurden in die Logdatei geschrieben."
    # Crash in Logdatei schreiben
    try {
        $crashLog = Join-Path $script:RootPath "logs\gui\crash_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $crashDir = Split-Path $crashLog -Parent
        if (-not (Test-Path $crashDir)) { New-Item -Path $crashDir -ItemType Directory -Force | Out-Null }
        @(
            "Hellion Power Tool - Crash Report"
            "Zeitpunkt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            "Fehler: $($_.Exception.Message)"
            "Typ: $($_.Exception.GetType().FullName)"
            "StackTrace:"
            $_.ScriptStackTrace
        ) | Out-File -FilePath $crashLog -Encoding UTF8
    } catch {}
    [System.Windows.MessageBox]::Show($crashMsg, "Hellion Power Tool - Fehler", 'OK', 'Error') | Out-Null
    # Timer aufräumen
    if ($null -ne $script:HealthTimer) { try { $script:HealthTimer.Stop() } catch {} }
}
