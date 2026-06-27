# uninstall.ps1
# Removes the HyperX Audio Switcher scheduled task and optionally deletes files.

#Requires -RunAsAdministrator

$taskName = "HyperX Audio Switch"

Write-Host ""
Write-Host "Uninstalling HyperX Audio Switcher..." -ForegroundColor Yellow

# Stop and remove scheduled task
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Scheduled task '$taskName' removed." -ForegroundColor Green
} else {
    Write-Host "Scheduled task '$taskName' not found, skipping." -ForegroundColor Gray
}

# Optionally delete files
$delete = Read-Host "Delete installed files too? (y/N)"
if ($delete -match "^[Yy]$") {
    $dest = Read-Host "Enter install directory (default: C:\Scripts\HyperX Audio Switcher)"
    if ([string]::IsNullOrWhiteSpace($dest)) { $dest = "C:\Scripts\HyperX Audio Switcher" }
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        Write-Host "Files deleted from $dest" -ForegroundColor Green
    } else {
        Write-Host "Directory not found: $dest" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Cyan
Write-Host ""
