# Raspberry Pi Automated Maintenance System
A PowerShell‑based automation tool that performs daily maintenance, OS updates, and Pi‑hole checks on a remote Raspberry Pi via SSH.
The project consists of:

A PowerShell module (RaspberryPi.MaintenanceTools.psm1)
Contains all SSH logic, normalization helpers, and wrapper functions.

A runner script (PiMaintenance-Run.ps1)
Orchestrates the maintenance workflow and writes a structured log.

## Project Structure
Code
raspberryPi_auto_update/
│
├── Modules/
│   └── RaspberryPi.MaintenanceTools.psm1
│
├── PiMaintenance-Run.ps1
└── raspberryPi_update.log

## How It Works
The runner script performs:

1. SSH connection test

2. Maintenance tasks

    - wipe logs
    - disk space
    - uptime
    - temperature
    - throttling
    - Pi‑hole status

3. OS update tasks
    - check upgradeable packages
    - generate summary
    - perform upgrades

4. Pi‑hole update tasks
    - Final summary + runtime

**All SSH commands are executed through the module’s wrappers:**

    - Invoke-MaintenanceCommand
    - Invoke-UpdateCommand

## Running the Script in VS Code

1. Activate your virtual environment
    .\venv\Scripts\Activate.ps1

2. Run the maintenance script
    .\PiMaintenance-Run.ps1

3. Check the log
    raspberryPi_update.log

## Scheduling the Script (Windows Task Scheduler)

1. Program/script:
    powershell.exe

2. Arguments:
    -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\PiMaintenance-Run.ps1"

**Recommended settings:**
1. Run whether user is logged on or not
2. Run with highest privileges
3. Daily trigger
4. Retry on failure

## Notes
- Your PIN is separate from your Windows password.
- Task Scheduler requires your actual password, not your PIN.
- The module must be imported using the correct path.