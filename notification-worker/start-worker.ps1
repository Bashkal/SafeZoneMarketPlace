Write-Host "Starting SafeZone Marketplace Notification Worker..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
node worker.js
