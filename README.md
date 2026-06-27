# HyperX Cloud III S Wireless — Auto Audio Switcher

Automatically switches your Windows default audio output device when your HyperX Cloud III S Wireless headset turns on or off. No more manually switching audio devices when you pick up or put down your headset.

---

## How It Works

Windows treats the wireless USB dongle as a permanently active audio device — even when the headset is powered off. This means Windows never switches away from it automatically.

This tool bypasses that by querying the dongle directly over HID (Human Interface Device protocol) to detect whether the headset is actually connected. It was reverse-engineered by capturing USB traffic between the dongle and HyperX NGENUITY using USBPcap and Wireshark.

**Discovery summary:**
- The dongle exposes a HID interface on usage page `0x1C0`
- Sending a query report (`0x0C, 0x02, 0x03, 0x01, 0x00, 0x02...`) causes the dongle to respond
- Response byte[6] = `2` → headset connected; `0` → headset disconnected
- A PowerShell monitor loop calls the Python detector every 3 seconds and switches audio accordingly

---

## Requirements
*Or at least tested on the following.*
- Windows 10 or 11
- Python 3 — [python.org](https://www.python.org/downloads/)
- PowerShell 5.1 or later (built into Windows)
- HyperX Cloud III S Wireless headset

---

## Installation

### Automated (recommended)

1. Clone or download this repo
2. Open PowerShell **as Administrator**
3. Run:

```powershell
.\install.ps1
```

The installer will:
- Install the `pywinusb` Python package
- Install the `AudioDeviceCmdlets` PowerShell module
- Ask where to install the files
- Show your available audio devices and ask which to use
- Create a scheduled task that starts the switcher silently at login

### Manual

1. Install dependencies:

```powershell
pip install pywinusb
Install-Module -Name AudioDeviceCmdlets -Force -Scope CurrentUser
```

2. Copy `src/AudioSwitch.ps1` and `src/hyperx_status.py` to a folder of your choice (e.g. `C:\Scripts\HyperX Audio Switcher\`)

3. Edit `AudioSwitch.ps1` and set your device names:

```powershell
param (
    [string]$HyperXName   = "HyperX Cloud III S Wireless",  # part of your HyperX device name
    [string]$FallbackName = "VG248",                         # part of your fallback device name
    [int]$CheckInterval   = 3                                # seconds between checks
)
```

4. Find your exact device names by running:

```powershell
Import-Module AudioDeviceCmdlets
Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" }
```

5. Create the scheduled task:

```powershell
$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
               -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"C:\Scripts\HyperX Audio Switcher\AudioSwitch.ps1`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName "HyperX Audio Switch" `
    -Action $action -Trigger $trigger -Settings $settings `
    -Principal $principal -Force
```

6. Start it immediately:

```powershell
Start-ScheduledTask -TaskName "HyperX Audio Switch"
```

---

## Configuration

All configuration is done via parameters in `AudioSwitch.ps1`:

| Parameter | Default | Description |
|---|---|---|
| `HyperXName` | `HyperX Cloud III S Wireless` | Partial name of the HyperX audio device |
| `FallbackName` | `(f.e. VG248)` | Partial name of the fallback audio device |
| `CheckInterval` | `3` | Seconds between connection checks |

Partial name matching is used — you don't need the full device name.

---

## Logs

The switcher writes a log file to the same directory as `AudioSwitch.ps1`:

```
AudioSwitch.log
```

Example:
```
2026-06-27 18:32:40 Audio monitor started. HyperX='HyperX Cloud III S Wireless' Fallback='VG248' Interval=3s
2026-06-27 18:33:01 HyperX connected — switching to headset
2026-06-27 18:45:22 HyperX disconnected — switching to fallback
```

---

## Uninstall

```powershell
.\uninstall.ps1
```

Or manually:

```powershell
Unregister-ScheduledTask -TaskName "HyperX Audio Switch" -Confirm:$false
```

---

## Troubleshooting

**Audio doesn't switch:**
- Run `python3 hyperx_status.py` manually — it should print `1` when headset is on and `0` when off
- Check `AudioSwitch.log` for errors

**`pywinusb` import error:**
- Run `pip install pywinusb` and make sure you're using the same Python that `python3` resolves to

**Scheduled task does nothing:**
- Open Task Scheduler, find "HyperX Audio Switch", check Last Run Result
- Temporarily remove `-WindowStyle Hidden` from the task argument to see errors

**Works when run manually but not from the task:**
- Make sure the task principal matches your Windows username
- Re-run `install.ps1` or recreate the task manually using the steps above

---

## Compatibility

| Device | Status |
|---|---|
| HyperX Cloud III S Wireless | ✅ Confirmed working |
| Other HyperX wireless headsets | ⚠️ Untested — may work if VID/PID matches |

The dongle VID/PID is `03F0:06BE` (HP, Inc). If you have a different HyperX wireless headset, open `hyperx_status.py` and update `VENDOR_ID` and `PRODUCT_ID`. You may also need to re-identify the correct usage page and report bytes using USBPcap.

---

## License

MIT
