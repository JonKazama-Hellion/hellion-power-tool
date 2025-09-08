@echo off
echo Signing PowerShell files...

powershell -ExecutionPolicy Bypass -Command ^
"$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like '*Hellion*' } | Select-Object -First 1; ^
if ($cert) { ^
  Get-ChildItem *.ps1 -Recurse | Where-Object { $_.FullName -notlike '*\.git\*' } | ForEach-Object { ^
    $result = Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert; ^
    Write-Host \"$($_.Name): $($result.Status)\" ^
  } ^
} else { ^
  Write-Host 'No certificate found' ^
}"

echo.
echo Signing completed!
pause