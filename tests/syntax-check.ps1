# Syntax-Check für alle geaenderten Dateien
$files = @(
    "$PSScriptRoot\..\src\hellion_gui.ps1",
    "$PSScriptRoot\..\src\modules\disk-maintenance.ps1",
    "$PSScriptRoot\..\src\modules\network-tools.ps1",
    "$PSScriptRoot\..\src\modules\driver-diagnostic.ps1"
)
$allOk = $true
foreach ($f in $files) {
    $resolved = Resolve-Path $f -ErrorAction SilentlyContinue
    if (-not $resolved) { Write-Output "NICHT GEFUNDEN: $f"; $allOk = $false; continue }
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $resolved -Raw -Encoding UTF8), [ref]$errors)
    $name = Split-Path $resolved -Leaf
    if ($errors.Count -gt 0) {
        $allOk = $false
        foreach ($e in $errors) {
            Write-Output "FEHLER $name Zeile $($e.Token.StartLine): $($e.Message)"
        }
    } else {
        Write-Output "OK: $name"
    }
}
# JSON check
try {
    $json = Get-Content "$PSScriptRoot\..\config\modules.json" -Raw | ConvertFrom-Json
    Write-Output "OK: modules.json ($($json.Count) Module)"
} catch {
    Write-Output "FEHLER: modules.json - $($_.Exception.Message)"
    $allOk = $false
}
if ($allOk) { Write-Output "`nALLE CHECKS BESTANDEN" } else { Write-Output "`nFEHLER GEFUNDEN" }
