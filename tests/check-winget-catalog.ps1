# ===================================================================
# WINGET KATALOG-PRUEFUNG
# Prüft ob alle geplanten Software-Pakete via Winget verfügbar sind
# INSTALLIERT NICHTS — nur Suche!
# ===================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WINGET KATALOG-PRUEFUNG" -ForegroundColor White
Write-Host "  Prüft Verfügbarkeit (installiert NICHTS!)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Winget prüfen
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetPath) {
    Write-Host "FEHLER: Winget nicht gefunden!" -ForegroundColor Red
    exit 1
}
Write-Host "Winget gefunden: $($wingetPath.Source)" -ForegroundColor Green
Write-Host ""

# Katalog — WingetId ist der offizielle Paket-Identifier
$catalog = @(
    # --- Browser ---
    @{ Kategorie="Browser";        Name="Google Chrome";           WingetId="Google.Chrome" }
    @{ Kategorie="Browser";        Name="Mozilla Firefox";         WingetId="Mozilla.Firefox" }
    @{ Kategorie="Browser";        Name="Brave Browser";           WingetId="Brave.Brave" }
    @{ Kategorie="Browser";        Name="Vivaldi";                 WingetId="Vivaldi.Vivaldi" }
    @{ Kategorie="Browser";        Name="Opera";                   WingetId="Opera.Opera" }
    @{ Kategorie="Browser";        Name="Opera GX";                WingetId="Opera.OperaGX" }

    # --- Gaming ---
    @{ Kategorie="Gaming";         Name="Steam";                   WingetId="Valve.Steam" }
    @{ Kategorie="Gaming";         Name="Epic Games Launcher";     WingetId="EpicGames.EpicGamesLauncher" }
    @{ Kategorie="Gaming";         Name="GOG Galaxy";              WingetId="GOG.Galaxy" }
    @{ Kategorie="Gaming";         Name="EA App";                  WingetId="ElectronicArts.EADesktop" }

    # --- Kommunikation ---
    @{ Kategorie="Kommunikation";  Name="Discord";                 WingetId="Discord.Discord" }
    @{ Kategorie="Kommunikation";  Name="Microsoft Teams";         WingetId="Microsoft.Teams" }
    @{ Kategorie="Kommunikation";  Name="Zoom";                    WingetId="Zoom.Zoom" }
    @{ Kategorie="Kommunikation";  Name="Telegram Desktop";        WingetId="Telegram.TelegramDesktop" }
    @{ Kategorie="Kommunikation";  Name="Thunderbird";             WingetId="Mozilla.Thunderbird" }

    # --- Media ---
    @{ Kategorie="Media";          Name="VLC Media Player";        WingetId="VideoLAN.VLC" }
    @{ Kategorie="Media";          Name="Spotify";                 WingetId="Spotify.Spotify" }
    @{ Kategorie="Media";          Name="foobar2000";              WingetId="PeterPawlowski.foobar2000" }
    @{ Kategorie="Media";          Name="Winamp";                  WingetId="Winamp.Winamp" }
    @{ Kategorie="Media";          Name="Audacity";                WingetId="Audacity.Audacity" }

    # --- Office ---
    @{ Kategorie="Office";         Name="LibreOffice";             WingetId="TheDocumentFoundation.LibreOffice" }
    @{ Kategorie="Office";         Name="Notepad++";               WingetId="Notepad++.Notepad++" }

    # --- Imaging ---
    @{ Kategorie="Imaging";        Name="Blender";                 WingetId="BlenderFoundation.Blender" }
    @{ Kategorie="Imaging";        Name="GIMP";                    WingetId="GIMP.GIMP" }
    @{ Kategorie="Imaging";        Name="ShareX";                  WingetId="ShareX.ShareX" }

    # --- Coding ---
    @{ Kategorie="Coding";         Name="Git";                     WingetId="Git.Git" }
    @{ Kategorie="Coding";         Name="Visual Studio Code";      WingetId="Microsoft.VisualStudioCode" }
    @{ Kategorie="Coding";         Name="Cursor";                  WingetId="Anysphere.Cursor" }
    @{ Kategorie="Coding";         Name="FileZilla Client";        WingetId="TimKosse.FileZilla.Client" }
    @{ Kategorie="Coding";         Name="WinSCP";                  WingetId="WinSCP.WinSCP" }
    @{ Kategorie="Coding";         Name="PuTTY";                   WingetId="SimonTatham.PuTTY" }

    # --- Tools ---
    @{ Kategorie="Tools";          Name="7-Zip";                   WingetId="7zip.7zip" }
    @{ Kategorie="Tools";          Name="WinRAR";                  WingetId="RARLab.WinRAR" }
    @{ Kategorie="Tools";          Name="Everything Search";       WingetId="voidtools.Everything" }
    @{ Kategorie="Tools";          Name="TreeSize Free";           WingetId="JAMSoftware.TreeSize.Free" }

    # --- Utilities ---
    @{ Kategorie="Utilities";      Name="AnyDesk";                 WingetId="AnyDeskSoftware.AnyDesk" }
    @{ Kategorie="Utilities";      Name="TeamViewer";              WingetId="TeamViewer.TeamViewer" }
    @{ Kategorie="Utilities";      Name="TeraCopy";                WingetId="CodeSector.TeraCopy" }
    @{ Kategorie="Utilities";      Name="PowerToys";               WingetId="Microsoft.PowerToys" }
    @{ Kategorie="Utilities";      Name="Sysinternals Suite";      WingetId="Microsoft.Sysinternals.ProcessExplorer" }
    @{ Kategorie="Utilities";      Name="HWiNFO";                  WingetId="REALiX.HWiNFO" }
    @{ Kategorie="Utilities";      Name="CPU-Z";                   WingetId="CPUID.CPU-Z" }
    @{ Kategorie="Utilities";      Name="CrystalDiskInfo";         WingetId="CrystalDewWorld.CrystalDiskInfo" }

    # --- Security ---
    @{ Kategorie="Security";       Name="Malwarebytes Free";       WingetId="Malwarebytes.Malwarebytes" }
    @{ Kategorie="Security";       Name="Avira Free Antivirus";    WingetId="Avira.FreeAntivirus" }
    @{ Kategorie="Security";       Name="Kaspersky Free";          WingetId="Kaspersky.KasperskyFree" }
    @{ Kategorie="Security";       Name="Bitdefender Free";        WingetId="Bitdefender.Bitdefender" }
    @{ Kategorie="Security";       Name="AdwCleaner";              WingetId="Malwarebytes.AdwCleaner" }
    @{ Kategorie="Security";       Name="SUPERAntiSpyware";        WingetId="SUPERAntiSpyware.SUPERAntiSpyware" }
    @{ Kategorie="Security";       Name="Spybot S&D";              WingetId="SaferNetworking.SpybotSD" }

    # --- Runtimes ---
    @{ Kategorie="Runtimes";       Name=".NET Desktop Runtime 8";  WingetId="Microsoft.DotNet.DesktopRuntime.8" }
    @{ Kategorie="Runtimes";       Name=".NET Desktop Runtime 9";  WingetId="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Kategorie="Runtimes";       Name="VC++ 2015-2022 Redist";   WingetId="Microsoft.VCRedist.2015+.x64" }
    @{ Kategorie="Runtimes";       Name="Java Runtime (Adoptium)"; WingetId="EclipseAdoptium.Temurin.21.JRE" }
    @{ Kategorie="Runtimes";       Name="DirectX Runtime";         WingetId="Microsoft.DirectX" }
    @{ Kategorie="Runtimes";       Name="Node.js LTS";             WingetId="OpenJS.NodeJS.LTS" }
    @{ Kategorie="Runtimes";       Name="Python 3";                WingetId="Python.Python.3.12" }
)

$found = 0
$notFound = 0
$results = @()
$currentKat = ""

foreach ($pkg in $catalog) {
    if ($pkg.Kategorie -ne $currentKat) {
        $currentKat = $pkg.Kategorie
        Write-Host ""
        Write-Host "--- $currentKat ---" -ForegroundColor Cyan
    }

    Write-Host "  Prüfe: $($pkg.Name) ($($pkg.WingetId))... " -NoNewline

    # winget show --id gibt Exit 0 wenn gefunden, sonst Fehler
    $output = & winget show --id $pkg.WingetId --accept-source-agreements 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0 -and $output -notmatch "No package found") {
        Write-Host "OK" -ForegroundColor Green
        $found++
        $results += @{ Pkg=$pkg; Status="OK"; Info="" }
    } else {
        Write-Host "NICHT GEFUNDEN" -ForegroundColor Red
        $notFound++
        # Alternativ-Suche
        Write-Host "    Suche Alternativen..." -ForegroundColor Yellow
        $searchOut = & winget search $pkg.Name --accept-source-agreements 2>&1 | Select-Object -First 8
        $altLines = $searchOut | Where-Object { $_ -match '\S' -and $_ -notmatch '^Name\s' -and $_ -notmatch '^-' }
        if ($altLines) {
            foreach ($line in $altLines) {
                Write-Host "    -> $line" -ForegroundColor DarkYellow
            }
        }
        $results += @{ Pkg=$pkg; Status="FEHLT"; Info=($altLines -join " | ") }
    }
}

# Zusammenfassung
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ERGEBNIS" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gefunden:       $found / $($catalog.Count)" -ForegroundColor Green
Write-Host "  Nicht gefunden: $notFound / $($catalog.Count)" -ForegroundColor $(if ($notFound -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($notFound -gt 0) {
    Write-Host "  FEHLENDE PAKETE:" -ForegroundColor Red
    foreach ($r in ($results | Where-Object { $_.Status -eq "FEHLT" })) {
        Write-Host "    - $($r.Pkg.Name) ($($r.Pkg.WingetId))" -ForegroundColor Yellow
        if ($r.Info) { Write-Host "      Alternativen: $($r.Info)" -ForegroundColor DarkGray }
    }
}

Write-Host ""
Write-Host "Fertig! Nichts wurde installiert." -ForegroundColor Green
