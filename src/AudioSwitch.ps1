# AudioSwitch.ps1
# Monitors the HyperX Cloud III S Wireless headset connection state and
# automatically switches the Windows default audio output device accordingly.
#
# Requires:
#   - AudioDeviceCmdlets PowerShell module
#   - Python 3 with pywinusb installed
#   - hyperx_status.py in the same directory as this script
#
# Usage:
#   Run directly:   powershell -ExecutionPolicy Bypass -File AudioSwitch.ps1
#   Silently:       powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File AudioSwitch.ps1

param (
    [string]$HyperXName   = "HyperX Cloud III S Wireless",
    [string]$FallbackName = "VG248",
    [int]$CheckInterval   = 3
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PythonScript = Join-Path $ScriptDir "hyperx_status.py"
$LogFile = Join-Path $ScriptDir "AudioSwitch.log"

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Add-Content -Path $LogFile -Value $line
}

try {
    Import-Module AudioDeviceCmdlets -ErrorAction Stop
} catch {
    Write-Log "FATAL: AudioDeviceCmdlets module not found. Run install.ps1 first."
    exit 1
}

if (-not (Test-Path $PythonScript)) {
    Write-Log "FATAL: hyperx_status.py not found at $PythonScript"
    exit 1
}

Write-Log "Audio monitor started. HyperX='$HyperXName' Fallback='$FallbackName' Interval=${CheckInterval}s"

$hyperxActive = $false

while ($true) {
    try {
        $devices        = Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" }
        $hyperxDevice   = $devices | Where-Object { $_.Name -like "*$HyperXName*" } | Select-Object -First 1
        $fallbackDevice = $devices | Where-Object { $_.Name -like "*$FallbackName*" } | Select-Object -First 1

        $result      = & python3 $PythonScript 2>$null
        $isConnected = ($result -eq "1")

        if ($isConnected -and -not $hyperxActive) {
            Write-Log "HyperX connected — switching to headset"
            if ($hyperxDevice) {
                Set-AudioDevice -Index $hyperxDevice.Index | Out-Null
            }
            $hyperxActive = $true
        }
        elseif (-not $isConnected -and $hyperxActive) {
            Write-Log "HyperX disconnected — switching to fallback"
            if ($fallbackDevice) {
                Set-AudioDevice -Index $fallbackDevice.Index | Out-Null
            }
            $hyperxActive = $false
        }
    } catch {
        Write-Log "ERROR: $_"
    }

    Start-Sleep -Seconds $CheckInterval
}
