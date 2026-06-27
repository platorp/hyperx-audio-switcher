# install.ps1
# Automated installer for HyperX Audio Switcher
# Run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   HyperX Cloud III S Wireless Audio Switcher  " -ForegroundColor Cyan
Write-Host "                  Installer                     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Check Python ──────────────────────────────────────────────────────────
Write-Host "[1/5] Checking Python 3..." -ForegroundColor Yellow
try {
    $pyVersion = & python3 --version 2>&1
    Write-Host "      Found: $pyVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: python3 not found. Install Python 3 from https://www.python.org/downloads/" -ForegroundColor Red
    exit 1
}

# ── 2. Install Python dependency ─────────────────────────────────────────────
Write-Host "[2/5] Installing pywinusb..." -ForegroundColor Yellow
try {
    & python3 -m pip install pywinusb --quiet
    Write-Host "      pywinusb installed." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to install pywinusb. Run: pip install pywinusb" -ForegroundColor Red
    exit 1
}

# ── 3. Install PowerShell module ─────────────────────────────────────────────
Write-Host "[3/5] Installing AudioDeviceCmdlets..." -ForegroundColor Yellow
try {
    if (-not (Get-Module -ListAvailable -Name AudioDeviceCmdlets)) {
        Install-Module -Name AudioDeviceCmdlets -Force -Scope CurrentUser
    }
    Write-Host "      AudioDeviceCmdlets ready." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to install AudioDeviceCmdlets." -ForegroundColor Red
    exit 1
}

# ── 4. Copy files ─────────────────────────────────────────────────────────────
Write-Host "[4/5] Copying files..." -ForegroundColor Yellow

$defaultDest = "C:\Scripts\HyperX Audio Switcher"
$dest = Read-Host "      Install directory (press Enter for '$defaultDest')"
if ([string]::IsNullOrWhiteSpace($dest)) { $dest = $defaultDest }

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$srcDir = Join-Path $PSScriptRoot "src"
Copy-Item "$srcDir\AudioSwitch.ps1" $dest -Force
Copy-Item "$srcDir\hyperx_status.py" $dest -Force
Write-Host "      Files copied to $dest" -ForegroundColor Green

# ── 5. Configure device names ─────────────────────────────────────────────────
Write-Host ""
Write-Host "      Detecting audio devices..." -ForegroundColor Yellow
Import-Module AudioDeviceCmdlets
$playback = Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" }
Write-Host ""
Write-Host "      Available playback devices:" -ForegroundColor Cyan
$playback | ForEach-Object { Write-Host "        [$($_.Index)] $($_.Name)" }
Write-Host ""

$hyperxName = Read-Host "      Enter part of your HyperX device name (default: 'HyperX Cloud III S Wireless')"
if ([string]::IsNullOrWhiteSpace($hyperxName)) { $hyperxName = "HyperX Cloud III S Wireless" }

$fallbackName = Read-Host "      Enter part of your fallback device name (default: 'VG248')"
if ([string]::IsNullOrWhiteSpace($fallbackName)) { $fallbackName = "VG248" }

# Patch AudioSwitch.ps1 with user values
$switchScript = Join-Path $dest "AudioSwitch.ps1"
(Get-Content $switchScript) `
    -replace 'HyperXName\s+=\s+"[^"]*"', "HyperXName   = `"$hyperxName`"" `
    -replace 'FallbackName\s+=\s+"[^"]*"', "FallbackName = `"$fallbackName`"" |
    Set-Content $switchScript

Write-Host "      Device names saved." -ForegroundColor Green

# ── 6. Create scheduled task ──────────────────────────────────────────────────
Write-Host "[5/5] Creating scheduled task..." -ForegroundColor Yellow

$taskName = "HyperX Audio Switch"
$psFile   = Join-Path $dest "AudioSwitch.ps1"

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
               -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$psFile`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $taskName `
    -Action $action -Trigger $trigger -Settings $settings `
    -Principal $principal -Force | Out-Null

Write-Host "      Scheduled task '$taskName' created." -ForegroundColor Green

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "   The switcher will start automatically on login." -ForegroundColor White
Write-Host "   To start it now, run:" -ForegroundColor White
Write-Host "   Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Logs: $dest\AudioSwitch.log" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
