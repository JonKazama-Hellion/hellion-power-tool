$errors = @()
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content (Join-Path $PSScriptRoot "..\src\hellion_gui.ps1") -Raw),
    [ref]$errors
)
if ($errors.Count -gt 0) {
    Write-Host "SYNTAX ERRORS: $($errors.Count)" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "  Line $($e.Token.StartLine): $($e.Message)" -ForegroundColor Yellow
    }
} else {
    $lines = (Get-Content (Join-Path $PSScriptRoot "..\src\hellion_gui.ps1")).Count
    Write-Host "hellion_gui.ps1: Syntax OK ($lines Zeilen)" -ForegroundColor Green
}
